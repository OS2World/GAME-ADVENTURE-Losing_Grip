#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/bif.c 1.9 96/10/14 16:10:29 mroberts Exp $";
#endif

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  bif.c - built-in function implementation
Function
  Implements built-in functions for TADS
Notes
  None
Modified
  12/16/92 MJRoberts     - add TADS/Graphic functions
  12/26/91 MJRoberts     - creation
*/

#include <ctype.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <time.h>
#include "std.h"
#include "bif.h"
#include "tio.h"
#include "run.h"
#include "voc.h"
#include "fio.h"
#include "dbg.h"
#include "prp.h"


/* yorn - yes or no */
void bifyon(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char     rsp[128];
    char    *p;
    char     c;
    runsdef  val;
    
    bifcntargs(ctx, 0, argc);            /* check for proper argument count */
    
    tioflushn(ctx->bifcxtio, 0);          /* ensure the prompt is displayed */
    tioreset(ctx->bifcxtio);         /* reset count of lines since kb input */
    tiogets(ctx->bifcxtio, (char *)0, rsp, (int)sizeof(rsp));   /* get file */
    for (p = rsp ; isspace(*p) ; ++p);           /* scan off leading spaces */
    
    c = *p;
    if (c == 'y' || c == 'Y') val.runsv.runsvnum = 1;
    else if (c == 'n' || c == 'N') val.runsv.runsvnum = 0;
    else val.runsv.runsvnum = -1;

    runpush(ctx->bifcxrun, DAT_NUMBER, &val);
}

/* setfuse */
void bifsfs(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    func;
    uint      tm;
    runsdef   val;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 3, argc);            /* check for proper argument count */
    func = runpopfn(ctx->bifcxrun);
    tm = runpopnum(ctx->bifcxrun);
    runpop(ctx->bifcxrun, &val);
    
    /* limitation:  don't allow string or list for value */
    if (val.runstyp == DAT_LIST || val.runstyp == DAT_SSTRING)
        runsig(ctx->bifcxrun, ERR_FUSEVAL);
    
    vocsetfd(voc, voc->voccxfus, func, (prpnum)0,
             tm, &val, ERR_MANYFUS);
}

/* remfuse */
void bifrfs(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    func;
    runsdef   val;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 2, argc);
    func = runpopfn(ctx->bifcxrun);
    runpop(ctx->bifcxrun, &val);
    vocremfd(voc, voc->voccxfus, func, (prpnum)0,
             &val, ERR_NOFUSE);
}

/* setdaemon */
void bifsdm(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    func;
    runsdef   val;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 2, argc);            /* check for proper argument count */
    func = runpopfn(ctx->bifcxrun);
    runpop(ctx->bifcxrun, &val);
    
    /* limitation:  don't allow string or list for value */
    if (val.runstyp == DAT_LIST || val.runstyp == DAT_SSTRING)
        runsig(ctx->bifcxrun, ERR_FUSEVAL);
    
    vocsetfd(voc, voc->voccxdmn, func, (prpnum)0, 0,
             &val, ERR_MANYDMN);
}

/* remdaemon */
void bifrdm(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    func;
    runsdef   val;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 2, argc);
    func = runpopfn(ctx->bifcxrun);
    runpop(ctx->bifcxrun, &val);
    vocremfd(voc, voc->voccxdmn, func, (prpnum)0,
             &val, ERR_NODMN);
}

/* incturn */
void bifinc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int turncnt;
    
    if (argc == 1)
    {
	/* get the number of turns to skip */
	turncnt = runpopnum(ctx->bifcxrun);
	if (turncnt < 1)
	    runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "incturn");
    }
    else
    {
	/* no arguments -> increment by one turn */
	bifcntargs(ctx, 0, argc);
	turncnt = 1;
    }

    /* skip the given number of turns */
    vocturn(ctx->bifcxrun->runcxvoc, turncnt, TRUE);
}

/* skipturn */
void bifskt(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int turncnt;

    bifcntargs(ctx, 1, argc);
    turncnt = runpopnum(ctx->bifcxrun);
    if (turncnt < 1)
	runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "incturn");
    vocturn(ctx->bifcxrun->runcxvoc, turncnt, FALSE);
}

/* quit */
void bifqui(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    /* check for proper argument count */
    bifcntargs(ctx, 0, argc);

    /* flush output buffer, and signal the end of the game */
    tioflush(ctx->bifcxtio);
    errsig(ctx->bifcxerr, ERR_RUNQUIT);
}

/* internal function to convert a TADS string into a C-string */
void bifcstr(ctx, buf, bufsiz, str)
bifcxdef *ctx;
char     *buf;
size_t    bufsiz;
char     *str;
{
    size_t  orglen;
    char   *p;
    
    orglen = osrp2(str) - 2;
    str += 2;
    if (orglen + 1 > bufsiz) runsig(ctx->bifcxrun, ERR_BIFCSTR);
    memcpy(buf, str, orglen);
    buf[orglen] = '\0';

    /* convert any \n sequences to newlines, and \t to tabs */
    for (p = buf ; *p ; ++p)
    {
	if (*p == '\\')
	{
	    switch(*(p+1))
	    {
	    case 'n':
		*p = '\n';
		goto move_down;

	    case 't':
		*p = '\t';
		goto move_down;

	    case '\'':
	    case '"':
	    case '\\':
		*p = *(p+1);
		goto move_down;
		
	    move_down:
		memmove(p+1, p+2, (size_t)(strlen(p+2)+1));
		break;

	    case '\0':
	    default:
		/* ignore it */
		break;
	    }
	}
    }
}

/* save */
void bifsav(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char    *fn;
    char     buf[OSFNMAX];
    int      err;
    runsdef  val;
    
    bifcntargs(ctx, 1, argc);
    fn = runpopstr(ctx->bifcxrun);
    bifcstr(ctx, buf, (size_t)sizeof(buf), fn);
    os_defext(buf, "SAV");
    err = fiosav(ctx->bifcxrun->runcxvoc, buf);
    runpush(ctx->bifcxrun, runclog(err), &val);
}

/* restore */
void bifrso(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char     *fn;
    char      buf[OSFNMAX];
    int       err;
    runsdef   val;
    voccxdef *vctx = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 1, argc);
    
    /* check for special restore(nil) - restore game given as parameter */
    if (runtostyp(ctx->bifcxrun) == DAT_NIL)
    {
        /* get filename from startup parameter, if any */
        if (!os_paramfile(buf))
        {
            /* no startup parameter - return 'true' */
            runpush(ctx->bifcxrun, DAT_TRUE, &val);
            return;
        }
    }
    else
    {
        /* get string parameter - it's the filename */
        fn = runpopstr(ctx->bifcxrun);
        bifcstr(ctx, buf, (size_t)sizeof(buf), fn);
        os_defext(buf, "SAV");
    }
    err = fiorso(vctx, buf);
    objulose(vctx->voccxundo);                /* blow away all undo records */
    runpush(ctx->bifcxrun, runclog(err), &val);

    /* note that the rest of the command line is to be ignored */
    vctx->voccxflg |= VOCCXFCLEAR;
}

/* logging */
void biflog(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char  buf[OSFNMAX];
    char *str;
    
    bifcntargs(ctx, 1, argc);
    if (runtostyp(ctx->bifcxrun) == DAT_NIL)
    {
        rundisc(ctx->bifcxrun);
        tiologcls(ctx->bifcxtio);
    }
    else
    {
        str = runpopstr(ctx->bifcxrun);
        bifcstr(ctx, buf, (size_t)sizeof(buf), str);
        tiologopn(ctx->bifcxtio, buf);
    }
}

