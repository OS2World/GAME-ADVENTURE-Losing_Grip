/*
$Header: c:/tads/tads2/RCS/MCS.H 1.2 92/11/24 21:57:50 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  mcs.h - memory cache swap manager
Function
  Definitions for memory cache swap manager
Notes
  The cache swap manager provides swap file services to the memory
  cache manager.  The cache manager calls the swap manager to write
  objects to the swap file and read in previously swapped-out objects.
Modified
  08/03/91 MJRoberts     - creation
*/

#ifndef MCS_INCLUDED
#define MCS_INCLUDED

/*#include <stdio.h> ###indep */

#ifndef STD_INCLUDED
# include "std.h"
#endif
#ifndef ERR_INCLUDED
# include "err.h"
#endif


/* swap segment descriptor */
typedef struct mcsdsdef mcsdsdef;
struct mcsdsdef
{
    ulong    mcsdsptr;                         /* seek pointer in swap file */
    ushort   mcsdssiz;                         /* size of this swap segment */
    ushort   mcsdsosz;                 /* size of object written to segment */
    uint     mcsdsobj;                                  /* client object ID */
    ushort   mcsdsflg;                                             /* flags */
#   define   MCSDSFINUSE   0x01                        /* segment is in use */
};


/*
 *   mcsseg - swap segment handle.  All swap-file segments are addressed
 *   through this handle type.  
 */
typedef ushort mcsseg;

/* swap manager context */
typedef struct mcscxdef mcscxdef;
struct mcscxdef
{
    osfildef   *mcscxfp; //###indep                               /* swap file handle */
    errcxdef   *mcscxerr;                         /* error handling context */
    ulong       mcscxtop;              /* top of swap file allocated so far */
    ulong       mcscxmax;        /* maximum size of swap file we're allowed */
    mcsdsdef  **mcscxtab;                     /* swap descriptor page table */
    mcsseg      mcscxmsg;               /* maximum segment allocated so far */
    struct mcmcx1def *mcscxmem;                   /* memory manager context */
};

#define MCSSEGINV ((mcsseg)~0)      /* invalid segment ID - error indicator */

/* initialize swapper - returns 0 for success, other for error */
void mcsini(/*_ mcscxdef *ctx, mcmcx1def *gmemctx, ulong maxsiz,
                osfildef *fp, errcxdef *errctx _*/); //###indep  

/* close swapper (release memory areas) */
void mcsclose(/*_ mcscxdef *ctx _*/);

/*
 *   Swap an object out.  The caller specifies the location and size of
 *   the object, as well as a unique handle (arbitrary, up to the caller;
 *   the only requirement is that it be unique among all caller objects
 *   and always the same for a particular caller's object) and the
 *   previous swap handle if the object ever had one.  If the object is
 *   not dirty (it hasn't been written since being swapped in), and the
 *   swap manager hasn't reused the swap slot, the swap manager doesn't
 *   need to write the memory, since it already has a copy on disk;
 *   instead, it can just mark the slot as back in use.  If the caller
 *   doesn't wish to take advantage of this optimization, always pass in
 *   dirty == TRUE, which will force a write regardless of the object ID.
 */
mcsseg mcsout(/*_ mcscxdef *ctx, uint objid, uchar *objptr,
                  ushort objsize, mcsseg oldswapseg, int dirty _*/);
	    
/* Swap an object in */
void mcsin(/*_ mcscxdef *ctx, mcsseg swapseg, uchar *objptr,
               ushort size _*/);


/* number of page pointers in page table (max number of pages) */
#define MCSPAGETAB 256

/* number of swap descriptors in a page */
#define MCSPAGECNT 256

/* find swap descriptor corresponding to swap segment number */
#define mcsdsc(ctx,seg) (&(ctx)->mcscxtab[(seg)>>8][(seg)&255])

/* write out a swap segment */
void mcswrt(/*_ mcscxdef *ctx, mcsdsdef *desc, uchar *buf, ushort bufl _*/);

#endif /* MCS_INCLUDED */
