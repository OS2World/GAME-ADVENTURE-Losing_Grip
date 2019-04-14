/*
$Header: c:/tads/tads2/RCS/MCL.H 1.1 92/04/11 12:12:48 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  mcl.h - memory cache loader
Function
  Object loader definitions
Notes
  The memory cache object loader is a subsystem used by the memory
  cache manager to load objects from a file.  The cache manager
  obtains a loader context during initialization, then refers to
  objects through loader handles.
  
  All loading is actually accomplished through client callbacks.
  There is no general loader implementation.  The "load handle" is
  defined here suitably for an fseek() location; it is assumed that
  clients will store the fseek() location of an object when setting
  up the load map, then use information stored at this fseek address
  to complete the load on demand.
Modified
  08/03/91 MJRoberts     - creation
*/

#ifndef MCL_INCLUDED
#define MCL_INCLUDED

#ifndef STD_INCLUDED
# include "std.h"
#endif
#ifndef ERR_INCLUDED
# include "err.h"
#endif

/* loader context */
typedef struct mclcxdef mclcxdef;
struct mclcxdef
{
    errcxdef *mclcxerr;                           /* error handling context */
};

/* loader handle */
typedef ulong mclhd;                          /* essentially a seek address */

#endif /* MCL_INCLUDED */
