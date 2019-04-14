#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/mch.c 1.4 96/10/14 16:11:41 mroberts Exp $";
#endif

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  mch.c - memory cache manager:  low-level heap manager
Function
  Low-level heap management functions
Notes
  This is a cover for malloc that uses proper error signalling
  conventions
Modified
  08/20/91 MJRoberts     - creation
*/

#include "os.h"
#include "std.h"
#include "mch.h"
#include "err.h"

/* global to keep track of all allocations */
IF_DEBUG(ulong mchtotmem;)

uchar *mchalo(ctx, siz, comment)
errcxdef *ctx;
ushort    siz;
char     *comment;
{
    uchar *ret;

    VARUSED(comment);
    IF_DEBUG(mchtotmem += siz;)

    ret = (uchar *)osmalloc((size_t)(unsigned)siz);
    if (ret)
        return(ret);
    else
    {
        errsig(ctx, ERR_NOMEM);
        NOTREACHEDV(uchar *);
    }
}
