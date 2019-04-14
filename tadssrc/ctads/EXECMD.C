#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/execmd.c 1.8 96/10/14 16:10:29 mroberts Exp $";
#endif

/* Copyright (c) 1987, 1990 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  execmd     - TADS Interpreter Execute user Command
Function
  Executes a user command after it has been parsed
Notes
  TADS 2.0 version

  This module contains the implementation of the entire "turn" sequence,
  which is:

    actor.actorAction( verb, do, prep, io )
    actor.location.roomAction( actor, verb, do, prep, io )
    if ( io ) 
    {
      if (io does not define verIo<Verb> directly)
          io.iobjGen(actor, verb, dobj, prep)
      if (do does not define do<Verb> directly)
          do.dobjGen(actor, verb, iobj, prep)
      io.verIo<Verb>( actor, do )
      if ( noOutput )
      {
        do.verDo<Verb>( actor, io )
	if ( noOutput ) io.io<Verb>( actor, do )
      }
    }
    else if ( do )
    {
      if (do does not define do<Verb> directly)
          do.dobjGen(actor, verb, nil, nil)
      do.verDo<Verb>( actor )
      if ( noOutput )do.do<Verb>( actor )
    }
    else verb.action( actor )
    daemons
    fuses

  If an exit is encountered, we skip straight to daemons.  If an abort,
  askio, or askdo is encountered, we skip everything remaining.  Under
  any of these exit scenarios, we return success to our caller.
  
  This module also contains code to set and remove fuses and daemons,
  since they are part of the player turn sequence.
Returns
  0 for success, other for failure.
Modified
  03/25/92 MJRoberts     - TADS 2.0
  08/13/91 MJRoberts     - add him/her support
  11/30/90 MJRoberts     - moved main execmd loop here from vocab, moved
                           fuses/daemon stuff to fuses.c
  04/23/90 MJRoberts     - clear alarms (notify's) in clrdaemons()
  07/07/89 MJRoberts     - add fuse/daemon context value
  06/28/89 MJRoberts     - default message if objects don't handle the verb
  11/06/88 MJRoberts     - provide error messages in setfuse, setdaemon, etc.
  11/06/88 MJRoberts     - be careful not to send doX message on ask?o
  11/05/88 MJRoberts     - save tpldef with "again"
  10/30/88 MJRoberts     - new "version 6" parser interface
  12/28/87 MJRoberts     - created
*/

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#include "err.h"
#include "voc.h"
#include "tio.h"
#include "mch.h"
#include "mcm.h"
#include "obj.h"
#include "prp.h"
#include "run.h"
#include "lst.h"

/* allocate and initialize a fuse/daemon/notifier array */
void vocinialo(ctx, what, cnt)
voccxdef  *ctx;
vocddef  **what;
int        cnt;
{
    vocddef *p;
    
    *what = (vocddef *)mchalo(ctx->voccxerr,
			      (ushort)(cnt * sizeof(vocddef)), "vocinialo");

    /* set all object/function entries to MCMONINV to indicate not-in-use */
    for (p = *what ; cnt ; ++p, --cnt)
	p->vocdfn = MCMONINV;
}

/* internal service routine to clear one set of fuses/deamons/alerters */
static void vocdmn1clr(dmn, cnt)
vocddef *dmn;
uint     cnt;
{
    for ( ; cnt ; --cnt, ++dmn) dmn->vocdfn = MCMONINV;
}

/* delete all fuses/daemons/alerters */
void vocdmnclr(ctx)
voccxdef *ctx;
{
    vocdmn1clr(ctx->voccxfus, ctx->voccxfuc);
    vocdmn1clr(ctx->voccxdmn, ctx->voccxdmc);
    vocdmn1clr(ctx->voccxalm, ctx->voccxalc);
}

/* save undo information for a daemon/fuse/notifier */
static void vocdusav(ctx, what)
voccxdef *ctx;
vocddef  *what;
{
    uchar     *p;
    objucxdef *uc = ctx->voccxundo;
    ushort     siz = sizeof(what) + sizeof(*what) + 1;
    
    /* if we don't need to save undo, quit now */
    if (!uc || !objuok(uc)) return;

    /* reserve space for our record */
    p = objures(uc, OBJUCLI, siz);
    
    /* set up our undo record */
    *p = VOC_UNDO_DAEMON;
    memcpy(p + 1, &what, (size_t)sizeof(what));
    memcpy(p + 1 + sizeof(what), what, (size_t)sizeof(*what));
    
    uc->objucxhead += siz;
}

/* apply undo information for a daemon/fuse/notifier */
void vocdundo(ctx, data)
voccxdef *ctx;
uchar    *data;
{
    vocddef *daemon;
    objnum   objn;
    ushort   siz;
    ushort   wrdsiz;
    uchar   *p;
    int      sccnt;
    objnum   sc;
    int      len1, len2;
    prpnum   prp;
    int      flags;
    char    *wrd;

    switch(*data)
    {
    case VOC_UNDO_DAEMON:
	memcpy(&daemon, data + 1, (size_t)sizeof(daemon));
	memcpy(daemon, data + 1 + sizeof(daemon), (size_t)sizeof(*daemon));
	break;

    case VOC_UNDO_NEWOBJ:
	/* get the object number */
	objn = osrp2(data + 1);

	/* delete the object's inheritance and vocabulary records */
	vocdel(ctx, objn);
	vocidel(ctx, objn);

	/* delete the object */
	mcmfre(ctx->voccxmem, (mcmon)objn);
	break;

    case VOC_UNDO_DELOBJ:
	/* get the object's number and size */
	objn = osrp2(data + 1);
	siz = osrp2(data + 3);
	wrdsiz = osrp2(data + 5);

	/* allocate the object with its original number */
	p = mcmalonum(ctx->voccxmem, siz, (mcmon)objn);

	/* copy the contents back to the object */
	memcpy(p, data + 7, (size_t)siz);

	/* get its superclass if it has one */
	sccnt = objnsc(p);
	if (sccnt) sc = osrp2(objsc(p));

	/* unlock the object, and create its inheritance records */
	mcmunlck(ctx->voccxmem, (mcmon)objn);
	vociadd(ctx, objn, MCMONINV, sccnt, &sc, VOCIFNEW | VOCIFVOC);

	/* restore the words as well */
	data += 7 + siz;
	while (wrdsiz)
	{
	    /* get the lengths from the buffer */
	    len1 = osrp2(data + 2);
	    len2 = osrp2(data + 4);

	    /* add the word */
	    vocadd2(ctx, data[0], objn, data[1], data+6, len1,
		    data+6+len1, len2);
	    
	    /* remove this object from the word size */
	    wrdsiz -= 6 + len1 + len2;
	    data += 6 + len1 + len2;
	}
	break;

    case VOC_UNDO_ADDVOC:
    case VOC_UNDO_DELVOC:
	flags = *(data + 1);
	prp = *(data + 2);
	objn = osrp2(data + 3);
	wrd = (char*)data + 5; //###cast
	if (*data == VOC_UNDO_ADDVOC)
	    vocdel1(ctx, objn, wrd, prp, FALSE, FALSE, FALSE);
	else
	    vocadd(ctx, prp, objn, flags, wrd);
	break;
    }
}

/* determine size of one of our client undo records */
ushort OS_LOADDS vocdusz(ctx, data)
voccxdef *ctx;
uchar    *data;
{
    VARUSED(ctx);

    switch(*data)
    {
    case VOC_UNDO_DAEMON:
	/* it's the size of the structures, plus one for the header */
	return (ushort)((sizeof(vocddef *) + sizeof(vocddef)) + 1);

    case VOC_UNDO_NEWOBJ:
	/* 2 bytes for the objnum plus 1 for the header */
	return 2 + 1;

    case VOC_UNDO_DELOBJ:
	/*
	 *   1 (header) + 2 (objnum) + 2 (size) + 2 (word size) + object
	 *   data size + word size
	 */
        return osrp2(data+3) + osrp2(data+5) + 1+2+2+2;

    case VOC_UNDO_ADDVOC:
    case VOC_UNDO_DELVOC:
	/* 1 (header) + 2 (objnum) + 1 (flags) + 1 (type) + word size */
	return osrp2(data + 5) + 5;

    default:
	return 0;
    }
}

/* save undo for object creation */
void vocdusave_newobj(voccxdef *ctx, objnum objn)
{
    objucxdef *uc = ctx->voccxundo;
    uchar     *p;

    p = objures(uc, OBJUCLI, 3);
    *p = VOC_UNDO_NEWOBJ;
    oswp2(p+1, objn);

    uc->objucxhead += 3;
}

/* callback context structure */
struct delobj_cb_ctx
{
    uchar *p;
};

/*
 *   Iteration callback to write vocabulary words for an object being
 *   deleted to an undo stream, so that they can be restored if the
 *   deletion is undone. 
 */
void delobj_cb(ctx, voc, vocw)
struct delobj_cb_ctx *ctx;
vocdef               *voc;
vocwdef              *vocw;
{
    uchar *p = ctx->p;
    
    /* write this object's header to the stream */
    p[0] = vocw->vocwtyp;
    p[1] = vocw->vocwflg;
    oswp2(p+2, voc->voclen);
    oswp2(p+4, voc->vocln2);

    /* write the words as well */
    memcpy(p+6, voc->voctxt, (size_t)(voc->voclen + voc->vocln2));

    /* advance the pointer */
    ctx->p += 6 + voc->voclen + voc->vocln2;
}

