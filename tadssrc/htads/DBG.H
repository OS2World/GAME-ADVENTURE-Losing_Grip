/*
$Header: c:/tads/tads2/RCS/DBG.H 1.7 94/11/06 13:07:49 mroberts Exp $
*/

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  dbg.h - debug interface
Function
  Debugger interface definitions
Notes
  The Debugger implementation is split into two parts:  the "engine",
  which implements the parts of the debugger that are independent of
  user interface; and the UI.  The UI is in a separate module so that
  several user interfaces can be provided, and a particular one chosen
  at link time.  The UI section should contain nothing that is generic,
  but only the parts specific to that user interface.
Modified
  03/28/92 MJRoberts     - creation
*/

#ifndef DBG_INCLUDED
#define DBG_INCLUDED

#ifndef ERR_INCLUDED
#include "err.h"
#endif
#ifndef RUN_INCLUDED
#include "run.h"
#endif
#ifndef TOK_INCLUDED
#include "tok.h"
#endif
#ifndef MCM_INCLUDED
#include "mcm.h"
#endif
#ifndef OBJ_INCLUDED
#include "obj.h"
#endif
#ifndef PRP_INCLUDED
#include "prp.h"
#endif
#ifndef TIO_INCLUDED
#include "tio.h"
#endif

/* stack frame record */
struct dbgfdef
{
    struct runsdef *dbgfbp;                        /* base pointer of frame */
    objnum  dbgfself;             /* 'self' object (MCMONINV for functions) */
    objnum  dbgftarg;                               /* actual target object */
    prpnum  dbgfprop;                          /* property being evalutated */
    int     dbgfargc;                                /* number of arguments */
    int     dbgfbif;      /* set to built-in function number if in built-in */
    uint    dbgffr;         /* offset in object of local frame symbol table */
    uint    dbgflin;                      /* OPCLINE operand of latest line */
};
typedef struct dbgfdef dbgfdef;

/* max number of frames to store in debug frame memory */
#define DBGMAXFRAME  100

/* maximum number of breakpoints set concurrently */
#define DBGBPMAX 50

/* breakpoint structure */
struct dbgbpdef
{
    objnum dbgbpself;               /* the "self" object for the breakpoint */
    objnum dbgbptarg;            /* actual target object for the breakpoint */
    uint   dbgbpofs;                  /* offset in object of the breakpoint */
    uint   dbgbpflg;                                    /* breakpoint flags */
#   define DBGBPFUSED  0x01                      /* breakpoint has been set */
#   define DBGBPFNAME  0x02              /* name of address has been stored */
#   define DBGBPFCOND  0x04          /* breakpoint has a condition attached */
#   define DBGBPFDISA  0x08                       /* breakpoint is disabled */
    uint   dbgbpnam;       /* offset of address name within dbgcxnam buffer */
    objnum dbgbpcond;        /* object containing compiled condition for bp */
};
typedef struct dbgbpdef dbgbpdef;

/* maximum number of watch expressions set concurrently */
#define DBGWXMAX 30

/* watch expression structure */
struct dbgwxdef
{
    objnum  dbgwxobj;              /* object containing compiled expression */
    objnum  dbgwxself;                         /* 'self' for the expression */
    uint    dbgwxnam;   /* offset of expression text within dbgcxnam buffer */
    uint    dbgwxflg;               /* flags for this watch expression slot */
#   define DBGWXFUSED  0x01                         /* watch slot is in use */
#   define DBGWXFNAME  0x02                /* name of watch has been stored */
};
typedef struct dbgwxdef dbgwxdef;

/* amount of space for bp names (original address strings from user) */
#define DBGCXNAMSIZ 2048

