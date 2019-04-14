/*
$Header: d:/tads/tads2/RCS/voc.h 1.8 96/10/14 16:10:50 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  voc.h - vocabulary definitions
Function
  Defines TADS vocabulary (player command parser) functionality
Notes
  None
Modified
  11/07/91 MJRoberts     - creation
*/

#ifndef VOC_INCLUDED
#define VOC_INCLUDED

#ifndef ERR_INCLUDED
#include "err.h"
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
#ifndef RUN_INCLUDED
#include "run.h"
#endif

/* maximum number of objects matching an ambiguous word */
#define VOCMAXAMBIG 200

/*
 *   Vocabulary relation structure - this structure relates a vocabulary
 *   word to an object and part of speech.  A list of these structures is
 *   attached to each vocabulary word structure to provide the word's
 *   meanings.
 */
typedef struct vocwdef vocwdef;
struct vocwdef
{
    uint   vocwnxt;      /* index of next vocwdef attached to the same word */
    objnum vocwobj;                      /* object associated with the word */
    uchar  vocwtyp;   /* property associated with the word (part of speech) */
    uchar  vocwflg;                                   /* flags for the word */
#define VOCFCLASS  1                          /* word is for a class object */
#define VOCFINH    2                 /* word is inherited from a superclass */
#define VOCFNEW    4                          /* word was added at run-time */
#define VOCFDEL    8                               /* word has been deleted */
};

/* vocabulary word structure */
typedef struct vocdef vocdef;
struct vocdef
{
    vocdef *vocnxt;                         /* next word at same hash value */
    uchar   voclen;                                   /* length of the word */
    uchar   vocln2;          /* length of second word (0 if no second word) */
    uint    vocwlst;      /* head of list of vocwdef's attached to the word */
    uchar   voctxt[1];                                  /* text of the word */
};

/* vocabulary inheritance cell */
typedef struct vocidef vocidef;
struct vocidef
{
    uchar            vocinsc;   /* # of superclasses (gives size of record) */
    union
    {
	struct
	{
	    uchar    vociusflg;                          /* flags for entry */
#define VOCIFCLASS  1  /* entry refers to a class object (loc records only) */
#define VOCIFVOC    2                 /* entry has vocabulary words defined */
#define VOCIFXLAT   4  /* superclasses must be translated from portable fmt */
#define VOCIFLOCNIL 8                  /* location is explicitly set to nil */
#define VOCIFNEW    16       /* object was allocated at run-time with "new" */
	    objnum   vociusloc;                   /* location of the object */
	    objnum   vociusilc;                       /* inherited location */
	    objnum   vociussc[1];                  /* array of superclasses */
	} vocius;
	vocidef     *vociunxt;
    } vociu;
#   define   vociflg vociu.vocius.vociusflg
#   define   vociloc vociu.vocius.vociusloc
#   define   vociilc vociu.vocius.vociusilc
#   define   vocisc  vociu.vocius.vociussc
#   define   vocinxt vociu.vociunxt
};

/* size of a page in a vocabulary pool */
#define VOCPGSIZ  8192

/* number of bytes in an inheritance cell page */
#define VOCISIZ 8192

/* maximum number of inheritance pages */
#define VOCIPGMAX 32

/* maximum number of inheritance pages (256 objects per page) */
#define VOCINHMAX 128

/* size of vocabulary hash table */
#define VOCHASHSIZ  256

/* size of a template structure */
#define VOCTPLSIZ 10

/* new-style template structure */
#define VOCTPL2SIZ  16


/*
 *   vocwdef's are fixed in size.  They're allocated in a set of arrays
 *   (the voccxwp member of the voc context has the list of arrays).  Each
 *   array is of a fixed number of vocwdef entries; a maximum number of
 *   vocwdef arrays is possible. 
 */
#define VOCWPGSIZ   2000                   /* number of vocwdef's per array */
#define VOCWPGMAX   16                  /* maximum number of vocwdef arrays */

/*
 *   To find a vocwdef entry given its index, divide the index by the
 *   number of entries per array to find the array number, and use the
 *   remainder to find the index within that array. 
 */
/*#define VOCW_IN_CACHE*/
#ifdef VOCW_IN_CACHE
vocwdef *vocwget(struct voccxdef *ctx, uint idx);
#else
#define vocwget(ctx, idx) \
    ((idx) == VOCCXW_NONE ? (vocwdef *)0 : \
      ((ctx)->voccxwp[(idx)/VOCWPGSIZ] + ((idx) % VOCWPGSIZ)))
