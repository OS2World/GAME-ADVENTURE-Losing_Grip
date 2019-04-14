/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  getstr  - get a string from the player
Function
  Reads a string from the player, doing all the necessary formatting
  and logging.
Notes
  This routine flushes output before getting the string.  The caller
  should display any desired prompt prior to calling getstring().  Never
  call os_gets() directly; use getstring() instead, since it logs the
  string to the log file if one is open.
Modified
  09/05/92 MJRoberts     - add buf length parameter to getstring
  04/07/91 JEras         - log '>' on prompt; disable moremode before prompt
  03/10/91 MJRoberts     - created (separated from vocab.c)
*/

#include <stdio.h>
#include "os.h"

osfildef *cmdfile; //###indep

/*
 *   getstring reads a string from the keyboard, doing all necessary
 *   output flushing.  Prompting is to be done by the caller.  This
 *   routine should be called instead of os_gets.
 */
int getstring(prompt, buf, bufl)
char *prompt;
char *buf;
{
    char   *os_gets(), *qasgets();
    char   *result;
    extern  osfildef *logfp, *scrfp; //###indep
    extern  int   scrquiet;

    /* show prompt if one was given and flush output */
    setmore(0);
    if (prompt)
    {
	outformat(prompt);
	if (logfp) fprintf(logfp, "%s", prompt); //###indep
    }
    outflushn(0);
    outreset();

    if (scrfp)
    {
      int quiet = scrquiet;

      /* try reading from command input file */
      if (!(result = qasgets(buf, bufl)))
      {
	/*
	 *   End of command input file; return to reading the keyboard.
	 *   If we didn't already show the prompt, show it now.  
	 */
        if (quiet && prompt) outformat(prompt);
        outflushn(0);
        outreset();
        result = os_gets(buf, bufl); //###length
      }
    }
    else
    {
      /* read command from keyboard */
      result = os_gets(buf, bufl); //###length
    }
    setmore(1);

    if (!result)
    {
	/* at eof - return an error */
        return(1);
    }
    else
    {
	/* write input to log and command files if appropriate */
        if (logfp) fprintf(logfp, "%s\n", buf); //###indep
        if (cmdfile) fprintf(cmdfile, ">%s\n", buf); //###indep
        return(0);
    }
}
