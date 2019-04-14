/*
** Notice that coords in this file assume (0,0) is the upper-left corner.
**  OS/2, in order to satisfy stuffy mathematicians, places (0,0) in the
**  lower-left corner. All coord transformations are handled in os2emux.c.
*/

#define INCL_PM
#define DEBUGMSG(x)	WinMessageBox(HWND_DESKTOP, NULLHANDLE, \
x, "TADS/2 Message", 0, MB_OK)

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include <os2.h>

#include "os2io.h"
#include "global.h"

static char *charbuf;
static long numchars;
static long char_size;

typedef struct style_t {
	long attr; /* The logical font # */
	long pos; /* position this style starts at */
} style;

static style *stylelist;
static long numstyles;
static long styles_size;

typedef struct word_t {
	long pos, len;
	long width; /* in pixels */
	long attr;

	long *letterpos; /* if not NULL, an array[0..len] of pixel offsets from wordpos; */
} word;

#define lineflag_Wrapped (1) /* line is a wrap or split from previous line */
#define lineflag_Extra (2) /* the magic extra line on the end */

typedef struct line_t {
	long pos; /* line starts here */
	long posend; /* number of chars. May not be exactly to start of next line, because it won't include the newline or space that ends the line. */
	word *wordlist;
	long numwords;
	short flags;
} lline;

static lline *linelist;
static long numlines;
static long lines_size;

static lline *tmplinelist;
static long tmplines_size;

static long scrollpos; /* character position at top of screen */
static long scrollline; /* number of line at top of screen, after xtext_layout() */
static long lastlineseen; /* last line read before more stuff was output. (-1) to indicate 
	all lines read. */
static long dotpos, dotlen; /* dotpos is in [0..numchars] */
static BOOL atdotbegin = TRUE;	// Should xted_movedot change the beginning of the dot?
static long lastdotpos = (-1), lastdotlen = 0; /* cached values -- fiddled inside 
	xtext_layout() */

static short isactive; /* is window active? */
static BOOL caretlit = FALSE; /* is the text caret blinked on or off? */

static long dirtybeg, dirtyend; /* mark the limits of what needs to be laid out, [) format */
static long dirtydelta; /* how much the dirty area has grown (or shrunk) */
static long startlay; /* pos of the char that starts the first laid-out line. */

static short isclear;

static short textwin_x, textwin_y, textwin_w, textwin_h;
static RECTL textwin_cursor_box; /* This is the area in which the cursor is an ibeam. */

#define xiobackstore (TRUE) /* OS/2 doesn't do back-store. But we hack around the problem. */

typedef struct histunit {
	char *str;
	short len;
} histunit;
static short historylength; /* cached in case the pref is changed */
static short historynum, historypos;
static histunit *history;

/* these are for xtext editing */
static long buflen;
static char *buffer;
static int *readpos;
static long inputfence;
static int *killflag;
static short originalattr;

/* Some semaphores since xtext_layout & redrawtext aren't re-entrant */
static BOOL inLayout = FALSE, inRedraw = FALSE, inFlipSelection = FALSE;

#define collapse_dot()  (dotpos += dotlen, dotlen = 0)
#define SIDEMARGIN (3)
#define TOPMARGIN (2)
#define BARWIDTH (15)

static long linesperpage;

static void redrawtext(HPS hps, long beg, long num, short clearnum);
static void flip_selection(long dpos, long dlen);
static void find_loc_by_pos(long pos, short *xposret, short *yposret);
static void xtext_layout(HPS hps);
static long find_pos_by_loc(short xpos, short ypos);
static long find_line_by_pos(long pos, long guessline);
static void measure_word(lline *curline, word *curword);
static void adjust_elevator(void);

extern VOID ShowScrollBar(BOOL bFlag);
extern SHORT UpdateFonts(HPS hps, BOOL fUpdate);

void mainwin_activate(BOOL turnon);
void mainwin_caret_changed(BOOL turnon);
void xtext_delete_start(long num);

extern void macrom_dirty_macrolist(void);

void xtext_init()
{
	char_size = 256;
	charbuf = (char *)malloc(sizeof(char) * char_size);
	numchars = 0;

	styles_size = 8;
	stylelist = (style *)malloc(sizeof(style) * styles_size);
	numstyles = 1;
	stylelist[0].pos = 0;
	stylelist[0].attr = lcidNorm; /* NORMAL style */

	lines_size = 8;
	linelist = (lline *)malloc(sizeof(lline) * lines_size);
	numlines = 0;

	tmplines_size = 8;
	tmplinelist = (lline *)malloc(sizeof(lline) * tmplines_size);

	historynum = 0;
	historylength = prefsTADS.historylength;
	history = (histunit *)malloc(historylength * sizeof(histunit));

	scrollpos = 0;
	scrollline = 0;
	startlay = 0; /* not yet used */

	dirtybeg = 0;
	dirtyend = 0;
	dirtydelta = 0;

	dotpos = 0;
	dotlen = 0;

	lastlineseen = 0;
	isclear = TRUE;
}

void xtext_end()
{
	free(charbuf);
	free(stylelist);
	free(linelist);
	free(tmplinelist);
	free(history);
}

void xtext_clear_window()
{
	int ix;
	
	if (!prefsTADS.clearbyscroll) {
		/* normal clear */
		xtext_delete_start(numlines);
	}
	else {
		/* bonzo scrolling clear */
		if (!isclear) {
			for (ix=0; ix<linesperpage; ix++)
				xtext_add('\n', -1);
		}
	}
	
	isclear = TRUE;
}

/* Invalidate the portion of the window which is dirty */
void xtext_dirty_window()
{
	SHORT	x0, y0, x1, y1;
	RECTL	rclBox;
	
	find_loc_by_pos(dirtybeg, &x0, &y0);
	find_loc_by_pos(dirtyend, &x1, &y1);
	mySetRect(&rclBox, x0, y0, x1, y1);
	WinInvalidateRect(hwndClient, &rclBox, TRUE);
}

void xtext_resize(short xpos, short ypos, short width, short height)
{
	textwin_x = xpos+SIDEMARGIN+prefsTADS.marginx;
	textwin_y = ypos+TOPMARGIN+prefsTADS.marginy;
	textwin_w = width-2*SIDEMARGIN-BARWIDTH-2*prefsTADS.marginx;
	textwin_h = height-2*TOPMARGIN-2*prefsTADS.marginy;

	textwin_cursor_box.xLeft = xpos;
	textwin_cursor_box.yTop = ypos;
	textwin_cursor_box.xRight = xpos + width - BARWIDTH;
	textwin_cursor_box.yBottom = ypos + height;
	
	dirtybeg = 0;
	dirtyend = numchars;
	dirtydelta = 0;

	linesperpage = textwin_h / lineheight_story;

	/*xtext_layout();*/ /* handled by WM_PAINT event */
}

/* Note that this function returns a RECTL whose y-coords are flipped. See
   os2emux.c for details */
void xtext_get_text_area(RECTL *box)
{
	*box = textwin_cursor_box;
}

void xtext_redraw(HPS hps)
{
	if (dirtybeg >= 0 || dirtyend >= 0) {
		xtext_layout(hps);
		return;
	}
	
	/* this assumes that an exposure event will not come in between a data update 
		and an xtext_layout call. (unless the exposure event itself forces xtext_layout first?) */
	/*flip_selection(dotpos, dotlen);*/
	redrawtext(hps, 0, -1, -1);
	flip_selection(dotpos, dotlen);

	adjust_elevator();
}

/* the last condition in each of these functions is a special case for the input fence. */

static long back_to_white(long pos)
{
	while (pos > 0 && charbuf[pos-1] != ' ' && charbuf[pos-1] != '\n' && pos-1 != inputfence-1)
		pos--;
	return pos;
}