#endif

/* daemon/fuse/alarm slot */
struct vocddef
{
    objnum   vocdfn;             /* object number of function to be invoked */
    runsdef  vocdarg;                  /* argument for daemon/fuse function */
    prpnum   vocdprp;             /* property number (used only for alarms) */
    uint     vocdtim;  /* time for fuses/alarms (0xffff -> each-turn alarm) */
};
typedef struct vocddef vocddef;

/* vocabulary object list entry */
struct vocoldef
{
    objnum  vocolobj;                           /* object matching the word */
    char   *vocolfst;         /* first word in cmd[] that identified object */
    char   *vocollst;          /* last word in cmd[] that identified object */
    int     vocolflg;                           /* special flags (ALL, etc) */
};
typedef struct vocoldef vocoldef;

/* vocabulary context */
struct voccxdef
{
    errcxdef  *voccxerr;                          /* error handling context */
    tiocxdef  *voccxtio;                                /* text i/o context */
    runcxdef  *voccxrun;                               /* execution context */
    mcmcxdef  *voccxmem;                          /* memory manager context */
    objucxdef *voccxundo;                                   /* undo context */
    uchar     *voccxpool;                  /* next free byte in vocdef pool */
    vocdef    *voccxfre;                        /* head of vocdef free list */
    char      *voccxcpp;                   /* pointer to compound word area */
    int        voccxcpl;                    /* length of compound word area */
    char      *voccxspp;                    /* pointer to special word area */
    int        voccxspl;                     /* length of special word area */
    uint       voccxrem;        /* number of bytes remaining in vocdef pool */
    vocidef  **voccxinh[VOCINHMAX];     /* vocidef page table: 256 per page */
    uchar     *voccxip[VOCIPGMAX];                 /* inheritance cell pool */
    vocidef   *voccxifr;              /* head of inheritance cell free list */
    uint       voccxiplst;          /* last inheritance cell page allocated */
    uint       voccxilst;      /* next unused byte in last inheritance page */
    int        voccxredo;                   /* flag: redo command in buffer */

    vocdef    *voccxhsh[VOCHASHSIZ];                          /* hash table */

#ifdef VOCW_IN_CACHE
    mcmon      voccxwp[VOCWPGMAX];        /* list of pages of vocab records */
    mcmon      voccxwplck;                  /* locked page of vocab records */
    vocwdef   *voccxwpgptr;             /* pointer to currently locked page */
#else
    vocwdef   *voccxwp[VOCWPGMAX];                  /* vocabulary word pool */
#endif

    uint       voccxwalocnt;             /* number of vocwdef's used so far */
    uint       voccxwfre;            /* index of first vocwdef in free list */
#define VOCCXW_NONE  ((uint)(-1))     /* index value indicating end of list */

    vocddef   *voccxdmn;                           /* array of daemon slots */
    uint       voccxdmc;                 /* number of slots in daemon array */
    vocddef   *voccxfus;                             /* array of fuse slots */
    uint       voccxfuc;                   /* number of slots in fuse array */
    vocddef   *voccxalm;                            /* array of alarm slots */
    uint       voccxalc;                  /* number of slots in alarm array */
    char       voccxtim[26];            /* game's timestamp (asctime value) */
    
    objnum     voccxvtk;                /* object number of "take" deepverb */
    objnum     voccxme;                      /* object number of "Me" actor */
    objnum     voccxstr;                       /* object number of "strObj" */
    objnum     voccxnum;                       /* object number of "numObj" */
    objnum     voccxit;                                  /* last "it" value */
    objnum     voccxhim;                                /* last "him" value */
    objnum     voccxher;                                /* last "her" value */
    objnum     voccxthc;                   /* count of items in "them" list */
    objnum     voccxthm[VOCMAXAMBIG];            /* list of items in "them" */
    objnum     voccxprd;                 /* "pardon" function object number */
    objnum     voccxpre;               /* "preparse" function object number */
    objnum     voccxppc;            /* "preparseCmd" function object number */
    objnum     voccxvag;                             /* "again" verb object */
    objnum     voccxini;                                 /* "init" function */
    objnum     voccxper;             /* "parseError" function object number */
    objnum     voccxprom;             /* "cmdPrompt" function object number */
    objnum     voccxpdis;                         /* parseDisambig function */
    objnum     voccxper2;                           /* parseError2 function */
    objnum     voccxpdef;                          /* parseDefault function */
    objnum     voccxpask;                           /* parseAskobj function */
    objnum     voccxpask2;                     /* parseAskobjActor function */

