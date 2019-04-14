#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/suprun.c 1.7 96/10/14 16:10:45 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  suprun.c - setup functions for run-time
Function
  This module implements the set-up functions needed at run-time
Notes
  Separated from sup.c to avoid having to link functions needed only
  in the compiler into the runtime.
Modified
  12/16/92 MJRoberts     - add TADS/Graphic extensions
  04/11/92 MJRoberts     - creation
*/

#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include "os.h"
#include "std.h"
#include "obj.h"
#include "prp.h"
#include "dat.h"
#include "tok.h"
#include "mcm.h"
#include "mch.h"
#include "sup.h"
#include "bif.h"

supbidef supbitab[] =
{
    { "say", bifsay },
    { "car", bifcar },
    { "cdr", bifcdr },
    { "length", biflen },
    { "randomize", bifsrn },
    { "rand", bifrnd },
    { "substr", bifsub },
    { "cvtstr", bifcvs },
    { "cvtnum", bifcvn },
    { "upper", bifupr },
    { "lower", biflwr },
    { "caps", bifcap },
    { "find", biffnd },
    { "getarg", bifarg },
    { "datatype", biftyp },
    { "setdaemon", bifsdm },
    { "setfuse", bifsfs },
    { "setversion", bifsvn },
    { "notify", bifnfy },
    { "unnotify", bifunn },
    { "yorn", bifyon },
    { "remfuse", bifrfs },
    { "remdaemon", bifrdm },
    { "incturn", bifinc },
    { "quit", bifqui },
    { "save", bifsav },
    { "restore", bifrso },
    { "logging", biflog },
    { "input", bifinp },
    { "setit", bifsit },
    { "askfile", bifask },
    { "setscore", bifssc },
    { "firstobj", biffob },
    { "nextobj", bifnob },
    { "isclass", bifisc },
    { "restart", bifres },
    { "debugTrace", biftrc },
    { "undo", bifund },
    { "defined", bifdef },
    { "proptype", bifpty },
    { "outhide", bifoph },
    { "runfuses", bifruf },
    { "rundaemons", bifrud },
    { "gettime", biftim },
    { "getfuse", bifgfu },
    { "intersect", bifsct },
    { "inputkey", bifink },
    { "objwords", bifwrd },
    { "addword", bifadw },
    { "delword", bifdlw },
    { "getwords", bifgtw },
    { "nocaps", bifnoc },
    { "skipturn", bifskt },
    { "clearscreen", bifcls },
    { "firstsc", bif1sc },
    { "verbinfo", bifvin },
    { "fopen", biffopen },
    { "fclose", biffclose },
    { "fwrite", biffwrite },
    { "fread", biffread },
    { "fseek", biffseek },
    { "fseekeof", biffseekeof },
    { "ftell", bifftell },
    { "outcapture", bifcapture },

    { "g_readpic", bifgrp },
    { "g_showpic", bifgsp },
    { "g_sethot", bifgsh },
    { "g_inventory", bifgin },
    { "g_compass", bifgco },
    { "g_overlay", bifgov },
    { "g_mode", bifgmd },
    { "g_music", bifgmu },
    { "g_pause", bifgpa },
    { "g_effect", bifgef },
    { "g_sound", bifgsn },
    { (char *)0, (void(*)())0 }
};

/* set up built-in functions array without symbol table (for run-time) */
void supbif(sup, bif, bifsiz)
supcxdef  *sup;
void     (*bif[])(/*_ bifcxdef*, int argc _*/);
int        bifsiz;
{
    supbidef *p;
    int       i;

    for (p = supbitab, i = 0 ; p->supbinam ; ++i, ++p)
    {
	if (i >= bifsiz) errsig(sup->supcxerr, ERR_MANYBIF);
	bif[i] = p->supbifn;
    }
}

/* set up contents property for load-on-demand */
void supcont(ctx, obj, prp)
supcxdef *ctx;
objnum    obj;
prpnum    prp;
{
    vocidef ***vpg;
    vocidef  **v;
    voccxdef  *voc = ctx->supcxvoc;
    int        i;
    int        j;
    int        len = 2;
    objnum     chi;
    objnum     loc;

    /* be sure the buffer is allocated */
    if (!ctx->supcxbuf)
    {
	ctx->supcxlen = 512;
	ctx->supcxbuf = mchalo(ctx->supcxerr, (ushort)ctx->supcxlen,
			       "supcont");
    }

    assert(prp == PRP_CONTENTS);         /* the only thing that makes sense */
    for (vpg = voc->voccxinh, i = 0 ; i < VOCINHMAX ; ++vpg, ++i)
    {
	if (!*vpg) continue;                     /* no entries on this page */
	for (v = *vpg, chi = (i << 8), j = 0 ; j < 256 ; ++v, ++chi, ++j)
	{
	    /* if there's no record at this location, skip it */
	    if (!*v) continue;

	    /* inherit the location if it hasn't been set to any value */
	    if ((*v)->vociloc == MCMONINV
		&& !((*v)->vociflg & VOCIFLOCNIL))
		loc = (*v)->vociilc;
	    else
		loc = (*v)->vociloc;

	    /* if this object is in the indicated location, add it */
	    if (loc == obj && !((*v)->vociflg & VOCIFCLASS))
	    {
		/* see if we have room in list buffer; expand buffer if not */
		if (len + 3 > ctx->supcxlen)
		{
		    mchfre(ctx->supcxbuf);
		    ctx->supcxlen = len + 512;
		    if (len + 3 > ctx->supcxlen)
			errsig(ctx->supcxmem->mcmcxgl->mcmcxerr, ERR_SUPOVF);
		    ctx->supcxbuf = mchalo(ctx->supcxerr,
					   (ushort)ctx->supcxlen, "supcont");
		}
		ctx->supcxbuf[len] = DAT_OBJECT;
		oswp2(ctx->supcxbuf + len + 1, chi);
		len += 3;
	    }
	}
    }

    oswp2(ctx->supcxbuf, len);
    objsetp(ctx->supcxmem, obj, prp, DAT_LIST, ctx->supcxbuf,
	    ctx->supcxrun->runcxundo);
}