static long fore_to_white(long pos)
{
	while (pos < numchars && charbuf[pos] != ' ' && charbuf[pos] != '\n' && pos != inputfence-1)
		pos++;
	return pos;
}

static long back_to_nonwhite(long pos)
{
	while (pos > 0 && (charbuf[pos-1] == ' ' || charbuf[pos-1] == '\n' || pos-1 == inputfence-1))
		pos--;
	return pos;
}

static long fore_to_nonwhite(long pos)
{
	while (pos < numchars && (charbuf[pos] == ' ' || charbuf[pos] == '\n' || pos == inputfence-1))
		pos++;
	return pos;
}

/* Coordinates are in screen lines. If num < 0, go to the end. clearnum is the 
	number of lines to clear (may be to a notional line); if 0, don't clear at 
	all; if -1, clear whole window. */
static void redrawtext(HPS hps, long beg, long num, short clearnum)
{
	long lx, wx, end, clearend;
	short ypos, ypos2, xpos, clearcount = 1;
	lline *thisline;
	word *thisword;

//	while (inRedraw) DosSleep(5);	// Not re-entrant, remember?
	inRedraw = TRUE;		// Start the semaphore

	if (num<0)
		end = numlines;
	else {
		end = beg+num;
		if (end > numlines)
			end = numlines;
	}

	if (beg < scrollline)
		beg = scrollline;

/*	if (clearnum > 0) {
		clearend = beg+clearnum;
		ypos = textwin_y + (beg-scrollline) * lineheight_story;
		ypos2 = textwin_y + (clearend-scrollline) * lineheight_story;
		if (ypos2 > textwin_y+textwin_h) {
			ypos2 = textwin_y+textwin_h;
		}
		if (ypos != ypos2)
			XClearArea(hps, textwin_x, ypos, textwin_w, ypos2-ypos);
	}
	else*/ if (clearnum < 0) {
		ypos = textwin_y + (beg-scrollline) * lineheight_story;
		ypos2 = textwin_y+textwin_h;
		if (ypos != ypos2)
			XClearArea(hps, textwin_x, ypos, textwin_w, ypos2-ypos);
	}

	for (lx=beg; lx<end; lx++) {
		thisline = (&linelist[lx]);
		ypos = textwin_y + (lx-scrollline) * lineheight_story;
		if (ypos + lineheight_story > textwin_y + textwin_h)
			break;
		ypos2 = ypos + lineheight_story;
		if (clearcount++ <= clearnum && ypos != ypos2)
			XClearArea(hps, textwin_x, ypos, textwin_w, ypos2-ypos);
		xpos = textwin_x;
		for (wx=0; wx<thisline->numwords; wx++) {
			thisword = thisline->wordlist+wx;
			XDrawString(hps, thisword->attr, xpos, ypos+lineheightoff_story, 
				charbuf+thisline->pos+thisword->pos, thisword->len);
			xpos += thisword->width;
		}
	}

	inRedraw = FALSE;
}

static void adjust_elevator()
{
	/* adjust to [scrollline, scrollline+linesperpage] out of [0, numlines] */
	
	if (numlines-linesperpage > 0) {
		WinSendMsg(hwndVertScroll, SBM_SETSCROLLBAR, MPFROMSHORT(scrollline),
			MPFROM2SHORT(0, numlines-linesperpage));
		WinSendMsg(hwndVertScroll, SBM_SETTHUMBSIZE, MPFROM2SHORT(linesperpage, numlines), 0);
		if (!fScrollVisible)
			ShowScrollBar(TRUE);
	}
	else {
		WinSendMsg(hwndVertScroll, SBM_SETSCROLLBAR, 0, 0);
		WinSendMsg(hwndVertScroll, SBM_SETTHUMBSIZE, 0, 0);
		if (fScrollVisible)
			ShowScrollBar(FALSE);
	}
}

void scroll_to(long newscrollline)
{
	long oldscrollline;

	if (newscrollline > numlines-linesperpage)
		newscrollline = numlines-linesperpage;
	if (newscrollline < 0)
		newscrollline = 0;

	if (numlines == 0)
		scrollpos = 0;
	else
		scrollpos = linelist[newscrollline].pos;
		
	if (scrollline != newscrollline) {
		short ypos1, ypos2, yhgt;

		oldscrollline = scrollline;
		flip_selection(dotpos, dotlen);
		scrollline = newscrollline;
		if (oldscrollline < newscrollline) {
			/* scroll down -- things move up */
			ypos1 = textwin_y + (newscrollline-oldscrollline) * lineheight_story;
			ypos2 = textwin_y + (0) * lineheight_story;
			yhgt = (linesperpage-(newscrollline-oldscrollline)) * lineheight_story;
			XCopyArea(hwndClient, textwin_x-SIDEMARGIN, ypos1, textwin_w+2*SIDEMARGIN, yhgt, 
				textwin_x-SIDEMARGIN, ypos2);
			redrawtext(hpsClient, linesperpage + oldscrollline, (newscrollline-oldscrollline), 
				(newscrollline-oldscrollline));
		}
		else {
			/* scroll up -- things move down */
			ypos2 = textwin_y + (oldscrollline-newscrollline) * lineheight_story;
			ypos1 = textwin_y + (0) * lineheight_story;
			yhgt = (linesperpage-(oldscrollline-newscrollline)) * lineheight_story;
			XCopyArea(hwndClient, textwin_x-SIDEMARGIN, ypos1, 
				textwin_w+2*SIDEMARGIN, yhgt, textwin_x-SIDEMARGIN, ypos2);
			redrawtext(hpsClient, newscrollline, (oldscrollline-newscrollline), 
				(oldscrollline-newscrollline));
		}
		flip_selection(dotpos, dotlen);
		adjust_elevator();
	}
}

static void refiddle_selection(long oldpos, long oldlen, long newpos, long newlen)
{
	if (oldlen==0 || newlen==0 || oldpos<0 || newpos<0) {
		flip_selection(oldpos, oldlen);
		flip_selection(newpos, newlen);
		return;
	}

	if (oldpos == newpos) {
		/* start at same place */
		if (oldlen < newlen) {
			flip_selection(oldpos+oldlen, newlen-oldlen);
		}
		else if (newlen < oldlen) {
			flip_selection(oldpos+newlen, oldlen-newlen);
		}
		return;
	}
	if (oldpos+oldlen == newpos+newlen) {
		/* end at same place */
		if (oldpos < newpos) {
			flip_selection(oldpos, newpos-oldpos);
		}
		else if (newpos < oldpos) {
			flip_selection(newpos, oldpos-newpos);
		}
		return;
	}

	flip_selection(oldpos, oldlen);
	flip_selection(newpos, newlen);
}

void mainwin_activate(BOOL turnon)
{
	RECTL box;
	
	if (turnon) {
		if (!isactive) {
			isactive = TRUE;
			flip_selection(dotpos, dotlen);	
		}
	}
	else {
		if (isactive) {
			flip_selection(dotpos, dotlen);
			isactive = FALSE;	
		}
	}
}

void mainwin_caret_changed(BOOL turnon)
{
	if (turnon) {
		if (!caretlit/*fCursorOn*/) {
			caretlit = TRUE;
			//fCursorOn = TRUE;
			if (dotlen==0) {
				flip_selection(dotpos, dotlen);
				XShowDot(hwndClient, TRUE);
			}
		}
	}
	else {
		if (caretlit/*fCursorOn*/) {
			if (dotlen==0)
				flip_selection(dotpos, dotlen);
			caretlit = FALSE;	
			XShowDot(hwndClient, FALSE);
		}
	}
}