/* restart */
void bifres(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    voccxdef *vctx = ctx->bifcxrun->runcxvoc;
    objnum    fn;

    if (argc == 2)
	fn = runpopfn(ctx->bifcxrun);            /* get function if present */
    else
    {
	bifcntargs(ctx, 0, argc);        /* check for proper argument count */
	fn = MCMONINV;                         /* no function was specified */
    }

    objulose(vctx->voccxundo);                /* blow away all undo records */
    vocrevert(vctx);                /* revert all objects to original state */
    vocdmnclr(vctx);                   /* clear out fuses/deamons/notifiers */

    /* call preinit if necessary (call it before invoking the user callback) */
    if (vctx->voccxpreinit != MCMONINV)
	runfn(ctx->bifcxrun, vctx->voccxpreinit, 0);

    /*
     *   If a restart function was provided, call it.  Note that we left
     *   the argument for the function on the stack, so there's no need to
     *   re-push it!  
     */
    if (fn != MCMONINV) runfn(ctx->bifcxrun, fn, 1);

    /* restart the game */
    errsig(ctx->bifcxerr, ERR_RUNRESTART);
}

/* input - get a line of input from the keyboard */
void bifinp(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char     inbuf[128];
    char    *p;
    runsdef  val;

    bifcntargs(ctx, 0, argc);            /* check for proper argument count */
    
    tioflushn(ctx->bifcxtio, 0);       /* make sure the prompt is displayed */
    tioreset(ctx->bifcxtio);         /* reset count of lines since kb input */
    tiogets(ctx->bifcxtio, (char *)0, &inbuf[2], (int)sizeof(inbuf) - 2);
    oswp2(inbuf, (int)strlen(inbuf+2) + 2);
    val.runsv.runsvstr = inbuf;

    runpush(ctx->bifcxrun, DAT_SSTRING, &val);
}

/* notify */
void bifnfy(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    objn;
    prpnum    prp;
    uint      tm;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 3, argc);            /* check for proper argument count */
    objn = runpopobj(ctx->bifcxrun);
    prp = runpopprp(ctx->bifcxrun);
    tm = runpopnum(ctx->bifcxrun);
    
    if (tm == 0) tm = 0xffff;            /* a time of zero means every turn */
    
    vocsetfd(voc, voc->voccxalm, objn, prp, tm,
             (runsdef *)0, ERR_MANYNFY);
}

/* unnotify */
void bifunn(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    objn;
    prpnum    prop;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 2, argc);
    objn = runpopobj(ctx->bifcxrun);
    prop = runpopprp(ctx->bifcxrun);
    vocremfd(voc, voc->voccxalm, objn, prop,
             (runsdef *)0, ERR_NONFY);
}

/* trace on/off */
void biftrc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    runsdef val;
    int     n;
    int     flag;

    if (argc == 2)
    {
	/* get the type indicator and the on/off status */
        n = runpopnum(ctx->bifcxrun);
	flag = runpoplog(ctx->bifcxrun);

	/* see what type of debugging they want to turn on or off */
	switch(n)
	{
	case 1:
	    /* turn on parser tracing */
	    if (flag)
		ctx->bifcxrun->runcxvoc->voccxflg |= VOCCXFDBG;
	    else
		ctx->bifcxrun->runcxvoc->voccxflg &= ~VOCCXFDBG;
	    break;

	default:
	    /* ignore other requests */
	    runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "debugTrace");
	}
    }
    else
    {
	/* break into debugger; return whether debugger is present */
	bifcntargs(ctx, 0, argc);
	runpush(ctx->bifcxrun, runclog(dbgstart(ctx->bifcxrun->runcxdbg)),
		&val);
    }
}

/* say */
void bifsay(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char *str;
    long  num;
    char  numbuf[30];

    if (argc != 2) bifcntargs(ctx, 1, argc);
    
    switch(runtostyp(ctx->bifcxrun))
    {
    case DAT_NUMBER:
        num = runpopnum(ctx->bifcxrun);
        sprintf(numbuf, "%ld", num);
        tioputs(ctx->bifcxtio, numbuf);
        break;
        
    case DAT_SSTRING:
        str = runpopstr(ctx->bifcxrun);
        outfmt(ctx->bifcxtio, str);
        break;
        
    case DAT_NIL:
        (void)runpoplog(ctx->bifcxrun);
        break;
        
    default:
        runsig1(ctx->bifcxrun, ERR_INVTBIF, ERRTSTR, "say");
    }
}

/* car */
void bifcar(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    uchar   *lstp;
    uint     siz;
    uint     lstsiz;
    runsdef  val;
    
    bifcntargs(ctx, 1, argc);
    bifchkarg(ctx, DAT_LIST);
    
    lstp = runpoplst(ctx->bifcxrun);
    
    /* get list's size, and point to its data string */
    lstsiz = osrp2(lstp) - 2;
    lstp += 2;
    
    /* push first element if one is present, otherwise push nil */
    if (lstsiz)
        runpbuf(ctx->bifcxrun, *lstp, lstp+1);
    else
        runpush(ctx->bifcxrun, DAT_NIL, &val);
}

/* cdr */
void bifcdr(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    uchar   *lstp;
    uint     siz;
    uint     lstsiz;
    runsdef  val;
    runsdef  stkval;
    
    bifcntargs(ctx, 1, argc);
    bifchkarg(ctx, DAT_LIST);
    
    lstp = runpoplst(ctx->bifcxrun);
    stkval.runstyp = DAT_LIST;
    stkval.runsv.runsvstr = (char*)lstp; //###cast
    
    /* get list's size, and point to its data string */
    lstsiz = osrp2(lstp) - 2;
    lstp += 2;
    
    if (lstsiz)
    {
        /* deduct size of first element from size of list */
        siz = datsiz(*lstp, lstp+1) + 1;
        lstsiz -= siz;
        
        /* allocate space for new list containing rest of list */
        runhres1(ctx->bifcxrun, lstsiz, 1, &stkval);
	lstp = (uchar*)stkval.runsv.runsvstr + siz + 2; //###cast

        /* write out size followed by list value string */
        lstsiz += 2;
        oswp2(ctx->bifcxrun->runcxhp, lstsiz);
        memcpy(ctx->bifcxrun->runcxhp+2, lstp, (size_t)(lstsiz-2));
        
        val.runsv.runsvstr = (char *)ctx->bifcxrun->runcxhp;
        val.runstyp = DAT_LIST;
        ctx->bifcxrun->runcxhp += lstsiz;
        runrepush(ctx->bifcxrun, &val);
    }
    else
        runpush(ctx->bifcxrun, DAT_NIL, &val);   /* empty list - cdr is nil */
}

/* caps */
void bifcap(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcntargs(ctx, 0, argc);
    tiocaps(ctx->bifxtio);  /* set output driver next-char-capitalized flag */
}

/* nocaps */
void bifnoc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcntargs(ctx, 0, argc);
    tionocaps(ctx->bifxtio);               /* set next-not-capitalized flag */
}

/* length */
void biflen(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    uchar   *p;
    runsdef  val;
    long     len;
    int      l;
    
    bifcntargs(ctx, 1, argc);
    switch(runtostyp(ctx->bifcxrun))
    {
    case DAT_SSTRING:
        p = (uchar *)runpopstr(ctx->bifcxrun);
        len = osrp2(p) - 2;
        break;

    case DAT_LIST:
        p = runpoplst(ctx->bifcxrun);
        l = osrp2(p) - 2;
        p += 2;
        
        /* count all elements in list */
        for (len = 0 ; l ; ++len)
        {
            int cursiz;
            
            /* get size of this element, and move past it */
            cursiz = datsiz(*p, p+1) + 1;
            l -= cursiz;
            p += cursiz;
        }
        break;

    default:
        runsig1(ctx->bifcxrun, ERR_INVTBIF, ERRTSTR, "length");
    }
    
    val.runsv.runsvnum = len;
    runpush(ctx->bifcxrun, DAT_NUMBER, &val);
}