    /* current command word list values */
    vocoldef  *voccxdobj;                /* current direct object word list */
    vocoldef  *voccxiobj;              /* current indirect object word list */
    
    /* previous command values - used by "again" */
    objnum     voccxlsa;                                  /* previous actor */
    objnum     voccxlsv;                                   /* previous verb */
    objnum     voccxlsd;                                   /* direct object */
    objnum     voccxlsi;                                 /* indirect object */
    objnum     voccxlsp;                                     /* preposition */
    uchar      voccxlst[VOCTPLSIZ];                             /* template */

    objnum     voccxpreinit;                            /* preinit function */

    /* special flags */
    uchar      voccxflg;
#define VOCCXFCLEAR    1      /* ignore remainder of command line (restore) */
#define VOCCXFVWARN    2                /* generate redundant verb warnings */
#define VOCCXFDBG      4           /* debug mode:  show parsing information */
};
typedef struct voccxdef voccxdef;

/* add a vocabulary word */
void vocadd(/*_ voccxdef *ctx, prpnum p, objnum objn,
                int classflag, char *wrdval _*/);

/* internal addword - must already be split into two words and lengths */
void vocadd2(/*_ voccxdef *ctx, prpnum p, objnum objn, int classflg,
                 char *wrd1, int len1, char *wrd2, int len2 _*/);

/* delete vocabulary for a given object */
void vocdel(/*_ voccxdef *ctx, objnum objn _*/);

/* lower-level vocabulary deletion routine */
void vocdel1(/*_ voccxdef *ctx, objnum objn, char *wrd, prpnum prp,
                 int really_delete, int revert, int keep_undo _*/);

/* delete all inherited vocabulary */
void vocdelinh(/*_ voccxdef *ctx _*/);

/* allocate space for an inheritance record if needed */
void vocialo(/*_ voccxdef *ctx, objnum obj _*/);

/* add an inheritance/location record */
void vociadd(/*_ voccxdef *ctx, objnum obj, objnum loc,
                 int numsc, objnum *sc, int flags _*/);

/* delete inheritance records for an object */
void vocidel(/*_ voccxdef *ctx, objnum chi _*/);

/* renumber an object's inheritance records - used for 'modify' */
void vociren(/*_ voccxdef *ctx, objnum oldnum, objnum newnum _*/);

/* caller-provided context structure for vocffw/vocfnw searches */
typedef struct vocseadef vocseadef;
struct vocseadef
{
    vocdef  *v;
    vocwdef *vw;
};

/* find first word matching a given word */
vocwdef *vocffw(/*_ voccxdef *ctx, char *wrd, int len, char *wrd2, int len2,
                   int p, vocseadef *search_ctx _*/);

/* find next word */
vocwdef *vocfnw(/*_ vocseadef *search_ctx _*/);

/* read a line of input text */
void vocread(/*_ voccxdef *ctx, char *buf, int bufl _*/);

/* compute size of a vocoldef list */
int voclistlen(/*_ vocoldef *lst _*/);

/* tokenize an input buffer */
int voctok(/*_ voccxdef *ctx, char *cmd, char *outbuf,
               char **wrd, int lower _*/);

/* get types for a word list */
int vocgtyp(/*_ voccxdef *ctx, char **cmd, int *types, char *orgbuf _*/);

/* execute a player command */
int voccmd(/*_ voccxdef *ctx, char *cmd, uint cmdlen _*/);

/* disambiguator */
int vocdisambig(/*_ voccxdef *ctx, vocoldef *outlist, vocoldef *inlist,
                    prpnum defprop, prpnum accprop, prpnum verprop,
		    char *cmd[], objnum otherobj, objnum cmdActor,
		    objnum cmdVerb, objnum cmdPrep, objnum cmdIobj,
		    char *cmdbuf _*/);

/* low-level executor */
int execmd(/*_ voccxdef *ctx, objnum actor, objnum prep,
               char *vverb, char *vprep, vocoldef *dolist, vocoldef *iolist,
	       char **cmd, char *cmdbuf _*/);

