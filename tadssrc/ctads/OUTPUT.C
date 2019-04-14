#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/output.c 1.9 96/10/14 16:10:39 mroberts Exp $";
#endif

/* Copyright (c) 1987, 1988 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  output     - TADS Interpreter and Compiler formatted Output routines
Function
  Provides formatted output support.  Text that is sent through outformat()
  is displayed with word-wrap so that words fill the line but are not broken
  across lines.  Other routines allow flushing the output buffer, displaying
  blank lines, and logging output to a file as well as to the display.
Notes
  Global int variables pagelength and linewidth, which default to 24 and 80
  respectively, can be set (preferably by os_init()) to different values if
  appropriate; the output routines use these parameters to format lines for
  output and to determine pauses between pages.
Returns
  None
Modified
  04/05/92 MJRoberts     - TADS 2.0 changes
  03/29/92 MJRoberts     - fix unfound formatstring handling
  08/01/91 MJRoberts     - no more mode when debugger is running
  07/18/91 MJRoberts     - improve t_outline [more] behavior
  07/01/91 MJRoberts     - Mac porting changes
  06/05/91 MJRoberts     - add format string support
  03/27/91 MJRoberts     - debugger enhancements
  03/10/91 MJRoberts     - integrate John's qa-scripter mods
  04/24/90 MJRoberts     - add \^ (equivalent to calling "caps()" intrinsic)
  04/16/89 MJRoberts     - add outcformat for compressed strings
  10/30/88 MJRoberts     - add outhide() and outshow() functions
  10/29/88 MJRoberts     - break lines on hyphens
  12/22/87 MJRoberts     - created
*/

#include <stdio.h>
#include <ctype.h>
#include <stdlib.h>
#include <string.h>

#include "os.h"
#include "std.h"
#include "run.h"
#include "voc.h"
#include "tio.h"
#include "mcm.h"

/* use our own isspace - anything about 127 is not a space */
#define outissp(c) (((uchar)c) <= 127 && isspace(c))

#ifndef MAC
# define USE_MORE     /* activate more-mode */
#endif /* MAC */

/* hack to run with TADS 2.0 with minimal reworking */
static runcxdef *runctx;                               /* execution context */
static uchar    *fmsbase;                        /* format string area base */
static uchar    *fmstop;                          /* format string area top */
static objnum    cmdActor;                                 /* current actor */

/* capture data */
static mcmcxdef *capture_ctx;        /* memory context to use for capturing */
static mcmon     capture_obj = MCMONINV;  /* object holding captured output */
static uint      capture_ofs;             /* write offset in capture object */
static int       capturing;              /* true -> we are capturing output */

/*
 *   Begin/end capturing 
 */
void tiocapture(tioctx, memctx, flag)
tiocxdef *tioctx;
mcmcxdef *memctx;
int       flag;
{
    if (flag)
    {
	/* create a new object if necessary */
	if (capture_obj == MCMONINV)
	{
	    mcmalo(memctx, 256, &capture_obj);
	    mcmunlck(memctx, capture_obj);
	}

	/* remember the memory context */
	capture_ctx = memctx;
    }

    /* remember capture status */
    capturing = flag;
}

/* clear all captured output */
void tioclrcapture(tioctx)
tiocxdef *tioctx;
{
    capture_ofs = 0;
}

/* get the object handle of the captured output */
mcmon tiogetcapture(ctx)
tiocxdef *ctx;
{
    return capture_obj;
}

/* get the amount of text captured */
uint tiocapturesize(ctx)
tiocxdef *ctx;
{
    return capture_ofs;
}

/* set up to run */
void tiosetfmt(ctx, rctx, fbase, flen)
tiocxdef *ctx;
runcxdef *rctx;
uchar    *fbase;
uint      flen;
{
    VARUSED(ctx);
    fmsbase = fbase;
    fmstop = fbase + flen;
    runctx = rctx;
}

void tiosetactor(ctx, actor)
tiocxdef *ctx;
objnum    actor;
{
    VARUSED(ctx);
    cmdActor = actor;
}
          

#define MAXWIDTH  OS_MAXWIDTH

/*
 *   QSPACE is the special character for a quoted space (internally,
 *   the sequence "\ " (backslash-space) is converted to QSPACE).  It
 *   must not be any printable character.  The value here may need to
 *   be changed in the extremely unlikely event that TADS is ever ported
 *   to an EBCDIC machine.
 */
#define QSPACE 26

extern int srcquiet;
extern osfildef *scrfp; /* ###indep */