/* find */
void biffnd(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char    *p1, *p2;
    int      len1, len2;
    int      outv;
    runsdef  val;
    int      typ;
    int      siz;
    
    bifcntargs(ctx, 2, argc);
    switch(runtostyp(ctx->bifcxrun))
    {
    case DAT_SSTRING:
        p1 = runpopstr(ctx->bifcxrun);
        len1 = osrp2(p1) - 2;
        p1 += 2;
        
        p2 = runpopstr(ctx->bifcxrun);
        len2 = osrp2(p2) - 2;
        p2 += 2;

        /* look for p2 within p1 */
        for (typ = DAT_NIL, outv = 1 ; len1 >= len2 ; ++p1, --len1, ++outv)
        {
            if (!memcmp(p1, p2, (size_t)len2))
            {
                typ = DAT_NUMBER;           /* use number in outv after all */
                break;                        /* that's it - we've found it */
            }
        }
        break;
        
    case DAT_LIST:
        p1 = (char *)runpoplst(ctx->bifcxrun);
        len1 = osrp2(p1) - 2;
        p1 += 2;

        /* get second item:  any old datatype */
        runpop(ctx->bifcxrun, &val);
        
        for (typ = DAT_NIL, outv = 1 ; len1 ; ++outv, p1 += siz, len1 -= siz)
        {
            siz = datsiz(*p1, p1 + 1) + 1;      /* get size of this element */
            if (val.runstyp != *p1) continue;          /* types don't match */
            
            switch(val.runstyp)
            {
            case DAT_NUMBER:
                if (val.runsv.runsvnum != osrp4(p1 + 1)) continue;
                break;
                
            case DAT_SSTRING:
            case DAT_LIST:
                if (osrp2(p1 + 1) != osrp2(val.runsv.runsvstr) ||
                    memcmp(p1 + 3, val.runsv.runsvstr + 2,
                           (size_t)(osrp2(p1 + 1) - 2)))
                    continue;
                break;
                
            case DAT_PROPNUM:
                if (osrp2(p1 + 1) != val.runsv.runsvprp) continue;
                break;
                
            case DAT_OBJECT:
            case DAT_FNADDR:
                if (osrp2(p1 + 1) != val.runsv.runsvobj) continue;
                break;
                
            default:
                break;
            }
            
            /* if we got here, it means we found a match */
            typ = DAT_NUMBER;                      /* use the value in outv */
            break;                            /* that's it - we've found it */
        }
        break;
        
    default:
        runsig1(ctx->bifcxrun, ERR_INVTBIF, ERRTSTR, "find");
    }
    
    /* push the value given by typ and outv */
    val.runsv.runsvnum = outv;
    runpush(ctx->bifcxrun, typ, &val);
}

/* setit - set current 'it' */
void bifsit(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    obj;
    int       typ;
    voccxdef *vcx = ctx->bifcxrun->runcxvoc;
    
    /* check for extended version that allows setting him/her */
    if (argc == 2)
    {
	if (runtostyp(ctx->bifcxrun) == DAT_NIL)
	{
	    rundisc(ctx->bifcxrun);                      /* discard the nil */
	    obj = MCMONINV;                           /* use invalid object */
	}
	else
	    obj = runpopobj(ctx->bifcxrun);               /* get the object */

	typ = runpopnum(ctx->bifcxrun);                     /* get the code */
	vcx->voccxthc = 0;                         /* clear the 'them' list */

	switch(typ)
	{
	case 0:                                                 /* set "it" */
	    vcx->voccxit = obj;
	    break;

	case 1:                                                /* set "him" */
	    vcx->voccxhim = obj;
	    break;

	case 2:                                                /* set "her" */
	    vcx->voccxher = obj;
	    break;
	}
	return;
    }

    /* "setit classic" has one argument only */
    bifcntargs(ctx, 1, argc);

    /* check to see if we're setting 'it' or 'them' */
    if (runtostyp(ctx->bifcxrun) == DAT_LIST)
    {
	uchar *lst;
	uint   siz;
	int    cnt;

	lst = runpoplst(ctx->bifcxrun);
	siz = osrp2(lst);
	lst += 2;
	siz -= 2;

	for (cnt = 0 ; siz ; )
	{
	    /* if this is an object, add to 'them' list (otherwise ignore) */
	    if (*lst == DAT_OBJECT)
		vcx->voccxthm[cnt++] = osrp2(lst+1);

	    lstadv(&lst, &siz);
	}
	vcx->voccxthc = cnt;
	vcx->voccxit = MCMONINV;
    }
    else
    {
	/* set 'it', and delete 'them' list */
	if (runtostyp(ctx->bifcxrun) == DAT_NIL)
	{
	    vcx->voccxit = MCMONINV;
	    rundisc(ctx->bifcxrun);
	}
	else
	    vcx->voccxit = runpopobj(ctx->bifcxrun);
	vcx->voccxthc = 0;
    }
}

/* randomize - seed random number generator */
void bifsrn(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcntargs(ctx, 0, argc);
    os_rand(&ctx->bifcxrnd);
    ctx->bifcxrndset = TRUE;
}

/* rand - get a random number */
void bifrnd(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    unsigned long result, max, randseed;
    int      tmp;
    runsdef  val;

    /* get argument - number giving upper bound of generated number */
    bifcntargs(ctx, 1, argc);
    bifchkarg(ctx, DAT_NUMBER);
    max = runpopnum(ctx->bifcxrun);

    /*
     *   If the random number generator has been seeded by a call to
     *   randomize(), use the new, improved random number generator.  If
     *   not, use the old random number generator to ensure that the same
     *   sequence of numbers is generated as always (to prevent breaking
     *   existing test scripts based on the old sequence). 
     */
    if (!ctx->bifcxrndset)
    {
	/* compute the next number in sequence, using old cheesy generator */
	randseed = ctx->bifcxrnd;
	randseed *= 1033;
	randseed += 5;
	tmp = randseed / 16384;
	randseed %= 16384;
	result = tmp / 7;

	/* adjust the result to be in the requested range */
	if ( max == 0 ) result = 0;
        else result = ( randseed % max ) + 1;
	
	/* save the new seed value, and return the value */
	ctx->bifcxrnd = randseed;
	val.runsv.runsvnum = result;
	runpush(ctx->bifcxrun, DAT_NUMBER, &val);
    }
    else
    {
#define BIF_RAND_M  ((ulong)2147483647)
#define BIF_RAND_Q  ((ulong)127773)
#define BIF_RAND_A  ((ulong)16807)
#define BIF_RAND_R  ((ulong)2836)

	long lo, hi, test;

	lo = ctx->bifcxrnd / BIF_RAND_Q;
	hi = ctx->bifcxrnd % BIF_RAND_Q;
	test = BIF_RAND_A*lo - BIF_RAND_R*hi;
	ctx->bifcxrnd = test;
	if (test > 0)
	    ctx->bifcxrnd = test;
	else
	    ctx->bifcxrnd = test + BIF_RAND_M;
	runpnum(ctx->bifcxrun, (((ulong)ctx->bifcxrnd) % max) + 1);
    }
}

/* askfile */
void bifask(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char *prompt;
    char  buf[OSFNMAX+2]; //###length
    char  pbuf[128];
    int   err;
    
    bifcntargs(ctx, 1, argc);
    prompt = runpopstr(ctx->bifcxrun);
    bifcstr(ctx, pbuf, (size_t)sizeof(pbuf), prompt);
    err = tioaskfile(ctx->bifcxtio, pbuf, buf + 2, (int)sizeof(buf) - 2);
    if (err)
        runpnil(ctx->bifcxrun);
    else
    {
        runsdef val;

        oswp2(buf, strlen(buf + 2) + 2);
        val.runsv.runsvstr = buf;
        runpush(ctx->bifcxrun, DAT_SSTRING, &val);
    }
}

/* setscore */
void bifssc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int s1, s2;

    /* optional new way - string argument */
    if (argc == 1 && runtostyp(ctx->bifcxrun) == DAT_SSTRING)
    {
        char  buf[80];
        char *p;
        
        p = runpopstr(ctx->bifcxrun);
        bifcstr(ctx, buf, (size_t)sizeof(buf), p);
        tiostrsc(ctx->bifcxtio, buf);
    }
    else
    {
        /* old way - two numeric arguments (displays: x/y) */
        bifcntargs(ctx, 2, argc);
        s1 = runpopnum(ctx->bifcxrun);
        s2 = runpopnum(ctx->bifcxrun);
        tioscore(ctx->bifcxtio, s1, s2);
    }
}

