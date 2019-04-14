/*
** Okay, here's the deal...
** This interpreter was adapted from Andrew Plotkin's XZip/MaxTADS, which run
**  under X-Windows and MacOS respectively. Those windowing systems place (0,0)
**  in the upper-left-hand corner, where God intended it.
** OS/2 does not do this.
** Rather than rewrite os2text.c to flip the coordinate system, I have added
**  patches to all of the functions in this file to flip the y coordinate as
**  needed. This requires the use of lClientHeight, a LONG which holds the
**  height of the client window and which is defined in global.h.
*/

#define INCL_PM

#include <os2.h>
#include <string.h>

#include "os2io.h"
#include "global.h"

/* The Rule:
	Leave backcolor as white (or the user's chosen background color)
	Leave mode as patCopy. 
	Text attributes are set as per lcurid. (Somewhat inefficient, but hell.)
*/

/* Here's where I do some of the y-coord switching */
VOID mySetRect(PRECTL prectl, LONG xL, LONG yT, LONG xR, LONG yB)
{
	prectl->xLeft = xL;
	prectl->yBottom = lClientHeight - yB;
	prectl->xRight = xR;
	prectl->yTop = lClientHeight - yT;
}

/* More y-coord switching */
VOID mySetPoint(PPOINTL ppoint, LONG x0, LONG y0)
{
	ppoint->x = x0;
	ppoint->y = lClientHeight - y0;
}

VOID myDrawBox(HPS hps, PRECTL prectl, LONG lCol, BOOL bFill)
{
	POINTL	corner1, corner2;
	LONG	lFlags = DRO_OUTLINE,
			lOldCol;

	if (bFill)
		lFlags = DRO_OUTLINEFILL;
	corner1.x = prectl->xLeft;
	corner1.y = prectl->yBottom;
	corner2.x = prectl->xRight;
	corner2.y = prectl->yTop;

	GpiSetCurrentPosition(hps, &corner1);
	lOldCol = GpiQueryColor(hps);
	GpiSetColor(hps, lCol);
	GpiBox(hps, lFlags, &corner2, 0, 0);
	GpiSetColor(hps, lOldCol);
}


static LONG lcurid;		/* current font id */
static ULONG forecolor = RGB_BLACK;
static ULONG backcolor = RGB_WHITE;
static ULONG curcolor = 0L;
BOOL fCursorBlink = FALSE;		/* True if the cursor is visible in blinking */
static BOOL fDotLocked = FALSE;		// Semaphore: can we access cursor?

void XKnowIgnorance()
{
	lcurid = 0L;
	curcolor = 0L;
}

/* Sets the font in a graphics context */
void XSetFont(HPS hps, LONG font)
{
	lcurid = font;
	GpiSetCharSet(hps, lcurid);
}

void XSetUpWindow(HWND win, HPS hps)
{
}

static void XSetColor(HPS hps, ULONG newcol)
{
	curcolor = newcol;
	GpiSetColor(hps, newcol);
}

void XSetForeColor(ULONG newcol)
{
	forecolor = newcol;
}

void XSetBackColor(ULONG newcol)
{
	backcolor = newcol;
}

/* Clears a window */
void XClearWindow(HPS hps)
{
	RECTL	rclPaint;
	BOOL	f = FALSE;

	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
	}
	myDrawBox(hps, &clientRect, backcolor, TRUE);
	if (f)
		XShowDot(hwndClient, TRUE);
}

/* Prevent updating the already-invalid portions of the window */
void XClipToValid(HWND win, HPS hps)
{
	WinExcludeUpdateRegion(hps, win);
}

/* Clear a square in a window */
void XClearArea(HPS hps, LONG xpos, LONG ypos, LONG wid, LONG hgt)
{
	RECTL	box;
	BOOL	f = FALSE;
	
	mySetRect(&box, xpos, ypos, xpos+wid, ypos+hgt);
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
	}
	myDrawBox(hps, &box, backcolor, TRUE);
	if (f)
		XShowDot(hwndClient, TRUE);
}

void XDrawReverseString(HPS hps, LONG font, short xpos, short ypos, 
	short fieldwid, char *buf, long len)
{
	RECTL box;
	POINTL	point;
	BOOL	f = FALSE;
	int linhgt, linhgtoff;
	
	if (lcurid != font) 
		XSetFont(hps, font);
	
/*	if (font == FONT_STATUS) {
		linhgt = lineheight_status;
		linhgtoff = lineheightoff_status;
	}
	else*/ {
		linhgt = lineheight_story;
		linhgtoff = lineheightoff_story;
	}
	
	mySetRect(&box, xpos, ypos-linhgtoff, xpos+fieldwid, ypos-linhgtoff+linhgt);
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
		fDotLocked = TRUE;
	}
	myDrawBox(hps, &box, forecolor, TRUE);

	mySetPoint(&point, xpos, ypos);

	XSetColor(hps, backcolor);
	GpiCharStringAt(hps, &point, len, buf);
	XSetColor(hps, forecolor);
	if (f) {
		fDotLocked = FALSE;
		XShowDot(hwndClient, TRUE);
	}
}

void XDrawString(HPS hps, LONG font, short xpos, short ypos, char *buf, long len)
{
	POINTL	point;
	BOOL	f = FALSE;
	
	if (lcurid != font)
		XSetFont(hps, font);
	if (curcolor != forecolor)
		GpiSetColor(hps, forecolor);

	mySetPoint(&point, xpos, ypos);
	
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
	}
	GpiCharStringAt(hps, &point, len, buf);
	if (f)
		XShowDot(hwndClient, TRUE);
}

