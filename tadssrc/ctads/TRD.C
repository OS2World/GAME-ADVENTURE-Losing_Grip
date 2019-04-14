#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/trd.c 1.10 96/10/14 16:10:47 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  trd.c - tads2 run-time driver
Function
  reads a binary file and executes it
Notes
  none
Modified
  04/04/92 MJRoberts     - creation
*/

#include <stdio.h>
#include "os.h"
#include "std.h"
#include "err.h"
#include "mch.h"
#include "obj.h"
#include "run.h"
#include "voc.h"
#include "bif.h"
#include "dbg.h"
#include "sup.h"
#include "cmd.h"
#include "fio.h"
#include "oem.h"

/* dummy setup function */
void supgnam(buf, tab, sc)
char *buf;
void *tab;
int   sc;
{
    strcpy(buf, "???");
}

/* dummy file read functions */
void tok_read_defines(tctx, fp, ec)
struct tokcxdef  *tctx;
struct osfiledef *fp;
errcxdef         *ec;
{
    errsig(ec, ERR_UNKRSC);
}

/* dummy debugger functions */
void trchid() {}
void trcsho() {}

struct runsdef *dbgfrfind(ctx, frobj, frofs)
dbgcxdef *ctx;
objnum    frobj;
uint      frofs;
{
    VARUSED(frobj);
    VARUSED(frofs);
    errsig(ctx->dbgcxerr, ERR_INACTFR);
}

void dbgss(ctx, ofs, instr)
struct dbgcxdef *ctx;
uint             ofs;
int              instr;
{
    VARUSED(ctx);
    VARUSED(ofs);
    VARUSED(instr);
    return;
}

int dbgstart(ctx)
struct dbgcxdef *ctx;
{
    VARUSED(ctx);
    return(TRUE);
}

/* use os_printf rather than printf */
/* #define trdptf os_printf */
/* ### Actually changed the code to say os_printf instead of trdptf */

void trdusage(ec)
errcxdef *ec;
{
    int  i;
    char buf[128];
    
    for (i = ERR_TRUS1 ; i <= ERR_TRUSL ; ++i)
    {
        errmsg(ec, buf, (uint)sizeof(buf), i);
        os_printf1("%s\n", buf); /* ###indep */
    }
    errsig(ec, ERR_USAGE);
}

/*
 *   Default memory sizes, if previously defined 
 */
#ifndef TRD_SETTINGS_DEFINED
# define TRD_HEAPSIZ  4096
# define TRD_STKSIZ   200
# define TRD_UNDOSIZ  (16 * 1024)
#endif