/* substr */
void bifsub(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char    *p;
    int      ofs;
    int      asklen;
    int      outlen;
    int      len;
    runsdef  val;

    bifcntargs(ctx, 3, argc);

    /* get the string argument */
    bifchkarg(ctx, DAT_SSTRING);
    p = runpopstr(ctx->bifcxrun);
    len = osrp2(p) - 2;
    p += 2;
    
    /* get the offset argument */
    bifchkarg(ctx, DAT_NUMBER);
    ofs = runpopnum(ctx->bifcxrun);
    if (ofs < 1) runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "substr");
    
    /* get the length argument */
    bifchkarg(ctx, DAT_NUMBER);
    asklen = runpopnum(ctx->bifcxrun);
    if (asklen < 0) runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "substr");

    --ofs;          /* convert offset to a zero bias (user provided 1-bias) */
    p += ofs;                           /* advance string pointer by offset */

    if (ofs >= len)
        outlen = 0;                         /* offset is past end of string */
    else if (asklen > len - ofs)
        outlen = len - ofs;                      /* just use rest of string */
    else
        outlen = asklen;                /* requested length can be provided */
    
    runpstr(ctx->bifcxrun, p, outlen, 3);
}

/* cvtstr - convert value to a string */
void bifcvs(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char *p;
    int   len;
    char  buf[30];
    
    bifcntargs(ctx, 1, argc);
    switch(runtostyp(ctx->bifcxrun))
    {
    case DAT_NIL:
        p = "nil";
        len = 3;
        (void)runpoplog(ctx->bifcxrun);
        break;
        
    case DAT_TRUE:
        p = "true";
        len = 4;
        (void)runpoplog(ctx->bifcxrun);
        break;
        
    case DAT_NUMBER:
        sprintf(buf, "%ld", runpopnum(ctx->bifcxrun));
        p = buf;
        len = strlen(buf);
        break;
    }
    
    runpstr(ctx->bifcxrun, p, len, 0);
}

/* cvtnum  - convert a value to a number */
void bifcvn(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    runsdef  val;
    char    *p;
    int      len;
    int      typ;
    long     acc;
    int      neg;
    
    bifcntargs(ctx, 1, argc);
    p = runpopstr(ctx->bifcxrun);
    len = osrp2(p) - 2;
    p += 2;
    
    if (len == 3 && !memcmp(p, "nil", (size_t)3))
        typ = DAT_NIL;
    else if (len == 4 && !memcmp(p, "true", (size_t)4))
        typ = DAT_TRUE;
    else
    {
        typ = DAT_NUMBER;
        while (*p && isspace(*p)) ++p;
        if (*p == '-')
        {
            neg = TRUE;
            for (++p ; *p && isspace(*p) ; ++p);
        }
        else neg = FALSE;

        /* accumulate the number digit by digit */
        for (acc = 0 ; len && isdigit(*p) ; ++p, --len)
            acc = (acc << 3) + (acc << 1) + ((*p) - '0');

        if (neg) acc = -acc;
        val.runsv.runsvnum = acc;
    }
    
    runpush(ctx->bifcxrun, typ, &val);
}

/* general string conversion function */
static void bifcvtstr(ctx, cvtfn, argc)
bifcxdef  *ctx;
void     (*cvtfn)(/*_ char *str, int len _*/);
int        argc;
{
    char    *p;
    int      len;
    runsdef  val;
    runsdef  stkval;
    
    bifcntargs(ctx, 1, argc);
    bifchkarg(ctx, DAT_SSTRING);
    
    p = runpopstr(ctx->bifcxrun);
    stkval.runstyp = DAT_SSTRING;
    stkval.runsv.runsvstr = p;
    len = osrp2(p);
    
    /* allocate space in heap for the string and convert */
    runhres1(ctx->bifcxrun, len, 1, &stkval);
    p = stkval.runsv.runsvstr;
    memcpy(ctx->bifcxrun->runcxhp, p, (size_t)len);
    (*cvtfn)(ctx->bifcxrun->runcxhp + 2, len - 2);
    
    val.runsv.runsvstr = (char *)ctx->bifcxrun->runcxhp;
    val.runstyp = DAT_SSTRING;
    ctx->bifcxrun->runcxhp += len;
    runrepush(ctx->bifcxrun, &val);
}

/* routine to convert a counted-length string to uppercase */
static void bifstrupr(str, len)
char *str;
int   len;
{
    for ( ; len ; --len, ++str)
    {
        if (*str == '\\' && len > 1)
            --len, ++str;
        else if (islower(*str))
            *str = toupper(*str);
    }
}

/* upper */
void bifupr(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcvtstr(ctx, bifstrupr, argc);
}

/* convert a counted-length string to lowercase */
static void bifstrlwr(str, len)
char *str;
int   len;
{
    for ( ; len ; --len, ++str)
    {
        if (*str == '\\' && len > 1)
            --len, ++str;
        else if (isupper(*str))
            *str = tolower(*str);
    }
}

/* lower */
void biflwr(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcvtstr(ctx, bifstrlwr, argc);
}

/* internal check to determine if object is of a class */
int bifinh(voc, v, cls)
voccxdef *voc;
vocidef  *v;
objnum    cls;
{
    int     i;
    objnum *sc;

    if (!v) return(FALSE);
    for (i = v->vocinsc, sc = v->vocisc ; i ; ++sc, --i)
    {
        if (*sc == cls
            || bifinh(voc, vocinh(voc, *sc), cls))
            return(TRUE);
    }
    return(FALSE);
}

/* isclass(obj, cls) */
void bifisc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    obj;
    objnum    cls;
    runsdef   val;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    
    bifcntargs(ctx, 2, argc);

    /* if checking for nil, return nil */
    if (runtostyp(ctx->bifcxrun) == DAT_NIL)
    {
	rundisc(ctx->bifcxrun);
	rundisc(ctx->bifcxrun);
	runpnil(ctx->bifcxrun);
	return;
    }

    /* get the arguments:  object, class */
    obj = runpopobj(ctx->bifcxrun);
    cls = runpopobj(ctx->bifcxrun);

    /* return the result from bifinh() */
    runpush(ctx->bifcxrun, runclog(bifinh(voc, vocinh(voc, obj), cls)), &val);
}

/* firstsc(obj) - get the first superclass of an object */
void bif1sc(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum obj;
    objnum sc;

    bifcntargs(ctx, 1, argc);
    obj = runpopobj(ctx->bifcxrun);
    sc = objget1sc(ctx->bifcxrun->runcxmem, obj);
    runpobj(ctx->bifcxrun, sc);
}

/* firstobj */
void biffob(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    vocidef ***vpg;
    vocidef  **v;
    objnum     obj;
    int        i;
    int        j;
    objnum     cls;
    voccxdef  *voc = ctx->bifcxrun->runcxvoc;

    /* get class to search for, if one is specified */
    if (argc == 0)
        cls = MCMONINV;
    else if (argc == 1)
        cls = runpopobj(ctx->bifcxrun);
    else
        runsig(ctx->bifcxrun, ERR_BIFARGC);
    
    for (vpg = voc->voccxinh, i = 0 ; i < VOCINHMAX ; ++vpg, ++i)
    {
        if (!*vpg) continue;
        for (v = *vpg, obj = (i << 8), j = 0 ; j < 256 ; ++v, ++obj, ++j)
        {
            if (!*v || ((*v)->vociflg & VOCIFCLASS)
                || (cls != MCMONINV && !bifinh(voc, *v, cls)))
                continue;
            
            /* this is an object we can use - push it */
            runpobj(ctx->bifcxrun, obj);
            return;
        }
    }
    
    /* no objects found at all - return nil */
    runpnil(ctx->bifcxrun);
}

