#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/ply.c 1.6 96/10/14 16:10:39 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  ply.c - play game
Function
  executes a game, starting with the 'init' function
Notes
  none
Modified
  04/04/92 MJRoberts     - creation
*/

#include "os.h"
#include "std.h"
#include "run.h"
#include "voc.h"
#include "err.h"
#include "obj.h"
#include <ctype.h>

/* play game */
void plygo(run, voc, tio, preinit, inited)
runcxdef *run;
voccxdef *voc;
tiocxdef *tio;
objnum    preinit;                   /* object number of preinit() function */
int       inited;              /* TRUE if preinit/init has already been run */
{
    int       err;
    errcxdef *ec = run->runcxerr;
    char      filbuf[128];
    int       first_time;

    first_time = TRUE;
    
startover:
    if (!inited)
    {
	/* use Me as the format-string actor for preinit and init */
	tiosetactor(voc->voccxtio, voc->voccxme);

	/*
	 *   Run preinit, if it hasn't been run yet.  Note that we only
	 *   do this the first time through.  If we come back here via the
	 *   restart function, preinit will already have been run in the
	 *   restart function itself, so we don't need to run it again.
	 */
	if (first_time)
	{
	    runrst(run);
	    if (preinit != MCMONINV) runfn(run, preinit, 0);
	    voc->voccxpreinit = preinit;

	    /* make a note that we've been through here once already */
	    first_time = FALSE;
	}
	
	/* run the "init" function */
	runrst(run);
	runfn(run, (objnum)voc->voccxini, 0);
    }
    
    /* check for startup parameter file to restore */
    if (os_paramfile(filbuf))
    {
        os_printf("\n\n[Restoring saved game]\n\n");
        err = fiorso(voc, filbuf);
        if (err)
            os_printf1("\n\nError: unable to restore file \"%s\"\n\n",
                      filbuf); //###indep
    }
    
    /* next time through, we'll need to run init again */
    inited = FALSE;
    
    /* read and execute commands */
    for (;;)
    {
        char buf[128];
        
        err = 0;
        ERRBEGIN(ec)
            
        /* read a new command if there's nothing to redo */
        if (!voc->voccxredo)
        {
	    char *prompt;
	    
            tioshow(tio);
            tioflush(tio);

	    /* make sure output capturing is off */
	    tiocapture(tio, (mcmcxdef *)0, FALSE);
	    tioclrcapture(tio);
	    
	    /* call user prompt function if provided, otherwise use default */
	    if (voc->voccxprom != MCMONINV)
	    {
		runrst(run);
		runpnum(run, (long)0);
		runfn(run, voc->voccxprom, 1);
		tioflushn(tio, 0);
		prompt = "";
	    }
	    else
	    {
		tioblank(tio);
		prompt = ">";
	    }
	    
	    tiogets(tio, prompt, buf, (int)sizeof(buf));
	    
	    /* special checking for ungraceful emergency exit */
	    if (!strcmp(buf, "$$ABEND")) exit(2);
            
            /* special qa checking */
            if (buf[0] == '@')
            {
		extern int  moremode;
		char       *p;
		
		p = buf + 1;
		if (*p == '@')
		{
		    moremode = 0;
		    ++p;
		}
		while (*p && isspace(*p)) ++p;
                if (*p) qasopn(p, FALSE);
                goto end_loop;
            }
        }
        voc->voccxredo = FALSE;              /* we've now consumed the redo */
	(void)os_break();       /* clear any pending break that's queued up */
        (void)voccmd(voc, buf, (uint)sizeof(buf));
        
    end_loop:
        ERRCATCH(ec, err)
            if (err != ERR_RUNQUIT && err != ERR_RUNRESTART) errclog(ec);
        ERREND(ec)

	/* on interrupt, undo last command (which was partially executed) */
	if (err == ERR_USRINT && voc->voccxundo)
	{
	    ERRBEGIN(ec)
		objundo(voc->voccxmem, voc->voccxundo);
	    ERRCATCH(ec, err)
		if (err != ERR_NOUNDO && err != ERR_ICUNDO)
		    errrse(ec);
	    ERREND(ec)
	}
            
        /* if they want to quit, we're done */
        if (err == ERR_RUNQUIT) break;
        else if (err == ERR_RUNRESTART) goto startover;
    }
}

