/*
$Header: c:/tads/tads2/RCS/BIF.H 1.5 94/11/06 13:06:06 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  bif.h - built-in functions interface
Function
  interface to run-time intrinsic function implementation
Notes
  None
Modified
  12/16/92 MJRoberts     - add TADS/Graphic functions
  12/26/91 MJRoberts     - creation
*/

#ifndef BIF_INCLUDED
#define BIF_INCLUDED

#ifndef OS_INCLUDED
# include "os.h"
#endif
#ifndef ERR_INCLUDED
# include "err.h"
#endif
#ifndef RUN_INCLUDED
# include "run.h"
#endif
#ifndef TIO_INCLUDED
# include "tio.h"
#endif


/* maximum number of file handles available */
#define BIFFILMAX  10


/* built-in execution context */
struct bifcxdef
{
    errcxdef *bifcxerr;                           /* error-handling context */
    runcxdef *bifcxrun;                           /* code execution context */
    tiocxdef *bifcxtio;                                 /* text I/O context */
    long      bifcxrnd;                               /* random number seed */
    int       bifcxseed1;                   /* first seed for new generator */
    int       bifcxseed2;                  /* second seed for new generator */
    int       bifcxseed3;                   /* third seed for new generator */
    int       bifcxrndset;                   /* randomize() has been called */
    osfildef *bifcxfile[BIFFILMAX];          /* file handles for fopen, etc */
};
typedef struct bifcxdef bifcxdef;

/*
 *   argument list checking routines - can be disabled for faster
 *   run-time 
 */

/* check for proper number of arguments */
/* void bifcntargs(bifcxdef *ctx, int argcnt) */

/* check that next argument has proper type */
/* void bifchkarg(bifcxdef *ctx, dattyp typ); */

#ifdef RUNFAST
# define bifcntargs(ctx, parmcnt, argcnt)
# define bifchkarg(ctx, typ)
#else /* RUNFAST */
# define bifcntargs(ctx, parmcnt, argcnt) \
  (parmcnt == argcnt ? DISCARD 0 : \
   (runsig(ctx->bifcxrun, ERR_BIFARGC), DISCARD 0))
# define bifchkarg(ctx, typ) \
  (runtostyp(ctx->bifcxrun) == typ ? DISCARD 0 : \
   (runsig(ctx->bifcxrun, ERR_INVTBIF), DISCARD 0))
#endif /* RUNFAST */