/* debug context */
struct dbgcxdef
{
    tiocxdef *dbgcxtio;                                 /* text i/o context */
    tokthdef *dbgcxtab;                                     /* symbol table */
    mcmcxdef *dbgcxmem;                     /* memory cache manager context */
    errcxdef *dbgcxerr;                           /* error handling context */
    struct    lindef *dbgcxlin;                    /* chain of line sources */
    int       dbgcxfcn;                          /* number of frames in use */
    int       dbgcxdep;          /* actual depth (if overflow frame buffer) */
    int       dbgcxfid;                        /* source file serial number */
    dbgfdef   dbgcxfrm[DBGMAXFRAME];                        /* stack frames */
    int       dbgcxflg;                          /* flags for debug session */
#   define    DBGCXFSS   0x01               /* single-stepping source lines */
#   define    DBGCXFSO   0x02       /* stepping over a function/method call */
#   define    DBGCXFOK   0x04                      /* debugger is linked in */
#   define    DBGCXFIND  0x08  /* in debugger - suppress stack trace on err */
#   define    DBGCXFGBP  0x10               /* global breakpoints in effect */
#   define    DBGCXFTRC  0x20                     /* call tracing activated */
    int       dbgcxsof;                    /* frame depth at step-over time */
    dbgbpdef  dbgcxbp[DBGBPMAX];                             /* breakpoints */
    dbgwxdef  dbgcxwx[DBGWXMAX];                       /* watch expressions */
    struct    prscxdef *dbgcxprs;                        /* parsing context */
    struct    runcxdef *dbgcxrun;                      /* execution context */
    uint      dbgcxnamf;               /* next free byte of dbgcxnam buffer */
    uint      dbgcxnams;                         /* size of dbgcxnam buffer */
    char     *dbgcxnam;                       /* space for bp address names */
    char     *dbgcxhstp;                             /* call history buffer */
    uint      dbgcxhstl;                           /* history buffer length */
    uint      dbgcxhstf;             /* offset of next free byte of history */
};
typedef struct dbgcxdef dbgcxdef;


/* ======================================================================== */
/*
 *   Compiler interface.  These routines are called by the compiler to
 *   inform the debug record generator about important events as
 *   compilation proceeds. 
 */


/*
 *   Tell the current line source that we're compiling an executable
 *   line, and tell it the object number and offset of the code within the
 *   object. 
 */
void dbgclin(/*_ struct tokcxdef *tokctx, objnum objn, uint ofs _*/);

/* size of information given to line source via lincmpinf method */
#define DBGLINFSIZ   4



/* ======================================================================== */
/*
 *   Run-time interface.  These routines are called by the run-time
 *   system to apprise the debugger of important events during execution.
 */


/* add a debug tracing record */
/* void dbgenter(dbgcxdef *ctx, runsdef *bp, objnum self, objnum target,
                 prpnum prop, int binum, int argc); */ 

/* tell debugger where the current line's local frame table is located */
/* void dbgframe(dbgcxdef *ctx, uint ofsfr, ofslin); */

/* single-step interrupt:  the run-time has reached a new source line */
/* void dbgssi(dbgcxdef *ctx, uint ofs, int instr, int err); */

/* pop debug trace level */
/* void dbgleave(dbgcxdef *ctx, int exittype); */
#define DBGEXRET   0                                /* return with no value */
#define DBGEXVAL   1                                 /* return with a value */
#define DBGEXPASS  2                       /* use 'pass' to exit a function */

/* dump the stack into text output */
/* void dbgdump(dbgcxdef *ctx); */

/* reset debug stack (throw away entire contents) */
/* void dbgrst(dbgcxdef *ctx); */

/* activate debugger if possible; returns TRUE if no debugger is present */
int dbgstart(/*_ dbgcxdef *ctx _*/);

/* add a string to the history buffer */
void dbgaddhist(/*_ dbgcxdef *ctx, char *bufl, int bufl _*/);

/*
 *   Find a base pointer, given the object+offset of the frame.  If the
 *   frame is not active, this routine signals ERR_INACTFR; otherwise, the
 *   bp value for the frame is returned. 
 */
struct runsdef *dbgfrfind(/*_ dbgcxdef *ctx, objnum frobj, uint frofs _*/);



/* ======================================================================== */
/*
 *   User Interface Support routines.  These routines are called by the
 *   user interface layer to get information from the debugger and perform
 *   debugging operations. 
 */


/*
 *   Get information about current line.  It is assumed that the caller
 *   knows the size of the line information .
 */
void dbglget(/*_ dbgcxdef *ctx, uchar *buf _*/);

/*
 *   Set a breakpoint by symbolic address: "function" or
 *   "object.property".  The string may contain whitespace characters
 *   around each symbol; it must be null-terminated.  If an error occurs,
 *   the error number is returned.  bpnum returns with the breakpoint
 *   number if err == 0.   If the condition string is given (and is
 *   not an empty string), the condition is compiled in the scope of
 *   the breakpoint and attached as the breakpoint condition.
 */
int dbgbpset(/*_ dbgcxdef *ctx, char *addr, int *bpnum _*/);

/* set a breakpoint at an object + offset location */
int dbgbpat(/*_ dbgcxdef *ctx ,objnum objn, objnum self,
                uint ofs, int *bpnum, char *bpname, int toggle,
		char *condition _*/);

/*
 *   Delete a breakpoint by breakpoint number (as returned from
 *   dbgbpset).  Returns error number, or 0 for success. 
 */