/*
 *   linewidth and pagelength define the size of a page (only important
 *   for pausing during long output).  The default is a 24x80 screen,
 *   but different sizes can be set in os_init where appropriate.
 */
int linewidth = 80;
int pagelength = 24;

/* 
 * This should be TRUE if the output should have two spaces after a period (or other
 * such punctuation. It should generally be TRUE for fixed-width fonts, and FALSE
 * for proportional fonts.
 */
int doublespace = 1; /* ###double */

static uchar linepos;
static uchar linecol;
int linecnt;
static char linebuf[MAXWIDTH];
static char tmpbuf[MAXWIDTH];
static uchar capsflag, nocapsflag;

#ifdef NEVER
static char tabstop[] =
"   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T   T";
#endif /* NEVER */

osfildef *logfp; /* ###indep */
static char logfname[128];

static uchar outcnt, hidout;
static int outflag = 1;
int dbghid;

/*
 *   outcaps() - sets an internal flag which makes the next letter output
 *   a capital, whether it came in that way or not.
 */
void outcaps()
{
    capsflag = 1;
    nocapsflag = 0;
}

void outnocaps()
{
    nocapsflag = 1;
    capsflag = 0;
}

int openlog( fn )
char *fn;
{
    if (closelog()) return( 1 );          /* if there's an old log, close it */
    strcpy( logfname, fn );                   /* save the filename for later */
    logfp = osfopwt( fn ); /* ###indep */
    if ( logfp )
        return( 0 );
    else
        return( 1 );
}

int closelog()
{
    if ( logfp )
    {
        osfcls( logfp ); /* ###indep //###void */
        os_settype( logfname, OSFTLOG );
        logfp = (osfildef *)0; /* ###indep */
    }
    return( 0 );
}

/*
 *   moremode is a flag that tells t_outline whether to count lines that
 *   it's displaying against the total on the screen so far.  If moremode
 *   is true, lines are counted, and the screen is paused with a [More]
 *   message when it's full.  When not in moremode, lines aren't counted.
 *   moremode should be turned off when displaying, for example, status
 *   line information.  Use setmore() to change the moremode state.
 */
int moremode = 1;
void setmore( state )
int state;
{
    moremode = state;
}

static void t_outline(nl,f,a1,a2,a3,a4)
int   nl;                                     /* true if newline is present */
char *f;
long a1, a2, a3, a4;
{
    extern int scrquiet;
    extern int tadsdebug;

    if ( !scrquiet )
    {
#ifdef USE_MORE
        if ( !scrfp && moremode && !tadsdebug && nl
           && linecnt++ >= pagelength )
        {
	    char c;
	    
            os_printf( "[More]" ); os_flush();
	    os_mouhide();
	    do
	    {
		c = os_getc();
	    } while (c != '\r' && c != '\n' && c != ' ');
	    os_moushow();
            os_printf( "\r      \r" );
            if (c == ' ') linecnt = 0;
        }
#endif /* USE_MORE */
        os_printf4( f, a1, a2, a3, a4 ); /* ###indep */
    }
    if ( logfp && moremode )
    {
        fprintf( logfp, f, a1, a2, a3, a4 );
    }
}

void outreset()
{
    linecnt = 0;
}

void outflushn( nl )
int nl;
{
    int    i;
    static int preview;
    static int just_did_nl;

    linebuf[linepos] = '\0';
    i = linepos - 1;
    if (nl)
    {
	for ( ; i >= 0 && outissp(linebuf[i]) ; --i);
    }

    if (nl == 3)
    {
        if (i+1 > preview)
        {
            t_outline(0, "%s", &linebuf[preview]);
            preview += strlen(&linebuf[preview]);
        }
    }
    else
    {
        char *fmt;                       /* format string to use for output */
        int   countnl = 0;         /* true if line counts for [more] paging */
        
        linebuf[++i] = '\0';
        switch(nl)
        {
        case 0:                                               /* no newline */
            fmt = "%s";
            break;
        case 1:                                                  /* newline */
            if (strlen(linebuf) || !just_did_nl)
            {
                fmt = "%s\n";
                countnl = 1;                   /* count the line for paging */
            }
            else
            {
                fmt = "%s";
            }
            break;
        case 2:                                /* no newline, os formatting */
            fmt = "%s ";
            break;
        }
        
        if (strlen(&linebuf[preview]))
            t_outline(countnl, fmt, &linebuf[preview]);
                
        if ( !nl ) os_flush();
        linecol = linepos = preview = 0;
        
        just_did_nl = (nl == 1);
    }
}