/* save undo for object deletion */
void vocdusave_delobj(voccxdef *ctx, objnum objn)
{
    objucxdef *uc = ctx->voccxundo;
    uchar     *p;
    uchar     *objp;
    uint       siz;
    uint       wrdsiz;
    uint       wrdcnt;
    struct delobj_cb_ctx fnctx;

    /* figure out how much we need to save */
    objp = mcmlck(ctx->voccxmem, (mcmon)objn);
    siz = objfree(objp);

    /* figure the word size */
    voc_count(ctx, objn, 0, &wrdcnt, &wrdsiz);

    /*
     *   we need to store an additional 6 bytes (2-length1, 2-length2,
     *   1-type, 1-flags) for each word 
     */
    wrdsiz += wrdcnt*6;

    /* set up the undo header */
    p = objures(uc, OBJUCLI, 7 + siz + wrdsiz);
    *p = VOC_UNDO_DELOBJ;
    oswp2(p+1, objn);
    oswp2(p+3, siz);
    oswp2(p+5, wrdsiz);

    /* save the object's data */
    memcpy(p+7, objp, (size_t)siz);

    /* write the words */
    fnctx.p = p+7 + siz;
    voc_iterate(ctx, objn, delobj_cb, &fnctx);

    /* unlock the object and advance the undo pointer */
    mcmunlck(ctx->voccxmem, (mcmon)objn);
    uc->objucxhead += 7 + siz + wrdsiz;
}

/* save undo for word creation */
void vocdusave_addwrd(ctx, objn, typ, flags, wrd)
voccxdef *ctx;
objnum    objn;
prpnum    typ;
int       flags;
char     *wrd;
{
    int        wrdsiz;
    uchar     *p;
    objucxdef *uc = ctx->voccxundo;

    /* figure out how much space we need, and reserve it */
    wrdsiz = osrp2(wrd);
    p = objures(uc, OBJUCLI, 5 + wrdsiz);

    *p = VOC_UNDO_ADDVOC;
    *(p+1) = flags;
    *(p+2) = typ;
    oswp2(p+3, objn);
    memcpy(p+5, wrd, (size_t)wrdsiz);

    uc->objucxhead += 5 + wrdsiz;
}

/* save undo for word deletion */
void vocdusave_delwrd(ctx, objn, typ, flags, wrd)
voccxdef *ctx;
objnum    objn;
prpnum    typ;
int       flags;
char     *wrd;
{
    int        wrdsiz;
    uchar     *p;
    objucxdef *uc = ctx->voccxundo;

    /* figure out how much space we need, and reserve it */
    wrdsiz = osrp2(wrd);
    p = objures(uc, OBJUCLI, 5 + wrdsiz);

    *p = VOC_UNDO_DELVOC;
    *(p+1) = flags;
    *(p+2) = typ;
    oswp2(p+3, objn);
    memcpy(p+5, wrd, (size_t)wrdsiz);

    uc->objucxhead += 5 + wrdsiz;
}
		      


/* set a fuse/daemon/notifier */
void vocsetfd(ctx, what, func, prop, tm, val, err)
voccxdef *ctx;
vocddef  *what;                    /* base of appropriate array for objects */
objnum    func;                                          /* function/object */
prpnum    prop;            /* property for notifier, or zero if fuse/daemon */
uint      tm;                                               /* time to wait */
runsdef  *val;                         /* value for argument to fuse/daemon */
int       err;                           /* error to signal if out of slots */
{
    int      slots;
    
    if (what == ctx->voccxdmn) slots = ctx->voccxdmc;
    else if (what == ctx->voccxalm) slots = ctx->voccxalc;
    else if (what == ctx->voccxfus) slots = ctx->voccxfuc;
    else errsig(ctx->voccxerr, ERR_BADSETF);
    
    /* find a free slot, and set up our fuse/daemon */
    for ( ; slots ; ++what, --slots)
    {
	if (what->vocdfn == MCMONINV)
	{
	    /* save an undo record for this slot before changing */
	    vocdusav(ctx, what);
	    
	    /* make the change */
	    what->vocdfn = func;
	    if (val) OSCPYSTRUCT(what->vocdarg, *val);
	    what->vocdprp = prop;
	    what->vocdtim = tm;
	    return;
	}
    }
    errsig(ctx->voccxerr, err);
}

/* remove a fuse/daemon/notifier */
void vocremfd(ctx, what, func, prop, val, err)
voccxdef *ctx;
vocddef  *what;
objnum    func;
prpnum    prop;
runsdef  *val;
int       err;
{
    int      slots;
    
    if (what == ctx->voccxdmn) slots = ctx->voccxdmc;
    else if (what == ctx->voccxalm) slots = ctx->voccxalc;
    else if (what == ctx->voccxfus) slots = ctx->voccxfuc;
    else errsig(ctx->voccxerr, ERR_BADREMF);
    
    /* find the slot with this same fuse/daemon/notifier, and remove it */
    for ( ; slots ; ++what, --slots)
    {
	if (what->vocdfn == func
	    && what->vocdprp == prop
	    && (!val || (val->runstyp == what->vocdarg.runstyp
			 && !memcmp(&val->runsv, &what->vocdarg.runsv,
				    (size_t)datsiz(val->runstyp,
						   &val->runsv)))))
	{
	    /* save an undo record for this slot before changing */
	    vocdusav(ctx, what);

	    what->vocdfn = MCMONINV;
	    return;
	}
    }

/*    errsig(ctx->voccxerr, err); <<<harmless - don't signal it>>> */
}

/*
 *   Count one or more turns - burn all fuses down by the given number of
 *   turns.  Execute any fuses that expire within the given interval, but
 *   not any that expire at the end of the last turn counted here.  (If
 *   incrementing by one turn only, no fuses will be executed.)  If the
 *   do_fuses flag is false, fuses are simply deleted if they burn down
 *   within the interval.  
 */
void vocturn(ctx, turncnt, do_fuses)
voccxdef *ctx;
int       turncnt;
int       do_fuses;
{
    vocddef *p;
    int      i;
    int      do_exe;

    while (turncnt--)
    {
	/* presume we won't find anything to execute */
	do_exe = FALSE;
	
	/* go through notifiers, looking for fuse-type notifiers */
	for (i = ctx->voccxalc, p = ctx->voccxalm ; i ; ++p, --i)
	{
	    if (p->vocdfn != MCMONINV && p->vocdtim != 0xffff
		&& p->vocdtim != 0)
	    {
		/* save an undo record for this slot before changing */
		vocdusav(ctx, p);
		
		if (--(p->vocdtim) == 0)
		    do_exe = TRUE;
	    }
	}
	
	/* now go through the fuses */
	for (i = ctx->voccxfuc, p = ctx->voccxfus ; i ; ++p, --i)
	{
	    if (p->vocdfn != MCMONINV && p->vocdtim != 0)
	    {
		/* save an undo record for this slot before changing */
		vocdusav(ctx, p);

		if (--(p->vocdtim) == 0)
		    do_exe = TRUE;
	    }
	}

	/*
	 *   if we'll be doing more, and anything burned down, run
	 *   current fuses before going on to the next turn 
	 */
	if ((!do_fuses || turncnt) && do_exe)
	    exefuse(ctx, do_fuses);
    }
}

/*
 *   display a default error message for a verb/dobj/iobj combo.
 *   The message is "I don't know how to <verb.sdesc> <dobj.thedesc>" if
 *   the dobj is present, and "I don't know how to <verb.sdesc> anything
 *   <prep.sdesc> <iobj.thedesc>" if the iobj is present.  Such a message
 *   is displayed when the objects in the command don't handle the verb
 *   (i.e., don't have any methods for verification of the verb:  they
 *   lack verDo<verb> or verIo<verb>).
 */
void exeperr(ctx, verb, dobj, prep, iobj)
voccxdef *ctx;
objnum    verb;
objnum    dobj;
objnum    prep;
objnum    iobj;
{
    if (ctx->voccxper2 != MCMONINV)
    {
	runrst(ctx->voccxrun);
	runpobj(ctx->voccxrun, iobj);
	runpobj(ctx->voccxrun, prep);
	runpobj(ctx->voccxrun, dobj);
	runpobj(ctx->voccxrun, verb);
	runfn(ctx->voccxrun, ctx->voccxper2, 4);
	return;
    }
    
    vocerr(ctx, 110, "I don't know how to ");
    runrst(ctx->voccxrun);
    runppr(ctx->voccxrun, verb, PRP_SDESC, 0);
    
    if (dobj != MCMONINV)
    {
	vocerr(ctx, 111, " ");
	runrst(ctx->voccxrun);
	runppr(ctx->voccxrun, dobj, PRP_THEDESC, 0);
    }
    else
    {
	vocerr(ctx, 112, " anything ");
	if (prep != MCMONINV)
	{
	    runrst(ctx->voccxrun);
	    runppr(ctx->voccxrun, prep, PRP_SDESC, 0);
	}
	else
	    vocerr(ctx, 113, "to");
	vocerr(ctx, 114, " ");
	runrst(ctx->voccxrun);
	runppr(ctx->voccxrun, iobj, PRP_THEDESC, 0);
    }
    vocerr(ctx, 115, ".");
}