/* nextobj */
void bifnob(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum     prv;
    vocidef ***vpg;
    vocidef  **v;
    objnum     obj;
    int        i;
    int        j;
    objnum     cls;
    voccxdef  *voc = ctx->bifcxrun->runcxvoc;

    /* get last position in search */
    prv = runpopobj(ctx->bifcxrun);
    
    /* get class to search for, if one is specified */
    if (argc == 1)
        cls = MCMONINV;
    else if (argc == 2)
        cls = runpopobj(ctx->bifcxrun);
    else
        runsig(ctx->bifcxrun, ERR_BIFARGC);
    
    /* start at previous object plus 1 */
    i = (prv >> 8);
    vpg = voc->voccxinh + i;
    j = (prv & 255);
    obj = prv;
    v = (*vpg) + j;
    
    for (;;)
    {
        ++j;
        ++obj;
        ++v;
        if (j == 256)
        {
            j = 0;
            ++i;
            ++vpg;
            if (!*vpg)
            {
                obj += 255;
                j += 255;
                continue;
            }
            v = (*vpg);
        }
        if (i >= VOCINHMAX)
        {
            runpnil(ctx->bifcxrun);
            return;
        }
        
        if (!*v || ((*v)->vociflg & VOCIFCLASS)
            || (cls != MCMONINV && !bifinh(voc, *v, cls)))
            continue;
            
        /* this is an object we can use - push it */
        runpobj(ctx->bifcxrun, obj);
        return;
    }
}

/* setversion */
void bifsvn(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    VARUSED(str);
    
    bifcntargs(ctx, 1, argc);
    (void)runpopstr(ctx->bifcxrun);
    /* note - setversion doesn't do anything in v2; uses timestamp instead */
}

/* getarg */
void bifarg(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int argnum;
    
    bifcntargs(ctx, 1, argc);
    bifchkarg(ctx, DAT_NUMBER);
    
    /* get and verify argument number */
    argnum = runpopnum(ctx->bifcxrun);
    if (argnum < 1) runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "getarg");

    runrepush(ctx->bifcxrun, ctx->bifcxrun->runcxbp - argnum - 1);
}

/* datatype */
void biftyp(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    runsdef val;
    
    bifcntargs(ctx, 1, argc);
    
    /* get whatever it is, and push the type */
    runpop(ctx->bifcxrun, &val);
    val.runsv.runsvnum = val.runstyp;          /* new value is the datatype */
    runpush(ctx->bifcxrun, DAT_NUMBER, &val);
}

/* undo */
void bifund(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objucxdef *ucx = ctx->bifcxrun->runcxvoc->voccxundo;
    mcmcxdef  *mcx = ctx->bifcxrun->runcxmem;
    errcxdef  *ec  = ctx->bifcxerr;
    int        err;
    int        undone;
    runsdef    val;

    bifcntargs(ctx, 0, argc);                               /* no arguments */

    ERRBEGIN(ec)
        if (ucx)
        {
            objundo(mcx, ucx);         /* try to undo to previous savepoint */
            undone = TRUE;                       /* looks like we succeeded */
        }
        else
            undone = FALSE;                  /* no undo context; can't undo */
    ERRCATCH(ec, err)
        if (err == ERR_NOUNDO || err == ERR_ICUNDO)
            undone = FALSE;
        else
            errrse(ec);            /* don't know how to handle other errors */
    ERREND(ec)

    /* return a value indicating whether the undo operation succeeded */
    runpush(ctx->bifcxrun, runclog(undone), &val);

    /* note that the rest of the command line is to be ignored */
    ctx->bifcxrun->runcxvoc->voccxflg |= VOCCXFCLEAR;
}

/* defined */
void bifdef(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    prpnum  prpn;
    objnum  objn;
    uint    ofs;
    runsdef val;

    bifcntargs(ctx, 2, argc);
    
    /* get offset of obj.prop */
    objn = runpopobj(ctx->bifcxrun);
    prpn = runpopprp(ctx->bifcxrun);
    ofs = objgetap(ctx->bifcxrun->runcxmem, objn, prpn, (objnum *)0, FALSE);
    
    /* if the property is defined, return true, else return nil */
    runpush(ctx->bifcxrun, runclog(ofs != 0), &val);
}

/* proptype */
void bifpty(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    prpnum   prpn;
    objnum   objn;
    uint     ofs;
    runsdef  val;
    objnum   orn;
    objdef  *objptr;
    prpdef  *propptr;

    bifcntargs(ctx, 2, argc);
    
    /* get offset of obj.prop */
    objn = runpopobj(ctx->bifcxrun);
    prpn = runpopprp(ctx->bifcxrun);
    ofs = objgetap(ctx->bifcxrun->runcxmem, objn, prpn, &orn, FALSE);
    
    if (ofs)
    {
        /* lock the object, read the prpdef, and unlock it */
        objptr = (objdef *)mcmlck(ctx->bifcxrun->runcxmem, (mcmon)orn);
        propptr = objofsp(objptr, ofs);
        val.runsv.runsvnum = prptype(propptr);
        mcmunlck(ctx->bifcxrun->runcxmem, (mcmon)orn);
    }
    else
    {
        /* property is not defined by object - indicate that type is nil */
        val.runsv.runsvnum = DAT_NIL;
    }
    
    /* special case:  DAT_DEMAND -> DAT_LIST (for contents properties) */
    if (val.runsv.runsvnum == DAT_DEMAND)
        val.runsv.runsvnum = DAT_LIST;

    /* return the property type as a number */
    runpush(ctx->bifcxrun, DAT_NUMBER, &val);
}

/* outhide */
void bifoph(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    runsdef val;
    int     hidden, output_occurred;

    bifcntargs(ctx, 1, argc);
    outstat(&hidden, &output_occurred);
    if (runtostyp(ctx->bifcxrun) == DAT_TRUE)
    {
	/* throw away the flag */
	rundisc(ctx->bifcxrun);
	
	/* figure out appropriate return value */
	if (!hidden)
	    val.runsv.runsvnum = 0;
	else if (!output_occurred)
	    val.runsv.runsvnum = 1;
	else
	    val.runsv.runsvnum = 2;
	runpush(ctx->bifcxrun, DAT_NUMBER, &val);

	/* actually hide the output, resetting count flag */
	outhide();
    }
    else if (runtostyp(ctx->bifcxrun) == DAT_NIL)
    {
	/* throw away the flag */
	rundisc(ctx->bifcxrun);

	/* show output, returning status */
	runpush(ctx->bifcxrun, runclog(outshow()), &val);
    }
    else if (runtostyp(ctx->bifcxrun) == DAT_NUMBER)
    {
	int n = runpopnum(ctx->bifcxrun);

	if (n == 0)
	{
	    /* output was not hidden - show output and return status */
	    runpush(ctx->bifcxrun, runclog(outshow()), &val);
	}
	else if (n == 1)
	{
	    /*
	     *   Output was hidden, but no output had occurred yet.
	     *   Leave output hidden and return whether any output has
	     *   occurred.
	     */
	    runpush(ctx->bifcxrun, runclog(output_occurred), &val);
	}
	else if (n == 2)
	{
	    /*
	     *   Output was hidden, and output had already occurred.  If
	     *   more output has occurred, return true, else return nil.
	     *   In either case, set the output_occurred flag back to
	     *   true, since it was true before the outhide(true).  
	     */
	    runpush(ctx->bifcxrun, runclog(output_occurred), &val);
	    outsethidden();
	}
	else
	    errsig1(ctx->bifcxerr, ERR_INVVBIF, ERRTSTR, "outhide");
    }
    else
	errsig(ctx->bifcxerr, ERR_REQNUM);
}

/* put a numeric value in a list */
static uchar *bifputnum(lstp, val)
uchar *lstp;
uint   val;
{
    *lstp++ = DAT_NUMBER;
    oswp4(lstp, (long)val);
    return(lstp + 4);
}