static void supiwrds(ctx, sc, target, flags)
voccxdef *ctx;
objnum    sc;                     /* superclass whose words are to be added */
objnum    target;                           /* object to which to add words */
{
    int       i;
    vocdef   *v;
    vocdef  **vp;
    vocwdef *vw;
    
    /* go through each hash value looking for superclass object */
    for (i = VOCHASHSIZ, vp = ctx->voccxhsh ; i ; ++vp, --i)
    {
        /* go through all words in this hash chain */
        for (v = *vp ; v ; v = v->vocnxt)
        {
	    /* go through all vocwdef's defined for this word */
	    for (vw = vocwget(ctx, v->vocwlst) ; vw ;
		 vw = vocwget(ctx, vw->vocwnxt))
	    {
		/* add word to target if it's defined for this superclass */
		if (vw->vocwobj == sc)
		    vocadd2(ctx, vw->vocwtyp, target, VOCFINH + flags,
			    v->voctxt, v->voclen,
			    (v->vocln2 ? v->voctxt + v->voclen : (uchar *)0),
			    v->vocln2);
	    }
        }
    }
}

/* set up inherited vocabulary for a particular object */
void supivoc1(sup, ctx, v, target, inh_from_obj, flags)
supcxdef *sup;
voccxdef *ctx;
vocidef  *v;                    /* vocidef for object we're inheriting from */
objnum    target;                  /* target object to which vocab is added */
int       inh_from_obj;       /* if true, inherit even if sc is not a class */
int       flags;                       /* extra VOCFxxx flags for the words */
{
    objnum   *sc;
    int       numsc;
    vocidef  *scv;
    
    for (numsc = v->vocinsc, sc = v->vocisc ; numsc ; ++sc, --numsc)
    {
        scv = vocinh(ctx, *sc);
        if (scv)
        {
            /* inherit from its superclasses first */
            supivoc1(sup, ctx, scv, target, FALSE, flags);
            
            /* if it's a class object, we can inherit from it */
            if (scv->vociflg & VOCIFCLASS)
            {
                /* inherit location, if we haven't already done so */
                if (v->vociilc == MCMONINV)
		{
		    if (scv->vociloc == MCMONINV)
			v->vociilc = scv->vociilc;
		    else
			v->vociilc = scv->vociloc;
		}
	    }

	    /*
	     *   inherit from superclass if it's a class, or if we're
	     *   supposed to inherit from any object 
	     */
	    if (inh_from_obj || (scv->vociflg & VOCIFCLASS))
	    {
                /* inherit vocabulary if this superclass has any words */
                if (scv->vociflg & VOCIFVOC)
		    supiwrds(ctx, *sc, target, flags);
            }
        }
        else
        {
            char  buf[TOKNAMMAX + 1];

	    /* get the symbol's name */
	    supgnam(buf, sup->supcxtab, *sc);

	    /* log an error with the symbol's name and location of first use */
	    sup_log_undefobj(ctx->voccxmem, ctx->voccxerr, ERR_UNDFOBJ,
			     buf, (int)strlen(buf), *sc);
        }
    }    
}

void sup_log_undefobj(mctx, ec, err, nm, nmlen, objn)
mcmcxdef *mctx;
errcxdef *ec;
int       err;
char     *nm;
int       nmlen;
objnum    objn;
{
    char   *p;
    size_t  len;

    /* get the object - it contains the location where it was defined */
    p = (char*)mcmlck(mctx, (mcmon)objn); //###cast
    p += OBJDEFSIZ;

    /* strip off the ": " suffix if it's present */
    len = strlen(p);

#ifdef OS_ERRLINE
    len += strlen(p + len + 1);
#endif

    /* log the error */
    errlog2(ec, err, ERRTSTR, errstr(ec, nm, nmlen),
	    ERRTSTR, errstr(ec, p, len));

    /* done with the object */
    mcmunlck(mctx, (mcmon)objn);
}