/*
 *   Execute daemons 
 */
void exedaem(ctx)
voccxdef *ctx;
{
    runcxdef *rcx = ctx->voccxrun;
    vocddef  *daemon;
    int       i;
    runsdef   val;
    int       err;

    for (i = ctx->voccxdmc, daemon = ctx->voccxdmn ; i ; ++daemon, --i)
    {
	if (daemon->vocdfn != MCMONINV)
        {
	    objnum thisd = daemon->vocdfn;
	    
	    ERRBEGIN(ctx->voccxerr)

	    OSCPYSTRUCT(val, daemon->vocdarg);
	    runpush(rcx, val.runstyp, &val);
	    runfn(rcx, thisd, 1);
	    
	    ERRCATCH(ctx->voccxerr, err)
		if (err != ERR_RUNEXIT)
		    errrse(ctx->voccxerr);
	    ERREND(ctx->voccxerr)
	}
    }
    for (i = ctx->voccxalc, daemon = ctx->voccxalm ; i ; ++daemon, --i)
    {
	if (daemon->vocdfn != MCMONINV && daemon->vocdtim == 0xffff)
	{
	    ERRBEGIN(ctx->voccxerr)

	    runppr(rcx, daemon->vocdfn, daemon->vocdprp, 0);
	    
	    ERRCATCH(ctx->voccxerr, err)
		if (err != ERR_RUNEXIT)
		    errrse(ctx->voccxerr);
	    ERREND(ctx->voccxerr)
	}
    }
}

/*
 *   Execute any pending fuses.  Return TRUE if any fuses were executed,
 *   FALSE otherwise.  
 */
int exefuse(ctx, do_run)
voccxdef *ctx;
int       do_run;
{
    runcxdef *rcx = ctx->voccxrun;
    vocddef  *daemon;
    int       i;
    int       found = FALSE;
    runsdef   val;
    int       err;

    for (i = ctx->voccxfuc, daemon = ctx->voccxfus ; i ; ++daemon, --i)
    {
	if (daemon->vocdfn != MCMONINV && daemon->vocdtim == 0)
	{
	    objnum thisf = daemon->vocdfn;
	 
	    found = TRUE;
	    ERRBEGIN(ctx->voccxerr)

	    /* save an undo record for this slot before changing */
	    vocdusav(ctx, daemon);

	    /* remove the fuse prior to running  */
	    daemon->vocdfn = MCMONINV;

	    if (do_run)
	    {
		OSCPYSTRUCT(val, daemon->vocdarg);
		runpush(rcx, val.runstyp, &val);
		runfn(rcx, thisf, 1);
	    }
	    
	    ERRCATCH(ctx->voccxerr, err)
		if (err != ERR_RUNEXIT)
		    errrse(ctx->voccxerr);
	    ERREND(ctx->voccxerr)
	}
    }
    for (i = ctx->voccxalc, daemon = ctx->voccxalm ; i ; ++daemon, --i)
    {
	if (daemon->vocdfn != MCMONINV && daemon->vocdtim == 0)
	{
	    objnum thisa = daemon->vocdfn;

	    found = TRUE;
	    ERRBEGIN(ctx->voccxerr)

	    /* save an undo record for this slot before changing */
	    vocdusav(ctx, daemon);

	    /* delete it prior to running it */
	    daemon->vocdfn = MCMONINV;

	    if (do_run)
		runppr(rcx, thisa, daemon->vocdprp, 0);
	    
	    ERRCATCH(ctx->voccxerr, err)
		if (err != ERR_RUNEXIT)
		    errrse(ctx->voccxerr);
	    ERREND(ctx->voccxerr)
	}
    }
    
    return(found);
}

/* execute iobjGen/dobjGen if appropriate */
static int exegen(ctx, obj, genprop, verprop, actprop)
voccxdef *ctx;
objnum    obj;                                 /* direct or indirect object */
prpnum    genprop;                                      /* xobjGen property */
prpnum    verprop;                                    /* verXoVerb property */
prpnum    actprop;                                       /* xoVerb property */
{
    int     hasgen;                                 /* has xobjGen property */
    objnum  genobj;                         /* object with xobjGen property */
    int     hasver;                               /* has verXoVerb property */
    objnum  verobj;                       /* object with verXoVerb property */
    int     hasact;                                  /* has xoVerb property */
    objnum  actobj; /* object with xoVerb property *?
    
    /* ignore it if there's no object here */
    if (obj == MCMONINV) return(FALSE);

    /* look up the xobjGen property, and ignore if not present */
    hasgen = objgetap(ctx->voccxmem, obj, genprop, &genobj, FALSE);
    if (!hasgen) return(FALSE);

    /* look up the verXoVerb and xoVerb properties */
    hasver = objgetap(ctx->voccxmem, obj, verprop, &verobj, FALSE);
    hasact = objgetap(ctx->voccxmem, obj, actprop, &actobj, FALSE);

    /* ignore if verXoVerb or xoVerb "overrides" xobjGen */
    if ((hasver && !bifinh(ctx, vocinh(ctx, genobj), verobj))
	|| (hasact && !bifinh(ctx, vocinh(ctx, genobj), actobj)))
	return(FALSE);
    
    /* all conditions are met - execute dobjGen */
    return(TRUE);
}

