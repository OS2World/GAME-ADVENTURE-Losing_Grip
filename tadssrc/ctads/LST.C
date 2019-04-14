#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/LST.C 1.2 94/11/06 13:06:58 mroberts Exp $";
#endif

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  lst.c - list manipulation routines
Function
  Routines to manipulate TADS run-time lists
Notes
  None
Modified
  08/13/91 MJRoberts     - creation
*/

#include <assert.h>
#include "lst.h"
#include "dat.h"

void lstadv(lstp, sizp)
uchar **lstp;
uint   *sizp;
{
    uint siz;
    
    siz = datsiz(**lstp, (*lstp)+1) + 1;
    assert(siz <= *sizp);
    *lstp += siz;
    *sizp -= siz;
}

