#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/RUNSTAT.C 1.2 94/11/06 13:07:09 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  runstat.c - tads 1 compatible runstat()
Function
  generates status line
Notes
  none
Modified
  04/04/92 MJRoberts     - creation
*/

#include "os.h"
#include "std.h"
#include "mcm.h"
#include "obj.h"
#include "run.h"
#include "tio.h"
#include "voc.h"
#include "dat.h"

static runcxdef *runctx;
static voccxdef *vocctx;
static tiocxdef *tioctx;

void runstat(flag)
int flag;
{
    objnum  locobj;
    runsdef val;
    
    runppr(runctx, vocctx->voccxme, PRP_LOCATION, 0);
    if (runtostyp(runctx) != DAT_OBJECT)
    {
	rundisc(runctx);
	return;
    }
    locobj = runpopobj(runctx);
    
    os_status(1);
    setmore(0);
    
    if (flag)
    {
	runpush(runctx, DAT_TRUE, &val);
	runppr(runctx, locobj, PRP_LOOKAROUND, 1);
    }
    else
	runppr(runctx, locobj, PRP_STATUSLINE, 0);
    
    tioputs(tioctx, "\\n");
    setmore(1);
    os_status(0);
}

void runistat(vctx, rctx, tctx)
voccxdef *vctx;
runcxdef *rctx;
tiocxdef *tctx;
{
    runctx = rctx;
    vocctx = vctx;
    tioctx = tctx;
}