/* execute a single command */
int exe1cmd(ctx, actor, verb, dobjv, prepptr, iobjv, endturn, tpl, newstyle)
voccxdef *ctx;
objnum    actor;
objnum    verb;
vocoldef *dobjv;
objnum   *prepptr;
vocoldef *iobjv;
int       endturn;         /* flag for end of turn; true ==> do fuses, etc. */
uchar    *tpl;                                 /* template for this command */
int       newstyle;
{
    int       i;
    objnum    loc;
    int       err;
    runcxdef *rcx = ctx->voccxrun;
    runsdef   val;
    objnum    prep = *prepptr;
    objnum    dobj = (dobjv ? dobjv->vocolobj : MCMONINV);
    objnum    iobj = (iobjv ? iobjv->vocolobj : MCMONINV);
    int       tplflags;
    int       dobj_first;

    /* remember the flags */
    tplflags = (tpl && newstyle ? voctplflg(tpl) : 0);
    dobj_first = (tplflags & VOCTPLFLG_DOBJ_FIRST);

    if (actor == MCMONINV) actor = ctx->voccxme;           /* default to Me */
    if (verb == ctx->voccxvag)                          /* is this 'again'? */
    {
	actor = ctx->voccxlsa;
	verb  = ctx->voccxlsv;
	dobj  = ctx->voccxlsd;
	iobj  = ctx->voccxlsi;
	prep  = ctx->voccxlsp;
	tpl   = ctx->voccxlst;
	
	if (verb == MCMONINV)
	{
	    vocerr(ctx, 26, "There's no command to repeat.");
	    tioflush(ctx->voccxtio);
	    return(0);
	}
	else if ((dobj != MCMONINV &&
		  !vocchkaccess(ctx, dobj, PRP_VALIDDO, 0, actor, verb))
		 || (iobj != MCMONINV &&
		     !vocchkaccess(ctx, iobj, PRP_VALIDIO, 0, actor, verb)))
	{
	    vocerr(ctx, 27, "You can't repeat that command.");
	    tioflush(ctx->voccxtio);
	    return(0);
	}
    }
    else
    {
	/* save current command info in case "again" is used next time */
	ctx->voccxlsa = actor;
	ctx->voccxlsv = verb;
	ctx->voccxlsd = dobj;
	ctx->voccxlsi = iobj;
	ctx->voccxlsp = prep;
	if (tpl)
	    memcpy(ctx->voccxlst, tpl, (size_t)sizeof(ctx->voccxlst));
    }
    
    /* set up actor for tio subsystem - format strings need to know */
    tiosetactor(ctx->voccxtio, actor);

    /* store current dobj and iobj vocoldef's for later reference */
    ctx->voccxdobj = dobjv;
    ctx->voccxiobj = iobjv;
    
    ERRBEGIN(ctx->voccxerr)

    /* invoke cmdActor.actorAction(verb, dobj, prep, iobj) */
    runrst(rcx);
    runpobj(rcx, iobj);
    runpobj(rcx, prep);
    runpobj(rcx, dobj);
    runpobj(rcx, verb);
    runppr(rcx, actor, PRP_ACTORACTION, 4);

    /* invoke actor.location.roomAction(actor, verb, dobj, prep, iobj) */
    runrst(rcx);
    runppr(rcx, actor, PRP_LOCATION, 0);
    if (runtostyp(rcx) == DAT_OBJECT)
    {
        loc = runpopobj(rcx);
	
	runrst(rcx);
	runpobj(rcx, iobj);
	runpobj(rcx, prep);
	runpobj(rcx, dobj);
	runpobj(rcx, verb);
	runpobj(rcx, actor);
	runppr(rcx, loc, PRP_ROOMACTION, 5);
    }
    else
	rundisc(rcx);
    
    /*
     *   If there's an indirect object, and the indirect object doesn't
     *   directly define io<Verb>, call iobj.iobjGen(actor, verb, dobj,
     *   prep) 
     */
    if (iobj != MCMONINV
	&& exegen(ctx, iobj, PRP_IOBJGEN, voctplvi(tpl), voctplio(tpl)))
    {
	runrst(rcx);
	runpobj(rcx, prep);
	runpobj(rcx, dobj);
	runpobj(rcx, verb);
	runpobj(rcx, actor);
	runppr(rcx, iobj, PRP_IOBJGEN, 4);
    }

    /* Likewise for direct object */
    if (dobj != MCMONINV
	&& exegen(ctx, dobj, PRP_DOBJGEN, voctplvd(tpl), voctpldo(tpl)))
    {
	runrst(rcx);
	runpobj(rcx, prep);
	runpobj(rcx, iobj);
	runpobj(rcx, verb);
	runpobj(rcx, actor);
	runppr(rcx, dobj, PRP_DOBJGEN, 4);
    }

    /*
     *   Now do what needs to be done, depending on the sentence structure.
     *      No objects         ==> cmdVerb.action( cmdActor )
     *
     *      Direct object only ==> cmdDobj.verDo<Verb>( actor )
     *                             cmdDobj.do<Verb>( actor )
     *
     *      Indirect + direct  ==> cmdDobj.verDo<Verb>( actor, cmdIobj )
     *                             cmdIobj.verIo<Verb>( actor, cmdDobj )
     *                             cmdIobj.io<Verb>( actor, cmdDobj )
     */
    tiohide(ctx->voccxtio);
    tioshow(ctx->voccxtio);                    /* clear message output flag */
    
    if (dobj == MCMONINV)
    {
	runrst(rcx);
	runpobj(rcx, actor);
	runppr(rcx, verb, PRP_ACTION, 1);
    }
    else if (iobj == MCMONINV)
    {
        if (!objgetap(ctx->voccxmem, dobj, voctplvd(tpl), (objnum *)0, FALSE))
	{
	    exeperr(ctx, verb, dobj, MCMONINV, MCMONINV);
	    goto skipToFuses;
	}
	
	runrst(rcx);
	runpobj(rcx, actor);
	runppr(rcx, dobj, voctplvd(tpl), 1);
	
	if (!tioshow(ctx->voccxtio))
	{
	    /* no output - process dobj.doVerb */
	    runrst(rcx);
	    runpobj(rcx, actor);
	    runppr(rcx, dobj, voctpldo(tpl), 1);
	}
    }
    else
    {
	if (!objgetap(ctx->voccxmem, dobj, voctplvd(tpl), (objnum *)0, FALSE))
	{
	    exeperr(ctx, verb, dobj, MCMONINV, MCMONINV);
	    goto skipToFuses;
	}
	else if (!objgetap(ctx->voccxmem, iobj, voctplvi(tpl), (objnum *)0,
			   FALSE))
	{
	    exeperr(ctx, verb, MCMONINV, prep, iobj);
	    goto skipToFuses;
	}

	/* call verDoVerb(actor [,iobj]) */
	runrst(rcx);
	if (!dobj_first) runpobj(rcx, iobj);
	runpobj(rcx, actor);
	runppr(rcx, dobj, voctplvd(tpl), (dobj_first ? 1 : 2));

	if (!tioshow(ctx->voccxtio))
	{
	    /* call verIoVerb(actor [,dobj]) */
	    runrst(rcx);
	    if (dobj_first) runpobj(rcx, dobj);
	    runpobj(rcx, actor);
	    runppr(rcx, iobj, voctplvi(tpl), (dobj_first ? 2 : 1));
	}
	
	if (!tioshow(ctx->voccxtio))
	{
	    runrst(rcx);
	    runpobj(rcx, dobj);
	    runpobj(rcx, actor);
	    runppr(rcx, iobj, voctplio(tpl), 2);
	}
    }
    
  skipToFuses:
    ERRCATCH(ctx->voccxerr, err)
	if (err == ERR_RUNASKI) *prepptr = errargint(0);
	if (err == ERR_RUNABRT || err == ERR_RUNASKD || err == ERR_RUNASKI)
	    return(err);
        if (err != ERR_RUNEXIT) errrse(ctx->voccxerr);
    ERREND(ctx->voccxerr)
    
    /*
     *   Finally, do fuses and daemons if this is the last object in the
     *   list for this command.
     */
    if (!endturn) return(0);          /* skip fuses/daemons if more to come */
    runrst(ctx->voccxrun);

    ERRBEGIN(ctx->voccxerr)
        exedaem(ctx);
        (void)exefuse(ctx, TRUE);
    ERRCATCH(ctx->voccxerr, err)
	if (err != ERR_RUNABRT) errrse(ctx->voccxerr);
    ERREND(ctx->voccxerr)
    return(0);
}

/*
 *   saveit stores the current direct object list in 'it' or 'them'.
 */
static void exesaveit(ctx, dolist)
voccxdef *ctx;
vocoldef *dolist;
{
    int       cnt;
    int       i;
    int       dbg = ctx->voccxflg & VOCCXFDBG;
    tiocxdef *tcx;
    runcxdef *rcx = ctx->voccxrun;

    cnt = voclistlen(dolist);
    if (cnt == 1)
    {
	ctx->voccxit = dolist[0].vocolobj;
	ctx->voccxthc = 0;

	if (dbg)
	{
	    tcx = ctx->voccxtio;
	    tioputs(tcx, ".. setting it: ");
	    runppr(rcx, ctx->voccxit, PRP_SDESC, 0);
	    tioputs(tcx, "\\n");
	}

	/* set "him" if appropriate */
	runppr(rcx, ctx->voccxit, PRP_ISHIM, 0);
	if (runtostyp(rcx) == DAT_TRUE)
	{
	    ctx->voccxhim = ctx->voccxit;
	    if (dbg) tioputs(tcx, "... [setting \"him\" to same object]\\n");
	}
	rundisc(rcx);

	/* set "her" if appropriate */
	runppr(rcx, ctx->voccxit, PRP_ISHER, 0);
	if (runtostyp(rcx) == DAT_TRUE)
	{
	    ctx->voccxher = ctx->voccxit;
	    if (dbg) tioputs(tcx, "... [setting \"her\" to same object]\\n");
	}
	rundisc(rcx);
    }
    else if (cnt > 1)
    {
	ctx->voccxthc = cnt;
	ctx->voccxit  = MCMONINV;
	if (dbg) tioputs(tcx, ".. setting them: [");
	for (i = 0 ; i < cnt ; ++i)
	{
	    ctx->voccxthm[i] = dolist[i].vocolobj;
	    if (dbg)
	    {
		runppr(rcx, dolist[i].vocolobj, PRP_SDESC, 0);
		tioputs(tcx, i+1 < cnt ? ", " : "]\\n");
	    }
	}
    }
}

/* display a multiple-object prefix */
void voc_multi_prefix(ctx, objn)
voccxdef *ctx;
objnum    objn;
{
    runcxdef *rcx = ctx->voccxrun;
    
    /*
     *   use multisdesc if defined (for compatibility with older games,
     *   use sdesc if multisdesc doesn't exist for this object) 
     */
    runrst(rcx);
    if (objgetap(ctx->voccxmem, objn, PRP_MULTISDESC,
		 (objnum *)0, FALSE) == 0)
	runppr(rcx, objn, PRP_SDESC, 0);
    else
	runppr(rcx, objn, PRP_MULTISDESC, 0);
    vocerr(ctx, 120, ": ");
}

