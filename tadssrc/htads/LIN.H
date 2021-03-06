/*
$Header: c:/tads/tads2/RCS/LIN.H 1.4 94/11/06 13:06:25 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  lin.h - line source definitions
Function
  Definitions for the basic line source class
Notes
  A line source is a mechanism for reading source text.  The tokenizer
  reads its input from a line source.  This is the basic class
  definition; individual line sources will define the functions and
  class data needed.
Modified
  08/14/91 MJRoberts     - creation
*/

#ifndef LIN_INCLUDED
#define LIN_INCLUDED

#ifndef LIB_INCLUDED
#include "lib.h"
#endif
#ifndef LOS_INCLUDED
#include "los.h"
#endif

/* line source superclass structure */
typedef struct lindef lindef;
struct lindef
{
    int   (*lingetp)(/*_ lindef *lin _*/);                 /* get next line */
    void  (*linclsp)(/*_ lindef *lin _*/);             /* close line source */
    void  (*linppos)(/*_ lindef *lin, char *buf, uint buflen _*/);
            /* write printable rep of position to buf (for error reporting) */
    void  (*linglop)(/*_ lindef *lin, uchar *buf _*/);
                       /* generate a line record for an OPCLINE instruction */
    int   (*linwrtp)(/*_ lindef *lin, osfildef *fp _*/);
            /* write line source information to binary file; TRUE ==> error */
    void  (*lincmpp)(/*_ lindef *lin, uchar *buf _*/);
          /* give location of compiled code for current line to line source */
    void  (*linactp)(/*_ lindef *lin _*/);              /* activate for dbg */
    void  (*lindisp)(/*_ lindef *lin _*/);                   /* disactivate */
    void  (*lintellp)(/*_ lindef *lin, uchar *pos _*/);     /* get position */
    void  (*linseekp)(/*_ lindef *lin, uchar *pos _*/);             /* seek */
    int   (*linreadp)(/*_ lindef *lin, char *buf, int siz _*/);    /* fread */
    void  (*linpaddp)(/*_ lindef *lin, uchar *pos, long delta _*/);
                                       /* add an offset to a position value */
    int   (*linqtopp)(/*_ lindef *lin, uchar *pos _*/);          /* at top? */
    int   (*lingetsp)(/*_ lindef *lin, uchar *buf, int siz _*/);/* get line */
    void  (*linnamp)(/*_ lindef *lin, char *buf _*/);    /* get source name */
    void  (*linfindp)(/*_ lindef *lin, char *buf, objnum *objp,
                          uint *ofsp _*/);      /* find nearest line record */
    void  (*lingotop)(/*_ lindef *lin, int where _*/);       /* seek global */
    long  (*linofsp)(/*_ lindef *lin _*/);    /* byte offset in line source */
    void  (*linrenp)(/*_ lindef *lin, objnum oldnum, objnum newnum _*/);
                                       /* renumber an object (for "modify") */
#   define  LINGOTOP   OSFSK_SET                /* go to top of line source */
#   define  LINGOEND   OSFSK_END                /* go to end of line source */
    lindef *linpar;                        /* parent of current line source */
    lindef *linnxt;                       /* next line in line source chain */
    int     linid;           /* serial number of line source (for debugger) */
    char   *linbuf;                              /* pointer to current line */
    ushort  linflg;                                                /* flags */
#   define  LINFEOF   0x01                 /* line source is at end of file */
#   define  LINFMORE  0x02          /* there's more to the line than linlen */
#   define  LINFDBG   0x04       /* debug record already generated for line */
#   define  LINFNOINC 0x08     /* ignore # directives from this line source */
#   define  LINFCMODE 0x10               /* line source is parsed in C-mode */
    ushort  linlen;                                   /* length of the line */
    ushort  linlln;           /* length of line record generated by lingloc */
};

/*
 *   Maximum allowed value for linlln, in bytes.  This allows subsystems
 *   that need to maintain local copies of seek locations to know how big
 *   an area to allocate for them.  
 */
#define LINLLNMAX   20

/* macros to cover calls to functions */
#define linget(lin) ((*((lindef *)(lin))->lingetp)((lindef *)(lin)))
#define lincls(lin) ((*((lindef *)(lin))->linclsp)((lindef *)(lin)))
#define linppos(lin, buf, buflen) \
 ((*((lindef *)(lin))->linppos)((lindef *)(lin), buf, buflen))
#define linglop(lin, buf) ((*((lindef *)(lin))->linglop)(lin, buf))
#define linwrt(lin, fp) ((*((lindef *)(lin))->linwrtp)(lin, fp))
#define lincmpinf(lin, buf) ((*((lindef *)(lin))->lincmpp)(lin, buf))
#define linactiv(lin) ((*((lindef *)(lin))->linactp)(lin))
#define lindisact(lin) ((*((lindef *)(lin))->lindisp)(lin))
#define lintell(lin, pos) ((*((lindef *)(lin))->lintellp)(lin, pos))
#define linseek(lin, pos) ((*((lindef *)(lin))->linseekp)(lin, pos))
#define linread(lin, buf, siz) ((*((lindef *)(lin))->linreadp)(lin, buf, siz))
#define linpadd(lin, pos, delta) \
  ((*((lindef *)(lin))->linpaddp)(lin, pos, delta))
#define linqtop(lin, pos) ((*((lindef *)(lin))->linqtopp)(lin, pos))
#define lingets(lin, buf, siz) ((*((lindef *)(lin))->lingetsp)(lin, buf, siz))
#define linnam(lin, buf) ((*((lindef *)(lin))->linnamp)(lin, buf))
#define linfind(lin, buf, objp, ofsp) \
  ((*((lindef *)(lin))->linfindp)(lin, buf, objp, ofsp))
#define lingoto(lin, where) ((*((lindef *)(lin))->lingotop)(lin, where))
#define linofs(lin) ((*((lindef *)(lin))->linofsp)(lin))
#define linrenum(lin, oldnum, newnum) \
  ((*((lindef *)(lin))->linrenp)(lin, oldnum, newnum))


#endif /* LIN_INCLUDED */