static void flip_selection(long dpos, long dlen)
{
	short xpos, ypos;
	short xpos2, ypos2;
	long ybody, ybody2;

//	while (inFlipSelection) DosSleep(5);
	if (!isactive) {
		return; /* not the front window */
	}

	if (dpos < 0) {
		return; /* dot hidden */
	}

	inFlipSelection = TRUE;
	if (dlen==0) {
		find_loc_by_pos(dpos, &xpos, &ypos);
		if (ypos < 0 || ypos+lineheight_story > textwin_h) {
			/* Do nothing */
		}
		else if (!caretlit/*fCursorOn*/) {
			/* Do nothing */
		}
		else {
			XShowDot(hwndClient, TRUE);
			XDrawDot(hpsClient, textwin_x + xpos,
				textwin_y + ypos + lineheightoff_story);
		}
	}
	else {
		XShowDot(hwndClient, FALSE);	/* Hide the cursor */
		find_loc_by_pos(dpos, &xpos, &ypos);
		find_loc_by_pos(dpos+dlen, &xpos2, &ypos2);
		if (ypos==ypos2) {
			/* within one line */
			if (xpos!=xpos2 && ypos>=0 && ypos+lineheight_story<=textwin_h) {
				XFillRectangle(hpsClient, gcflip, xpos+textwin_x, ypos+textwin_y, xpos2-xpos,
					lineheight_story);
			}
		}
		else {
			if (xpos < textwin_w && ypos>=0 && ypos+lineheight_story<=textwin_h) {
				/* first partial line */
				XFillRectangle(hpsClient, gcflip, xpos+textwin_x, ypos+textwin_y, textwin_w-xpos,
					lineheight_story);
			}
			ybody = ypos+lineheight_story;
			ybody2 = ypos2;
			if (ybody < ybody2 && ybody2>=0 && ybody+lineheight_story<=textwin_h) {
				if (ybody < 0)
					ybody = 0;
				if (ybody2+lineheight_story > textwin_h)
					ybody2 = textwin_h;
				/* main body */
				XFillRectangle(hpsClient, gcflip, textwin_x, ybody+textwin_y, textwin_w, ybody2-ybody);
			}
			if (xpos2 && ypos2>=0 && ypos2+lineheight_story<=textwin_h) {
				/* last partial line */
				XFillRectangle(hpsClient, gcflip, textwin_x, ypos2+textwin_y, xpos2, lineheight_story);
			}
		}
	}
	inFlipSelection = FALSE;
}

/* push lines from tmplinelist[0..newnum) in place of linelist[oldbeg..oldend) */
static void slapover(long newnum, long oldbeg, long oldend)
{
	long wx, lx;
	long newnumlines;

	newnumlines = numlines-(oldend-oldbeg)+newnum;
	if (newnumlines >= lines_size) {
		while (newnumlines >= lines_size)
			lines_size *= 2;
		linelist = (lline *)realloc(linelist, sizeof(lline) * lines_size);
	}

	/* clobber old */
	for (lx=oldbeg; lx<oldend; lx++) {
		word *thisword;
		/* --- finalize word structure --- */
		for (wx=0, thisword=linelist[lx].wordlist;
			 wx<linelist[lx].numwords;
			 wx++, thisword++) {
			if (thisword->letterpos) {
				free(thisword->letterpos);
			}
		}
		free(linelist[lx].wordlist);
		linelist[lx].wordlist = NULL;
	}

	if (oldend < numlines && newnumlines != numlines) {
		memmove(&linelist[oldend+(newnumlines-numlines)],
				&linelist[oldend],
				sizeof(lline) * (numlines-oldend));
	}
	/* ### adjust scrollline by difference too? */
	numlines = newnumlines;

	if (newnum) {
		memcpy(&linelist[oldbeg],
			   &tmplinelist[0],
			   sizeof(lline) * (newnum));
	}
}

/* xpos, ypos are relative to textwin origin */
static long find_pos_by_loc(short xpos, short ypos)
{
	short ix;
	long linenum;
	long wx, atpos, newpos;
	lline *curline;
	word *curword;

	if (ypos < 0) 
		linenum = (-1) - ((-1)-ypos / lineheight_story);
	else
		linenum = ypos / lineheight_story;

	linenum += scrollline;

	if (linenum < 0)
		return 0;
	if (linenum >= numlines)
		return numchars;

	curline = (&linelist[linenum]);
	if (xpos < 0) {
		return curline->pos; /* beginning of line */
	}
	
	atpos = 0;
	for (wx=0; wx<curline->numwords; wx++) {
		newpos = atpos + curline->wordlist[wx].width;
		if (xpos < newpos)
			break;
		atpos = newpos;
	}
	if (wx==curline->numwords) {
		return curline->posend; /* end of line */
	}

	xpos -= atpos; /* now xpos is relative to word beginning */
	curword = (&curline->wordlist[wx]);
	if (!curword->letterpos)
		measure_word(curline, curword);

	for (ix=0; ix<curword->len; ix++) {
		if (xpos <= (curword->letterpos[ix]+curword->letterpos[ix+1])/2)
			break;
	}
	return curline->pos + curword->pos + ix;
}

/* returns the last line such that pos >= line.pos. guessline is a guess to start searching at; 
	-1 means end of file. Can return -1 if pos is before the start of the layout. */
static long find_line_by_pos(long pos, long guessline)
{
	long lx;

	if (guessline < 0 || guessline >= numlines)
		guessline = numlines-1;

	if (guessline < numlines-1 && linelist[guessline].pos <= pos) {
		for (lx=guessline; lx<numlines; lx++) {
			if (linelist[lx].pos > pos)
				break;
		}
		lx--;
	}
	else {
		for (lx=guessline; lx>=0; lx--) {
			if (linelist[lx].pos <= pos)
				break;
		}
	}

	return lx;
}

/* returns values relative to textwin origin, at top of line. */
static void find_loc_by_pos(long pos, short *xposret, short *yposret)
{
	long lx;
	long wx, atpos;
	lline *curline;
	word *curword;

	lx = find_line_by_pos(pos, -1);
	if (lx < 0) {
		/* somehow before first line laid out */
		*xposret = 0;
		*yposret = (-scrollline) * lineheight_story;
		return;
	}
	curline = (&linelist[lx]);

	*yposret = (lx-scrollline) * lineheight_story;
	atpos = 0;
	for (wx=0; wx<curline->numwords; wx++) {
		if (curline->pos+curline->wordlist[wx].pos+curline->wordlist[wx].len >= pos)
			break;
		atpos += curline->wordlist[wx].width;
	}
	if (wx==curline->numwords) {
		*xposret = atpos;
		return;
	}

	curword = (&curline->wordlist[wx]);
	if (!curword->letterpos)
		measure_word(curline, curword);

	atpos += curword->letterpos[pos - (curline->pos+curword->pos)];

	*xposret = atpos;
}

static void measure_word(lline *curline, word *curword)
{
	short cx;
	char *buf;
	short direction;
	short letterwid;
	long *arr;

	if (curword->letterpos)
		free(curword->letterpos);

	arr = (long *)malloc(sizeof(long) * (curword->len+1));

	buf = charbuf+curline->pos+curword->pos;
	XCharPos(hpsClient, curword->attr, buf, curword->len, arr);
	arr[curword->len] = curword->width;

	curword->letterpos = arr;
}

static void strip_garbage(char *buf, long len)
{
	long ix;

	for (ix=0; ix<len; ix++, buf++) {
		if (iscntrl(*buf))
			*buf = ' ';
	}
}

/* pos < 0 means add at end.
 all this is grotesquely inefficient if adding anywhere but the end. */
void xtext_add(char ch, long pos)
{
	if (ch != '\n')
		isclear = FALSE;
	if (pos<0)
		pos = numchars;
	xtext_replace(pos, 0, &ch, 1);
}