void XTextExtents(HPS hps, LONG font, char *buf, long len, short *width)
{
	POINTL	aptl[TXTBOX_COUNT];

	if (lcurid != font) 
		XSetFont(hps, font);

	GpiQueryTextBox(hps, len, buf, TXTBOX_COUNT, aptl);

	*width = aptl[TXTBOX_CONCAT].x - aptl[TXTBOX_BOTTOMLEFT].x;
}

void XCharPos(HPS hps, LONG font, char *buf, long len, long *positions)
{
	LONG	i;
	PPOINTL	aptl;
	
	if (lcurid != font)
		XSetFont(hps, font);
	
	aptl = (PPOINTL)malloc(sizeof(POINTL) * (len+1));
	if (!GpiQueryCharStringPos(hps, 0L, len, buf, NULL, aptl)) {
		free(aptl);
		return;
	}
	positions[0] = 0;
	for (i = 1; i <= len; i++) {
		positions[i] = aptl[i].x - aptl[0].x;
	}
	free(aptl);
	return;
}

void XFillRectangle(HPS hps, short pattern, short xpos, short ypos, short wid, short hgt)
{
	RECTL box;
	BOOL f = FALSE;
	
	mySetRect(&box, xpos, ypos, xpos+wid, ypos+hgt);
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
		fDotLocked = TRUE;
	}
	switch (pattern) {			/* gcblack &c. defined in os2io.h */
		case gcblack:
			myDrawBox(hps, &box, RGB_BLACK, TRUE);
			break;
		case gcwhite:
			myDrawBox(hps, &box, RGB_WHITE, TRUE);
			break;
		case gcflip:
			WinInvertRect(hps, &box);
			break;
	}
	if (f) {
		fDotLocked = FALSE;
		XShowDot(hwndClient, TRUE);
	}
}


void XFillRectangleColor(HPS hps, LONG lCol, short xpos, short ypos, short wid, short hgt)
{
	RECTL box;
	BOOL f = FALSE;
	
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
		fDotLocked = TRUE;
	}
	mySetRect(&box, xpos, ypos, xpos+wid, ypos+hgt);
	myDrawBox(hps, &box, lCol, TRUE);
	if (f) {
		fDotLocked = FALSE;
		XShowDot(hwndClient, TRUE);
	}
}

void XDrawRectangle(HPS hps, short xpos, short ypos, short wid, short hgt)
{
	RECTL box;
	BOOL f = FALSE;
	
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
	}
	mySetRect(&box, xpos, ypos, xpos+wid+1, ypos+hgt+1);
	myDrawBox(hps, &box, forecolor, FALSE);
	if (f)
		XShowDot(hwndClient, TRUE);
}

/* Actually print the cursor */
static void XDisplayDot(HPS hps)
{
	RECTL	box;
	
	box.xLeft = cursorX;
	box.yBottom = cursorY;
	box.xRight = cursorX + cursorWidth;
	box.yTop = cursorY + cursorHeight;
	WinInvertRect(hps, &box);
	fCursorBlink = !fCursorBlink;
}

/* Show or hide the cursor */
void XShowDot(HWND hwnd, BOOL bFlag)
{
	while (fDotLocked) DosSleep(5);
	fDotLocked = TRUE;
	if (fCursorOn == bFlag && fCursorBlink == bFlag) {
		fDotLocked = FALSE;
		return;
	}
	if ((bFlag && !fCursorBlink) || (!bFlag && fCursorBlink))
		XDisplayDot(hpsClient);
	fCursorOn = bFlag;
	fDotLocked = FALSE;
}

/* Make the cursor blink */
void XBlinkDot(HPS hps)
{
	RECTL	box;

	while (fDotLocked) DosSleep(5);
	fDotLocked = TRUE;
	if (!fCursorOn) {
		fDotLocked = FALSE;
		return;
	}
	XDisplayDot(hpsClient);
	fDotLocked = FALSE;
}

/* Move the cursor around */
void XDrawDot(HPS hps, short xpos, short ypos)
{
	POINTL	ptl;

	mySetPoint(&ptl, xpos-1, ypos+1);
	while (fDotLocked) DosSleep(5);
	fDotLocked = TRUE;
	if (fCursorOn && fCursorBlink) {
		XDisplayDot(hps);
	}
	cursorX = ptl.x;
	cursorY = ptl.y;
	if (fCursorOn && !fCursorBlink) {
		XDisplayDot(hps);
	}
	fDotLocked = FALSE;
}

void XDrawLine(HPS hps, short xpos, short ypos, short xpos2, short ypos2)
{
	POINTL ptl;
	
	mySetPoint(&ptl, xpos, ypos);
	GpiSetCurrentPosition(hps, &ptl);
	mySetPoint(&ptl, xpos2, ypos2);
	GpiLine(hps, &ptl);
}

/* This scrolls the window and then invalidates the new region. */
void XCopyArea(HWND win, short xpos, short ypos, short wid, short hgt, 
	short destxpos, short destypos)
{
	RECTL	rclBox;
	BOOL	f = FALSE;
	
	mySetRect(&rclBox, xpos, ypos, xpos+wid, ypos+hgt);
	if (fCursorOn) {
		f = TRUE;
		XShowDot(hwndClient, FALSE);
	}
	WinScrollWindow(win, destxpos-xpos, ypos-destypos, &rclBox, NULL,
		NULLHANDLE, NULLHANDLE, 0L);
	if (f)
		XShowDot(hwndClient, TRUE);
}
