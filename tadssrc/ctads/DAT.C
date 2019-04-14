#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/DAT.C 1.3 94/11/06 13:07:27 mroberts Exp $";
#endif

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  dat.c - datatype manipulation routines
Function
  Functions to operate on TADS run-time datatypes
Notes
  Datatypes are portable, hence the hard-coded values for data
  sizes.
Modified
  08/13/91 MJRoberts     - creation
*/

#include "std.h"
#include "dat.h"
#include "lst.h"
#include "prp.h"
#include "obj.h"
#include "voc.h"

/* return size of a data value */
uint datsiz(typ, val)
dattyp  typ;
dvoid  *val;
{
    switch(typ)
    {
    case DAT_NUMBER:
	return(4);                /* numbers are in 4-byte lsb-first format */

    case DAT_OBJECT:
	return(2);         /* object numbers are in 2-byte lsb-first format */

    case DAT_SSTRING:
    case DAT_DSTRING:
    case DAT_LIST:
	return(osrp2((char *)val));

    case DAT_NIL:
    case DAT_TRUE:
	return(0);

    case DAT_PROPNUM:
    case DAT_SYN:
    case DAT_FNADDR:
    case DAT_REDIR:
	return(2);
	
    case DAT_TPL:
	/* template is counted array of 10-byte entries, plus length byte */
	return(1 + ((*(uchar *)val) * VOCTPLSIZ));

    case DAT_TPL2:
	return(1 + ((*(uchar *)val) * VOCTPL2SIZ));

    default:
	return(0);
    }
}