/* update data, adjusting dot and styles as necessary. */
void xtext_replace(long pos, long oldlen, char *buf, long newlen)
{
	long newnumchars;

	newnumchars = numchars-oldlen+newlen;
	if (newnumchars >= char_size) {
		while (newnumchars >= char_size) 
			char_size *= 2;
		charbuf = (char *)realloc(charbuf, sizeof(char) * char_size);
	}

	if (pos < dirtybeg || dirtybeg < 0)
		dirtybeg = pos;

	if (newlen != oldlen) {
		if (pos+oldlen != numchars) {
			memmove(charbuf+pos+newlen, charbuf+pos+oldlen, sizeof(char) * (numchars-(pos+oldlen)));
		}
		if (numchars >= dirtyend)
			dirtyend = numchars+1;
		dirtydelta += (newlen-oldlen);
	}
	else {
		if (pos+newlen >= dirtyend)
			dirtyend = pos+newlen+1;
		dirtydelta += (newlen-oldlen);
	}

	/* copy in the new stuff */
	if (newlen)
		memmove(charbuf+pos, buf, sizeof(char) * newlen);

	/* diddle the dot */
	if (dotpos >= pos+oldlen) {
		/* starts after changed region */
		dotpos += (newlen-oldlen);
	}
	else if (dotpos >= pos) {
		/* starts inside changed region */
		if (dotpos+dotlen >= pos+oldlen) {
			/* ...but ends after it */
			dotlen = (dotpos+dotlen)-(pos+oldlen);
			dotpos = pos+newlen;
		}
		else {
			/* ...and ends inside it */
			dotpos = pos+newlen;
			dotlen = 0;
		}
	}
	else {
		/* starts before changed region */
		if (dotpos+dotlen >= pos+oldlen) {
			/* ...but ends after it */
			dotlen += (newlen-oldlen);
		}
		else if (dotpos+dotlen >= pos) {
			/* ...but ends inside it */
			dotlen = (pos+newlen) - dotpos;
		}			
	}

	numchars = newnumchars;
}

void xtext_setstyle(long pos, short attr)
{
	long sx;

	if (pos < 0)
		pos = numchars;

	for (sx=numstyles-1; sx>=0; sx--) {
		if (stylelist[sx].pos <= pos) {
			break;
		}
	}
	if (sx < 0) {
		printf("### oops, went back behind style 0\n");
		return;
	}

	if (stylelist[sx].pos == pos) {
		stylelist[sx].attr = attr;
	}
	else {
		/* insert a style after sx */
		sx++;
		if (numstyles+1 >= styles_size) {
			styles_size *= 2;
			stylelist = (style *)realloc(stylelist, sizeof(style) * styles_size);
		}
		numstyles++;
		if (sx < numstyles) {
			memmove(&stylelist[sx+1], &stylelist[sx], sizeof(style) * (numstyles-sx));
			stylelist[sx].pos = pos;
			stylelist[sx].attr = attr;
		}
	}

	if (pos != numchars) {
		/* ### should only go to next style */
		dirtybeg = pos;
		dirtyend = numchars;
		dirtydelta = 0;
		xtext_layout(hpsClient);
	}
}

void xtext_set_lastseen()
{
	lastlineseen = numlines;
}

void xtext_end_visible()
{
	long lx;

	if (!prefsTADS.paging
		|| lastlineseen < 0 || lastlineseen >= (numlines-linesperpage)-1) {
		/* straight to end */
		if (scrollline < numlines-linesperpage) {
			scroll_to(numlines-linesperpage);
		}
	}
	else {
		lx = lastlineseen-1;
		while (lx < numlines-linesperpage) {
			scroll_to(lx);
			SetMessageBoxText("[Hit any key to continue.]", FALSE);
			xio_pause();
			if (scrollline == lx)		// Deal w/the user scrolling
				lx += (linesperpage-1);	//  by him/herself
			else lx = scrollline + (linesperpage-1);
		}
		scroll_to(numlines-linesperpage);
		SetMessageBoxText(NULL, FALSE);
	}

	lastlineseen = (-1);
}

/* delete num lines from the top */
void xtext_delete_start(long num)
{
	long delchars;
	long lx, sx, sx2;
	short origattr;

	if (num > numlines)
		num = numlines;
	if (num < 0)
		num = 0;

	if (numlines==0)
		return;

	if (num < numlines)
		delchars = linelist[num].pos;
	else
		delchars = numchars;

	if (!delchars)
		return;

	/* lines */
	slapover(0, 0, num);
	for (lx=0; lx<numlines; lx++) {
		linelist[lx].pos -= delchars;
		linelist[lx].posend -= delchars;
	}

	/* styles */
	for (sx=0; sx<numstyles; sx++) {
		if (stylelist[sx].pos > delchars)
			break;
	}
	if (sx>0) {
		origattr = stylelist[sx-1].attr;
		stylelist[0].pos = 0;
		stylelist[0].attr = origattr;
		for (sx2=1; sx<numstyles; sx++, sx2++) {
			stylelist[sx2].pos = stylelist[sx].pos - delchars;
			stylelist[sx2].attr = stylelist[sx].attr;
		}
		numstyles = sx2;
	}

	/* chars */
	if (numchars > delchars) 
		memmove(&charbuf[0], &charbuf[delchars], sizeof(char) * (numchars-delchars));
	numchars -= delchars;

	/* adjust, I mean, everything */
	if (dirtybeg != (-1)) {
		dirtybeg -= delchars;
		dirtyend -= delchars;
		if (dirtyend < 0) {
			dirtybeg = (-1);
			dirtyend = (-1);
		}
		else if (dirtybeg < 0) {
			dirtybeg = 0;
		}
	}

	dotpos -= delchars;
	if (dotpos < 0) {
		if (dotpos+dotlen < 0) {
			dotpos = 0;
			dotlen = 0;
		}
		else {
			dotlen += dotpos;
			dotpos = 0;
		}
	}
	lastdotpos -= delchars;
	if (lastdotpos < 0) {
		if (lastdotpos+lastdotlen < 0) {
			lastdotpos = 0;
			lastdotlen = 0;
		}
		else {
			lastdotlen += lastdotpos;
			lastdotpos = 0;
		}
	}
	inputfence -= delchars;
	if (inputfence < 0)
		inputfence = 0;

	if (lastlineseen != (-1)) {
		lastlineseen -= num;
		if (lastlineseen < 0)
			lastlineseen = (-1);
	}

	scrollline -= num;
	scrollpos -= delchars;
	if (scrollline < 0 || scrollpos < 0) {
		scrollline = 0;
		scrollpos = 0;
		redrawtext(hpsClient, 0, -1, -1);
		flip_selection(dotpos, dotlen);
		adjust_elevator();
	}
	else {
		adjust_elevator();
	}
}

void xtext_adjust()
{
	HPS	hpsTemp;
	
	hpsTemp = WinGetPS(hwndClient);
	XClipToValid(hwndClient, hpsTemp);
	GpiCreateLogColorTable(hpsTemp, 0L, LCOLF_RGB, 0L, 0L, NULL);
	UpdateFonts(hpsTemp, FALSE);
	XKnowIgnorance();
	xtext_layout(hpsTemp);
	WinReleasePS(hpsTemp);
	XKnowIgnorance();
}