void outprv()
{
    linebuf[linepos] = '\0';
#ifdef USE_MORE
    os_printf1( "%s\r", linebuf ); /* ###indep */
#else /* USE_MORE */
    outflushn(3);
#endif /* USE_MORE */
}

void outflush()
{
    outflushn( 1 );
}

/*
 *   outhide() - Hides output until an outshow() is received.
 */
void outhide()
{
    outflag = 0;
    outcnt = 0;
    hidout = 0;
}

/*
 *   Check output status.  Indicate whether output is currently hidden,
 *   and whether any hidden output has occurred. 
 */
void outstat(hidden, output_occurred)
int *hidden;
int *output_occurred;
{
    *hidden = !outflag;
    *output_occurred = outcnt;
}

/* set the flag to indicate that output has occurred */
void outsethidden()
{
    outcnt = 1;
    hidout = 1;
}

/*
 *   outshow() - turns output back on, and returns TRUE (1) if any output
 *   has occurred since the last outshow(), FALSE (0) otherwise.
 */
int outshow()
{
    outflag = 1;
    if ( dbghid && hidout )
    {
        hidout = 0;
        trcsho();
    }
    return( outcnt );
}

void outblank()
{
    outcnt = 1;
    
    if ( !outflag )                                        /* hiding output */
    {
        if ( dbghid && !hidout ) trchid();           /* trace hidden output */
        hidout = 1;                         /* make a note of hidden output */
        if ( !dbghid ) return;           /* normally, don't show the output */
    }

    outflush();
    t_outline(1, "\n", 0L);
}

static void outtab()
{
    do
    {
        linebuf[linepos++] = ' ';
        ++linecol;
    } while (((linecol + 1) & 3) != 0 && linecol < MAXWIDTH);
    /* } while (tabstop[linecol] != 'T' && linecol < MAXWIDTH); */
}

#ifdef USE_MORE
# define FLUSHLINE outflush()
# define IF_MORE_MODE(x)  (x)
#else /* USE_MORE */
# define FLUSHLINE outflushn( 2 )
# define IF_MORE_MODE(x)  0
#endif /* USE_MORE */