static void trdmain1(ec, argc, argv)
errcxdef *ec;
int       argc;
char     *argv[];
{
    int        t;
    osfildef  *swapfp = (osfildef *)0;
    runcxdef   runctx;
    bifcxdef   bifctx;
    voccxdef   vocctx;
    void     (*bif[75])(/*_ dvoid *ctx _*/);
    mcmcxdef  *mctx;
    mcmcx1def *globalctx;
    dbgcxdef   dbg;
    supcxdef   supctx;
    int        err;
    char      *swapname = 0;
    char       swapbuf[OSFNMAX];
    char     **argp;
    char      *arg;
    char      *infile;
    char      *exefile;            /* try with executable file if no infile */
    ulong      swapsize = 0xffffffffL;        /* allow unlimited swap space */
    int        swapena = TRUE;               /* TRUE if swapping is enabled */
    int        i;
    int        pause = FALSE;                 /* pause after finishing game */
    extern int doublespace; /* two spaces after each period. ###double */
    fiolcxdef  fiolctx;
    noreg int  loadopen = FALSE;
    char       inbuf[OSFNMAX];
    ulong      cachelimit = 0xffffffff;
    ushort     undosiz = TRD_UNDOSIZ;      /* default undo context size 16k */
    objucxdef *undoptr;
    uint       flags;         /* flags used to write the file we're reading */
    objnum     preinit;         /* preinit object, if we need to execute it */
    uint       heapsiz = TRD_HEAPSIZ;
    uint       stksiz = TRD_STKSIZ;
    runsdef   *mystack;
    uchar     *myheap;
    extern osfildef *cmdfile; /* ###indep         /* hacky v1 qa interface - command log fp */
    extern osfildef *logfp; /* ###indep            /* hacky v1 qa interface - output log fp */
    int        preload = FALSE;              /* TRUE => preload all objects */
    ulong      totsize;
    
    NOREG((&loadopen))

    /* parse arguments */
    for (i = 1, argp = argv + 1 ; i < argc ; ++argp, ++i)
    {
        arg = *argp;
        if (*arg == '-')
        {
            switch(*(arg+1))
            {
            case 'i':
                qasopn(cmdarg(ec, &argp, &i, argc, 1, trdusage), TRUE);
                break;
                
            case 'o':
                cmdfile = osfopwt(cmdarg(ec, &argp, &i, argc, 1, trdusage)); //###indep
                break;
                
            case 'l':
                logfp = osfopwt(cmdarg(ec, &argp, &i, argc, 1, trdusage)); //###indep
                break;

            case 'p':
                if (!stricmp(arg, "-plain"))
                {
                    os_plain();
                    break;
                }
                pause = cmdtog(ec, pause, arg, 1, trdusage);
                break;
                
            case 'd': /* ###double */
                if (!strnicmp(arg, "-double", 7))
                {
                    doublespace = cmdtog(ec, doublespace, arg, 6, trdusage);
                    break;
                }
                break;
                
            case 'm':
                switch(*(arg + 2))
                {
                case 's':
                    stksiz = atoi(cmdarg(ec, &argp, &i, argc, 2, trdusage));
                    break;
                    
                case 'h':
                    heapsiz = atoi(cmdarg(ec, &argp, &i, argc, 2, trdusage));
                    break;
                    
                default:
                    cachelimit = atol(cmdarg(ec, &argp, &i, argc, 1,
                                             trdusage));
                    break;
                }
                break;
                
            case 't':
                /* swap file options:  -tf file, -ts size, -t- (no swap) */
                switch(*(arg+2))
                {
                case 'f':
                    swapname = cmdarg(ec, &argp, &i, argc, 2, trdusage);
                    break;
                    
                case 's':
                    swapsize = atol(cmdarg(ec, &argp, &i, argc, 2, trdusage));
                    break;
                    
                case 'p':
                    preload = cmdtog(ec, preload, arg, 2, trdusage);
                    break;
                    
                default:
                    swapena = cmdtog(ec, swapena, arg, 1, trdusage);
                    break;
                }
                break;
                
            case 'u':
                undosiz = atoi(cmdarg(ec, &argp, &i, argc, 1, trdusage));
                break;
                
            default:
                trdusage(ec);
            }
        }
        else break;
    }

    /* get input name argument, and make sure it's the last argument */
    if (i == argc)
    {
        osfildef *fp;
        ulong     curpos;
        ulong     endpos;
        osfildef *os_exeseek();
        
        /* try to read from os-dependent part of program being executed */
        infile = (char *)0;
        exefile = (argv && argv[0] ? argv[0] : "TRX");
        
        /* seek if we can even open the file - if not, abort w/usage msg */
        fp = os_exeseek(exefile, "TGAM");
        if (!fp) trdusage(ec);
        
        /* see if there's anything at end of exefile */
        curpos = osfpos(fp);
        osfseek(fp, 0L, OSFSK_END);
        endpos = osfpos(fp);
        osfcls(fp);
        
        /* if nothing at end, abort with usage message */
        if (endpos == curpos) trdusage(ec);
    }
    else
    {
        infile = *argp;
        exefile = (char *)0;
        if (i + 1 != argc) trdusage(ec);

        strcpy(inbuf, infile);
        
        /* add default .GAM extension to input file */
        os_defext(inbuf, "gam");

        /*
         *   if the name with the .GAM extension doesn't exist, use the
         *   original name 
         */
        if (osfacc(inbuf)) strcpy(inbuf, infile);
		
        /* use the buffer's current contents as the input filename */
        infile = inbuf;
    }

    /* open up the swap file */
    if (swapena && swapsize)
    {
        swapfp = os_create_tempfile(swapname, swapbuf);
        if (swapname == 0) swapname = swapbuf;
        if (swapfp == 0) errsig(ec, ERR_OPSWAP);
    }
    
    ERRBEGIN(ec)

    /* initialize cache manager context */
    globalctx = mcmini(cachelimit, 128, swapsize, swapfp, ec);
    mctx = mcmcini(globalctx, 128, fioldobj, &fiolctx,
                   objrevert, (dvoid *)0);
    mctx->mcmcxrvc = mctx;

    /* set up an undo context */
    if (undosiz)
        undoptr = objuini(mctx, undosiz, vocdundo, vocdusz, &vocctx);
    else
        undoptr = (objucxdef *)0;

    /* set up vocabulary context */
    vocini(&vocctx, ec, mctx, &runctx, undoptr, 100, 100, 200);    

    /* allocate stack and heap */
    totsize = (ulong)stksiz * (ulong)sizeof(runsdef);
    if (totsize != (ushort)totsize)
        errsig1(ec, ERR_STKSIZE, ERRTINT, (uint)(65535/sizeof(runsdef)));
    mystack = (runsdef *)mchalo(ec, (ushort)totsize, "runtime stack");
    myheap = mchalo(ec, (ushort)heapsiz, "runtime heap");

    /* set up execution context */
    runctx.runcxerr = ec;
    runctx.runcxmem = mctx;
    runctx.runcxstk = mystack;
    runctx.runcxstop = &mystack[stksiz];
    runctx.runcxsp = mystack;
    runctx.runcxbp = mystack;
    runctx.runcxheap = myheap;
    runctx.runcxhp = myheap;
    runctx.runcxhtop = &myheap[heapsiz];
    runctx.runcxundo = undoptr;
    runctx.runcxbcx = &bifctx;
    runctx.runcxbi = bif;
    runctx.runcxtio = (tiocxdef *)0;
    runctx.runcxdbg = &dbg;
    runctx.runcxvoc = &vocctx;
    runctx.runcxdmd = supcont;
    runctx.runcxdmc = &supctx;
    runctx.runcxext = 0;

    /* set up setup context */
    supctx.supcxerr = ec;
    supctx.supcxmem = mctx;
    supctx.supcxtab = (tokthdef *)0;
    supctx.supcxbuf = (uchar *)0;
    supctx.supcxlen = 0;
    supctx.supcxvoc = &vocctx;
    supctx.supcxrun = &runctx;

    /* set up debug context */
    dbg.dbgcxtio = (tiocxdef *)0;
    dbg.dbgcxmem = mctx;
    dbg.dbgcxerr = ec;
    dbg.dbgcxtab = (tokthdef *)0;
    dbg.dbgcxfcn = 0;
    dbg.dbgcxdep = 0;
    dbg.dbgcxflg = 0;
    dbg.dbgcxlin = (lindef *)0;                      /* no line sources yet */

    /* set up built-in function context */
    CLRSTRUCT(bifctx);
    bifctx.bifcxerr = ec;
    bifctx.bifcxrun = &runctx;
    bifctx.bifcxtio = (tiocxdef *)0;
    bifctx.bifcxrnd = 0;
    bifctx.bifcxrndset = FALSE;

    /* add the built-in functions, keywords, etc */
    supbif(&supctx, bif, (int)(sizeof(bif)/sizeof(bif[0])));

    /* set up status line hack */
    runistat(&vocctx, &runctx, (tiocxdef *)0);

    /* turn on the "busy" cursor before loading */
    os_csr_busy(TRUE);

    /* read the game from the binary file */
    fiord(mctx, &vocctx, (struct tokcxdef *)0,
          infile, exefile, &fiolctx, &preinit, &flags,
          (struct tokpdef *)0, (uchar **)0, (uint *)0, (uint *)0,
          1 + (preload ? 2 : 0));
    loadopen = TRUE;

    /* turn off the "busy" cursor */
    os_csr_busy(FALSE);

    /* play the game */
    plygo(&runctx, &vocctx, (tiocxdef *)0, preinit,
          !(flags & FIOFBIN) && !(flags & FIOFSYM));
    
    /* close load file */
    fiorcls(&fiolctx);
    
    if (pause)
    {
        os_printf("[strike a key to exit]");
        os_waitc();
        os_printf("\n");
    }
    
    /* close and delete swapfile, if one was opened */
    if (swapfp)
    {
        osfcls(swapfp);
        swapfp = (osfildef *)0;
        osfdel(swapname);
    }

    ERRCLEAN(ec)
        /* close and delete swapfile, if one was opened */
        if (swapfp)
        {
            osfcls(swapfp);
            swapfp = (osfildef *)0;
            osfdel(swapname);
        }
        
        /* close the load file if one was opened */
        if (loadopen) fiorcls(&fiolctx);
    ERRENDCLN(ec)
}