static void xtext_layout(HPS hps)
{
	long ix, jx, ejx, lx;
	long styx, nextstylepos;
	short curstyle;
	long overline, overlineend;
	long tmpl, startpos;
	short prevflags;
	short needwholeredraw;
	short fontspace;
	
	short direction;
	short wordwidth;
	
	static long lastline = 0; /* last line dirtied */

	//while (inLayout) DosSleep(5);	// Wait for interlopers
	inLayout = TRUE;		// Start the semaphore

	if (dirtybeg < 0 || dirtyend < 0) {
		if (lastdotpos != dotpos || lastdotlen != dotlen) {
			refiddle_selection(lastdotpos, lastdotlen, dotpos, dotlen);
			/*flip_selection(lastdotpos, lastdotlen);*/
			lastdotpos = dotpos;
			lastdotlen = dotlen;
			/*flip_selection(lastdotpos, lastdotlen);*/
		}
		inLayout = FALSE;
		return;
	}

	/* if any text diddling is done, we'll just flip automatically */
	flip_selection(lastdotpos, lastdotlen);
	lastdotpos = dotpos;
	lastdotlen = dotlen;

	if (numlines==0) {
		overline = 0;
		startpos = 0;
	}
	else {
		lx = find_line_by_pos(dirtybeg, lastline);
		/* now lx is the line containing dirtybeg */

		if (lx>0 && lx<numlines && (linelist[lx].flags & lineflag_Wrapped)) {
			/* do layout from previous line, in case a word from the changed area pops back there. */
			lx--;
		}
		overline = lx;
		startpos = linelist[overline].pos;
	}

	/* get the first relevant style */
	for (styx=numstyles-1; styx>0; styx--)
		if (stylelist[styx].pos <= startpos)
			break;
	if (styx==numstyles-1)
		nextstylepos = numchars+10;
	else
		nextstylepos = stylelist[styx+1].pos;
	curstyle = stylelist[styx].attr;
	if (curstyle == lcidNorm)
		fontspace = iNormSpace;
	else if (curstyle == lcidBold)
		fontspace = iBoldSpace;

	/* start a-layin' */
	tmpl = 0;
	prevflags = 0;

	while (startpos<numchars && !(startpos >= dirtyend && charbuf[startpos]=='\n')) {
		lline *thisline;
		long tmpw, tmpwords_size;
		long widthsofar, spaceswidth;

		if (tmpl+1 >= tmplines_size) {
			/* the +1 allows the extra blank line at the end */
			tmplines_size *= 2;
			tmplinelist = (lline *)realloc(tmplinelist, sizeof(lline) * tmplines_size);
		}
		thisline = (&tmplinelist[tmpl]);
		thisline->flags = prevflags;
		tmpwords_size = 8;
		thisline->wordlist = (word *)malloc(tmpwords_size * sizeof(word));
		tmpw = 0;

		/*printf("### laying tmpline %d, from charpos %d\n", tmpl, startpos);*/
		tmpl++;
		if (tmpl > 5000) {	/* Check for runaway printing */
			DEBUGMSG("BUG: Runaway xtext_layout()! Quit while you can!");
			inLayout = FALSE;
			return;
		}

		ix = startpos;
		widthsofar = 0;
		prevflags = 0;

		while (ix<numchars && charbuf[ix]!='\n') {
			word *thisword;

			while (ix >= nextstylepos) {
				/* ahead one style */
				styx++;
				if (styx==numstyles-1)
					nextstylepos = numchars+10;
				else
					nextstylepos = stylelist[styx+1].pos;
				curstyle = stylelist[styx].attr;
				if (curstyle == lcidNorm)
					fontspace = iNormSpace;
				else if (curstyle == lcidBold)
					fontspace = iBoldSpace;
			}

			if (tmpw >= tmpwords_size) {
				tmpwords_size *= 2;
				thisline->wordlist = (word *)realloc(thisline->wordlist, tmpwords_size * sizeof(word));
			}
			thisword = (&thisline->wordlist[tmpw]);
			/* --- initialize word structure --- */

			thisword->letterpos = NULL;
			for (jx=ix; 
				jx<numchars && jx<nextstylepos && charbuf[jx]!=' ' && charbuf[jx]!='\n'; 
				jx++);
			
			XTextExtents(hps, curstyle, charbuf+ix, jx-ix, &wordwidth);
			if (widthsofar + wordwidth > textwin_w) {
				prevflags = lineflag_Wrapped;
				if (tmpw == 0) {
					/* do something clever -- split the word, put first part in tmplist. */
					long letx;
					long wordwidthsofar = 0;
					for (letx=ix; letx<jx; letx++) {
						XTextExtents(hps, curstyle, charbuf+letx, 1, &wordwidth);
						if (widthsofar + wordwidthsofar+wordwidth > textwin_w) {
							break;
						}
						wordwidthsofar += wordwidth;
					}
					jx = letx;
					wordwidth = wordwidthsofar;
					/* spaceswidth and ejx will be 0 */
					/* don't break */
				}
				else {
					/* ejx and spaceswidth are properly set from last word, trim them off. */
					thisword--;
					thisword->len -= ejx;
					thisword->width -= spaceswidth;
					break;
				}
			}

			/* figure out trailing whitespace */
			ejx = 0;
			while (jx+ejx<numchars && jx+ejx<nextstylepos && charbuf[jx+ejx]==' ') {
				ejx++;
			}
			spaceswidth = ejx * fontspace;
			
			/* put the word in tmplist */
			thisword->pos = ix-startpos;
			thisword->len = jx+ejx-ix;
			thisword->attr = curstyle;
			thisword->width = wordwidth+spaceswidth;
			widthsofar += thisword->width;
			tmpw++; 

			ix = jx+ejx;
		}
		thisline->pos = startpos;
		if (tmpw) {
			word *thisword = (&thisline->wordlist[tmpw-1]);
			thisline->posend = startpos + thisword->pos + thisword->len;
		}
		else {
			thisline->posend = startpos;
		}

		if (ix<numchars && charbuf[ix]=='\n')
			ix++;

		thisline->numwords = tmpw;
		if (prefsTADS.fulljustify && prevflags==lineflag_Wrapped && tmpw>1) {
			/* gonna regret this, I just bet */
			long extraspace, each;
			extraspace = textwin_w - widthsofar;
			each = extraspace / (tmpw-1);
			extraspace -= (each*(tmpw-1));
			for (jx=0; jx<extraspace; jx++) {
				thisline->wordlist[jx].width += (each+1);
			}
			for (; jx<tmpw-1; jx++) {
				thisline->wordlist[jx].width += each;
			}
		}
		
		startpos = ix;
	} /* done laying tmp lines */

	if (startpos == numchars && (numchars==0 || charbuf[numchars-1]=='\n')) {
		/* lay one more line! */
		lline *thisline;
		thisline = (&tmplinelist[tmpl]);
		thisline->flags = lineflag_Extra;
		tmpl++;
		
		thisline->wordlist = (word *)malloc(sizeof(word));
		thisline->numwords = 0;
		thisline->pos = startpos;
		thisline->posend = startpos;
	}

	/*printf("### laid %d tmplines, and startpos now %d (delta %d)\n", tmpl, startpos, dirtydelta);*/

	for (lx=overline; lx<numlines && linelist[lx].pos < startpos-dirtydelta; lx++);
	if (lx==numlines-1 && (linelist[lx].flags & lineflag_Extra)) {
		/* account for the extra line */
		lx++;
	}
	overlineend = lx;

	/*printf("### overwrite area is lines [%d..%d) (of %d); replacing with %d lines\n", overline, overlineend, numlines, tmpl);*/

	slapover(tmpl, overline, overlineend);

	lastline = overline+tmpl; /* re-cache value */
	needwholeredraw = FALSE;

	/* diddle scroll stuff */
	if (scrollpos <= dirtybeg) {
		/* disturbance is off bottom of screen -- do nothing */
	}
	else if (scrollpos >= startpos-dirtydelta) {
		/* disturbance is off top of screen -- adjust so that no difference is visible. */
		scrollpos += dirtydelta;
		scrollline += (overline-overlineend) - tmpl;
	}
	else {
		scrollpos += dirtydelta; /* kind of strange, but shouldn't cause trouble */
		if (scrollpos >= numchars)
			scrollpos = numchars-1;
		if (scrollpos < 0)
			scrollpos = 0;
		scrollline = find_line_by_pos(scrollpos, scrollline);
		needwholeredraw = TRUE;
	}

	dirtybeg = -1;
	dirtyend = -1;
	dirtydelta = 0;

	if (needwholeredraw) {
		redrawtext(hps, scrollline, -1, -1);
	}
	else if (tmpl == overlineend-overline) {
		redrawtext(hps, overline, tmpl, tmpl);
	}
	else {
		if (overlineend > numlines)
			redrawtext(hps, overline, -1, overlineend-overline);
		else
			redrawtext(hps, overline, -1, numlines-overline);
	}

	flip_selection(lastdotpos, lastdotlen);

	adjust_elevator();

	inLayout = FALSE;
}