static void outchar( c )
char c;
{
    int  i;
    char brkchar;
    int  qspace;
    
    if (outissp(c)) c = ' ';     /* make sure we only output regular spaces */
    
    if ( c == QSPACE )
    {
        qspace = 1;
        c = ' ';
    }
    else if (c > 26)
        qspace = 0;
    
    if (capsflag && isalpha( c ))        /* if capsflag set, capitalize this */
    {
        if (islower( c )) c = toupper( c );         /* convert to upper case */
        capsflag = 0;       /* okay, we've capitalized something; clear flag */
    }
    else if (nocapsflag && isalpha(c))
    {
	if (isupper(c)) c = tolower(c);
	nocapsflag = 0;
    }

    /* if in capture mode, simply capture the character */
    if (capturing)
    {
	uchar *p; /* ###uchar */

	/* lock the object holding the captured text */
	p = mcmlck(capture_ctx, capture_obj);

        /* make sure the capture object is big enough */
	if (mcmobjsiz(capture_ctx, capture_obj) <= capture_ofs)
	{
	    /* expand the object by another 256 bytes */
	    p = mcmrealo(capture_ctx, capture_obj, capture_ofs + 256);
	}

	/* add this character */
	*(p + capture_ofs++) = c;

	/* unlock the capture object */
	mcmtch(capture_ctx, capture_obj);
	mcmunlck(capture_ctx, capture_obj);

	/*
	 *   we're done - we don't want to actually display the character
	 *   while capturing 
	 */
	return;
    }

    /* add the character to out output buffer, flushing as needed */
    if (linecol + 1 < linewidth)         /* there's room for this character */
    {
        /* ignore non-quoted space at start of line */
        if (outissp(c) && !linecol && !qspace) return;
 
        if (outissp(c) && linecol && !qspace )         /* non-quoted space? */
        {
            int  pos1 = linepos - 1;
            char p = linebuf[pos1];             /* check previous character */

            if (outissp(p)) return;               /* ignore repeated spaces */

            /*
             *   Certain punctuation requires a double space:  a period,
             *   a question mark, an exclamation mark, or a colon; or any
             *   of these characters followed by any number of single and/or
             *   double quotes.  First, scan back to before any quotes, if
             *   are on one now, then check the preceding character; if it's
             *   one of the punctuation marks requiring a double space, add
             *   this space a second time.  (In addition to scanning back
             *   past quotes, scan past parentheses, brackets, and braces.)
             *   //###double: This only occurs if doublespace is set TRUE.
             */    
            if (doublespace) { 
              while ( pos1 &&
               ( p == '"' || p == '\'' || p == ')' || p == ']' || p == '}'
                || p == os_hilite(1) || p == os_hilite(2)))
              {
                  p = linebuf[--pos1];
              }
              if ( p == '.' || p == '?' || p == '!' || p == ':' )
              {
                  linebuf[linepos++] = c;
                  ++linecol;
              }
            }
        }
        linebuf[linepos++] = c;                     /* output this character */
        ++linecol;
        return;
    }
    /*
     *   The line would overflow if this character were added.  Find the
     *   most recent word break, and output the line up to the previous
     *   word.  Note that if we're trying to output a space, we'll just
     *   add it to the line buffer.  If the last character of the line
     *   buffer is already a space, we won't do anything right now.  
     */
    if (outissp(c))            /* if this is a space, we're at a word break */
    {
	if (linebuf[linepos - 1] != ' ')
	    linebuf[linepos++] = ' ';

/*	FLUSHLINE; */
	return;
    }
    
    /*
     *   Find the most recent word break: look for a space or a dash.
     *   Note that when "more" mode isn't active (which means that line
     *   breaks will be handled by the OS-level display code rather than
     *   here), we will NOT break on dashes.  Note that if we're about to
     *   write a hyphen, skip all contiguous hyphens, because we want to
     *   keep them together as a single punctuation mark; then keep going
     *   in the normal manner, which will keep the hyphens plus the word
     *   they're attached to together as a single unit.  If spaces precede
     *   the sequence of hyphens, include the prior word as well.  
     */
    i = linepos - 1;
    if (c == '-')
    {
	/* skip any contiguous hyphens at the end of the line */
	for ( ; i >= 0 && linebuf[i] == '-' ; --i);

	/* skip any spaces preceding the sequence of hyphens */
	for ( ; i >= 0 && outissp(linebuf[i]) ; --i);
    }

    /* now find the preceding space */
    for ( ; i >= 0 && !outissp(linebuf[i])
         && !IF_MORE_MODE(linebuf[i] == '-') ; --i);

    if (i < 0)                                 /* did we find a word break? */
    {
        FLUSHLINE;                    /* no - just output the line as it is */
        return;
    }
    brkchar = linebuf[i];                  /* remember word-break character */
    linebuf[linepos] = '\0';              /* null-terminate the line buffer */
    strcpy( tmpbuf, &linebuf[i+1] );        /* next line starts after break */
    if (outissp(brkchar)) linebuf[i] = '\0';   /* terminate at the space... */
    else linebuf[i+1] = '\0';                    /* ... or after the hyphen */
    FLUSHLINE;                               /* output up to the word break */
   
    strcpy( linebuf, tmpbuf );           /* move next line into line buffer */
    linepos = strlen( linebuf );             /* new position in line buffer */
    for (linecol = 0, i = 0 ; i < linepos ; ++i)
        if (linebuf[i] >= 26) ++linecol;
    linebuf[linepos++] = c;              /* add the new character to buffer */
    ++linecol;
}


/*
 *   sqflag, if true, indicates that the string being output by outformat is
 *   compressed, so it must be decompressed as it is output.
 */
static uchar sqflag;

/*
 *   nextout() returns the next character in a string, and updates the
 *   string pointer.
 */
/* static char nextout(char **s); */
#define nextout(s) (*((*(s))++))

/*
 *   start/end watchpoint evaluation - suppress all dstring output
 */
static uchar outwxflag;
void outwx(flag)
int flag;
{
    outwxflag = flag;
}

/*
 *   This routine sends out a string, one character at a time (via outchar).
 *   Escape codes ('\n', and so forth) are handled here.
 *
 *   If sqflag is true, we decompress the string as we output it.
 */