/* gettime */
void biftim(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    time_t     timer;
    struct tm *tblock;
    uchar      ret[80];
    uchar     *p;
    runsdef    val;
    
    bifcntargs(ctx, 0, argc);
    tzset();
    timer = time(NULL);
    tblock = localtime(&timer);
    
    /* adjust values for return format */
    tblock->tm_year += 1900;
    tblock->tm_mon++;
    tblock->tm_wday++;
    tblock->tm_yday++;
    
    /* build return list value */
    oswp2(ret, 47);
    p = ret + 2;
    p = bifputnum(p, tblock->tm_year);
    p = bifputnum(p, tblock->tm_mon);
    p = bifputnum(p, tblock->tm_mday);
    p = bifputnum(p, tblock->tm_wday);
    p = bifputnum(p, tblock->tm_yday);
    p = bifputnum(p, tblock->tm_hour);
    p = bifputnum(p, tblock->tm_min);
    p = bifputnum(p, tblock->tm_sec);
    *p++ = DAT_NUMBER;
    oswp4(p, (long)timer);

    val.runstyp = DAT_LIST;
    val.runsv.runsvstr = (char*)ret; //###cast
    runpush(ctx->bifcxrun, DAT_LIST, &val);
}

/* getfuse */
void bifgfu(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    vocddef  *daem;
    objnum    func;
    runsdef   val;
    runcxdef *rcx = ctx->bifcxrun;
    int       slots;
    prpnum    prop;
    voccxdef *vcx = ctx->bifcxrun->runcxvoc;

    bifcntargs(ctx, 2, argc);
 
    if (runtostyp(rcx) == DAT_FNADDR)
    {
	/* check on a setfuse()-style fuse: get fnaddr, parm */
	func = runpopfn(rcx);
	runpop(rcx, &val);

	for (slots = vcx->voccxfuc, daem = vcx->voccxfus ;
	     slots ; ++daem, --slots)
	{
	    if (daem->vocdfn == func
		&& daem->vocdarg.runstyp == val.runstyp
		&& !memcmp(&val.runsv, &daem->vocdarg.runsv,
			   (size_t)datsiz(val.runstyp, &val.runsv)))
		goto ret_num;
	}
    }
    else
    {
	/* check on a notify()-style fuse: get object, &message */
	func = runpopobj(rcx);
	prop = runpopprp(rcx);

	for (slots = vcx->voccxalc, daem = vcx->voccxalm ;
	     slots ; ++daem, --slots)
	{
	    if (daem->vocdfn == func && daem->vocdprp == prop)
		goto ret_num;
	}
    }
    
    /* didn't find anything - return nil */
    runpush(rcx, DAT_NIL, &val);
    return;
    
ret_num:
    /* return current daem->vocdtim */
    runpnum(rcx, (long)daem->vocdtim);
    return;
}

/* runfuses */
void bifruf(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int     ret;
    runsdef val;

    bifcntargs(ctx, 0, argc);
    ret = exefuse(ctx->bifcxrun->runcxvoc, TRUE);
    runpush(ctx->bifcxrun, runclog(ret), &val);
}

/* rundaemons */
void bifrud(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcntargs(ctx, 0, argc);
    exedaem(ctx->bifcxrun->runcxvoc);
}

/* intersect */
void bifsct(bifctx, argc)
bifcxdef *bifctx;
int       argc;
{
    runcxdef *ctx = bifctx->bifcxrun;
    uchar    *l1;
    uchar    *l2;
    uchar    *l3;
    uint      siz1;
    uint      siz2;
    uint      siz3;
    uchar    *p;
    uint      l;
    uint      dsz1;
    uint      dsz2;
    runsdef   val;
    runsdef   stk1, stk2;
    
    bifcntargs(bifctx, 2, argc);
    l1 = runpoplst(ctx);
    siz1 = osrp2(l1);
    l2 = runpoplst(ctx);
    siz2 = osrp2(l2);

    /* make sure the first list is smaller - if not, switch them */
    if (siz1 > siz2)
	l3 = l1, l1 = l2, l2 = l3, siz3 = siz1, siz1 = siz2, siz2 = siz3;
    
    /* size of result is at most size of smaller list (which is now siz1) */
    stk1.runstyp = stk2.runstyp = DAT_LIST;
    stk1.runsv.runsvstr = (char*)l1; //###cast
    stk2.runsv.runsvstr = (char*)l2; //###cast
    runhres2(ctx, siz1, 2, &stk1, &stk2);
    l1 = (uchar*)stk1.runsv.runsvstr; //###cast
    l2 = (uchar*)stk2.runsv.runsvstr; //###cast
    l3 = ctx->runcxhp + 2;

    /* go through list1, and copy each element that is found in list2 */
    for (l1 += 2, l2 += 2, siz1 -= 2, siz2 -= 2 ; siz1 ; lstadv(&l1, &siz1))
    {
	dsz1 = datsiz(*l1, l1 + 1) + 1;
	for (l = siz2, p = l2 ; l ; lstadv(&p, &l))
	{
	    dsz2 = datsiz(*p, p + 1) + 1;
#ifndef AMIGA
	    if (dsz1 == dsz2 && !memcmp(l1, p, (size_t)dsz1))
#else /* AMIGA */
	    if (!memcmp(l1, p, (size_t)dsz1) && (dsz1 == dsz2) )
#endif /* AMIGA */
	    {
		memcpy(l3, p, (size_t)dsz1);
		l3 += dsz1;
		break;
	    }
	}
    }
    
    /* set up return value, take it out of the heap, and push value */
    val.runsv.runsvstr = (char*)ctx->runcxhp; //###cast
    val.runstyp = DAT_LIST;
    oswp2(ctx->runcxhp, (uint)(l3 - ctx->runcxhp));
    ctx->runcxhp = l3;
    runrepush(ctx, &val);
}

/* inputkey */
void bifink(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    uchar c;
    uchar str[3];
    int   l;
    
    bifcntargs(ctx, 0, argc);
    tioflushn(ctx->bifcxtio, 0);
    c = os_getc();
    if (c)
    {
	str[0] = c;
	str[1] = '\0';
	l = 1;
    }
    else
    {
	str[0] = c;
	str[1] = os_getc();
	str[2] = '\0';
	l = 2;
    }

    /* reset the [more] counter */
    outreset();

    /* return the string */
    runpstr(ctx->bifcxrun, str, l, 0);
}

/* get direct/indirect object word list */
void bifwrd(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int       ob;
    vocoldef *v;
    char      buf[128]; //###char
    char     *dst; //###char
    char     *src; //###char
    uint      len;
    runsdef   val;
    
    bifcntargs(ctx, 1, argc);

    /* figure out what word list to get */
    ob = runpopnum(ctx->bifcxrun);
    switch(ob)
    {
    case 1:
	v = ctx->bifcxrun->runcxvoc->voccxdobj;
	break;

    case 2:
	v = ctx->bifcxrun->runcxvoc->voccxiobj;
	break;

    default:
	runpnil(ctx->bifcxrun);
	return;
    }

    /* now build a list of strings from the words, if there are any */
    if (v && v->vocolfst && v->vocollst)
    {
	for (dst = buf + 2, src = v->vocolfst ; src <= v->vocollst ;
	     src += len+1)
	{
	    *dst++ = DAT_SSTRING;
	    len = strlen(src);
	    oswp2(dst, len + 2);
	    strcpy(dst + 2, src);
	    dst += len + 2;
	}
    }
    else
	dst = buf + 2;

    /* finish setting up the list length and return it */
    len = dst - buf;
    oswp2(buf, len);
    val.runsv.runsvstr = buf;
    val.runstyp = DAT_LIST;
    runpush(ctx->bifcxrun, DAT_LIST, &val);
}

/* add a vocabulary word to an object */
void bifadw(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char     *wrd;
    objnum    objn;
    prpnum    prpn;
    vocidef  *voci;
    int       classflg;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;

    bifcntargs(ctx, 3, argc);

    /* get the arguments */
    objn = runpopobj(ctx->bifcxrun);
    prpn = runpopprp(ctx->bifcxrun);
    wrd = runpopstr(ctx->bifcxrun);

    /* make sure the property is a valid part of speech property */
    if (!prpisvoc(prpn))
	runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "addword");

    /* get the vocidef for the object, and see if it's a class object */
    voci = vocinh(voc, objn);

    classflg = VOCFNEW;
    if (voci->vociflg & VOCIFCLASS) classflg |= VOCFCLASS;

    /* add the word */
    vocadd(voc, prpn, objn, classflg, wrd);

    /* generate undo for the operation */
    vocdusave_addwrd(voc, objn, prpn, classflg, wrd);
}

