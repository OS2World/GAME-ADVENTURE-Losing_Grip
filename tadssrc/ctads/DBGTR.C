/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  dbgtr.c - Debugging functions for run-time
Function
  Provides dummy entrypoints for various debugger functions for run-time.
Notes
  Eliminates a number of time- and space-consuming functions from TR.
  Also defines a couple of TOKTH entrypoints since there will be no
  need for a symbol table when debugging is not enabled.
Modified
  12/18/92 MJRoberts     - creation
*/

#include "std.h"
#include "tok.h"
#include <stdlib.h>

void dummy_add() {}
int  dummy_sea() { return(0); }
void dummy_set() {}
void dummy_each() {}
uint tokhsh() { return(0); }

/* dummy symbol table entrypoints */
void tokthini(ec, mctx, symtab1)
errcxdef *ec;
mcmcxdef *mctx;
toktdef  *symtab1;
{
    tokthdef *symtab = (tokthdef *)symtab1;      /* convert to correct type */

    CLRSTRUCT(*symtab);
    symtab1->toktfadd = dummy_add;
    symtab1->toktfsea = dummy_sea;
    symtab1->toktfset = dummy_set;
    symtab1->toktfeach = dummy_each;
    symtab1->tokterr = ec;
    symtab->tokthmem = mctx;
}

/* dummy debugger entrypoints */
void dbgent() {}
void dbglv() {}
int  dbgnam(ctx, outbuf, typ, val)
void *ctx;
char *outbuf;
int   typ;
int   val;
{
    memcpy(outbuf, "<NO SYMBOL TABLE>", (size_t)17);
    return(17);
}

void dbgds() {}

/*
void dbglget() {}
void dbgclin() {}
void dbgstktr() {}
*/