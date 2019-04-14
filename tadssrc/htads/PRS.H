/*
$Header: c:/tads/tads2/RCS/PRS.H 1.5 94/11/06 13:05:48 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  prs.h - parser definitions
Function
  Definitions for the parser
Notes
  None
Modified
  08/30/91 MJRoberts     - creation
*/

#ifndef PRS_INCLUDED
#define PRS_INCLUDED

#ifndef ERR_INCLUDED
#include "err.h"
#endif
#ifndef TOK_INCLUDED
#include "tok.h"
#endif
#ifndef PRP_INCLUDED
#include "prp.h"
#endif
#ifndef EMT_INCLUDED
#include "emt.h"
#endif
#ifndef VOC_INCLUDED
#include "voc.h"
#endif

/* expression parse tree node */
typedef struct prsndef prsndef;
struct prsndef
{
    int    prsntyp;                                    /* type of this node */
    int    prsnnlf;                        /* number of leaves on this node */
    union
    {
	tokdef   prsnvt;                        /* leaf node: token at leaf */
	prsndef *prsnvn[1];               /* non-leaf: one or more subnodes */
    } prsnv;
};

/*
 *   Case table: the case table is a linked list of arrays of case
 *   records, each of which contains a value (in the form of a tokdef) and
 *   a label number.  When additional case table entries are needed,
 *   another array is added to the list, providing essentially unlimited
 *   cases in a switch.  Note that this is the parser's internal record of
 *   a case table as it's being parsed, and is converted to a different
 *   representation during code generation. 
 */
#define PRSCTSIZE 50            /* number of case entries in one case array */
typedef struct prsctdef prsctdef;
struct prsctdef
{
    prsctdef *prsctnxt;                         /* next array in case table */
    struct
    {
	tokdef prscttok;                             /* value of this label */
	uint   prsctofs;                    /* code position for this label */
    }         prsctcase[PRSCTSIZE];                                /* cases */
};

/* case table control block */
struct prscsdef
{
    struct prsctdef *prscstab;                          /* first case table */
    uint             prscscnt;                           /* number of cases */
    uint             prscsdflt;                 /* offset of 'default' code */
};
typedef struct prscsdef prscsdef;

/* parsing context */
struct prscxdef
{
    errcxdef *prscxerr;                           /* error handling context */
    tokcxdef *prscxtok;                         /* lexical analysis context */
    toktdef  *prscxstab;                   /* table to which to add symbols */
    toktdef  *prscxgtab;                       /* goto (label) symbol table */
    mcmcxdef *prscxmem;                          /* memory handling context */
    emtcxdef *prscxemt;                                  /* emitter context */
    voccxdef *prscxvoc;                               /* vocabulary context */
    uchar    *prscxcpp;             /* pointer to compound word memory area */
    uint      prscxcpf;       /* offset of next free byte of compound words */
    size_t    prscxcps;                /* size of compound word memory area */
    uchar    *prscxfsp;                    /* pointer to format string area */
    uint      prscxfsf;       /* offset of next free byte of format strings */
    size_t    prscxfss;                       /* size of format string area */
    uchar    *prscxspp;                     /* pointer to special word area */
    uint      prscxspf;        /* offset of next free byte of special words */
    size_t    prscxsps;                        /* size of special word area */
    ushort    prscxflg;                                      /* parse flags */
#   define    PRSCXFLIN  0x01   /* debug mode: generate inline line records */
#   define    PRSCXFLCL  0x02  /* debug mode: generate inline local records */
#   define    PRSCXFLST  0x04       /* parsing a list element - no indexing */
#   define    PRSCXFARC  0x08          /* check argument counts in user fns */
#   define    PRSCXFV1E  0x10    /* v1 'else' compat - ignore ';' after '}' */
#   define    PRSCXFWTCH 0x20               /* compiling "watch" expression */
#   define    PRSCXFFUNC 0x40      /* compiling function - no 'self' object */
#   define    PRSCXFTPL1 0x80                    /* use old-style templates */
    uint      prscxprp;         /* maximum property number allocated so far */
    uint      prscxext;               /* count of external functions so far */
    uchar    *prscxnode;                   /* next available node structure */
    uint      prscxsofs;               /* starting offset of current string */
    ushort    prscxslen;                        /* length of current string */
    ushort    prscxnsiz;                              /* bytes in node pool */
    ushort    prscxnrem;                    /* remaining bytes in node pool */
    uchar    *prscxnrst;                   /* value for resetting prscxnode */
    ushort    prscxrrst;                   /* value for resetting prscxnrem */
    uchar    *prscxplcl;                        /* pool for local variables */
    ushort    prscxslcl;                              /* size of local pool */
    ushort    prscxextc;                     /* count of external functions */
    uchar     prscxpool[1];                     /* pool for node allocation */
};
typedef struct prscxdef prscxdef;