/* delete a vocabulary word from an object */
void bifdlw(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char     *wrd;
    objnum    objn;
    prpnum    prpn;
    vocidef  *voci;
    int       classflg;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;

    bifcntargs(ctx, 3, argc);

    /* get the arguments */
    objn = runpopobj(ctx->bifcxrun);
    prpn = runpopprp(ctx->bifcxrun);
    wrd = runpopstr(ctx->bifcxrun);

    /* make sure the property is a valid part of speech property */
    if (!prpisvoc(prpn))
	runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "delword");

    /* delete the word */
    vocdel1(voc, objn, wrd, prpn, FALSE, FALSE, TRUE);
}

/* callback context for word list builder */
struct bifgtw_cb_ctx
{
    uchar *p;
    int    typ;
};

/* callback for word list builder */
static void bifgtw_cb(ctx, voc, vocw)
struct bifgtw_cb_ctx *ctx;
vocdef               *voc;
vocwdef              *vocw;
{
    /* ignore deleted objects */
    if (vocw->vocwflg & VOCFDEL)
	return;

    /* ignore objects of the inappropriate type */
    if (vocw->vocwtyp != ctx->typ)
	return;
    
    /* the datatype is string */
    *ctx->p = DAT_SSTRING;

    /* copy the first word */
    memcpy(ctx->p + 3, voc->voctxt, (size_t)voc->voclen);

    /* if there are two words, add a space and the second word */
    if (voc->vocln2)
    {
	*(ctx->p + 3 + voc->voclen) = ' ';
	memcpy(ctx->p + 4 + voc->voclen, voc->voctxt + voc->voclen,
	       (size_t)voc->vocln2);
	oswp2(ctx->p + 1, voc->voclen + voc->vocln2 + 3);
	ctx->p += voc->voclen + voc->vocln2 + 4;
    }
    else
    {
	oswp2(ctx->p + 1, voc->voclen+2);
	ctx->p += voc->voclen + 3;
    }
}

/* get the list of words for an object for a particular part of speech */
void bifgtw(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum    objn;
    prpnum    prpn;
    vocidef  *voci;
    int       classflg;
    voccxdef *voc = ctx->bifcxrun->runcxvoc;
    int       cnt;
    int       siz;
    runsdef   val;
    struct bifgtw_cb_ctx fnctx;

    bifcntargs(ctx, 2, argc);

    /* get the arguments */
    objn = runpopobj(ctx->bifcxrun);
    prpn = runpopprp(ctx->bifcxrun);
    
    /* make sure the property is a valid part of speech property */
    if (!prpisvoc(prpn))
	runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "delword");

    /* get the size of the list we'll need to build */
    voc_count(voc, objn, prpn, &cnt, &siz);

    /*
     *   calculate how much space it will take to make a list out of all
     *   these words: 2 bytes for the list length header; plus, for each
     *   entry, 1 byte for the type header, 2 bytes for the string size
     *   header, and possibly one extra byte for the two-word separator --
     *   a total of 4 bytes extra per word.  
     */
    siz += 2 + 4*cnt;

    /* reserve the space */
    runhres(ctx->bifcxrun, siz, 0);

    /* set up our callback context, and build the list */
    fnctx.p = ctx->bifcxrun->runcxhp + 2;
    fnctx.typ = prpn;
    voc_iterate(voc, objn, bifgtw_cb, &fnctx);

    /* set up the return value */
    val.runstyp = DAT_LIST;
    val.runsv.runsvstr = (char*)ctx->bifcxrun->runcxhp; //###cast

    /* write the list length, and advance past the space we used */
    oswp2(ctx->bifcxrun->runcxhp, fnctx.p - ctx->bifcxrun->runcxhp);
    ctx->bifcxrun->runcxhp = fnctx.p;

    /* return the list */
    runrepush(ctx->bifcxrun, &val);
}

/* verbinfo service routine - add an object to the output list */
static uchar *bifvin_putprpn(p, prpn)
uchar  *p;
prpnum  prpn;
{
    *p++ = DAT_PROPNUM;
    oswp2(p, prpn);
    return p + 2;
}

/* verbinfo */
void bifvin(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    objnum  verb;
    objnum  prep;
    uint    tplofs;
    uchar   tplbuf[VOCTPL2SIZ];
    int     newstyle;

    /* get the verb */
    verb = runpopobj(ctx->bifcxrun);
    
    /* check for the presence of a preposition */
    if (argc == 1)
    {
	/* no preposition */
	prep = MCMONINV;
    }
    else
    {
	/* the second argument is the preposition */
	bifcntargs(ctx, 2, argc);
	prep = runpopobj(ctx->bifcxrun);
    }

    /* look up the template */
    if (voctplfnd(ctx->bifcxrun->runcxvoc, verb, prep, tplbuf, &newstyle))
    {
	prpnum   prp_do, prp_verdo, prp_io, prp_verio;
	int      flg_dis_do;
	ushort   siz;
	uchar   *p;
	runsdef  val;

	/* get the information from the template */
	prp_do     = voctpldo(tplbuf);
	prp_verdo  = voctplvd(tplbuf);
	prp_io     = voctplio(tplbuf);
	prp_verio  = voctplvi(tplbuf);
	flg_dis_do = (voctplflg(tplbuf) & VOCTPLFLG_DOBJ_FIRST) != 0;

	/*
	 *   figure space for the return value: if there's a prep, three
	 *   property pointers plus a boolean, otherwise just two property
	 *   pointers 
	 */
	siz = 2 + 2*(2+1);
	if (prep != MCMONINV)
	    siz += (2+1) + 1;

	/* reserve the space */
	runhres(ctx->bifcxrun, siz, 0);

	/* build the output list */
	p = ctx->bifcxrun->runcxhp;
	oswp2(p, siz);
	p += 2;

	p = bifvin_putprpn(p, prp_verdo);
	if (prep == MCMONINV)
	{
	    p = bifvin_putprpn(p, prp_do);
	}
	else
	{
	    p = bifvin_putprpn(p, prp_verio);
	    p = bifvin_putprpn(p, prp_io);
	    *p++ = runclog(flg_dis_do);
	}

	/* build the return value */
	val.runstyp = DAT_LIST;
	val.runsv.runsvstr = (char*)ctx->bifcxrun->runcxhp; //###cast

	/* consume the space */
	ctx->bifcxrun->runcxhp += siz;

	/* return the list */
	runrepush(ctx->bifcxrun, &val);
    }
    else
    {
	/* no template for this verb - return nil */
	runpnil(ctx->bifcxrun);
    }
}


/* clearscreen */
void bifcls(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    bifcntargs(ctx, 0, argc);
    oscls();
}

/*
 *   File operations 
 */

/* fopen(file, mode) */
void biffopen(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    char      fname[OSFNMAX];
    char     *p;
    char     *mode;
    int       modelen;
    int       fnum;
    osfildef *fp;
    
    bifcntargs(ctx, 2, argc);

    /* get the filename */
    p = runpopstr(ctx->bifcxrun);
    bifcstr(ctx, fname, (size_t)sizeof(fname), p);

    /* get the mode string */
    mode = runpopstr(ctx->bifcxrun);
    modelen = osrp2(mode) - 2;
    mode += 2;
    if (modelen < 1)
	goto bad_mode;

    /* allocate a filenum for the file */
    for (fnum = 0 ; fnum < BIFFILMAX ; ++fnum)
    {
	if (ctx->bifcxfile[fnum] == 0)
	    break;
    }
    if (fnum == BIFFILMAX)
    {
	/* return nil to indicate failure */
	runpnil(ctx->bifcxrun);
	return;
    }

    /* try opening the file */
    switch(mode[0])
    {
    case 'w':
    case 'W':
	if (modelen > 1)
	{
	    if (modelen > 2 || mode[1] != '+') goto bad_mode;
	    fp = osfoprwtb(fname);
	}
	else
	    fp = osfopwb(fname);
	break;

    case 'r':
    case 'R':
	if (modelen > 1)
	{
	    if (modelen > 2 || mode[1] != '+') goto bad_mode;
	    fp = osfoprwb(fname);
	}
	else
	    fp = osfoprb(fname);
	break;

    default:
	goto bad_mode;
    }

    /* if we couldn't open it, return nil */
    if (!fp)
    {
	runpnil(ctx->bifcxrun);
	return;
    }

    /* take the descriptor slot, and return the file number */
    ctx->bifcxfile[fnum] = fp;
    runpnum(ctx->bifcxrun, (long)fnum);
    return;


    /* come here on a mode error */
bad_mode:
    runsig1(ctx->bifcxrun, ERR_INVVBIF, ERRTSTR, "fopen");
}
	      
