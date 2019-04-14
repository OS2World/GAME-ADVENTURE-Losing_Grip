/*
$Header: c:/tads/tads2/RCS/TIO.H 1.5 94/11/06 13:07:08 mroberts Exp $
*/

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  tio.h - text I/O interface
Function
  Formatted text input and output interface definition
Notes
  None
Modified
  09/05/92 MJRoberts     - add length parameter to getstring()
  02/16/92 MJRoberts     - creation
*/

#ifndef TIO_INCLUDED
#define TIO_INCLUDED

#ifndef ERR_INCLUDED
# include "err.h"
#endif
#ifndef OBJ_INCLUDED
# include "obj.h"
#endif

/* text i/o context */
struct tiocxdef
{
    errcxdef *tiocxerr;                           /* error handling context */
};
typedef struct tiocxdef tiocxdef;


/* redirect all tioxxx routines to TADS v1.x outxxx equivalents */
#define tioflushn(ctx, nl) outflushn(nl)
#define tioflush(ctx)      outflush(ctx)
#define tioblank(ctx)      outblank()
#define tioreset(ctx)      outreset(ctx)
#define tiogets(ctx, prompt, str, siz) getstring(prompt, str, siz)
#define tioputs(ctx, str)  outformat(str)
#define tiocaps(ctx)       outcaps()
#define tionocaps(ctx)     outnocaps()
#define tioshow(ctx)       outshow()
#define tiohide(ctx)       outhide()
#define tiologopn(ctx,fn)  openlog(fn)
#define tiologcls(ctx)     closelog()
#define tioaskfile(ctx, prompt, buf, bufsiz) os_askfile(prompt, buf, bufsiz)
#define tioscore(ctx, s1, s2) os_score(s1, s2)
#define tiostrsc(ctx, s)   os_strsc(s)

/* set up format strings in output subsystem */
void tiosetfmt(/*_ tiocxdef *ctx, struct runcxdef *rctx, uchar *fmtbase,
                   uint fmtlen _*/);

/* tell tio subsystem the current actor */
void tiosetactor(/*_ struct tiocxdef *ctx, objnum actor _*/);

/* turn output capture on/off */
void tiocapture(/*_ struct tiocxdef *tioctx, struct mcmcxdef *memctx,
                    int flag _*/);

/* get the capture object handle */
mcmon tiogetcapture(/*_ struct tiocxdef *ctx _*/);

/* get the amount of text captured */
uint tiocapturesize(/*_ struct tiocxdef *ctx _*/);

#endif /* TIO_INCLUDED */