/* find a template */
int voctplfnd(/*_ voccxdef *ctx, objnum verb_in, objnum prep,
                  uchar *tplout, int *newstyle _*/);

/*
 *   check noun - determines whether the next set of words is a valid noun
 *   phrase.  No complaint is issued if not; this check is generally made
 *   to figure out what type of sentence we're dealing with.  This is
 *   simple; we just call vocgobj() with the complaint flag turned off.
 */
/* int vocchknoun(voccxdef *ctx, char **cmd, int *typelist, int cur,
                  int *next, vocoldef *nounlist, int chkact); */
#define vocchknoun(ctx, cmd, typelist, cur, next, nounlist, chkact) \
 vocgobj(ctx, cmd, typelist, cur, next, FALSE, nounlist, TRUE, chkact)

/*
 *   get noun - reads an object list.  We simply call vocgobj() with the
 *   complaint and multiple-noun flags turned on.
 */
/* int vocgetnoun(voccxdef *ctx, char **cmd, int *typelist, int cur,
                  int *next, vocoldef *nounlist); */
#define vocgetnoun(ctx, cmd, typelist, cur, next, nounlist) \
 vocgobj(ctx, cmd, typelist, cur, next, TRUE, nounlist, TRUE, FALSE)

/* get object */
int vocgobj(/*_ voccxdef *ctx, char **cmd, int *typelist, int cur,
                int *next, int complain, vocoldef *nounlist,
		int multi, int chkact _*/);

/* check access to an object */
int vocchkaccess(/*_ voccxdef *ctx, objnum obj, prpnum verprop,
                     int seqno, objnum actor, objnum verb _*/);

/* size of input buffer */
#define VOCBUFSIZ 128

/* macros to read values out of templates */
#define voctplpr(tpl) ((objnum)osrp2(((uchar *)tpl)))        /* preposition */
#define voctplvi(tpl) ((prpnum)osrp2(((uchar *)tpl) + 2))      /* verIoVerb */
#define voctplio(tpl) ((prpnum)osrp2(((uchar *)tpl) + 4))         /* ioVerb */
#define voctplvd(tpl) ((prpnum)osrp2(((uchar *)tpl) + 6))      /* verDoVerb */
#define voctpldo(tpl) ((prpnum)osrp2(((uchar *)tpl) + 8))         /* doVerb */
#define voctplflg(tpl) (*(((uchar *)tpl) + 10))                    /* flags */

/* flag values for the voctplflg */
#define VOCTPLFLG_DOBJ_FIRST   0x01     /* disambiguate direct object first */


/* special type flags */
#define VOCS_ALL    1
#define VOCS_EXCEPT 2
#define VOCS_IT     4
#define VOCS_THEM   8
#define VOCS_NUM    16
#define VOCS_COUNT  32
#define VOCS_PLURAL 64
#define VOCS_ANY    128
#define VOCS_HIM    256
#define VOCS_HER    512
#define VOCS_STR    1024

/* special internally-defined one-character word flags */
#define VOCW_AND   ','
#define VOCW_THEN  '.'
#define VOCW_OF    'O'
#define VOCW_ALL   'A'
#define VOCW_BOTH  'B'
#define VOCW_IT    'I'
#define VOCW_HIM   'M'
#define VOCW_ONE   'N'
#define VOCW_ONES  'P'
#define VOCW_HER   'R'
#define VOCW_THEM  'T'
#define VOCW_BUT   'X'
#define VOCW_ANY   'Y'

/* structure for special internal word table */
struct vocspdef
{
    char *vocspin;
    char  vocspout;
};
typedef struct vocspdef vocspdef;

/* check if a word is a special word - true if word is given special word */
/* int vocspec(char *wordptr, int speccode); */
#define vocspec(w, s) (*(w) == (s))

/* set a fuse/daemon/notifier */
void vocsetfd(/*_ voccxdef *ctx, vocddef *what, objnum func, prpnum prop,
                  uint tm, runsdef *val, int err _*/);

/* remove a fuse/daemon/notifier */
void vocremfd(/*_ voccxdef *ctx, vocddef *what, objnum func, prpnum prop,
                  runsdef *val, int err _*/);

/* count a turn (down all fuse/notifier timers) */
void vocturn(/*_ voccxdef *ctx _*/);