/* log an error */
static void trdlogerr(ctx, fac, err, argc, argv)
errcxdef *ctx;
char     *fac;
int       err;
int       argc;
erradef  *argv;
{
    int   i;
    char  buf[256];
    char  msg[256];
    short status;	// SRG: For holding status mode
    extern short statusmode;	// SRG: Def'd in os2io.c

    status = statusmode;	// SRG: Save current statusmode (?)
    statusmode = 0;		// SRG: Force print in client window
#if defined(ERR_LINK_MESSAGES) && defined(OS_SKIP_ERROR_CODES)
    os_printf1("\n[An error has occurred within %s: ", fac); /* ###indep */
#else
    os_printf2("\n[%s-%d: ", fac, err); /* ###indep */
#endif
    errmsg(ctx, msg, (uint)sizeof(msg), err);
    errfmt(buf, (int)sizeof(buf), msg, argc, argv);
    os_printf1("%s]\n", buf); /* ###indep */
    statusmode = status;	// SRG: Restore statusmode
}

/* main - called by os main after setting up arguments */
int trdmain(argc, argv)
int   argc;
char *argv[];
{
    errcxdef  errctx;
    int       err;
    osfildef *fp;
    
    errctx.errcxlog = trdlogerr;
    errctx.errcxlgc = &errctx;
    errctx.errcxfp  = (osfildef *)0;
    fp = oserrop(argv[0]);
    errini(&errctx, fp);
    
    os_printf2("tr: the TADS Run-time v2.2.1.%d (%s)\n",
           TADS_OEM_VERSION, TADS_OEM_NAME); // ###indep
    os_printf("Copyright (c) 1993, 1996 Michael J. Roberts\n");
 
    ERRBEGIN(&errctx)
        trdmain1(&errctx, argc, argv);
    ERRCATCH(&errctx, err)
        if (err != ERR_USAGE && err != ERR_RUNQUIT)
            errclog(&errctx);
        if (errctx.errcxfp) osfcls(errctx.errcxfp);
        os_expause();
        return(OSEXFAIL);
    ERREND(&errctx)
        
    if (errctx.errcxfp) osfcls(errctx.errcxfp);
    return(OSEXSUCC);
}