/* enumerate the built-in functions */
void bifyon(/*_ bifcxdef *ctx, int argc _*/);           /* yorn - yes or no */
void bifsfs(/*_ bifcxdef *ctx, int argc _*/);                    /* setfuse */
void bifrfs(/*_ bifcxdef *ctx, int argc _*/);                    /* remfuse */
void bifsdm(/*_ bifcxdef *ctx, int argc _*/);                  /* setdaemon */
void bifrdm(/*_ bifcxdef *ctx, int argc _*/);                  /* remdaemon */
void bifinc(/*_ bifcxdef *ctx, int argc _*/);                    /* incturn */
void bifqui(/*_ bifcxdef *ctx, int argc _*/);                       /* quit */
void bifsav(/*_ bifcxdef *ctx, int argc _*/);                       /* save */
void bifrso(/*_ bifcxdef *ctx, int argc _*/);                    /* restore */
void biflog(/*_ bifcxdef *ctx, int argc _*/);                    /* logging */
void bifres(/*_ bifcxdef *ctx, int argc _*/);                    /* restart */
void bifinp(/*_ bifcxdef *ctx, int argc _*/);   /* input - get line from kb */
void bifnfy(/*_ bifcxdef *ctx, int argc _*/);                     /* notify */
void bifunn(/*_ bifcxdef *ctx, int argc _*/);                   /* unnotify */
void biftrc(/*_ bifcxdef *ctx, int argc _*/);               /* trace on/off */
void bifsay(/*_ bifcxdef *ctx, int argc _*/);                        /* say */
void bifcar(/*_ bifcxdef *ctx, int argc _*/);                        /* car */
void bifcdr(/*_ bifcxdef *ctx, int argc _*/);                        /* cdr */
void bifcap(/*_ bifcxdef *ctx, int argc _*/);                       /* caps */
void biflen(/*_ bifcxdef *ctx, int argc _*/);                     /* length */
void biffnd(/*_ bifcxdef *ctx, int argc _*/);                       /* find */
void bifsit(/*_ bifcxdef *ctx, int argc _*/);   /* setit - set current 'it' */
void bifsrn(/*_ bifcxdef *ctx, int argc _*/);       /* randomize: seed rand */
void bifrnd(/*_ bifcxdef *ctx, int argc _*/); /* rand - get a random number */
void bifask(/*_ bifcxdef *ctx, int argc _*/);                    /* askfile */
void bifssc(/*_ bifcxdef *ctx, int argc _*/);                   /* setscore */
void bifsub(/*_ bifcxdef *ctx, int argc _*/);                     /* substr */
void bifcvs(/*_ bifcxdef *ctx, int argc _*/);  /* cvtstr: convert to string */
void bifcvn(/*_ bifcxdef *ctx, int argc _*/);  /* cvtnum: convert to number */
void bifupr(/*_ bifcxdef *ctx, int argc _*/);                      /* upper */
void biflwr(/*_ bifcxdef *ctx, int argc _*/);                      /* lower */
void biffob(/*_ bifcxdef *ctx, int argc _*/);                   /* firstobj */
void bifnob(/*_ bifcxdef *ctx, int argc _*/);                    /* nextobj */
void bifsvn(/*_ bifcxdef *ctx, int argc _*/);                 /* setversion */
void bifarg(/*_ bifcxdef *ctx, int argc _*/);                     /* getarg */
void biftyp(/*_ bifcxdef *ctx, int argc _*/);                   /* datatype */
void bifisc(/*_ bifcxdef *ctx, int argc _*/);                    /* isclass */
void bifund(/*_ bifcxdef *ctx, int argc _*/);                       /* undo */
void bifdef(/*_ bifcxdef *ctx, int argc _*/);                    /* defined */
void bifpty(/*_ bifcxdef *ctx, int argc _*/);                   /* proptype */
void bifoph(/*_ bifcxdef *ctx, int argc _*/);                    /* outhide */
void bifgfu(/*_ bifcxdef *ctx, int argc _*/);                    /* getfuse */
void bifruf(/*_ bifcxdef *ctx, int argc _*/);                   /* runfuses */
void bifrud(/*_ bifcxdef *ctx, int argc _*/);                 /* rundaemons */
void biftim(/*_ bifcxdef *ctx, int argc _*/);                    /* gettime */
void bifsct(/*_ bifcxdef *ctx, int argc _*/);                  /* intersect */
void bifink(/*_ bifcxdef *ctx, int argc _*/);                   /* inputkey */
void bifwrd(/*_ bifcxdef *ctx, int argc _*/);                   /* objwords */
void bifadw(/*_ bifcxdef *ctx, int argc _*/);                    /* addword */
void bifdlw(/*_ bifcxdef *ctx, int argc _*/);                    /* delword */
void bifgtw(/*_ bifcxdef *ctx, int argc _*/);                   /* getwords */
void bifnoc(/*_ bifcxdef *ctx, int argc _*/);                     /* nocaps */
void bifskt(/*_ bifcxdef *ctx, int argc _*/);                   /* skipturn */
void bifcls(/*_ bifcxdef *ctx, int argc _*/);                /* clearscreen */
void bif1sc(/*_ bifcxdef *ctx, int argc _*/);                    /* firstsc */
void bifvin(/*_ bifcxdef *ctx, int argc _*/);                   /* verbinfo */
void bifcapture(/*_ bifcxdef *ctx, int argc _*/);             /* outcapture */

void biffopen(/*_ bifcxdef *ctx, int argc _*/);                    /* fopen */
void biffclose(/*_ bifcxdef *ctx, int argc _*/);                  /* fclose */
void biffwrite(/*_ bifcxdef *ctx, int argc _*/);                  /* fwrite */
void biffread(/*_ bifcxdef *ctx, int argc _*/);                    /* fread */
void biffseek(/*_ bifcxdef *ctx, int argc _*/);                    /* fseek */
void biffseekeof(/*_ bifcxdef *ctx, int argc _*/);              /* fseekeof */
void bifftell(/*_ bifcxdef *ctx, int argc _*/);                    /* ftell */




/*
 *   TADS/graphic functions - these are present in the text system, but
 *   don't do anything.
 */
void bifgrp(/*_ bifcxdef *ctx, int argc _*/);    /* g_readpic: read picture */
void bifgsp(/*_ bifcxdef *ctx, int argc _*/);    /* g_showpic: show picture */
void bifgsh(/*_ bifcxdef *ctx, int argc _*/);     /* g_sethot: set hot list */
void bifgin(/*_ bifcxdef *ctx, int argc _*/);                /* g_inventory */
void bifgco(/*_ bifcxdef *ctx, int argc _*/);                  /* g_compass */
void bifgov(/*_ bifcxdef *ctx, int argc _*/);                  /* g_overlay */
void bifgmd(/*_ bifcxdef *ctx, int argc _*/);                     /* g_mode */
void bifgmu(/*_ bifcxdef *ctx, int argc _*/);                    /* g_music */
void bifgpa(/*_ bifcxdef *ctx, int argc _*/);                    /* g_pause */
void bifgef(/*_ bifcxdef *ctx, int argc _*/);                   /* g_effect */
void bifgsn(/*_ bifcxdef *ctx, int argc _*/);                    /* g_sound */

#endif /* BIF_INCLUDED */
