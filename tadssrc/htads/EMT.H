/*
$Header: c:/tads/tads2/RCS/emt.h 1.4 93/01/08 04:33:18 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  emt.h - emitter definitions
Function
  Defines interface to the code emitter
Notes
  None
Modified
  09/23/91 MJRoberts     - creation
*/

#ifndef EMT_INCLUDED
#define EMT_INCLUDED

#ifndef STD_INCLUDED
# include "std.h"
#endif
#ifndef ERR_INCLUDED
# include "err.h"
#endif
#ifndef MCM_INCLUDED
# include "mcm.h"
#endif
#ifndef OBJ_INCLUDED
# include "obj.h"
#endif

/* temporary labels/forward reference fixups */
struct emtldef
{
    ushort  emtllnk;                  /* link: first/next forward reference */
    ushort  emtlofs;         /* offset of label/forward reference to fix up */
    uchar   emtlflg;                                               /* flags */
#   define  EMTLFSET    1         /* label has been set - no longer forward */
};
typedef struct emtldef emtldef;

/* end of link list */
#define EMTLLNKEND ((ushort)~0)

/* emitter context */
struct emtcxdef
{
    errcxdef *emtcxerr;                           /* error handling context */
    mcmcxdef *emtcxmem;                            /* cache manager context */
    mcmon     emtcxobj;                  /* object code is being written to */
    ushort    emtcxofs;        /* offset of next byte of code to be written */
    uchar    *emtcxptr;                       /* pointer to object's memory */
    int       emtcxlcnt;                          /* size of emtcxlbl array */
    ushort    emtcxlfre;              /* first free label/forward reference */
    emtldef   emtcxlbl[1];      /* array of labels/forward reference fixups */
    objnum    emtcxfrob;                      /* debug frame object, if any */
};
typedef struct emtcxdef emtcxdef;

/* pre-emit list element structure */
struct emtledef
{
    uchar   emtletyp;
    long    emtleval;
};
typedef struct emtledef emtledef;

/* pre-emit list definition structure */
struct emtlidef
{
    int      emtlicnt;                    /* number of elements in the list */
    emtledef emtliele[1];                         /* array of list elements */
};
typedef struct emtlidef emtlidef;

/* emit a value, given as a token */
void emtval(/*_ emtcxdef *ctx, struct tokdef *tok, uchar *base _*/);

/* emit an operand-less opcode */
/* void emtop(emtcxdef *ctx, uchar op); */
#define emtop(ctx,op) \
 (emtres(ctx, (ushort)1), \
  (void)(*((ctx)->emtcxptr + (ctx)->emtcxofs++) = (op)))

/* emit a single byte */
/* void emtbyte(emtcxdef *ctx, uchar b); */
#define emtbyte(ctx,b) emtop(ctx,b)

/* emit bytes from memory */
/* void emtmem(emtcxdef *ctx, dvoid *ptr, size_t siz); */
#define emtmem(ctx,ptr,siz) \
 (emtres(ctx, (ushort)(siz)),\
  memcpy((ctx)->emtcxptr + (ctx)->emtcxofs,ptr,(size_t)(siz)),\
  (void)((ctx)->emtcxofs += (siz)))

/* emit a 2-byte integer value */
/* void emtint2(emtcxdef *ctx, int i); */
#define emtint2(ctx,i) \
 (emtres(ctx, (ushort)2), oswp2((ctx)->emtcxptr + (ctx)->emtcxofs, i), \
 (ctx)->emtcxofs+=2)

/* emit a 2-byte integer at a particular offset in the code */
#define emtint2at(ctx,i,ofs) \
 (oswp2((ctx)->emtcxptr + (ofs), i))

/* read a 2-byte integer previously emitted */
#define emtint2from(ctx, ofs) \
 (osrp2((ctx)->emtcxptr + (ofs)))

/* emit a 4-byte integer value */
/* void emtint4(emtcxdef *ctx, long l); */
#define emtint4(ctx,l) \
 (emtres(ctx, (ushort)4), oswp4((ctx)->emtcxptr + (ctx)->emtcxofs, l), \
 (ctx)->emtcxofs+=4)


/* set up temporary labels in code generation context */
void emtlini(/*_ emtcxdef *ctx _*/);

/* get a temporary code label */
uint emtglbl(/*_ emtcxdef *ctx _*/);

/* get a temporary code label set to the current code location */
uint emtgslbl(/*_ emtcxdef *ctx _*/);

/*
 *   Set a temporary label to the current position, releasing it if
 *   desired.  If the label is released, *lab is set to an invalid label
 *   value (EMTLLNKEND) so that the caller can detect (for error-handling
 *   purposes) whether the label has been freed. 
 */
void emtslbl(/*_ emtcxdef *ctx, uint *lab, int release _*/);

/*
 *   Release a temporary label for re-use.  *lab is set to EMTLLNKEND so
 *   that the caller can detect (for error-handling purposes) whether the
 *   label has been freed. 
 */
void emtdlbl(/*_ emtcxdef *ctx, uint *lab _*/);

/*
 *   Clear label, ignoring errors (used for error cleanup). *lab is set
 *   to EMTLLNKEND to flag that it's been freed. 
 */
void emtclbl(/*_ emtcxdef *ctx, uint *lab _*/);

/* return TRUE if a label has been set, FALSE if not set */
/* int emtqset(emtcxdef *ctx, uint lab); */
#define emtqset(ctx,lab) (((ctx)->emtcxlbl[lab].emtlflg & EMTLFSET) != 0)

/* emit a jump to a temporary label */
void emtjmp(/*_ emtcxdef *ctx, uchar op, uint lab _*/);

/* reserve space for code */
void emtres(/*_ emtcxdef *ctx, ushort bytes _*/);

/* emit a list value */
void emtlst(/*_ emtcxdef *ctx, uint ofs, uchar *base _*/);

/* incremental addition to object size when we run out of space */
#define EMTINC 256

#endif /* EMT_INCLUDED */
