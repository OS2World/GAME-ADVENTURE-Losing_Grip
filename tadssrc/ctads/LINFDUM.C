#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/LINFDUM.C 1.3 94/11/06 13:08:29 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  linfdum.c - dummy implementation of line source loader
Function
  Implements a line source loader that just reads a file line source
  from a .gam file and ignores the information therein.  Used to link
  the run-time if debugging functions are not desired (because the
  rest of the linf implementation will be unnecessary in this case).
Notes
  None
Modified
  04/11/92 MJRoberts     - creation
*/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "os.h"
#include "std.h"
#include "err.h"
#include "mch.h"
#include "linf.h"
#include "dbg.h"

/* read and ignore a file-line-source from binary (.gam) file */
int linfload(fp, dbgctx, ec, path)
osfildef *fp;
dbgcxdef *dbgctx;
errcxdef *ec;
tokpdef  *path;
{
    linfdef *linf;
    uchar    buf[128];
    uint     pgcnt;
    ulong    reccnt;

    VARUSED(ec);
    VARUSED(dbgctx);
    VARUSED(path);
    
    /* read the source's description from the file */
    if (osfrb(fp, buf, 6)
	|| osfrb(fp, buf + 6, (int)buf[1]))
	return(TRUE);
    
    /* skip the pages of debugging line records */
    reccnt = osrp4(buf + 2);
    if (!reccnt) return(FALSE);                  /* no debug records at all */
    pgcnt = 1 + ((reccnt - 1) >> 10);             /* figure number of pages */
    while (pgcnt--)
    {
	if (osfseek(fp, (1024 * DBGLINFSIZ), OSFSK_CUR)) return(TRUE);
    }

    /* do nothing with this information - just return success */
    return(FALSE);
}


