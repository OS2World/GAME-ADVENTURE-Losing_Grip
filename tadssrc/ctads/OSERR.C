#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/OSERR.C 1.3 94/11/06 13:06:04 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  oserr.c - find error message file
Function
  Looks in executable's directory for TADSERR.MSG, and opens it
Notes
  None
Modified
  04/24/93 JEras         - use new os_locate() to find tadserr.msg
  04/27/92 MJRoberts     - creation
*/

#include <string.h>
#include "os.h"

osfildef *oserrop(arg0)
char *arg0;
{
    char  buf[128];

    if ( !os_locate("tadserr.msg", 11, arg0, buf, sizeof(buf)) )
        return((osfildef *)0);
    return(osfoprb(buf));
}
