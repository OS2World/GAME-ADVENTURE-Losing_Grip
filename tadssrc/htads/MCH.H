/*
$Header: c:/tads/tads2/RCS/MCH.H 1.1 92/04/11 12:12:49 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  mch.h - memory cache heap manager
Function
  Low-level heap management functions
Notes
  This is the low-level heap manager, which maintains a list of
  non-relocatable, non-swappable blocks of memory.  The cache
  manager uses the heap manager for its basic storage needs.
Modified
  08/03/91 MJRoberts     - creation
*/

#ifndef MCH_INCLUDED
#define MCH_INCLUDED

#include <stdlib.h>

#ifndef STD_INCLUDED
#include "std.h"
#endif
#ifndef ERR_INCLUDED
#include "err.h"
#endif

/*
 *   Allocate a block of memory; returns pointer to the block.
 *   An out-of-memory error is signalled if insufficient memory
 *   is available.  The comment is for debugging purposes only.
 */
uchar *mchalo(/*_ errcxdef *ctx, ushort siz, char *comment _*/);

/* allocate a structure */
#define MCHNEW(errctx, typ, comment) \
 ((typ *)mchalo(errctx, (ushort)sizeof(typ), comment))

/* free a block of memory */
/* void mchfre(uchar *ptr); */
#define mchfre(ptr) (osfree(ptr))

#endif /* MCH_INCLUDED */
