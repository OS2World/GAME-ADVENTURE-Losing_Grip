#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/CMD.C 1.4 94/11/06 13:07:06 mroberts Exp $";
#endif

/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  cmd.c - command line option reader
Function
  service functions for interpreting command line options
Notes
  none
Modified
  04/04/92 MJRoberts     - creation
*/

#include "os.h"
#include "std.h"
#include "err.h"

/* get a toggle argument */
int cmdtog(ec, prv, argp, ofs, usagefn)
errcxdef *ec;
int       prv;
char     *argp;
int       ofs;
void    (*usagefn)(/*_ errcxdef* _*/);
{
    switch(argp[ofs + 1])
    {
    case '+':
	return(TRUE);
	
    case '-':
	return(FALSE);
	
    case '\0':
	return(!prv);
	
    default:
	(*usagefn)(ec);
	NOTREACHEDV(int);
    }
}

/* get an argument to a switch */
char *cmdarg(ec, argpp, ip, argc, ofs, usagefn)
errcxdef   *ec;
char     ***argpp;
int        *ip;
int         argc;
int         ofs;
void      (*usagefn)(/*_ errcxdef* _*/);
{
    char *ret;
    
    ret = (**argpp) + ofs + 1;
    if (!*ret)
    {
	++(*ip);
        ++(*argpp);
	ret = **argpp;
    }
    
    if (!ret || !*ret || *ip >= argc) (*usagefn)(ec);
    return(ret);
}