/* Pass the SHORT2FROMMP(mp2) parameter from the scrollbar message to this function */
void scroll_splat(SHORT msg)
{
	switch (msg) {
		case SB_LINEUP:
			xted_scroll(op_UpLine);
			break;
		case SB_LINEDOWN:
			xted_scroll(op_DownLine);
			break;
		case SB_PAGEUP:
			xted_scroll(op_UpPage);
			break;
		case SB_PAGEDOWN:
			xted_scroll(op_DownPage);
			break;
		default:
			return;
	}
}

static long drag_firstbeg, drag_firstend;
static short drag_scrollmode; /* 0 for click in elevator; 1 for dragged in elevator; 
	2 for endzones; 3 for click in background */
static short drag_hitypos; 
static long drag_origline;

/* got a mouse hit. */
void xtext_hitdown(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum)
{
	long pos;
	long px, px2;

		switch (button) { /* text window */
			case 1:
	  		case 2:
				xpos -= textwin_x;
				ypos -= textwin_y;

				pos = find_pos_by_loc(xpos, ypos);
				if (button==1) {
					if (!(clicknum & 1)) {
						px = back_to_white(pos);
						px2 = fore_to_white(pos);
					}
					else {
						px = pos;
						px2 = pos;
					}
					dotpos = px;
					dotlen = px2-px;
					drag_firstbeg = px;
					drag_firstend = px2;
				}
				else {
					if (pos < dotpos+dotlen/2) {
						drag_firstbeg = dotpos+dotlen;
					}
					else {
						drag_firstbeg = dotpos;
					}
					drag_firstend = drag_firstbeg;
					if (pos < drag_firstbeg) {
						if (!(clicknum & 1))
							dotpos = back_to_white(pos);
						else
							dotpos = pos;
						dotlen = drag_firstend-dotpos;
					}
					else if (pos > drag_firstend) {
						dotpos = drag_firstbeg;
						if (!(clicknum & 1))
							dotlen = fore_to_white(pos)-drag_firstbeg;
						else
							dotlen = pos-drag_firstbeg;
					}
					else {
						dotpos = drag_firstbeg;
						dotlen = drag_firstend-drag_firstbeg;
					}
				}
				xtext_layout(hpsClient);
				break;
			default:
				break;
		}
}

void xtext_hitmove(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum)
{
	long pos, px;

	xpos -= textwin_x;
	ypos -= textwin_y;

	switch (button) {
		case 1:
		case 2:
			pos = find_pos_by_loc(xpos, ypos);
			if (pos < drag_firstbeg) {
				if (!(clicknum & 1))
					dotpos = back_to_white(pos);
				else
					dotpos = pos;
				dotlen = drag_firstend-dotpos;
			}
			else if (pos > drag_firstend) {
				dotpos = drag_firstbeg;
				if (!(clicknum & 1))
					dotlen = fore_to_white(pos)-drag_firstbeg;
				else
					dotlen = pos-drag_firstbeg;
			}
			else {
				dotpos = drag_firstbeg;
				dotlen = drag_firstend-drag_firstbeg;
			}
			xtext_layout(hpsClient);
			break;
		default:
			break;
	}
}

void xtext_hitup(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum)
{
	short px;

}

/* A function to find text. Returns TRUE on success, FALSE on failure */
BOOL xtext_find(BOOL fForward, BOOL fCase, char *word)
{
	LONG findPos, findLine;
	int i, iWordLen;
	
	iWordLen = strlen(word);
	if (fForward) {
		findPos = dotpos + dotlen;
		while (findPos <= numchars - iWordLen + 1) {
			if (fCase)
				i = strncmp(charbuf+findPos, word, iWordLen);
			else i = strnicmp(charbuf+findPos, word, iWordLen);
			if (i == 0) {
				findLine = find_line_by_pos(findPos, scrollline);
				scroll_to(findLine);
				refiddle_selection(dotpos, dotlen,
					findPos, iWordLen);
				dotpos = findPos;
				dotlen = iWordLen;
				lastdotpos = dotpos;
				lastdotlen = dotlen;
				return TRUE;
			}
			findPos++;
		}
		return FALSE;
	}
	else {
		findPos = dotpos-1;
		if (findPos > numchars - iWordLen + 1)
			findPos = numchars - iWordLen + 1;
		while (findPos >= 0) {
			if (fCase)
				i = strncmp(charbuf+findPos, word, iWordLen);
			else i = strnicmp(charbuf+findPos, word, iWordLen);
			if (i == 0) {
				findLine = find_line_by_pos(findPos, scrollline);
				scroll_to(findLine);
				refiddle_selection(dotpos, dotlen,
					findPos, iWordLen);
				dotpos = findPos;
				dotlen = iWordLen;
				lastdotpos = dotpos;
				lastdotlen = dotlen;
				return TRUE;
			}
			findPos--;
		}
		return FALSE;
	}
}

/* editing functions... */

void xted_init(int vbuflen, char *vbuffer, int *vreadpos, int *vkillflag)
{
	killflag = vkillflag;
	*killflag = (-1);
	buflen = vbuflen;
	buffer = vbuffer;
	readpos = vreadpos;

	if (*readpos) {
		inputfence = numchars;
		originalattr = stylelist[numstyles-1].attr;
		xtext_setstyle(-1, lcidInput);
		xtext_replace(dotpos, 0, buffer, *readpos);
		xtext_layout(hpsClient);
	}
	else {
		inputfence = numchars;
		originalattr = stylelist[numstyles-1].attr;
		xtext_setstyle(-1, lcidInput);
	}

	historypos = historynum;
}

void xted_insert(short ch)
{
	char realch;
	
	if (iscntrl(ch))
		ch = ' ';
	
	realch = ch;
		
	if (dotpos < inputfence) {
		dotpos = numchars;
		dotlen = 0;
		xtext_add(ch, dotpos);
	}
	else {
		xtext_replace(dotpos, dotlen, &realch, 1);
	}

	xtext_layout(hpsClient);
	xtext_end_visible();
}

void xted_delete(short op)
{
	long pos;

	if (dotpos < inputfence)
		return;
		
	if (dotlen != 0 && (op == op_BackChar || op == op_ForeChar)) {
		xtext_replace(dotpos, dotlen, "", 0);
		xtext_layout(hpsClient);
		return;
	}
		
	collapse_dot();

	switch (op) {
		case op_BackChar:
			if (dotpos <= inputfence)
				return;
			xtext_replace(dotpos-1, 1, "", 0);
			break;
		case op_ForeChar:
			if (dotpos < inputfence || dotpos >= numchars)
				return;
			xtext_replace(dotpos, 1, "", 0);
			break;
		case op_BackWord:
			pos = back_to_nonwhite(dotpos);
			pos = back_to_white(pos);
			if (pos < inputfence)
				pos = inputfence;
			if (pos >= dotpos)
				return;
			xtext_replace(pos, dotpos-pos, "", 0);
			break;
		case op_ForeWord:
			pos = fore_to_nonwhite(dotpos);
			pos = fore_to_white(pos);
			if (pos < inputfence)
				pos = inputfence;
			if (pos <= dotpos)
				return;
			xtext_replace(dotpos, pos-dotpos, "", 0);
			break;
		case op_Line:
			if (dotpos < inputfence)
				return;
			pos = inputfence;
			xtext_replace(pos, numchars-pos, "", 0);
			break;
	}
	xtext_layout(hpsClient);
}