/* execute command for each object in direct object list */
static int exeloop(ctx, actor, verb, dolist, prep, iobj, multi, tpl, newstyle)
voccxdef *ctx;
objnum    actor;
objnum    verb;
vocoldef *dolist;
objnum   *prep;
vocoldef *iobj;
int       multi;
uchar    *tpl;
int       newstyle;
{
    runcxdef *rcx = ctx->voccxrun;
    int       cnt;
    int       err;
    int       i;
    vocoldef *dobj;
    
    cnt = (dolist ? voclistlen(dolist) : 1);
    if (cnt < 1) cnt = 1;             /* must execute command at least once */

    /*
     *   If we have multiple direct objects, or we're using "all" with
     *   just one direct object, check with the verb to see if multiple
     *   words are acceptable: call verb.rejectMultiDobj, and see what it
     *   returns; if it returns true, don't allow multiple words, and
     *   expect that rejectMultiDobj displayed an error message.
     *   Otherwise, proceed.  
     */
    if ((multi || cnt > 1) && dolist && dolist[0].vocolobj != MCMONINV)
    {
	int typ;

	ERRBEGIN(ctx->voccxerr)
	    runrst(rcx);
	    if (!prep || *prep == MCMONINV)
		runpnil(rcx);
	    else
		runpobj(rcx, *prep);
	    runppr(rcx, verb, PRP_REJECTMDO, 1);
	    typ = runtostyp(rcx);
	    rundisc(rcx);
	ERRCATCH(ctx->voccxerr, err)
	    if (err == ERR_RUNEXIT || err == ERR_RUNABRT)
		return err;
	    else
		errrse(ctx->voccxerr);
	ERREND(ctx->voccxerr)

	/* if they returned 'true', don't bother continuing */
	if (typ == DAT_TRUE)
	    return(0);
    }

    for (i = 0 ; i < cnt ; ++i)
    {
	dobj = (dolist ? &dolist[i] : 0);

	/*
	 *   If we have a number or string, set the current one in
	 *   numObj/strObj 
	 */
	if (dolist && dolist[i].vocolflg == VOCS_STR)
	    vocsetobj(ctx, ctx->voccxstr, DAT_SSTRING,
		      dolist[i].vocolfst + 1, &dolist[i], &dolist[i]);
	else if (dolist && dolist[i].vocolflg == VOCS_NUM)
	{
	    long v1, v2;

	    v1 = atol(dolist[i].vocolfst);
	    oswp4(&v2, v1);
	    vocsetobj(ctx, ctx->voccxnum, DAT_NUMBER, &v2,
		      &dolist[i], &dolist[i]);
	}

        /*
	 *   For cases where we have a bunch of direct objects (or even
	 *   one when "all" was used), we shall preface the output from
	 *   each iteration with the name of the object we're acting on
	 *   currently.  In other cases, there is no prefix.
	 */
	if ((multi || cnt > 1) && dobj)
	    voc_multi_prefix(ctx, dobj->vocolobj);

	if (err = exe1cmd(ctx, actor, verb, dobj, prep, iobj,
			  (i + 1 == cnt), tpl, newstyle))
	    return(err);
	
	tioflush(ctx->voccxtio);
    }
    return(0);
}

/*
 *   check for ALL or ANY in the list - use multi-mode if found, even if
 *   we have only one object 
 */
int check_for_multi(dolist)
vocoldef *dolist;
{
    int dolen;
    int i;

    /* scan the list for ALL or ANY */
    dolen = voclistlen(dolist);
    for (i = 0 ; i < dolen ; ++i)
    {
	if (dolist[i].vocolflg & (VOCS_ALL | VOCS_ANY | VOCS_THEM))
	    return TRUE;
    }

    /* didn't find any */
    return FALSE;
}

/*
 *   Try running the preparseCmd user function.  Returns 0 if the
 *   function doesn't exist or returns 'true', ERR_PREPRSCMDCAN if it
 *   returns 'nil' (and thus wants to cancel the command), and
 *   ERR_PREPRSCMDREDO if it returns a list (and thus wants to redo the
 *   command). 
 */
int try_preparse_cmd(ctx, cmd, wrdcnt, preparse_list)
voccxdef  *ctx;
char     **cmd;
int        wrdcnt;
char     **preparse_list;
{
    uchar    listbuf[VOCBUFSIZ + 2 + 3*VOCBUFSIZ];
    int      i;
    uchar   *p;
    size_t   len;
    runsdef  val;
    int      typ;

    /* if there's no preparseCmd, keep processing */
    if (ctx->voccxppc == MCMONINV)
	return 0;
    
    /* build a list of the words */
    for (p = listbuf + 2, i = 0 ; i < wrdcnt ; ++i)
    {
	len = strlen(cmd[i]);
	*p++ = DAT_SSTRING;
	oswp2(p, len+2);
	memcpy(p+2, cmd[i], len);
	p += len + 2;
    }
    
    /* set the length of the whole list */
    len = p - listbuf;
    oswp2(listbuf, len);
    
    /* push the list as the argument, and call the user's preparseCmd */
    val.runstyp = DAT_LIST;
    val.runsv.runsvstr = (char*)listbuf; //###cast
    runpush(ctx->voccxrun, DAT_LIST, &val);
    runfn(ctx->voccxrun, ctx->voccxppc, 1);
    
    /* get the result */
    typ = runtostyp(ctx->voccxrun);
    
    /* if they returned a list, it's a new command to execute */
    if (typ == DAT_LIST)
    {
	/* get the list and give it to the caller */
	*preparse_list = (char*)runpoplst(ctx->voccxrun); //###cast
	
	/* indicate that the command is to be reparsed with the new list */
	return ERR_PREPRSCMDREDO;
    }
    
    /* if the result is nil, don't process this command further */
    rundisc(ctx->voccxrun);
    if (typ == DAT_NIL)
	return ERR_PREPRSCMDCAN;
    else
	return 0;
}

/*
 *   execmd() - executes a user's command given the verb's verb and
 *   preposition words, a list of nouns to be used as indirect objects,
 *   and a list to be used for direct objects.  The globals cmdActor and
 *   cmdPrep should already be set.  This routine tries to find a template
 *   for the verb which matches the player's command.  If no template
 *   matches, we try (using default objects and, if that fails, requests
 *   to the player for objects) to fill in any missing information in the
 *   player's command.  If that still fails, we will say we don't
 *   understand the sentence and leave it at that.  
 */
int execmd(ctx, actor, prep, vverb, vprep, dolist, iolist,
	   cmd, cmdbuf, wrdcnt, preparse_list)
