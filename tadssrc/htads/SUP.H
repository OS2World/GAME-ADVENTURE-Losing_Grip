/*
$Header: d:/tads/tads2/RCS/sup.h 1.3 96/10/14 16:10:45 mroberts Exp $
*/

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  sup.h - definitions for post-compilation setup
Function
  does post-compilation setup, such as setting up contents lists
Notes
  none
Modified
  03/28/92 MJRoberts     - creation
*/

#ifndef SUP_INCLUDED
#define SUP_INCLUDED

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
#ifndef VOC_INCLUDED
#include "voc.h"
#endif

/* setup context */
struct supcxdef
{
    errcxdef *supcxerr;
    mcmcxdef *supcxmem;                    /* memory manager client context */
    voccxdef *supcxvoc;                   /* player command parsing context */
    tokthdef *supcxtab;                           /* top-level symbol table */
    runcxdef *supcxrun;                                /* execution context */
    uchar    *supcxbuf;                        /* space for building a list */
    ushort    supcxlen;                                   /* size of buffer */
};
typedef struct supcxdef supcxdef;

/* set up contents list for one object for demand-on-load */
void supcont(/*_ supcxdef *ctx, objnum obj, prpnum prp _*/);

/* set up inherited vocabulary (called before executing game) */
void supivoc(/*_ supcxdef *ctx _*/);

/* find required objects/functions */
void supfind(/*_ errcxdef *ctx, tokthdef *tab, voccxdef *voc,
                 objnum *preinit _*/);

/* set up reserved words */
void suprsrv(/*_ supcxdef *sup, void (*bif[])(struct bifcxdef *, int),
                 toktdef *tab, int bifsiz, int v1compat _*/);

/* set up built-in functions without symbol table (for run-time) */
void supbif(/*_ supcxdef *sup, void (*bif)(struct bifcxdef *, int),
               int bifsiz _*/);

/* log an undefined-object error */
void sup_log_undefobj(/*_ mcmcxdef *mctx, errcxdef *ec, int err,
                          char *sym_name, int sym_name_len, objnum objn _*/);

/* table of built-in functions */
typedef struct supbidef supbidef;
struct supbidef
{
    char  *supbinam;                                    /* name of function */
    void (*supbifn)(/*_ struct bifcxdef *, int _*/);   /* C routine to call */
};

/* external definition for special token table */
extern tokldef supsctab[];

#endif /* SUP_INCLUDED */