void xted_enter(short op)
{
	long len;

	if (op != op_Enter)
		return;

	if (killflag)
		*killflag = '\n';
	xtext_setstyle(-1, originalattr);

	len = numchars-inputfence;
	if (len > buflen)
		len = buflen;
	memmove(buffer, charbuf+inputfence, len*sizeof(char));
	*readpos = len;

	if (len) {
		/* add to history */
		if (historynum==historylength) {
			free(history[0].str);
			memmove(&history[0], &history[1], (historylength-1) * (sizeof(histunit)));
		}
		else
			historynum++;
		history[historynum-1].str = malloc(len*sizeof(char));
		memmove(history[historynum-1].str, charbuf+inputfence, len*sizeof(char));
		history[historynum-1].len = len;
	}

	xtext_add('\n', -1);
	dotpos = numchars;
	dotlen = 0;
	xtext_layout(hpsClient);

	/* a somewhat strange place to put the buffer trimmer, but what the heck. */
	if (numchars > prefsTADS.buffersize + prefsTADS.bufferslack) {
		long lx;
		for (lx=0; lx<numlines; lx++)
			if (linelist[lx].pos > (numchars-prefsTADS.buffersize))
				break;
		if (lx) {
			xtext_delete_start(lx);
		}
	}
}

void xtext_line_timeout()
{
	long len;

	/* same as xted_enter(), but skip the unnecessary stuff.
	 We don't need to add to history, collapse the dot, xtext_layout, trim the buffer, 
	 or shrink the status window. */
	
	len = numchars-inputfence;
	if (len > buflen)
		len = buflen;
	memmove(buffer, charbuf+inputfence, len*sizeof(char));
	*readpos = len;

	if (len) {
		xtext_replace(inputfence, len, "", 0);
		dotpos = numchars;
		dotlen = 0;
		xtext_layout(hpsClient);
	}

	xtext_setstyle(-1, originalattr);
}

void xted_scroll(short op)
{
	switch (op) {
		case op_UpLine:
			scroll_to(scrollline-1);
			break;
		case op_DownLine:
			scroll_to(scrollline+1);
			break;
		case op_UpPage:
			scroll_to(scrollline-(linesperpage-1));
			break;
		case op_DownPage:
			scroll_to(scrollline+(linesperpage-1));
			break;
		case op_ToTop:
			scroll_to(0);
			break;
		case op_ToBottom:
			scroll_to(numlines);
			break;
	}
}

void xted_movecursor(short op)
{
	long pos;

	switch (op) {
		case op_BackChar:
			collapse_dot();
			if (dotpos > 0) {
				dotpos--;
				if (dotpos < scrollpos)
					xted_scroll(op_UpLine);
			}
			break;
		case op_ForeChar:
			collapse_dot();
			if (dotpos < numchars) {
				dotpos++;
				if (find_line_by_pos(dotpos, scrollline) >=
					scrollline + linesperpage)
					xted_scroll(op_DownLine);
			}
			break;
		case op_BackWord:
			collapse_dot();
			dotpos = back_to_nonwhite(dotpos);
			dotpos = back_to_white(dotpos);
			if (dotpos < scrollpos)
				xted_scroll(op_UpLine);
			break;
		case op_ForeWord:
			collapse_dot();
			dotpos = fore_to_nonwhite(dotpos);
			dotpos = fore_to_white(dotpos);
			if (find_line_by_pos(dotpos, scrollline) >=
				scrollline + linesperpage)
				xted_scroll(op_DownLine);
			break;
		case op_BeginLine:
			if (dotlen) {
				dotlen = 0;
			}
			else {
				if (dotpos >= inputfence)
					dotpos = inputfence;
				else {
					pos = dotpos;
					while (pos > 0 && charbuf[pos-1] != '\n')
						pos--;
					dotpos = pos;
				}
			}
			break;
		case op_EndLine:
			if (dotlen) {
				collapse_dot();
			}
			else {
				if (dotpos >= inputfence)
					dotpos = numchars;
				else {
					pos = dotpos;
					while (pos < numchars && charbuf[pos] != '\n')
						pos++;
					dotpos = pos;
				}
			}
			break;
	}
	xtext_layout(hpsClient);
}

void xted_movedot(short op)
{
	long pos;

	switch (op) {
		case op_BackChar:
			if (dotlen == 0 || atdotbegin) {
				if (dotpos <= 0) return;
				dotpos--;
				dotlen++;
				atdotbegin = TRUE;
			}
			else {
				dotlen--;
				atdotbegin = FALSE;
			}
			if (dotpos < scrollpos)
				xted_scroll(op_UpLine);
			break;
		case op_ForeChar:
			if (dotlen == 0 || !atdotbegin) {
				if (dotpos >= numchars) return;
				dotlen++;
				atdotbegin = FALSE;
			}
			else {
				dotpos++;
				dotlen--;
				atdotbegin = TRUE;
			}
			if (find_line_by_pos(dotpos, scrollline) > scrollline + linesperpage)
				xted_scroll(op_DownLine);
			break;
		case op_BackWord:
			if (dotlen == 0 || atdotbegin) {
				pos = back_to_nonwhite(dotpos);
				pos = back_to_white(pos);
				dotlen = ((dotpos + dotlen) - pos);
				dotpos = pos;
				atdotbegin = TRUE;
			}
			else {
				pos = back_to_nonwhite(dotpos + dotlen);
				pos = back_to_white(pos);
				dotlen = (pos - dotpos);
				if (dotlen < 0) {
					dotpos = pos;
					dotlen = -dotlen;
					atdotbegin = TRUE;
				}
				else atdotbegin = FALSE;
			}
			if (dotpos < scrollpos)
				xted_scroll(op_UpLine);
			break;
		case op_ForeWord:
			if (dotlen == 0 || !atdotbegin) {
				pos = fore_to_nonwhite(dotpos + dotlen);
				pos = fore_to_white(pos);
				dotlen = (pos - dotpos);
				atdotbegin = FALSE;
			}
			else {
				pos = fore_to_nonwhite(dotpos);
				pos = fore_to_white(pos);
				dotlen = ((dotpos + dotlen) - pos);
				if (dotlen < 0) {
					dotlen = -dotlen;
					dotpos = pos - dotlen;
					atdotbegin = FALSE;
				}
				else {
					dotpos = pos;
					atdotbegin = TRUE;
				}
			}
			if (find_line_by_pos(dotpos, scrollline) > scrollline + linesperpage)
				xted_scroll(op_DownLine);
			break;
		case op_BeginLine:
			if (dotpos >= inputfence) {
				if (dotlen == 0 || atdotbegin)
					dotlen = (dotpos + dotlen) - inputfence;
				else
					dotlen = dotpos - inputfence;
				dotpos = inputfence;
				atdotbegin = TRUE;
			}
			else {
				if (dotlen == 0 || atdotbegin)
					pos = dotpos;
				else pos = dotpos + dotlen;
				while (pos > 0 && charbuf[pos-1] != '\n')
					pos--;
				if (dotlen == 0 || atdotbegin) {
					dotlen = (dotpos + dotlen) - pos;
					dotpos = pos;
					atdotbegin = TRUE;
				}
				else {
					dotlen = pos - dotpos;
					if (dotlen < 0) {
						dotlen = -dotlen;
						dotpos = pos;
						atdotbegin = TRUE;
					}
					else atdotbegin = FALSE;
				}
			}
			break;
		case op_EndLine:
			if (dotpos >= inputfence) {
				if (atdotbegin)
					dotpos += dotlen;
				dotlen = numchars - dotpos;
				atdotbegin = FALSE;
			}
			else {
				if (dotlen == 0 || atdotbegin)
					pos = dotpos;
				else pos = dotpos + dotlen;
				while (pos < numchars && charbuf[pos] != '\n')
					pos++;
				if (dotlen == 0 || atdotbegin) {
					dotlen = pos - dotpos;
					if (dotlen < 0) {
						dotlen = -dotlen;
						atdotbegin = TRUE;
					}
					else atdotbegin = FALSE;
				}
				else {
					dotpos += dotlen;
					dotlen = pos - dotpos;
					if (dotlen < 0) {
						dotlen = -dotlen;
						dotpos = pos;
						atdotbegin = TRUE;
					}
					else atdotbegin = FALSE;
				}
			}
			break;
	}
	xtext_layout(hpsClient);
}