/* initialize voc context */
void vocini(/*_ voccxdef *vocctx, errcxdef *errctx, mcmcxdef *memctx,
                runcxdef *runctx, objucxdef *undoctx, int fuses,
                int daemons, int notifiers _*/);

/* allocate fuse/daemon/notifier array for voc ctx initialization */
void vocinialo(/*_ voccxdef *ctx, vocddef **what, int cnt _*/);

/* get a vocidef given an object number */
/* vocidef *vocinh(voccxdef *ctx, objnum obj); */
#define vocinh(ctx, obj) ((ctx)->voccxinh[(obj) >> 8][(obj) & 255])

/* revert all objects back to original state, using inheritance records */
void vocrevert(/*_ voccxdef *ctx _*/);

/* clear all fuses/daemons/notifiers (useful for restarting) */
void vocdmnclr(/*_ voccxdef *ctx _*/);

/* display a parser error message */
void vocerr(/*_ voccxdef *ctx, int err, char *f, ... _*/);

/* client undo callback - undoes a daemon/fuse/notifier */
void vocdundo(/*_ voccxdef *ctx, uchar *data _*/);

/* client undo size figuring callback - return size of client undo record */
ushort OS_LOADDS vocdusz(/*_ voccxdef *ctx, uchar *data _*/);

/* compute vocabulary word hash value */
uint vochsh(/*_ char *t, int len _*/);

/* TADS versions of isalpha, isspace, isdigit, etc */
#define vocisupper(c) ((uchar)(c) <= 127 && isupper(c))
#define vocislower(c) ((uchar)(c) <= 127 && islower(c))
#define vocisalpha(c) ((uchar)(c) > 127 || isalpha(c))
#define vocisspace(c) ((uchar)(c) <= 127 && isspace(c))
#define vocisdigit(c) ((uchar)(c) <= 127 && isdigit(c))


/*
 *   Undo types for voc subsystem 
 */
#define VOC_UNDO_DAEMON   1                    /* fuse/daemon status change */
#define VOC_UNDO_NEWOBJ   2                              /* object creation */
#define VOC_UNDO_DELOBJ   3                              /* object deletion */
#define VOC_UNDO_ADDVOC   4                  /* add vocabulary to an object */
#define VOC_UNDO_DELVOC   5             /* delete vocabulary from an object */


/*
 *   Our own stack.  We need to allocate some fairly large structures
 *   (for the disambiguation lists, mostly) in a stack-like fashion, and
 *   we don't want to consume vast quantities of the real stack, because
 *   some machines have relatively restrictive limitations on stack usage.
 *   To provide some elbow room, we'll use a stack-like structure of our
 *   own: we'll allocate out of this structure as needed, and whenever we
 *   leave a C stack frame, we'll also leave our own stack frame. 
 */

/* re-initialize the stack, allocating space for it if needed */
void  voc_stk_ini(/*_ voccxdef *ctx, uint siz _*/);

/* enter a stack frame, marking our current position */
#define voc_enter(marker)  (*(marker) = voc_stk_cur)

/* leave a stack frame, restoring the entry position */
#define voc_leave(marker)  (voc_stk_cur = marker)

/* return a value */
#define VOC_RETVAL(marker, retval) \
       voc_leave(marker); return retval

/* allocate space from the stack */
dvoid *voc_stk_alo(/*_ voccxdef *ctx, uint siz _*/);

/* allocation cover macros */
#define VOC_STK_ARRAY(ctx, typ, var, cnt) \
    (var = (typ *)voc_stk_alo(ctx, (uint)((cnt) * sizeof(typ))))

#define VOC_MAX_ARRAY(ctx, typ, var) \
    VOC_STK_ARRAY(ctx, typ, var, VOCMAXAMBIG)

/* the actual stack area */
extern char *voc_stk_ptr;
extern char *voc_stk_cur;

/*
 *   Stack size for the vocab stack.  We'll scale our stack needs based
 *   on the size of the vocoldef structure, since this is the most common
 *   item to be allocated on the vocab stack.  We'll also scale based on
 *   the defined VOCMAXAMBIG parameter, since it is the number of elements
 *   usually allocated.  The actual amount of space needed depends on how
 *   the functions in vocab.c and execmd.c work, so this parameter may
 *   need to be adjusted for changes to the player command parser. 
 */
#define VOC_STACK_SIZE  (16 * VOCMAXAMBIG * sizeof(vocoldef))

#endif /* VOC_INCLUDED */

