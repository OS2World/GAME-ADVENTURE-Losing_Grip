#ifdef RCSID
static char RCSid[] =
"$Header: c:/tads/tads2/RCS/OUT.C 1.5 94/11/06 13:07:28 mroberts Exp $";
#endif

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  out.c - output formatter
Function
  Formats output text:  word wrap, etc.
Notes
  None
Modified
  10/27/91 MJRoberts     - creation
*/

#include <string.h>
#include "os.h"
#include "tio.h"

void outfmt(ctx, txt)
tiocxdef *ctx;
char     *txt;
{
    char   buf[128];
    int    len;
    int    bufrem;
    char  *p;

    VARUSED(ctx);
    
    len = osrp2(txt) - 2;
    txt += 2;

    while (len)
    {
	/* buffer up some text, keeping '\' sequences intact */
	for (p = buf, bufrem = sizeof(buf) - 2 ; bufrem > 2 && len ; )
	{
	    /* if this is a '\' sequence, copy two bytes */
	    if (*txt == '\\' && len >= 2)
	    {
		*p++ = *txt++;
		--len;
		--bufrem;
	    }
	    
	    /* copy the current byte */
	    *p++ = *txt++;
	    --len;
	    --bufrem;
	}
	
	/* we've reached the end of the buffer; send it out */
	*p = '\0';
	tioputs(ctx, buf);
    }
}

