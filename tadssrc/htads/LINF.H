/*
$Header: c:/tads/tads2/RCS/LINF.H 1.4 94/11/06 13:05:50 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  linf.h - line source File
Function
  Defines the file line source
Notes
  The file line source reads lines from an OS file.
Modified
  08/14/91 MJRoberts     - creation
*/

#ifndef LINF_INCLUDED
#define LINF_INCLUDED

#ifndef STD_INCLUDED
#include "std.h"
#endif
#ifndef OS_INCLUDED
#include "os.h"
#endif
#ifndef LIN_INCLUDED
#include "lin.h"
#endif

#include <stdio.h>
#include "mcm.h"

/* maximum number of pages of debugging records we can keep */
#define LINFPGMAX 128

struct linfdef
{
    lindef    linflin;                                   /* superclass data */
    osfildef *linffp;                  /* file pointer for this line source */
    char      linfbuf[100];                 /* buffer for the line contents */
    int       linfnum;                               /* current line number */
    ulong     linfseek;                    /* seek position of current line */
    mcmcxdef *linfmem;                            /* memory manager context */
    mcmon     linfpg[LINFPGMAX];             /* pages for debugging records */
    ulong     linfcrec;        /* number of debugger records written so far */
    char      linfnam[1];                        /* name of file being read */
};
typedef struct linfdef linfdef;

/* initialize a file line source, opening the file for the line source */
linfdef *linfini(/*_ mcmcxdef *mctx, errcxdef *errctx, char *filename,
                     int flen, struct tokpdef *path _*/);

/* get next line from line source */
int linfget(/*_ lindef *lin _*/);

/* generate printable rep of current position in source (for errors) */
void linfppos(/*_ lindef *lin, char *buf, uint bufl _*/);

/* close line source */
void linfcls(/*_ lindef *lin _*/);

/* generate source-line debug instruction */
void linfglop(/*_ lindef *lin, uchar *buf _*/);

/* save line source to binary (.gam) file */
int linfwrt(/*_ lindef *lin, osfildef *fp _*/);

/* load a file-line-source from binary (.gam) file */
int linfload(/*_ osfildef *fp, struct dbgcxdef *dbgctx, errcxdef *ec,
                 struct tokpdef *path _*/);

/* add a debugger line record for the current line */
void linfcmp(/*_ lindef *lin, uchar *buf _*/);

/* find nearest line record to a file seek location */
void linffind(/*_ lindef *lin, char *buf, objnum *objp, uint *ofsp _*/);

/* activate line source for debugging */
void linfact(/*_ lindef *lin _*/);

/* disactivate line source */
void linfdis(/*_ lindef *lin _*/);

/* get current seek position */
void linftell(/*_ lindef *lin, uchar *pos _*/);

/* seek */
void linfseek(/*_ lindef *lin, uchar *pos _*/);

/* read */
int linfread(/*_ lindef *lin, char *buf, uint siz _*/);

/* add a signed delta to a seek positon */
void linfpadd(/*_ lindef *lin, uchar *pos, long delta _*/);

/* query whether at top of file */
int linfqtop(/*_ lindef *lin _*/);

/* read one line at current seek position */
int linfgets(/*_ lindef *lin, char *buf, uint bufsiz _*/);

/* get name of line source */
void linfnam(/*_ lindef *lin, char *buf _*/);

/* go to top or bottom */
void linfgoto(/*_ lindef *lin, int where _*/);

/* return the current offset in the line source */
long linfofs(/*_ lindef *lin _*/);

/* renumber an object */
void linfren(/*_ lindef *lin, objnum oldnum, oldnum newnum _*/);

/* debugging echo */
#ifdef DEBUG
# define LINFDEBUG(x) x
#else /* DEBUG */
# define LINFDEBUG(x)
#endif /* DEBUG */

#endif /* LINF_INCLUDED */