int dbgbpdel(/*_ dbgcxdef *ctx, int bpnum _*/);

/* disable or enable a breakpoint, by breakpoint number; returns error num */
int dbgbpdis(/*_ dbgcxdef *ctx, int bpnum, int disable _*/);

/* list breakpoints, using user callback to do display */
void dbgbplist(/*_ dbgcxdef *ctx, void dispfn(dvoid *ctx, char *str),
                   dvoid *dispctx _*/);

/* call callback with lindef data for each breakpoint currently set */
void dbgbpeach(/*_ dbgcxdef *ctx,
                   void (*fn)(dvoid *fnctx, int id, uchar *buf),
		   dvoid *fnctx _*/);

/* evaluate an expression (a text string to be parsed); returns error num */
int dbgeval(/*_ dbgcxdef *ctx, char *expr,
                void (*dispfn)(dvoid *dispctx, char *str, int strl),
		dvoid *dispctx, int level _*/);

/* display a stack traceback through a user callback */
void dbgstktr(/*_ dbgcxdef *ctx,
                  void (*dispfn)(dvoid *dispctx, char *str, int strl),
                  dvoid *dispctx, int level, int toponly _*/);

/* format a display of where execution is stopped into a buffer */
void dbgwhere(/*_ dbgcxdef *ctx, char *buf _*/);

/* set a watch expression; returns error or 0 for success */
int dbgwxset(/*_ dbgcxdef *ctx, char *expr, int *wxnum, int level _*/);

/* delete a watch expression */
int dbgwxdel(/*_ dbgcxdef *ctx, int wxnum _*/);

/* update all watch expressions */
void dbgwxupd(/*_ dbgcxdef *ctx,
                  void (*dispfn)(dvoid *dispctx, char *txt, int len),
		  dvoid *dispctx _*/);

/* switch to a new active lindef */
void dbgswitch(/*_ struct lindef **linp, struct lindef *newlin _*/);


/* ======================================================================== */
/*
 *   User Interface Routines.  The routines are called by the debugger
 *   to perform user interaction.
 */


/* debugger user interface main command loop */
void dbgucmd(/*_ dbgcxdef *ctx, int bphit, int err _*/);

/* debugger user interface initialization */
void dbguini(/*_ dbgcxdef *ctx _*/);

/*
 *   Debugger user interface: display an error.  This is called mainly so
 *   that the debugger can display an error using special output
 *   formatting if the error occurs while debugging. 
 */
void dbguerr(/*_ dbgcxdef *ctx, int errno, char *msg _*/);


#ifdef DBG_OFF
# define dbgenter(ctx, bp, self, target, prop, binum, argc)
# define dbgleave(ctx, exittype)
# define dbgdump(ctx)
# define dbgrst(ctx) ((void)0)
# define dbgframe(ctx, frofs, linofs)
# define dbgssi(ctx, ofs, instr, err)
#else /* DBG_OFF */
# define dbgenter(ctx, bp, self, target, prop, binum, argc) \
   dbgent(ctx, bp, self, target, prop, binum, argc)
# define dbgleave(ctx, exittype) dbglv(ctx, exittype)
# define dbgdump(ctx) dbgds(ctx)
# define dbgrst(ctx) ((ctx)->dbgcxfcn = (ctx)->dbgcxdep = 0)
# define dbgframe(ctx, frofs, linofs) \
   (((ctx)->dbgcxfrm[(ctx)->dbgcxfcn - 1].dbgffr = (frofs)), \
    ((ctx)->dbgcxfrm[(ctx)->dbgcxfcn - 1].dbgflin = (linofs)))
# define dbgssi(ctx, ofs, instr, err) dbgss(ctx, ofs, instr, err)
#endif /* DBG_OFF */


/* ======================================================================== */
/* private internal routines */

void dbgent(/*_ dbgcxdef *ctx, struct runsdef *bp, objnum self, objnum target,
                  prpnum prop, int binum, int argc _*/);

void dbglv(/*_ dbgcxdef *ctx, int exittype _*/);

void dbgds(/*_ dbgcxdef *ctx _*/);

void dbgss(/*_ dbgcxdef *ctx, uint ofs _*/);

void dbgpval(/*_ dbgcxdef *ctx, struct runsdef *val,
                 void (*dispfn)(dvoid *dispctx, char *str, int strl),
		 dvoid *dispctx, int showtype _*/);

int dbgtabsea(/*_ struct toktdef *tab, char *name, int namel, int hash,
                  struct toksdef *ret _*/);

#endif /* DBG_INCLUDED */
