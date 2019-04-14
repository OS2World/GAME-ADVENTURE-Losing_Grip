/*
$Header: c:/tads/tads2/RCS/FIO.H 1.6 94/11/06 13:05:28 mroberts Exp $
*/

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  fio.h - file i/o interface
Function
  fiel i/o functions - write game, read game, save game, restore game
Notes
  none
Modified
  04/02/92 MJRoberts     - creation
*/

#ifndef FIO_INCLUDED
#define FIO_INCLUDED

#ifndef MCM_INCLUDED
#include "mcm.h"
#endif
#ifndef OS_INCLUDED
#include "os.h"
#endif

/* load-on-demand context (passed in by mcm in load callback) */
typedef struct fiolcxdef fiolcxdef;
struct fiolcxdef
{
    osfildef *fiolcxfp;                        /* file pointer of load file */
    errcxdef *fiolcxerr;                          /* error handling context */
    ulong     fiolcxst;                          /* starting offset in file */
    uint      fiolcxflg;                   /* flags from original load file */
    uint      fiolcxseed;                                    /* fioxor seed */
    uint      fiolcxinc;                                /* fioxor increment */
};

/* write game to binary file */
void fiowrt(/*_ struct mcmcxdef *mctx, struct voccxdef *vctx,
                struct tokcxdef *tokctx,
                struct tokthdef *tab, uchar *fmts, uint fmtl,
		char *fname, uint flags, objnum preinit, int extcount,
		int prpcnt _*/);

/* flag values for use with fiowrt */
#define FIOFSYM   0x01               /* include symbol table in output file */
#define FIOFLIN   0x02          /* include source file tracking information */
#define FIOFPRE   0x04        /* preinit needs to be run after reading game */
#define FIOFCRYPT 0x08           /* "encrypt" objects prior to writing them */
#define FIOFBIN   0x10                        /* writing precompiled header */
#define FIOFFAST  0x20                     /* fast-load records are in file */
#define FIOFCASE  0x40    /* case folding was turned on in original compile */

/* read game from binary file; sets up loader callback context */
void fiord(/*_ mcmcxdef *mctx, voccxdef *vctx, char *fname, char *exename,
               fiolcxdef *setupctx, objnum *preinit, uint *flagp,
	       struct tokpdef *path, uchar **fmtsp, uint *fmtlp,
	       uint *pcntptr, uint run_init _*/);

/* shut down load-on-demand subsystem, close load file */
void fiorcls(/*_ fiolcxdef *ctx _*/);

/* loader callback - load an object on demand */
void OS_LOADDS fioldobj(/*_ fiolcxdef *ctx, mclhd handle, uchar *ptr,
                            ushort siz _*/);

/* save a game - returns TRUE on failure */
int fiosav(/*_ voccxdef *vctx, char *fname _*/);

/* restore a game - returns TRUE on failure */
int fiorso(/*_ voccxdef *vctx, char *fname _*/);

/* encrypt/decrypt an object */
void fioxor(/*_ uchar *p, uint siz _*/);


/* strings stored in binary game file for identification and validation */

/* file header string */
#define FIOFILHDR "TADS2 bin\012\015\032"

/* CURRENT file format version string */
#define FIOVSNHDR  "v2.2.0"

/* other file format versions that can be READ by this version */
#define FIOVSNHDR2 "v2.0.0"
#define FIOVSNHDR3 "v2.0.1"

#endif /* FIO_INCLUDED */