int outformat( s )
char *s;
{
    char     c;
    int      done = 0;
    char     fmsbuf[40];       /* space for constructing translation string */
    int      fmslen;
    char    *f, *f1;
    int      infmt = 0;
    
    c = nextout(&s);
    if ( c ) outcnt = 1;                      /* make a note of this output */

    if ( !outflag )
    {
        if ( dbghid && !hidout ) trchid();    /* trace output for debugging */
        hidout = 1;                         /* make a note of hidden output */
        if ( !dbghid ) return( 0 );      /* not showing output - we're done */
    }
    if (outwxflag) return(0);    /* debugger showing watchpoints - suppress */
    
    while ( c )
    {
        if ( infmt )                      /* collecting translation string? */
        {
            /*
             *   if the string is too long for our buffer, or we've come
             *   across a backslash (illegal in a format string), we must
             *   have a stray percent sign; dump the whole string so far
             *   and act as though we have no format string 
             */
            if ( c == '\\' || f == &fmsbuf[sizeof(fmsbuf)] )
            {
                outchar('%');
                for (f1 = fmsbuf ; f1 < f ; ++f1) outchar(*f1);
                infmt = 0;
                continue;                   /* process this character again */
            }
            else if ( c == '%' && f == fmsbuf )     /* double percent sign? */
            {
                outchar('%');           /* send out the single percent sign */
                infmt = 0;       /* no longer processing translation string */
            }
            else if ( c == '%' ) /* found end of string? translate it if so */
            {
                uchar         *fms;
                int            caps = 0;
                                
                *f = '\0';                         /* null-terminate string */
                if (isupper(fmsbuf[0]))                     /* capitalized? */
                {
                    /* follow capitalization, but look for lower case */
                    fmsbuf[0] = tolower(fmsbuf[0]);        /* for searching */
                    caps = 1;              /* note to follow capitalization */
                }
                
                /* find the string in the format string table */
                fmslen = strlen(fmsbuf);
                for (fms = fmsbase ; fms < fmstop ; )
                {
                    uint propnum;
                    uint len;
                    
                    propnum = osrp2(fms);
                    len = osrp2(fms + 2) - 2;
                    if (len == fmslen &&
                        !memcmp(fms + 4, fmsbuf, (size_t)len))
                    {
                        if (caps) outcaps();
                        runppr(runctx, cmdActor, propnum, 0);
                        break;
                    }

                    /* move on to next formatstring if not yet found */
                    fms += len + 4;
                }

                /* if we can't find it, dump the format string as-is */
                if (fms == fmstop)
                {
                    if (caps) fmsbuf[0] = toupper(fmsbuf[0]); /* rstore cap */
                    outchar('%');
                    for (f1 = fmsbuf ; f1 < f ; ++f1) outchar(*f1);
                    outchar('%');
                }
                
                infmt = 0;               /* no longer reading format string */
            }
            else
            {
                *f++ = c;
            }
            
            c = nextout(&s);
            continue;
        }
        
        if ( c == '%' )                              /* translation string? */
        {
            infmt = 1;
            f = fmsbuf;
        }
        else if ( c == '\\' )                       /* special escape code? */
        {
	    c = nextout(&s);
	    
	    if (capturing && c != '^' && c != 'v' && c != '\0')
	    {
		outchar('\\');
		outchar(c);

		/* keep the \- and also put out the next two chars */
		if (c == '-')
		{
		    outchar(nextout(&s));
		    outchar(nextout(&s));
		}
	    }
	    else
	    {
		switch(c)
		{
		case 'n':                                       /* newline? */
		    outflush();                         /* yes, output line */
                    break;
                case 't':                                           /* tab? */
		    outtab();
                    break;
                case 'b':                                    /* blank line? */
		    outblank();
                    break;
                case '\0':                               /* line ends here? */
                    done = 1;
                    break;
                case ' ':                                   /* quoted space */
		    outchar( QSPACE ); /* send out a quoted space character */
                    break;
                case '^':                      /* capitalize next character */
                    capsflag = 1;
		    nocapsflag = 0;
                    break;
		case 'v':
		    nocapsflag = 1;
		    capsflag = 0;
		    break;
                case '(':
                    if (os_hilite(2)) outchar(os_hilite(2));
                    break;
                case ')':
                    if (os_hilite(1)) outchar(os_hilite(1));
                    break;
		case '-':
		    outchar(nextout(&s));
		    outchar(nextout(&s));
		    break;
                default:                 /* just pass invalid escapes as-is */
                    outchar( c );
		}
            }
        }
        else outchar( c );                              /* normal character */
        
        if ( done ) c = '\0';
        else c = nextout(&s);
    }

    /* if we ended up inside what looked like a format string, dump string */
    if (infmt)
    {
        outchar('%');
        for (f1 = fmsbuf ; f1 < f ; ++f1) outchar(*f1);
    }

    return( 0 );                                                 /* success */
}

/*
 *   outcformat is used to output compressed strings.  It merely sets a flag
 *   and calls outformat.
 */
int outcformat( s )
char *s;
{
    int retval;
    
    retval = outformat( s );
    return( retval );
}