/* service routine for file routines - get and validate a file number */
static osfildef *bif_get_file(ctx, fnump)
bifcxdef *ctx;
int      *fnump;
{
    long fnum;

    /* get the file number and make sure it's valid */
    fnum = runpopnum(ctx->bifcxrun);
    if (fnum < 0 || fnum > BIFFILMAX || ctx->bifcxfile[fnum] == 0)
	runsig(ctx->bifcxrun, ERR_BADFILE);

    /* put the validated file number, if the caller wants it */
    if (fnump) *fnump = (int)fnum;

    /* return the file array pointer */
    return ctx->bifcxfile[fnum];
}

void biffclose(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int       fnum;
    osfildef *fp;

    /* get the file number */
    bifcntargs(ctx, 1, argc);
    fp = bif_get_file(ctx, &fnum);

    /* close the file and release the slot */
    osfcls(fp);
    ctx->bifcxfile[fnum] = 0;
}
	      
void bifftell(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    osfildef *fp;

    /* get the file number */
    bifcntargs(ctx, 1, argc);
    fp = bif_get_file(ctx, (int *)0);

    /* return the seek position */
    runpnum(ctx->bifcxrun, osfpos(fp)); //###indep
}
	      
void biffseek(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    osfildef *fp;
    long      pos;

    /* get the file pointer */
    bifcntargs(ctx, 2, argc);
    fp = bif_get_file(ctx, (int *)0);

    /* get the seek position, and seek there */
    pos = runpopnum(ctx->bifcxrun);
    osfseek(fp, pos, OSFSK_SET); //###indep
}
	      
void biffseekeof(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    osfildef *fp;

    /* get the file pointer */
    bifcntargs(ctx, 1, argc);
    fp = bif_get_file(ctx, (int *)0);

    /* seek to the end */
    osfseek(fp, 0L, OSFSK_END); //###indep
}
	      
void biffwrite(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    osfildef *fp;
    char      typ;
    char      buf[32];
    runsdef   val;
    
    /* get the file */
    bifcntargs(ctx, 2, argc);
    fp = bif_get_file(ctx, (int *)0);

    /* put a byte indicating the type */
    runpop(ctx->bifcxrun, &val);
    typ = val.runstyp;
    if (osfwb(fp, &typ, 1))
	goto ret_error;

    /* see what type of data we want to put */
    switch(typ)
    {
    case DAT_NUMBER:
	oswp4(buf, val.runsv.runsvnum);
	if (osfwb(fp, buf, 4))
	    goto ret_error;
	break;

    case DAT_SSTRING:
	/* write the string, including the length prefix */
	if (osfwb(fp, val.runsv.runsvstr, osrp2(val.runsv.runsvstr)))
	    goto ret_error;
	break;
	
    case DAT_TRUE:
	/* all we need for this is the type prefix */
	break;
	
    default:
	/* other types are not acceptable */
	runsig1(ctx->bifcxrun, ERR_INVTBIF, ERRTSTR, "fwrite");
    }

    /* success */
    runpnil(ctx->bifcxrun);
    return;

ret_error:
    val.runstyp = DAT_TRUE;
    runpush(ctx->bifcxrun, DAT_TRUE, &val);
}
	      
void biffread(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    osfildef *fp;
    char      typ;
    char      buf[32];
    runsdef   val;
    ushort    len;

    /* get the file pointer */
    bifcntargs(ctx, 1, argc);
    fp = bif_get_file(ctx, (int *)0);

    /* read the type byte */
    if (osfrb(fp, &typ, 1))
	goto ret_error;

    /* read the data according to the type */
    switch(typ)
    {
    case DAT_NUMBER:
	if (osfrb(fp, buf, 4))
	    goto ret_error;
	runpnum(ctx->bifcxrun, osrp4(buf));
	break;
	
    case DAT_SSTRING:
	/* get the size */
	if (osfrb(fp, buf, 2))
	    goto ret_error;
	len = osrp2(buf);

	/* reserve space */
	runhres(ctx->bifcxrun, len, 0);

	/* read the string into the reserved space */
	if (osfrb(fp, ctx->bifcxrun->runcxhp + 2, len - 2))
	    goto ret_error;

	/* set up the string */
	oswp2(ctx->bifcxrun->runcxhp, len);
	val.runstyp = DAT_SSTRING;
	val.runsv.runsvstr = (char*)ctx->bifcxrun->runcxhp; //###cast

	/* consume the space */
	ctx->bifcxrun->runcxhp += len;

	/* push the value */
	runrepush(ctx->bifcxrun, &val);
	break;
	
    case DAT_TRUE:
	val.runstyp = DAT_TRUE;
	runpush(ctx->bifcxrun, DAT_TRUE, &val);
	break;

    default:
	goto ret_error;
    }

    /* success - we've already pushed the return value */
    return;

ret_error:
    runpnil(ctx->bifcxrun);
}

void bifcapture(ctx, argc)
bifcxdef *ctx;
int       argc;
{
    int       flag;
    mcmcxdef *mcx = ctx->bifcxrun->runcxmem;
    mcmon     obj;
    uint      siz;
    uint      ofs;
    uchar     *p; //###uchar
    runsdef   val;

    /* get the capture on/off flag */
    bifcntargs(ctx, 1, argc);
    switch(runtostyp(ctx->bifcxrun))
    {
    case DAT_TRUE:
	/* turn on capturing */
	tiocapture(ctx->bifcxtio, mcx, TRUE);

	/*
	 *   The return value is a status code used to restore the
	 *   original status on the bracketing call to turn off output.
	 *   The only status necessary is the current output size. 
	 */
	siz = tiocapturesize(ctx->bifcxtio);
	runpnum(ctx->bifcxrun, (long)siz);
	break;

    case DAT_NUMBER:
	/* get the original offset */
	ofs = runpopnum(ctx->bifcxrun);

	/* get the capture object and size */
	obj = tiogetcapture(ctx->bifcxtio);
	siz = tiocapturesize(ctx->bifcxtio);
	if (obj == MCMONINV)
	{
	    runpnil(ctx->bifcxrun);
	    return;
	}

	/* turn off capturing and reset the buffer on the outermost call */
	if (ofs == 0)
	{
	    tiocapture(ctx->bifcxtio, mcx, FALSE);
	    tioclrcapture(ctx->bifcxtio);
	}

	/* lock the object */
	p = mcmlck(mcx, obj);

	/* include only the part that happened after the matching call */
	p += ofs;
	siz = (ofs > siz) ? 0 : siz - ofs;

	ERRBEGIN(ctx->bifcxerr)

	/* push the string onto the stack */
	runpstr(ctx->bifcxrun, p, siz, 0);
	
        ERRCLEAN(ctx->bifcxerr)
	    /* done with the object - unlock it */
	    mcmunlck(mcx, obj);
        ERRENDCLN(ctx->bifcxerr)

	/* done with the object - unlock it */
	mcmunlck(mcx, obj);
	break;

    default:
        runsig1(ctx->bifcxrun, ERR_INVTBIF, ERRTSTR, "outcapture");
    }
}

