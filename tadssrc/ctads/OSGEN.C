#include <ctype.h>
#include <string.h>
#include "os.h"

/*
 *  Look for a tads-related file in the standard locations and, if
 *  the search is successful, store the result file name in the given
 *  buffer.  Return 1 if the file was located, 0 if not.
 *
 *  Search the following areas for the file:  current directory, program
 *  directory (as derived from argv[0]), and the TADS path.
 */
int os_locate(fname, flen, arg0, buf, bufsiz)
char   *fname;                                    /* name of file to locate */
int     flen;                                            /* length of fname */
char   *arg0;                 /* argv[0] - for looking in program directory */
char   *buf;                                     /* result file name buffer */
size_t  bufsiz;                         /* size of result buffer (not used) */
{
    /* Check the current directory */
    if (osfacc(fname) == 0)
    {
        memcpy(buf, fname, flen);
        buf[flen] = 0;
        return(1);
    }

    /* Check the program directory */
    if (arg0 && *arg0)
    {
        char   *p;

        /* find the end of the directory name of argv[0] */
        for ( p = arg0 + strlen(arg0);
              p > arg0 && *(p-1) != OSPATHCHAR && !strchr(OSPATHALT, *(p-1));
              --p )
            ;

        /* don't bother if there's no directory on argv[0] */
        if (p > arg0)
        {
            size_t  len = (size_t)(p - arg0);

            memcpy(buf, arg0, len);
            memcpy(buf+len, fname, flen);
            buf[len+flen] = 0;
            if (osfacc(buf) == 0) return(1);
        }
    }

#ifdef USE_PATHSEARCH
    /* Check TADS path */
    if ( pathfind(fname, flen, "TADS", buf, bufsiz) )
        return(1);
#endif /* USE_PATHSEARCH */

    return(0);
}

#ifdef USE_PATHSEARCH
/* search a path specified in the environment for a tads file */
static int pathfind(fname, flen, pathvar, buf, bufsiz)
char   *fname;                                      /* name of file to find */
int     flen;                                            /* length of fname */
char   *pathvar;                                          /* path to search */
char   *buf;                                     /* result file name buffer */
size_t  bufsiz;                         /* size of result buffer (not used) */
{
    char   *e;

    if ( !(e = getenv(pathvar)) )
        return(0);
    for ( ;; )
    {
        char   *sep;
        size_t  len;

        if ( (sep = strchr(e, OSPATHSEP)) )
        {
            len = (size_t)(sep-e);
            if (!len) continue;
        }
        else
        {
            len = strlen(e);
            if (!len) break;
        }
        memcpy(buf, e, len);
        if (buf[len-1] != OSPATHCHAR && !strchr(OSPATHALT, buf[len-1]))
            buf[len++] = OSPATHCHAR;
        memcpy(buf+len, fname, flen);
        buf[len+flen] = 0;
        if (osfacc(buf) == 0) return(1);
        if (!sep) break;
        e = sep+1;
    }
    return(0);
}
#endif /* USE_PATHSEARCH */

/* Functions missing from OS/2 libraries */

void do_nothing_2(void);

void do_nothing_2()
{
	/* do nothing */
}

int stristr(char *p, char *q) {
	int len = strlen(q);
	for (; *p; p++) {
		if (!strnicmp(p, q, len))
			return 1;	// True
	}
	return 0;			// False
}

void tzset(void)
{
	/* Do nothing */
}