void xted_option_capability(BOOL *cuttable, BOOL *copyable)
{
	*copyable = (dotlen != 0);
	*cuttable = (dotlen != 0 && dotpos >= inputfence);
}

void xted_cutbuf(short op)
{
	char *cx;
	long num;
	long tmppos;

	switch (op) {
		case op_Copy:
			if (dotlen) {
				copy_selec_to_clip(charbuf+dotpos, sizeof(char)*dotlen);
			}
			break;
		case op_Wipe:
			if (dotlen) {
				copy_selec_to_clip(charbuf+dotpos, sizeof(char)*dotlen);
				if (dotpos >= inputfence) {
					xtext_replace(dotpos, dotlen, "", 0);
					xtext_layout(hpsClient);
				}
			}
			break;
		case op_Erase:
			if (dotlen) {
				if (dotpos >= inputfence) {
					xtext_replace(dotpos, dotlen, "", 0);
					xtext_layout(hpsClient);
				}
			}
			break;
		case op_Kill:
			if (dotpos < inputfence) {
				/* maybe extend to end-of-line and copy? */
				break;
			}
			dotlen = numchars-dotpos;
			copy_selec_to_clip(charbuf+dotpos, sizeof(char)*dotlen);
			xtext_replace(dotpos, dotlen, "", 0);
			xtext_layout(hpsClient);
			break;
		case op_Yank:
			collapse_dot();
			if (dotpos < inputfence)
				dotpos = numchars;
			/*cx = clone_scrap(&num);
			strip_garbage(cx, num);
			if (cx && num) {
				tmppos = dotpos;
				xtext_replace(tmppos, 0, cx, num);
				dotpos = tmppos+num;
				dotlen = 0;
				free(cx);
			}
			xtext_layout(hpsClient);*/
			break;
		case op_YankReplace:
			/*cx = clone_scrap(&num);
			strip_garbage(cx, num);
			if (cx && num) {
				if (dotpos < inputfence) {
					dotpos = numchars;
					dotlen = 0;
				}
				tmppos = dotpos;
				xtext_replace(tmppos, dotlen, cx, num);
				dotpos = tmppos+num;
				dotlen = 0;
				free(cx);
			}
			xtext_layout(hpsClient);*/
			break;
		case op_Untype:
			if (numchars == inputfence)
				break;
			dotpos = inputfence;
			dotlen = numchars-inputfence;
			copy_selec_to_clip(charbuf+dotpos, sizeof(char)*dotlen);
			xtext_replace(dotpos, dotlen, "", 0);
			xtext_layout(hpsClient);
			break;
	
	}
}

void xted_history(short op)
{
	long pos, len;

	switch (op) {
		case op_BackLine:
			if (historypos > 0) {
				historypos--;
				xtext_replace(inputfence, numchars-inputfence, 
					history[historypos].str, history[historypos].len);
				dotpos = inputfence + history[historypos].len;
				dotlen = 0;
				xtext_layout(hpsClient);
			}
			break;
		case op_ForeLine:
			if (historypos < historynum) {
				historypos++;
				if (historypos < historynum) {
					xtext_replace(inputfence, numchars-inputfence, 
						history[historypos].str, history[historypos].len);
					dotpos = inputfence + history[historypos].len;
					dotlen = 0;
				}
				else {
					xtext_replace(inputfence, numchars-inputfence, "", 0);
					dotpos = inputfence;
					dotlen = 0;
				}
				xtext_layout(hpsClient);
			}
	}
}

// This is only called when restoring macros from the preference file
void xted_define_macro_text(short keynum, char *text)
{
	static cmdentry *macrocommand = NULL;
	char buf[256];
	char *cx, *cx2;

	if (!macrocommand) {
		macrocommand = xkey_find_cmd_by_name("macro");
		if (!macrocommand) {
			SetMessageBoxText("Error: unable to find macro command entry.", TRUE);
			return;
		}
	}
	if (keycmds[keynum] != macrocommand) {
		return;
	}

	cx2 = (char *)malloc(sizeof(char) * (strlen(text)+1));
	strcpy(cx2, text);

	if (keycmdargs[keynum])
		free(keycmdargs[keynum]);
	keycmdargs[keynum] = cx2;
}

void xted_define_macro(short keynum)
{
	static cmdentry *macrocommand = NULL;
	char buf[256];
	char *cx, *cx2;

	if (!macrocommand) {
		macrocommand = xkey_find_cmd_by_name("macro");
		if (!macrocommand) {
			SetMessageBoxText("Error: unable to find macro command entry.", TRUE);
			return;
		}
	}
	if (keycmds[keynum] != macrocommand) {
		if (keycmds[keynum] 
			&& keycmds[keynum]->func == xtexted_meta
			&& keycmds[keynum]->operand == op_DefineMacro) {
			xtexted_meta(op_Cancel);
		}
		else {
			cx = xkey_get_key_name(keynum);
			sprintf(buf, "Key <%s> is not bound to the macro command.", cx);
			SetMessageBoxText(buf, TRUE);
		}
		macrom_dirty_macrolist();
		return;
	}

	if (dotlen == 0) {
		SetMessageBoxText("You must select some text to define this macro as.",
			TRUE);
		macrom_dirty_macrolist();
		return;
	}

	cx2 = (char *)malloc(sizeof(char) * (dotlen+1));
	memcpy(cx2, charbuf+dotpos, dotlen * sizeof(char));
	cx2[dotlen] = '\0';
	strip_garbage(cx2, dotlen);

	if (keycmdargs[keynum])
		free(keycmdargs[keynum]);
	keycmdargs[keynum] = cx2;

	cx = xkey_get_key_name(keynum);
	if (!cx2 || !cx2[0])
		sprintf(buf, "Macro <%s> is not defined.", cx);
	else if (strlen(cx2) > (sizeof(buf)-64))
		sprintf(buf, "Macro <%s> is defined to something too long to display.", cx);
	else
		sprintf(buf, "Macro <%s> defined to \"%s\".", cx, cx2);
	SetMessageBoxText(buf, TRUE);
	macrom_dirty_macrolist();
}

void xted_macro(short op)
{
	char *str, *cx;

	str = keycmdargs[op];
	if (!str || !str[0]) {
		char buf[128];
		cx = xkey_get_key_name(op);
		sprintf(buf, "Macro <%s> is not defined.", cx);
		SetMessageBoxText(buf, TRUE);
		return;
	}

	if (dotpos < inputfence) {
		dotpos = numchars;
		dotlen = 0;
	}
	else {
		collapse_dot();
	}

	xtext_replace(dotpos, 0, str, strlen(str));

	xtext_layout(hpsClient);
	xtext_end_visible();
}

void xted_macro_enter(short op)
{
	char *str, *cx;

	str = keycmdargs[op];
	if (!str || !str[0]) {
		char buf[128];
		cx = xkey_get_key_name(op);
		sprintf(buf, "Macro <%s> is not defined.", cx);
		SetMessageBoxText(buf, TRUE);
		return;
	}

	dotpos = inputfence;
	dotlen = numchars - dotpos;

	xtext_replace(dotpos, dotlen, str, strlen(str));

	xted_enter(op_Enter);
}

void xted_noop(short op)
{
	/* good for debugging */
}