/* parse function or object definition */
void prscode(/*_ prscxdef *ctx _*/);

/* parse a statement (or compound statement) */
void prsstm(/*_ prscxdef *ctx, uint brk, uint cont, int parms, int locals,
                uint entofs, prscsdef *swctl, uint curfr _*/);

/* delete 'goto' labels belonging to current code block */
void prsdelgoto(/*_ prscxdef *ctx _*/);

/* parse an expression and generate code for it */
void prsxgen(/*_ prscxdef *ctx _*/);

/*
 *   parse and generate an expression, checking for a possibly incorrect
 *   assignment if in C operator mode 
 */
void prsxgen_pia(/*_ prscxdef *ctx _*/);

/* string accumulation routines */
ushort prsxsst(/*_ prscxdef *ctx _*/);
void prsxsad(/*_ prscxdef *ctx, char *p, ushort len _*/);
void prsxsend(/*_ prscxdef *ctx _*/);

/* determine if a type is valid for logical operators */
#define prsvlog(typ) \
 ((typ)==TOKTNUMBER || (typ)==TOKTNIL || (typ)==TOKTTRUE)

/* convert a value to a logical type, if it's a number */
#define prs2log(typ, val) \
 ((typ)==TOKTNUMBER ? ((val) ? TOKTTRUE : TOKTNIL) : (typ))

/* reset node pool */
/* void prsrstn(prscxdef *ctx); */
#define prsrstn(ctx) \
 ((ctx)->prscxnode = (ctx)->prscxnrst, \
  (ctx)->prscxnrem = (ctx)->prscxrrst)

/* maximum number of superclasses for a single object */
#define  PRSMAXSC 64

/* amount of space to allocate for a new object */
#define PRSOBJSIZ 256

/* add a symbol to the symbol table */
void prsdef(/*_ prscxdef *ctx, tokdef *tok, int typ _*/);

/*
 *   Require a property identifier, returning the property number. The
 *   token containing the property identifier is removed from the input
 *   stream.  
 */
prpnum prsrqpr(/*_ prscxdef *ctx _*/);

/* signal a "missing required token" error, finding token name */
void prssigreq(/*_ prscxdef *ctx, int t _*/);

/* generate code from a parse tree */
void prsgexp(/*_ prscxdef *ctx, prsndef *n _*/);

/* generate code for initializer */
void prsgini(/*_ prscxdef *ctx, prsndef *node, uint curfr _*/);

/* check for and skip a required token */
void prsreq(/*_ prscxdef *ctx, int t _*/);

/* get next token, require it to be a particular value, then skip it */
void prsnreq(/*_ prscxdef *ctx, int t _*/);

/* START parsing an expression - resets node pool */
prsndef *prsexpr(/*_ prscxdef *ctx _*/);

/* allocate space in the parse node area */
uchar *prsbalo(/*_ prscxdef *ctx, uint siz _*/);

/* build a quad operator node */
prsndef *prsnew4(/*_ prscxdef *ctx, int t, prsndef *n1, prsndef *n2,
                            prsndef *n3, prsndef *n4 _*/);

/* build a tertiary operator node */
prsndef *prsnew3(/*_ prscxdef *ctx, int t, prsndef *n1, prsndef *n2,
                            prsndef *n3 _*/);

/* build a binary operator node */
prsndef *prsnew2(/*_ prscxdef *ctx, int t, prsndef *n1,
                            prsndef *n2 _*/);

/* build a unary operator node */
prsndef *prsnew1(/*_ prscxdef *ctx, int t, prsndef *n _*/);

/* build a new value node */
prsndef *prsnew0(/*_ prscxdef *ctx, tokdef *tokp _*/);

/* start parsing an initializer expression (resets node pool) */
prsndef *prsxini(/*_ prscxdef *ctx _*/);


#endif /* PRS_INCLUDED */
