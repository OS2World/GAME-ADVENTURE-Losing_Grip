/* Copyright (c) 1991 by Michael J. Roberts.  All rights reserved. */
/*
Name
  qas  - qa scripter
Function
  Allows TADS to read part or all of the commands from a session from a
  file.
Notes
  Some operating systems (e.g., Mac) obtain user input in ways that don't
  involve the command line.  For these systems to work properly, the os_xxx
  routines that invoke other input methods must be "qa scripter aware"; for
  example, the Mac os_askfile() routine must put the filename it gets back
  in the command log file, or must read directly from the command log file,
  or both.
Modified
  03/10/91 MJRoberts   - created
*/

#include "os.h" //###indep

/*
 *  Globals for the script reader
 */
osfildef *scrfp = (osfildef *)0; //###indep                      /* script file */
int scrquiet = 0;             /* flag: true ==> script is NOT shown as read */

/*
 *   open script file
 */
int qasopn(scrnam, quiet)
char *scrnam;
int   quiet;
{
    if (scrfp) return(1);                    /* already reading from script */
    if (!(scrfp = osfoprt(scrnam))) return(1);
    scrquiet = quiet;
    return(0);
}

/*
 *   close script file
 */
void qasclose()
{
    /* only close the script file if there's one open */
    if (scrfp)
    {
        osfcls( scrfp );
        scrfp = (osfildef *)0; //###indep            /* no more script file */
        scrquiet = 0;
    }
}

/* what to update */
#ifdef USE_LDESC
# define RUNSTATTYPE 1
#else
# define RUNSTATTYPE 0
#endif

/*
 *   Read the next line from the script file (this is essentially the
 *   script-redirected os_gets).  Only lines starting with '>' are
 *   considered script input lines; all other lines are comments, and are
 *   ignored.  
 */
char *qasgets(buf, bufl)
register char *buf;
int            bufl;
{
    /* shouldn't be here at all if there's no script file */
    if (!scrfp) return((char *)0);

    /* update status line */
    runstat(RUNSTATTYPE);

    /* keep going until we find something we like */
    for ( ;; )
    {
	char c;
	
	/*
	 *   Read the next character of input.  If it's not a newline,
	 *   there's more on the same line, so read the rest and see what
	 *   to do.  
	 */
	c = osfgetc(scrfp); //###indep
	if (c != '\n')
	{
	    /* read the rest of the line */
	    if (!osfgets(buf, bufl, scrfp)) //###indep
	    {
		/* end of file:  close the script and return eof */
		qasclose();
		return((char *)0);
	    }
	    
	    /* if the line started with '>', strip '\n' and return line */
	    if (c == '>')
	    {
		int l;
		
		if ((l = strlen(buf)) && buf[l-1] == '\n') buf[l-1] = 0;
		if (!scrquiet) outformat(buf);
		outflushn(1);
		return(buf);
	    }
	}
	else if (c == EOF )
	    return((char *)0);
    }
}
