/*
$Header: c:/tads/tads2/RCS/LST.H 1.1 92/04/11 12:12:56 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  lst.h - list definitions
Function
  Run-time list definitions
Notes
  A TADS run-time list is essentially a packed counted array.
  The first thing in a list is a ushort, which specifies the
  number of elements in the list.  The list elements are then
  packed into the list immediately following.
Modified
  08/13/91 MJRoberts     - creation
*/

#ifndef LST_INCLUDED
#define LST_INCLUDED

#ifndef DAT_INCLUDED
#include "dat.h"
#endif

/* advance a list pointer/size pair to the next element of a list */
void lstadv(/*_ uchar **lstp, uint *sizp _*/);

#endif /* LST_INCLUDED */