voccxdef  *ctx;
objnum     actor;
objnum     prep;
char      *vverb;
char      *vprep;
vocoldef  *dolist;
vocoldef  *iolist;
char     **cmd;
char      *cmdbuf;
int        wrdcnt;
char     **preparse_list;
{
    objnum    verb;
    objnum    iobj;
    int       i;
    int       multi = FALSE;
    vocwdef  *n;
    int       cnt;
    vocoldef *newnoun;
    int       next;
    char     *exenewcmd;
    char     *donewcmd;
    char     *ionewcmd;
    char     *exenewbuf;
    char     *donewbuf;
    char     *ionewbuf;
    char    **exenewlist;
    char    **donewlist;
    char    **ionewlist;
    int      *exenewtype;
    int      *donewtype;
    int      *ionewtype;
    vocoldef *dolist1;
    vocoldef *iolist1;
    uchar     tpl[VOCTPL2SIZ];
    int       foundtpl;        /* used to determine success of tpl searches */
    runcxdef *rcx = ctx->voccxrun;
    uint      tplofs;                          /* offset of template object */
    uchar    *tplptr;                          /* pointer to template value */
    int       tplcnt;                        /* number of templates in list */
    uint      actofs;                        /* offset of 'action' property */
    int       askflags;                /* flag for what we need to ask user */
    int       newstyle;   /* flag indicating new-style template definitions */
    int       tplflags;
    int       err;
    char     *save_sp;

    switch(try_preparse_cmd(ctx, cmd, wrdcnt, preparse_list))
    {
    case 0:
	/* proceed with the command */
	break;

    case ERR_PREPRSCMDCAN:
	/* command cancelled */
	return 0;

    case ERR_PREPRSCMDREDO:
	/* redo the command - so indicate to the caller */
	return ERR_PREPRSCMDREDO;
    }
    
    n = vocffw(ctx, vverb, (int)strlen(vverb),
	       vprep, (vprep ? (int)strlen(vprep) : 0), PRP_VERB,
	       (vocseadef *)0);
    if (!n)
    {
	vocerr(ctx, 18, "I don't understand that sentence.");
	return(1);
    }
    verb = n->vocwobj;

    /* default actor is "Me" */
    if (actor == MCMONINV) actor = ctx->voccxme;
    
    /* set a savepoint, if we're keeping undo information */
    if (ctx->voccxundo)
	objusav(ctx->voccxundo);

    /*
     *   Check that the room will allow this command -- it may not
     *   due to darkness or other ailment.  We can find out with the
     *   roomCheck(verb) message, sent to the meobj.  
     */
    {
	int t;
    
	runrst(rcx);
	runpobj(rcx, verb);
	runppr(rcx, ctx->voccxme, PRP_ROOMCHECK, 1);
	t = runpoplog(rcx);
	if (!t) return(0);                     /* discontinue, but no error */
    }

    /* look for a new-style template first, then the old-style template */
    tplofs = objgetap(ctx->voccxmem, verb, PRP_TPL2, (objnum *)0, FALSE);
    if (tplofs == 0)
	tplofs = objgetap(ctx->voccxmem, verb, PRP_TPL, (objnum *)0, FALSE);

    /* also look to see if the verb has an Action method */
    actofs = objgetap(ctx->voccxmem, verb, PRP_ACTION, (objnum *)0, FALSE);
    
    if (tplofs == 0 && actofs == 0 && verb != ctx->voccxvag)
    {
	vocerr(ctx, 23,
	 "internal error: verb has no action, doAction, or ioAction");
	return(1);
    }

    /*
     *   Check to see if we have an "all" - if we do, we'll need to
     *   display the direct object's name even if only one direct object
     *   comes of it.  
     */
    multi = check_for_multi(dolist);

    /* set up dobj word list in case objwords is used */
    ctx->voccxdobj = dolist;

    /* set up our stack allocations, which we may need from now on */
    voc_enter(&save_sp);
    VOC_STK_ARRAY(ctx, char,     donewcmd,  VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     ionewcmd,  VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     donewbuf,  2*VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     ionewbuf,  2*VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char *,   donewlist, VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char *,   ionewlist, VOCBUFSIZ);
    VOC_MAX_ARRAY(ctx, int,      donewtype);
    VOC_MAX_ARRAY(ctx, int,      ionewtype);
    VOC_MAX_ARRAY(ctx, vocoldef, dolist1);
    VOC_MAX_ARRAY(ctx, vocoldef, iolist1);

    /* keep going until we're done with the sentence */
    for ( ;; )
    {
	askflags = err = 0;
	
	ERRBEGIN(ctx->voccxerr)
	
	/*
	 *   Now see what kind of sentence we have.  If we have no
	 *   objects and an action, use the action.  If we have a direct
	 *   object and a doAction, use the doAction.  If we have an
	 *   indirect object and an ioAction with a matching preposition,
	 *   use the ioAction.  If we have an indirect object and no
	 *   matching ioAction, complain.  If we have a direct object and
	 *   no doAction or ioAction, complain.  If we have fewer objects
	 *   than we really want, ask the user for more of them.  
	 */
	if (voclistlen(dolist) == 0 && voclistlen(iolist) == 0)
	{
	    if (actofs || verb == ctx->voccxvag)
	    {
		if (err = exeloop(ctx, actor, verb, (vocoldef *)0, &prep,
				  (vocoldef *)0, multi, (uchar *)0, 0))
		    goto exit_error;
	    }
	    else
	    {
		/*
		 *   The player has not specified any objects, but the
		 *   verb seems to require one.  See if there's a unique
		 *   default.  
		 */
		runrst(rcx);
		runpnil(rcx);
		runpobj(rcx, prep);
		runpobj(rcx, actor);
		runppr(rcx, verb, PRP_DODEFAULT, 3);
		
		if (runtostyp(rcx) == DAT_LIST)
		{
		    uchar   *l = runpoplst(rcx);
		    uint     lstsiz;
		    objnum   defobj;
		    int      objcnt;
		    objnum   newprep;
		    runsdef  val;
		    objnum   o;
		    
		    /* push list back on stack, to keep in heap */
		    val.runsv.runsvstr = (char *)l;
		    val.runstyp = DAT_LIST;
		    runrepush(rcx, &val);
		    
		    /* get list size out of list */
		    lstsiz = osrp2(l) - 2;
		    l += 2;

		    /* find default preposition for verb, if any */
		    runppr(rcx, verb, PRP_PREPDEFAULT, 0);
		    if (runtostyp(rcx) == DAT_OBJECT)
			newprep = runpopobj(rcx);
		    else
		    {
			newprep = MCMONINV;
			rundisc(rcx);
		    }
		    
		    if (!voctplfnd(ctx, verb, newprep, tpl, &newstyle))
		    {
			for (objcnt = 0 ; lstsiz && objcnt < 2
			     ; lstadv(&l, &lstsiz))
			{
			    if (*l == DAT_OBJECT)
			    {
				++objcnt;
				defobj = osrp2(l + 1);
			    }
			}
		    }
		    else
		    {
			int dobj_first;
			
			/*
			 *   Get the template flags.  If we must
			 *   disambiguate the direct object first for this
			 *   verb, do so now. 
			 */
			tplflags = (newstyle ? voctplflg(tpl) : 0);
			dobj_first = (tplflags & VOCTPLFLG_DOBJ_FIRST);

			for (objcnt = 0 ; lstsiz && objcnt < 2
			     ; lstadv(&l, &lstsiz))
			{
			    if (*l == DAT_OBJECT)
			    {
				o = osrp2(l + 1);
				if (!objgetap(ctx->voccxmem, o, voctplvd(tpl),
					      (objnum *)0, FALSE))
				    continue;
				
				tiohide(ctx->voccxtio);
				if (newprep != MCMONINV && !dobj_first)
				    runpnil(rcx);
				runpobj(rcx, actor);
				runppr(rcx, o, voctplvd(tpl),
				       ((newprep != MCMONINV && !dobj_first)
					? 2 : 1));
				
				if (!tioshow(ctx->voccxtio))
				{
				    ++objcnt;
				    defobj = o;
				}
			    }
			}
			
			/* no longer need list in heap, so discard it */
			rundisc(rcx);
		
			/* use default object if there's exactly one */
			if (objcnt == 1)
			{
			    dolist[0].vocolobj = defobj;
			    dolist[0].vocolflg = 0;
			    dolist[0].vocolfst = dolist[0].vocollst = 0;
			    dolist[1].vocolobj = MCMONINV;
			    dolist[1].vocolflg = 0;
			    dolist[1].vocolfst = dolist[1].vocollst = 0;

			    runrst(rcx);
			    if (ctx->voccxpdef != MCMONINV)
			    {
				runpnil(rcx);
				runpobj(rcx, defobj);
				runfn(rcx, ctx->voccxpdef, 2);
			    }
			    else
			    {
				/* tell the player what we're doing */
				vocerr(ctx, 130, "(");
				runppr(rcx, defobj, PRP_THEDESC, 0);
				vocerr(ctx, 131, ")");
				tioflush(ctx->voccxtio);
			    }
			    err = -2;                         /* "continue" */
			    goto exit_error;
			}
		    }
		}
		else
		    rundisc(rcx);
	    
		/*
		 *   No unique default; ask the player for a direct
		 *   object, and try the command again if he is kind
		 *   enough to provide one.  
		 */
		askflags = ERR_RUNASKD;
	    }
	}
	else if (voclistlen(iolist) == 0)
	{
	    /* direct object(s), but no indirect object -- find doAction */
	    if (voctplfnd(ctx, verb, MCMONINV, tpl, &newstyle))
	    {
		/* disambiguate the direct object list, now that we can */
		if (vocdisambig(ctx, dolist1, dolist, PRP_DODEFAULT,
				PRP_VALIDDO, voctplvd(tpl), cmd, MCMONINV,
				actor, verb, prep, MCMONINV, cmdbuf, 0))
		{
		    err = -1;
		    goto exit_error;
		}
		iobj = MCMONINV;

		/*
		 *   save the disambiguated direct object list, in case
		 *   we hit an askio in the course of processing it 
		 */
		memcpy(dolist, dolist1,
		       (size_t)(voclistlen(dolist1) + 1)*sizeof(dolist[0]));

		/* re-check for multi-mode */
		if (!multi)
		    multi = check_for_multi(dolist1);
		
		/* save it/them/him/her, and execute the command */
		exesaveit(ctx, dolist1);
		if (err = exeloop(ctx, actor, verb, dolist1, &prep,
				  (vocoldef *)0, multi, tpl, newstyle))
		    goto exit_error;
	    }
	    else
	    {
		/* no doAction - we'll need to find an indirect object */
		runrst(rcx);
		runppr(rcx, verb, PRP_PREPDEFAULT, 0);
		if (runtostyp(rcx) != DAT_OBJECT)
		{
		    rundisc(rcx);
		    vocerr(ctx, 24, "I don't recognize that sentence.");
		    err = -1;
		    goto exit_error;
		}
		prep = runpopobj(rcx);
	    
		runrst(rcx);
		runpobj(rcx, prep);
		runpobj(rcx, actor);
		runppr(rcx, verb, PRP_IODEFAULT, 2);
		
		if (runtostyp(rcx) == DAT_LIST)
		{
		    uchar   *l = runpoplst(rcx);
		    uint     lstsiz;
		    objnum   defobj;
		    int      objcnt;
		    runsdef  val;
		    objnum   o;
		    
		    /* push list back on stack, to keep in heap */
		    val.runsv.runsvstr = (char *)l;
		    val.runstyp = DAT_LIST;
		    runrepush(rcx, &val);
		    
		    /* get list size out of list */
		    lstsiz = osrp2(l) - 2;
		    l += 2;
		    
		    if (!voctplfnd(ctx, verb, prep, tpl, &newstyle))
		    {
			for (objcnt = 0 ; lstsiz && objcnt < 2
			     ; lstadv(&l, &lstsiz))
			{
			    if (*l == DAT_OBJECT)
			    {
				objcnt++;
				defobj = osrp2(l + 1);
			    }
			}
		    }
		    else
		    {
			int dobj_first;
			
			/*
			 *   Get the template flags.  If we must
			 *   disambiguate the direct object first for this
			 *   verb, do so now. 
			 */
			tplflags = (newstyle ? voctplflg(tpl) : 0);
			dobj_first = (tplflags & VOCTPLFLG_DOBJ_FIRST);
			if (dobj_first)
			{
			    if (vocdisambig(ctx, dolist1, dolist,
					    PRP_DODEFAULT, PRP_VALIDDO,
					    voctplvd(tpl), cmd, MCMONINV,
					    actor, verb, prep, MCMONINV,
					    cmdbuf, tplflags))
			    {
				err = -1;
				goto exit_error;
			    }

			    /* only one direct object is allowed here */
			    if (voclistlen(dolist1) > 1)
			    {
				vocerr(ctx, 28, "You can't use multiple \
objects with this command.");
				err = -1;
				goto exit_error;
			    }

			    /* save the object in the original list */
			    memcpy(dolist, dolist1,
				   (size_t)(2 * sizeof(dolist[0])));
			}
			
			for (objcnt = 0 ; lstsiz && objcnt < 2
			     ; lstadv(&l, &lstsiz))
			{
			    if (*l == DAT_OBJECT)
			    {
				o = osrp2(l + 1);
				if (!objgetap(ctx->voccxmem, o, voctplvi(tpl),
					      (objnum *)0, FALSE))
				    continue;
				
				tiohide(ctx->voccxtio);
				if (dobj_first)
				    runpobj(rcx, dolist[0].vocolobj);
				runpobj(rcx, actor);
				runppr(rcx, o, voctplvi(tpl),
				       (dobj_first ? 2 : 1));
				if (!tioshow(ctx->voccxtio))
				{
				    objcnt++;
				    defobj = o;
				}
			    }
			}
		    }
		    
		    /* no longer need list in heap, so discard it */
		    rundisc(rcx);

		    /* if there's exactly one default object, use it */
		    if (objcnt == 1)
		    {
			iolist[0].vocolobj = defobj;
			iolist[0].vocolflg = 0;
			iolist[0].vocolfst = iolist[0].vocollst = 0;
			iolist[1].vocolobj = MCMONINV;
			iolist[1].vocolflg = 0;
			iolist[1].vocolfst = iolist[1].vocollst = 0;
		    
			/* tell the user what we're assuming */
			runrst(rcx);
			if (ctx->voccxpdef != MCMONINV)
			{
			    runpobj(rcx, prep);
			    runpobj(rcx, defobj);
			    runfn(rcx, ctx->voccxpdef, 2);
			}
			else
			{
			    vocerr(ctx, 130, "(");
			    runppr(rcx, prep, PRP_SDESC, 0);
			    vocerr(ctx, 132, " ");
			    runppr(rcx, defobj, PRP_THEDESC, 0);
			    vocerr(ctx, 131, ")");
			}
			tioflush(ctx->voccxtio);
			err = -2;                             /* "continue" */
			goto exit_error;
		    }
		}
		else
		    rundisc(rcx);
	    
		/*
		 *   We didn't get a unique default indirect object, so
		 *   we should ask the player for an indirct object, and
		 *   repeat the command should he provide one.  
		 */
		askflags = ERR_RUNASKI;
	    }
	}
	else
	{
	    objnum otherobj;
	    
	    /*
	     *   We have both direct and indirect objects.  If we don't
	     *   yet have the direct object, go ask for it 
	     */
	    if (voclistlen(dolist) == 0)
	    {
		askflags = ERR_RUNASKD;
		goto exit_error;
	    }

	    /* find the template for this verb/prep combination */
	    if (!voctplfnd(ctx, verb, prep, tpl, &newstyle))
	    {
		vocerr(ctx, 24, "I don't recognize that sentence.");
		err = -1;
		goto exit_error;
	    }

	    /* get the flags (if old-style, flags are always zero) */
	    tplflags = (newstyle ? voctplflg(tpl) : 0);

	    /*
	     *   the "other" object (dobj if doing iobj, iobj if doing
	     *   dobj) is not known when the first object is disambiguated
	     */
	    otherobj = MCMONINV;

	    /* disambiguate the objects in the proper order */
	    if (tplflags & VOCTPLFLG_DOBJ_FIRST)
	    {
		/* disambiguate the direct object list */
		if (vocdisambig(ctx, dolist1, dolist, PRP_DODEFAULT,
				PRP_VALIDDO, voctplvd(tpl), cmd, otherobj,
				actor, verb, prep, iobj, cmdbuf, tplflags))
		{
		    err = -1;
		    goto exit_error;
		}

		/*
		 *   only one direct object is allowed if it's
		 *   disambiguated first 
		 */
		if (voclistlen(dolist1) > 1)
		{
		    vocerr(ctx, 28,
			 "You can't use multiple objects with this command.");
		    err = -1;
		    goto exit_error;
		}

		/* the other object is now known for iboj disambiguation */
		otherobj = dolist1[0].vocolobj;
	    }

	    /* disambiguate the indirect object list */
	    if (vocdisambig(ctx, iolist1, iolist, PRP_IODEFAULT,
			    PRP_VALIDIO, voctplvi(tpl), cmd, otherobj,
			    actor, verb, prep, iobj, cmdbuf, tplflags))
	    {
		err = -1;
		goto exit_error;
	    }

	    /* only one indirect object is allowed */
	    if (voclistlen(iolist1) > 1)
	    {
		vocerr(ctx, 25,
		       "You can't use multiple indirect objects.");
		err = -1;
		goto exit_error;
	    }
	    otherobj = iobj = iolist1[0].vocolobj;

	    /*
	     *   disambiguate the direct object list if we haven't
	     *   already done so (we might have disambiguated it first due
	     *   to the DisambigDobjFirst flag being set in the template)
	     */
	    if (!(tplflags & VOCTPLFLG_DOBJ_FIRST)
		&& vocdisambig(ctx, dolist1, dolist, PRP_DODEFAULT,
			       PRP_VALIDDO, voctplvd(tpl), cmd, otherobj,
			       actor, verb, prep, iobj, cmdbuf, tplflags))
	    {
		err = -1;
		goto exit_error;
	    }
		
	    /* re-check for multi-mode */
	    if (!multi)
		multi = check_for_multi(dolist1);
	    
	    /* save it/them/him/her, and execute the command */
	    exesaveit(ctx, dolist1);
	    if (err = exeloop(ctx, actor, verb, dolist1, &prep, iolist1,
			      multi, tpl, newstyle))
		goto exit_error;
	}
	
    exit_error: ;
	
	ERRCATCH(ctx->voccxerr, err)
	    if (err == ERR_RUNASKI) prep = errargint(0);
	    if (err != ERR_RUNASKD && err != ERR_RUNASKI)
		errrse(ctx->voccxerr);
	ERREND(ctx->voccxerr)

	switch(err)
	{
	case 0:
	    break;
	    
	case ERR_RUNABRT:
	    VOC_RETVAL(save_sp, err);
	    
	case ERR_RUNASKI:
	case ERR_RUNASKD:
	    askflags = err;
	    break;
	    
	case -2:                   /* special code: continue with main loop */
	    continue;

	case -1:                           /* special code: return an error */
	default:
	    VOC_RETVAL(save_sp, 1);
	}
    
	/*
	 *   If we got this far, we probably want more information.  The
	 *   askflags can tell us what to do from here.  
	 */
	if (askflags)
	{
	    /* find new template indicated by the additional object */
	    foundtpl = voctplfnd(ctx, verb, prep, tpl, &newstyle);
	    tplflags = (newstyle ? voctplflg(tpl) : 0);
	
	    /* find a default object of the type requested */
	    runrst(rcx);
	    if (askflags == ERR_RUNASKD) runpnil(rcx);
	    runpobj(rcx, prep);
	    runpobj(rcx, actor);
	    runppr(rcx, verb,
		   (askflags == ERR_RUNASKD ? PRP_DODEFAULT : PRP_IODEFAULT),
		   (askflags == ERR_RUNASKD ? 3 : 2));
	    
	    /*
	     *   If we got a list back from ?oDefault, and we have a new
	     *   template for the command, process the list normally with
	     *   the object verification routine for this template.  If we
	     *   end up with exactly one object, we will assume it is the
	     *   object to be used; otherwise, make no assumption and ask
	     *   the user for guidance.  
	     */
	    if (runtostyp(rcx) == DAT_LIST && foundtpl)
	    {
		uchar   *l = runpoplst(rcx);
		uint     lstsiz;
		int      objcnt;
		objnum   defobj;
		objnum   o;
		runsdef  val;
		int      pushiobj;
		
		/* push list back on stack, to keep it in the heap */
		val.runsv.runsvstr = (char *)l;
		val.runstyp = DAT_LIST;
		runrepush(rcx, &val);
		
		/* get list size out of list */
		lstsiz = osrp2(l) - 2;
		l += 2;
		
		for (objcnt = 0 ; lstsiz && objcnt < 2 ; lstadv(&l, &lstsiz))
		{
		    if (*l == DAT_OBJECT)
		    {
			int verprop;
		    
			o = osrp2(l + 1);
			verprop = (askflags == ERR_RUNASKD ? voctplvd(tpl)
			                                : voctplvi(tpl));
		
			if (!objgetap(ctx->voccxmem, o, verprop,
				      (objnum *)0, FALSE))
			    continue;

			tiohide(ctx->voccxtio);

			/*
			 *   In the unlikely event that we have an
			 *   indirect object but no direct object, push
			 *   the iobj.  This can happen when the player
			 *   types a sentence such as "verb prep iobj".  
			 */
			pushiobj = (voclistlen(iolist) != 0
				    && askflags == ERR_RUNASKD
				    && !(tplflags & VOCTPLFLG_DOBJ_FIRST));
			if (pushiobj) runpobj(rcx, iolist[0].vocolobj);
			runpobj(rcx, actor);
			runppr(rcx, o, verprop, pushiobj ? 2 : 1);
			if (!tioshow(ctx->voccxtio))
			{
			    ++objcnt;
			    defobj = o;
			}

		    }
		}
		
		/* no longer need list in heap, so discard it */
		rundisc(rcx);
		
		/* if we found exactly one object, it's the default */
		if (objcnt == 1)
		{
		    if (askflags == ERR_RUNASKD)
		    {
			dolist[0].vocolobj = defobj;
			dolist[0].vocolflg = 0;
			dolist[0].vocolfst = dolist[0].vocollst = 0;
			dolist[1].vocolobj = MCMONINV;
			dolist[1].vocolflg = 0;
			dolist[1].vocolfst = dolist[1].vocollst = 0;
		    }
		    else
		    {
			iolist[0].vocolobj = defobj;
			iolist[0].vocolflg = 0;
			iolist[0].vocolfst = iolist[0].vocollst = 0;
			iolist[1].vocolobj = MCMONINV;
			iolist[1].vocolflg = 0;
			iolist[1].vocolfst = iolist[1].vocollst = 0;
		    }
		    
		    /* tell the user what we're assuming */
		    if (ctx->voccxpdef != MCMONINV)
		    {
			if (askflags == ERR_RUNASKI)
			    runpobj(rcx, prep);
			else
			    runpnil(rcx);
			runpobj(rcx, defobj);
			runfn(rcx, ctx->voccxpdef, 2);
		    }
		    else
		    {
			vocerr(ctx, 130, "(");
			if (askflags == ERR_RUNASKI)
			{
			    runppr(rcx, prep, PRP_SDESC, 0);
			    vocerr(ctx, 132, " ");
			}
			runppr(rcx, defobj, PRP_THEDESC, 0);
			vocerr(ctx, 131, ")");
		    }
		    tioflush(ctx->voccxtio);
		    continue;                      /* try the command again */
		}
	    }
	    else
		rundisc(rcx);

	    /* make sure output capturing is off for the prompt */
	    tiocapture(ctx->voccxtio, (mcmcxdef *)0, FALSE);
	    tioclrcapture(ctx->voccxtio);
	    
	    /*
	     *   if there's a parseAskobjActor routine, use it;
	     *   otherwise, if there's a parseAskobj routine, use that;
	     *   otherwise, generate the default phrasing 
	     */
	    if (ctx->voccxpask2 != MCMONINV)
	    {
		if (askflags == ERR_RUNASKI)
		    runpobj(ctx->voccxrun, prep);
		runpobj(ctx->voccxrun, verb);
		runpobj(ctx->voccxrun,
			actor == MCMONINV ? ctx->voccxme : actor);
		runfn(ctx->voccxrun, ctx->voccxpask2,
		      askflags == ERR_RUNASKI ? 3 : 2);
	    }
	    else if (ctx->voccxpask != MCMONINV)
	    {
		if (askflags == ERR_RUNASKI)
		    runpobj(ctx->voccxrun, prep);
		runpobj(ctx->voccxrun, verb);
		runfn(ctx->voccxrun, ctx->voccxpask,
		      askflags == ERR_RUNASKI ? 2 : 1);
	    }
	    else
	    {
		/*
		 *   Phrase the question: askDo: "What do you want
		 *   <actor> to <verb>?"  askIo: "What do you want <actor>
		 *   to <verb> it <prep>?"  If the actor is Me, leave the
		 *   actor out of it.  
		 */
		if (actor != MCMONINV && actor != ctx->voccxme)
		{
		    vocerr(ctx, 148, "What do you want ");
		    runppr(rcx, actor, PRP_THEDESC, 0);
		    vocerr(ctx, 149, " to ");
		}
		else
		{
		    /* no actor - don't mention one */
		    vocerr(ctx, 140, "What do you want to ");
		}

		/* add the verb */
		runppr(rcx, verb, PRP_SDESC, 0);

		/*
		 *   add an appropriate pronoun for the direct object,
		 *   and the preposition, if we're asking for an indirect
		 *   object 
		 */
		if (askflags == ERR_RUNASKI)
		{
		    int   i;
		    int   cnt;
		    int   distinct;
		    char *lastfst;

		    /*
		     *   If possible, tailor the pronoun to the situation
		     *   rather than using "it"; if we have multiple
		     *   objects, use "them", and if we have agreement
		     *   with the possible single objects about "him" or
		     *   "her", use that.  Otherwise, use "it".  If "all"
		     *   was specified for any word, automatically assume
		     *   multiple distinct objects were specified.  
		     */
		    cnt = voclistlen(dolist);
		    for (distinct = 0, i = 0, lastfst = 0 ; i < cnt ; ++i)
		    {
			/* if the first word is different here, note it */
			if (lastfst != dolist[i].vocolfst)
			{
			    /* this is a different word - count it */
			    ++distinct;
			    lastfst = dolist[i].vocolfst;
			}

			/* always assume multiple distinct objects on "all" */
			if (dolist[i].vocolflg & VOCS_ALL)
			{
			    distinct = 2;
			    break;
			}
		    }

		    /*
		     *   If we have multiple words, use "them";
		     *   otherwise, see if we can find agreement about
		     *   using "him" or "her". 
		     */
		    if (distinct > 1)
		    {
			/* multiple words specified by user - use "them" */
			vocerr(ctx, 144, " them ");
		    }
		    else
		    {
			int is_him;
			int is_her;

			/* run through the objects and check him/her */
			for (i = 0 ; i < cnt ; ++i)
			{
			    int him1, her1;

			    /* if it's special (number, string), use "it" */
			    if (dolist[i].vocolobj == MCMONINV)
			    {
				him1 = FALSE;
				her1 = FALSE;
			    }
			    else
			    {
				/* check for "him" */
				runppr(rcx, dolist[i].vocolobj, PRP_ISHIM, 0);
				him1 = (runtostyp(rcx) == DAT_TRUE);
				rundisc(rcx);
				
				/* check for "her" */
				runppr(rcx, dolist[i].vocolobj, PRP_ISHER, 0);
				her1 = (runtostyp(rcx) == DAT_TRUE);
				rundisc(rcx);
			    }

			    /*
			     *   if this is the first object, it
			     *   definitely agrees; otherwise, keep going
			     *   only if it agrees with what we found on
			     *   the last pass 
			     */
			    if (i == 0)
			    {
				is_him = him1;
				is_her = her1;
			    }
			    else
			    {
				/* turn off either that is no longer true */
				if (!him1) is_him = FALSE;
				if (!her1) is_her = FALSE;
			    }

			    /* if both are false, stop now */
			    if (!is_him && !is_her)
				break;
			}

			/*
			 *   If we could agree on either "him" or "her",
			 *   use that pronoun; otherwise, use "it".  If we
			 *   found both "him" and "her" are acceptable for
			 *   all objects, use "them".  
			 */
			if (is_him && is_her)
			    vocerr(ctx, 147, " them ");
			else if (is_him)
			    vocerr(ctx, 145, " him ");
			else if (is_her)
			    vocerr(ctx, 146, " her ");
			else
			    vocerr(ctx, 141, " it ");
		    }

		    /* finish off the question with the prep and a "?" */
		    if (prep != MCMONINV) runppr(rcx, prep, PRP_SDESC, 0);
		    else vocerr(ctx, 142, "to");
		}
		vocerr(ctx, 143, "?");
	    }
	    tioflush(ctx->voccxtio);
		
	    /*
	     *   Get a new command line.  If the player gives us
	     *   something that looks like a noun list, and nothing more,
	     *   he anwered our question; otherwise, he's typing a new
	     *   command, so we must return to the caller with the reparse
	     *   flag set.  
	     */
	    if (askflags == ERR_RUNASKD)
	    {
		exenewbuf = donewbuf;
		exenewcmd = donewcmd;
		exenewlist = donewlist;
		exenewtype = donewtype;
	    }
	    else
	    {
		exenewbuf = ionewbuf;
		exenewcmd = ionewcmd;
		exenewlist = ionewlist;
		exenewtype = ionewtype;
	    }

	    vocread(ctx, exenewcmd, VOCBUFSIZ,
		    askflags == ERR_RUNASKD ? 3 : 4);
	    if (!(cnt = voctok(ctx, exenewcmd, exenewbuf, exenewlist,
			       TRUE, FALSE)))
	    {
		runrst(rcx);
		runfn(rcx, ctx->voccxprd, 0);
		VOC_RETVAL(save_sp, 1);
	    }
	    if (cnt < 0) { VOC_RETVAL(save_sp, 1); }
	    
	    exenewlist[cnt] = 0;
	    if (vocgtyp(ctx, exenewlist, exenewtype, cmdbuf))
	    {
		VOC_RETVAL(save_sp, 1);
	    }
	    newnoun = (askflags == ERR_RUNASKD ? dolist : iolist);
	    
	    cnt = vocchknoun(ctx, exenewlist, exenewtype, 0, &next,
			     newnoun, FALSE);
	    
	    if (cnt < 0) { VOC_RETVAL(save_sp, 1); }       /* invalid syntax */
	    if (cnt == 0
		|| (exenewlist[next] && !vocspec(exenewlist[next], VOCW_THEN)
		    && *exenewlist[next] != '\0'))
	    {
		strcpy(cmdbuf, exenewcmd);
		ctx->voccxredo = TRUE;
		VOC_RETVAL(save_sp, 1);
	    }
	    /* give it another go by going back to the top of the loop */
	}
	else
	{
	    /* normal exit flags - return success */
	    VOC_RETVAL(save_sp, 0);
	}
    }
}

