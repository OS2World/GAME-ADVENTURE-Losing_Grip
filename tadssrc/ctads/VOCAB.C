#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/vocab.c 1.7 96/10/14 16:10:51 mroberts Exp $";
#endif

/* Copyright (c) 1987-1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  vocab  - TADS run-time player command parser
Function
  Player command parser
Notes
  This version of the parser is for TADS 2.0.
Returns
  0 for success, 1 for failure
Modified
  03/11/92 MJRoberts     - TADS 2.0
  11/20/91 MJRoberts     - fix isVisible operation
  11/02/91 MJRoberts     - fix strObj.value problem
  08/13/91 MJRoberts     - add him/her support
  08/12/91 MJRoberts     - make strObj.value an RSTRING (preprsfn arg, too)
  08/08/91 MJRoberts     - add preprsfn (preparse function)
  04/12/91 MJRoberts     - check abortcmd: if true, skip rest of cmd line
  03/10/91 MJRoberts     - moved getstring() to getstr.c for modularity,
                           pick up John's qa-scripter mods
  06/28/89 MJRoberts     - call rtreset() before pardonfn invocations
  11/04/88 MJRoberts     - fix "it" and "them"
  10/30/88 MJRoberts     - new "version 6" game/parser interface
  12/27/87 MJRoberts     - created
*/

#include <stdio.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#include "err.h"
#include "voc.h"
#include "tio.h"
#include "mcm.h"
#include "obj.h"
#include "prp.h"
#include "run.h"


/* SRG: Added prototype to remove compiler warning */
static int has_gen_num_adj();

/* the extra off-stack stack */
char *voc_stk_ptr;
char *voc_stk_cur;
char *voc_stk_end;


/* word type flags */
#define VOCT_ARTICLE 1
#define VOCT_ADJ     2
#define VOCT_NOUN    4
#define VOCT_PREP    8
#define VOCT_VERB    16
#define VOCT_SPEC    32             /* special words - "of", ",", ".", etc. */
#define VOCT_PLURAL  64

static char *type_names[] =
{
    "article", "adj", "noun", "prep", "verb", "special", "plural"
};

/* array of flag values for words by part of speech */
static int voctype[] =
{ 0, 0, VOCT_VERB, VOCT_NOUN, VOCT_ADJ, VOCT_PREP, VOCT_ARTICLE };

/*
 *   read a command from the keyboard, doing all necessary
 *   output flushing and prompting.
 */
void vocread(ctx, buf, bufl, type)
voccxdef *ctx;
char     *buf;
int       bufl;
int       type;
{
    char *prompt;
    
    /* make sure output capturing is off */
    tiocapture(ctx->voccxtio, (mcmcxdef *)0, FALSE);
    tioclrcapture(ctx->voccxtio);
	    
    if (ctx->voccxprom != MCMONINV)
    {
	/*runrst(ctx->voccxrun);*/
	runpnum(ctx->voccxrun, (long)type);
	runfn(ctx->voccxrun, ctx->voccxprom, 1);
	tioflushn(ctx->voccxtio, 0);
	prompt = "";
    }
    else
    {
	tioblank(tio);
	prompt = ">";
    }

    tiogets(ctx->voccxtio, prompt, buf, bufl);
    if (!strcmp(buf, "$$ABEND")) exit(2);
}

/*
 *   Compare a pair of words, truncated to six characters or the
 *   length of the first word, whichever is longer.  (The first word is
 *   the user's entry, the second is the reference word in the dictionary.)
 *   Returns TRUE if the words match, FALSE otherwise.
 */
static int voceq(s1, l1, s2, l2)
char *s1;
uint  l1;
char *s2;
uint  l2;
{
    int i;

    if (l1 == 0 && l2 == 0)  return(TRUE);           /* both NULL - a match */
    if (l1 == 0 || l2 == 0)  return(FALSE);  /* one NULL only - not a match */
    if (l1 >= 6 && l2 >= l1) l2 = l1;
    if (l1 != l2)            return(FALSE);                /* ==> not equal */
    for (i = 0 ; i < l1 ; i++)
        if (*s1++ != *s2++)  return(FALSE);
    return(TRUE);                                          /* strings match */
}

/* find the next word in a search */
vocwdef *vocfnw(voccx, search_ctx)
voccxdef  *voccx;
vocseadef *search_ctx;
{
    vocdef  *v, *vf;
    vocwdef *vw, *vwf;
    vocdef  *c = search_ctx->v;
    int      first;

    /* continue with current word's vocwdef list if anything is left */
    first = TRUE;
    vw = vocwget(voccx, search_ctx->vw->vocwnxt);
    for (v = c, vf = (vocdef *)0 ; v ; v = v->vocnxt, first = FALSE)
    {
	/* if this word matches, look at the objects in its list */
        if (first
	    || (voceq(c->voctxt, c->voclen, v->voctxt, v->voclen)
		&& voceq(c->voctxt + c->voclen, c->vocln2,
			 v->voctxt + v->voclen, v->vocln2)
		&& (!vf || v->voclen < vf->voclen)))
	{
	    /*
	     *   on the first time through, vw has already been set up
	     *   with the next vocwdef in the current list; on subsequent
	     *   times through the loop, start at the head of the current
	     *   word's list 
	     */
	    if (!first) vw = vocwget(voccx, v->vocwlst);

	    /* search the list from vw forward */
	    for ( ; vw ; vw = vocwget(voccx, vw->vocwnxt))
	    {
		if (search_ctx->vw->vocwtyp == vw->vocwtyp
		    && !(vw->vocwflg & VOCFCLASS)
		    && !(vw->vocwflg & VOCFDEL))
		{
		    /*
		     *   remember the first vocdef that we found, and
		     *   remember this, the first matching vocwdef; then
		     *   break out of the vocwdef search and continue
		     *   looking for a better word text fit 
		     */
		    vf = v;
		    vwf = vw;
		    break;
		}
	    }
	}
    }

    /* return the first vocwdef in this word's list */
    search_ctx->v = vf;
    search_ctx->vw = (vf ? vwf : 0);
    return(search_ctx->vw);
}

/* find the first vocdef matching a set of words */
vocwdef *vocffw(ctx, wrd, len, wrd2, len2, p, search_ctx)
voccxdef  *ctx;
char      *wrd;                                         /* word to be found */
int        len;                                     /* length of the string */
char      *wrd2;                                     /* second word, if any */
int        len2;             /* length of second word (0 if no second word) */
int        p;                        /* part of speech (as property number) */
vocseadef *search_ctx;      /* caller-provided context area for next search */
{
    uint     hshval;
    vocdef  *v, *vf;
    vocwdef *vw, *vwf;
    
    hshval = vochsh(wrd, len);
    for (v = ctx->voccxhsh[hshval], vf = 0 ; v ; v = v->vocnxt)
    {
	if (voceq(wrd, len, v->voctxt, v->voclen)
	    && voceq(wrd2, len2, v->voctxt + v->voclen, v->vocln2)
	    && (!vf || v->voclen < vf->voclen))
	{
	    /* look for a suitable object in the vocwdef list */
	    for (vw = vocwget(ctx, v->vocwlst) ; vw ;
		 vw = vocwget(ctx, vw->vocwnxt))
	    {
		if (vw->vocwtyp == p && !(vw->vocwflg & VOCFCLASS)
		    && !(vw->vocwflg & VOCFDEL))
		{
		    /*
		     *   remember the first vocdef that we found, and
		     *   remember this, the first matching vocwdef; then
		     *   break out of the vocwdef search and continue
		     *   looking for a better word text fit 
		     */
		    vf = v;
		    vwf = vw;
		    break;
		}
	    }
	}
    }

    /* set up the caller-provided search structure for next time */
    vw = (vf ? vwf : 0);
    if (search_ctx)
    {
	search_ctx->v = vf;
	search_ctx->vw = vw;
    }
    return(vw);
}

/* display a parser error */
#ifdef LINT
void vocerr(voccxdef *ctx, int err, char *f, ...)
{
    long a1=0, a2=0, a3=0;
#else /* LINT */
void vocerr(ctx, err, f, a1, a2, a3)
voccxdef *ctx;
int       err;
char     *f;
long      a1, a2, a3;
{
#endif /* LINT */

    char  errbuf[400];
    char *p = errbuf;
    
    /* if the user has a parseError function, see if it provides a msg */
    if (ctx->voccxper != MCMONINV)
    {
        runcxdef *rcx = ctx->voccxrun;
        dattyp    typ;
        size_t    len;
        
        /*runrst(rcx);*/
        runpstr(rcx, f, (int)strlen(f), 0);         /* 2nd arg: default msg */
        runpnum(rcx, (long)err);                   /* 1st arg: error number */
        runfn(rcx, ctx->voccxper, 2);                   /* run parseError() */
        
        typ = runtostyp(rcx);
        if (typ == DAT_SSTRING)
        {
            p = runpopstr(rcx);
            len = osrp2(p) - 2;
            p += 2;
            if (len > sizeof(errbuf) - 1) len = sizeof(errbuf) - 1;
            memcpy(errbuf, p, len);
            errbuf[len] = '\0';

            /* format string is returned string, outbuf follows in errbuf */
            f = errbuf;
            p = errbuf + len + 1;
        }
        else rundisc(rcx);
    }

    (void)tioshow(ctx->voccxtio);
    sprintf(p, f, a1, a2, a3);
    tioputs(ctx->voccxtio, p);
}

/* determine if a tokenized word is a special internal word flag */
/* int vocisspec(char *wrd); */
#define vocisspec(wrd) \
   (vocisupper(*wrd) || (!vocisalpha(*wrd) && *wrd != '\'' && *wrd != '-'))

static vocspdef vocsptab[] =
{
    { "of",     VOCW_OF   },
    { "and",    VOCW_AND  },
    { "then",   VOCW_THEN },
    { "all",    VOCW_ALL  },
    { "everyt", VOCW_ALL  },
    { "both",   VOCW_BOTH },
    { "but",    VOCW_BUT  },
    { "except", VOCW_BUT  },
    { "one",    VOCW_ONE  },
    { "ones",   VOCW_ONES },
    { "it",     VOCW_IT   },
    { "them",   VOCW_THEM },
    { "him",    VOCW_HIM  },
    { "her",    VOCW_HER  },
    { "any",    VOCW_ANY  },
    { "either", VOCW_ANY  },
    { 0,        0         }
};

#ifdef NEVER
/*
 *   Remove the special-word flag from a word - restores the word to its
 *   original value as typed in by the player.  Note that this is a bit
 *   fragile, as it's dependent on the exact specialWords storage
 *   mechanism -- if that changes, this code will need to change as well.  
 */
static void voc_un_special(ctx, wrd, typelist, special_id, part_of_speech)
voccxdef *ctx;
char     *wrd;
int      *typelist;
int       part_of_speech;
{
    if (ctx->voccxspp)
    {
	char *p;
	char *endp;
	int   len;

	/* get the length of the word to make sure we get the right one */
	len = strlen(wrd);

	/* skip the requisite number of special words */
	p = ctx->voccxspp;
	endp = p + ctx->voccxspl;
	for ( ; p < endp && *p != special_id ; p += *(p+1) + 2);

	/*
	 *   go through those until we find one that matches except for
	 *   the first character (which is what we're restoring 
	 */
	for ( ; p < endp && *p == special_id ; p += *(p+1) + 2)
	{
	    if (*(p+1) == len
		&& (len == 1 || !memcmp(wrd+1, p+3, (size_t)(len-1))))
	    {
		/* got it - restore the original first letter */
		wrd[0] = *(p+2);
		break;
	    }
	}
    }
    else
    {
	int i;
	
	/* find the built-in special word with the given ID */
	for (i = 0 ; i < sizeof(vocsptab)/sizeof(vocsptab[0]) ; ++i)
	{
	    if (vocsptab[i].vocspout == special_id)
	    {
		/* found it - restore the first letter */
		wrd[0] = vocsptab[i].vocspin[0];
		break;
	    }
	}
    }

    /* restore part of speech */
    *typelist = part_of_speech;
}
#endif /* NEVER */

/* test a word to see if it's a particular special word */
static int voc_check_special(ctx, wrd, checktyp)
voccxdef *ctx;
char     *wrd;
int       checktyp;
{
    /* search the user or built-in special table, as appropriate */
    if (ctx->voccxspp)
    {
	char *p;
	char *endp;
	char  typ;
	int   len;
	int   wrdlen = strlen(wrd);
	
	for (p = ctx->voccxspp, endp = p + ctx->voccxspl ;
	     p < endp ; )
	{
	    typ = *p++;
	    len = *p++;

	    /* if this word matches in type and text, we have a match */
	    if (typ == checktyp
		&& len == wrdlen && !memcmp(p, wrd, (size_t)len))
		return TRUE;

	    /* no match - keep going */
	    p += len;
	}
    }
    else
    {
	vocspdef *x;
	
	for (x = vocsptab ; x->vocspin ; ++x)
	{
	    /* if it matches in type and text, we have a match */
	    if (x->vocspout == checktyp
		&& !strncmp(wrd, x->vocspin, (size_t)6))
		return TRUE;
	}
    }

    /* didn't find a match for the text and type */
    return FALSE;
}


/* tokenize a command line - returns number of words in command */
int voctok(ctx, cmd, outbuf, wrd, lower, cvt_ones)
voccxdef *ctx;
uchar    *cmd;                                       /* command to break up */
uchar    *outbuf;                        /* buffer for separating the words */
uchar    *wrd[];                            /* pointers to individual words */
int       lower;                      /* flag: lowercase words only if true */
int       cvt_ones;        /* flag: treat 'one' and 'ones' as special words */
{
    int       i;
    vocspdef *x;
    int       l;
    char     *p;
    uchar    *w;
    int       len;

    for (i = 0 ;; )
    {
        while (vocisspace(*cmd)) cmd++;
        if (!*cmd)
        {
            wrd[i] = outbuf;
            *outbuf = '\0';
            return(i);
        }

        wrd[i++] = outbuf;
        if (vocisalpha(*cmd) || *cmd == '\'' || *cmd == '-')
        {
            while(vocisalpha(*cmd) || vocisdigit(*cmd) ||
                  *cmd=='\'' || *cmd=='-')
            {
                *outbuf++ = (vocisupper(*cmd) && lower) ? tolower(*cmd) : *cmd;
                ++cmd;
            }
            
            /*
             *   Check for a special case:  abbreviations that end in a
             *   period.  For example, "Mr. Patrick J. Wayne."  We wish
             *   to absorb the period after "Mr" and the one after "J"
             *   into the respective words; we detect this condition by
             *   actually trying to find a word in the dictionary that
             *   has the period.
             */
            w = wrd[i-1];
            len = outbuf - w;
            if (*cmd == '.')
            {
                *outbuf++ = *cmd++;           /* add the period to the word */
                *outbuf = '\0';                        /* null-terminate it */
                ++len;
                if (!vocffw(ctx, w, len, (char *)0, 0, PRP_NOUN,
			    (vocseadef *)0)
                    && !vocffw(ctx, w, len, (char *)0, 0, PRP_ADJ,
			       (vocseadef *)0))
                {
                    /* no word with period in dictionary - remove period */
                    --outbuf;
                    --cmd;
                    --len;
                }
            }

            /* null-terminate the buffer */
            *outbuf = '\0';

            /* find compound words and glue them together */
            for (p = ctx->voccxcpp, l = ctx->voccxcpl ; l ; )
            {
                int   l1 = osrp2(p);
                char *p2 = p + l1;                       /* get second word */
                int   l2 = osrp2(p2);
                char *p3 = p2 + l2;                    /* get compound word */
                int   l3 = osrp2(p3);
                
                if (i > 1 && len == (l2 - 2)
                    && !memcmp(w, p2 + 2, (size_t)len)
                    && strlen((char*)wrd[i-2]) == (l1 - 2) //###cast
                    && !memcmp(wrd[i-2], p + 2, (size_t)(l1 - 2)))
                {
                    memcpy(wrd[i-2], p3 + 2, (size_t)(l3 - 2));
                    *(wrd[i-2] + l3 - 2) = '\0';
                    --i;
                    break;
                }

                /* move on to the next word */
                l -= l1 + l2 + l3;
                p = p3 + l3;
            }

            /*
	     *   Find any special keywords, and set to appropriate flag
	     *   char.  Note that we no longer convert "of" in this
	     *   fashion; "of" is now handled separately in order to
	     *   facilitate its use as an ordinary preposition. 
	     */
	    if (ctx->voccxspp)
	    {
		char *p;
		char *endp;
		char  typ;
		int   len;
		int   wrdlen = strlen((char*)wrd[i-1]); //###cast
		
		for (p = ctx->voccxspp, endp = p + ctx->voccxspl ;
		     p < endp ; )
		{
		    typ = *p++;
		    len = *p++;
		    if (len == wrdlen && !memcmp(p, wrd[i-1], (size_t)len)
			&& (cvt_ones || (typ != VOCW_ONE && typ != VOCW_ONES))
			&& typ != VOCW_OF)
		    {
			*wrd[i-1] = typ;
			*(wrd[i-1] + 1) = '\0';
			break;
		    }
		    p += len;
		}
	    }
	    else
	    {
		for (x = vocsptab ; x->vocspin ; ++x)
		{
		    if (!strncmp((char*)wrd[i-1], x->vocspin, (size_t)6) //###cast
			&& (cvt_ones ||
			    (x->vocspout != VOCW_ONE
			     && x->vocspout != VOCW_ONES))
			&& x->vocspout != VOCW_OF)
		    {
			*wrd[i-1] = x->vocspout;
			*(wrd[i-1] + 1) = '\0';
			break;
		    }
		}
	    }

            /* make sure the output pointer is fixed up to the right spot */
            outbuf = wrd[i-1];
            outbuf += strlen((char*)outbuf); //###cast
        }
        else if (vocisdigit( *cmd ))
        {
            while(vocisdigit(*cmd) || vocisalpha(*cmd)
		  || *cmd == '\'' || *cmd == '-')
                *outbuf++ = *cmd++;
        }
        else switch( *cmd )
        {
        case '.':
        case '!':
        case '?':
        case ';':
            *outbuf++ = VOCW_THEN;
            ++cmd;
            break;
        case ',':
        case ':':
            *outbuf++ = VOCW_AND;
            ++cmd;
            break;
        case '"':
            {
                uchar *lenptr;
                
                *outbuf++ = *cmd++;
                lenptr = outbuf;              /* remember where length goes */
                outbuf += 2;
                while (*cmd && *cmd != '"') *outbuf++ = *cmd++;
                oswp2(lenptr, ((int)(outbuf - lenptr)));
                if (*cmd == '"') cmd++;
                break;
            }
        default:
            vocerr(ctx, 1, "I don't understand the punctuation \"%c\".",
                   *cmd);
            return( -1 );
        }
        *outbuf++ = '\0';
    }
}

/*
 *   figure out what parts of speech are associated with each
 *   word in a tokenized command list
 */
int vocgtyp(ctx, cmd, types, orgbuf)
voccxdef *ctx;
char     *cmd[];                        /* array of tokenized command words */
int       types[];                                 /* output area for types */
char     *orgbuf;                                /* original command buffer */
{
    int      cur;
    int      t;
    vocdef  *v;
    vocwdef *vw;
    char    *p;
    int      len;
    
startover:
    if (ctx->voccxflg & VOCCXFDBG)
	tioputs(ctx->vocxtio, ". Checking words:\\n");

    for (cur = 0 ; cmd[cur] ; ++cur)
    {
        p = cmd[cur];
        len = strlen(p);
        
        if (vocisspec(p))
        {
            t = VOCT_SPEC;
        }
        else
        {
            /*
             *   Now check the various entries of this word to get the
             *   word type flag bits.  The Noun and Adjective flags can
             *   be set for any word which matches this word in the first
             *   six letters (or more if more were provided by the player),
             *   but the Plural flag can only be set if the plural word
             *   matches exactly.  Note that this pass only matches the
             *   first word in two-word verbs; the second word is
             *   considered later during the semantic analysis.
             */
            for (t = 0, v = ctx->voccxhsh[vochsh(p, len)] ; v ; v = v->vocnxt)
            {
                if (voceq(p, len, v->voctxt, v->voclen))
                {
		    /* we have a match - look through relation list for word */
		    for (vw = vocwget(ctx, v->vocwlst) ; vw ;
			 vw = vocwget(ctx, vw->vocwnxt))
		    {
			/* skip this word if it's been deleted */
			if (vw->vocwflg & VOCFDEL)
			    continue;

			if (vw->vocwtyp == PRP_PLURAL)
			{
			    /* plurals must be exact (non-truncated) match */
			    if (len == v->voclen)
				t |= (VOCT_NOUN | VOCT_PLURAL);
			}
			else
			    t |= voctype[vw->vocwtyp];
		    }
                }
            }
        }

        /* if the word isn't found, provide a chance to "oops" it */
        if (!t && !voc_check_special(ctx, p, VOCW_OF))
        {
            char  oopsbuf[128];
            char *p1;

            /* flag an error, and ask for a new command */
            vocerr(ctx, 2, "I don't know the word \"%s\".", p);
            vocread(ctx, oopsbuf, (int)sizeof(oopsbuf), 1);

            /* capitalize and scan off leading spaces */
            for (p1 = oopsbuf ; *p1 ; ++p1)
                *p1 = (vocisupper(*p1) ? tolower(*p1) : *p1);
            for (p1 = oopsbuf ; vocisspace(*p1) ; ++p1);

            /* see if they are saying "oops" */
            if ((strlen(p1) > 5 && !memcmp(p1, "oops ", 5))
		|| (strlen(p1) > 2 && !memcmp(p1, "o ", 2)))
            {
                char   redobuf[200];
                char  *q;
                int    i;
                int    wc;
                char **w;
                char  *outp;
                
                /* copy words up to unknown word */
                for (outp = redobuf, i = 0, w = cmd ; i < cur ; ++i, ++w)
                {
                    len = strlen(*w);
                    memcpy(outp, *w, (size_t)len);
                    outp += len;
                    *outp++ = ' ';
                }

                /* find word after "oops" and replace unknown word with it */
		while (*p1 && !vocisspace(*p1)) ++p1;
		while (vocisspace(*p1)) ++p1;
                for (q = p1, len = 0 ; *q && (vocisalpha(*q) || vocisdigit(*q)
                     || *q == '\'' || *q == '-' ) ; ++q, ++len);
                memcpy(outp, p1, (size_t)len);
                outp += len;
                *outp++ = ' ';

                /* copy remaining words */
                for (++w ; *w ; ++w)
                {
                    len = strlen(*w);
                    memcpy(outp, *w, (size_t)len);
                    outp += len;
                    *outp++ = ' ';
                }
                *outp = '\0';

                /* try tokenizing the string, then start over with typing */
                *(cmd[0]) = '\0';
                if ((wc = voctok(ctx, redobuf, cmd[0], cmd,
				 FALSE, FALSE)) <= 0)
                    return(1);
                cmd[wc] = 0;
                goto startover;
            }
            else
            {
                strcpy(orgbuf, oopsbuf);
                ctx->voccxredo = 1;
                return(1);
            }
	}

	/* display if in debug mode */
	if (ctx->voccxflg & VOCCXFDBG)
	{
	    char  buf[128];
	    int   i;
	    char *p;
	    int   cnt;
	    
	    (void)tioshow(ctx->voccxtio);
	    sprintf(buf, "... %s (", cmd[cur]);
	    p = buf + strlen(buf);
	    cnt = 0;
	    for (i = 0 ; i < sizeof(type_names)/sizeof(type_names[0]) ; ++i)
	    {
		if (t & (1 << i))
		{
		    if (cnt) *p++ = ',';
		    strcpy(p, type_names[i]);
		    p += strlen(p);
		    ++cnt;
		}
	    }
	    *p++ = ')';
	    *p++ = '\\';
	    *p++ = 'n';
	    *p = '\0';
	    tioputs(ctx->voccxtio, buf);
	}
        
        types[cur] = t;                         /* record type of this word */
    }
    
    return(0);                           /* successful acquisition of types */
}

/*
 *   intersect - takes two lists and puts the intersection of them into
 *   the first list.
 */
static int vocisect(list1, list2)
objnum *list1;
objnum *list2;
{
    int i, j, k;

    for (i = k = 0 ; list1[i] != MCMONINV ; ++i)
    {
        for (j = 0 ; list2[j] != MCMONINV ; ++j)
        {
            if (list1[i] == list2[j])
            {
                list1[k++] = list1[i];
                break;
            }
        }
    }
    list1[k] = MCMONINV;
    return(k);
}

/*
 *   Intersect lists, including parallel flags lists.  The flags from the
 *   two lists for any matching object are OR'd together. 
 */
static int vocisect_flags(list1, flags1, list2, flags2)
objnum *list1;
char   *flags1;
objnum *list2;
char   *flags2;
{
    int i, j, k;

    for (i = k = 0 ; list1[i] != MCMONINV ; ++i)
    {
        for (j = 0 ; list2[j] != MCMONINV ; ++j)
        {
            if (list1[i] == list2[j])
            {
                list1[k] = list1[i];
		flags1[k] = flags1[i] | flags2[j];
	        ++k;
                break;
            }
        }
    }
    list1[k] = MCMONINV;
    return(k);
}

/*
 *   get obj list: build a list of the objects that are associated with a
 *   given word of player input.
 */
static int vocgol(ctx, list, plurals, wrd, typ, first, cur, last, ofword)
voccxdef *ctx;
objnum   *list;
char     *plurals;
char     *wrd;
int       typ;
int       first;
int       cur;
int       last;
int       ofword;
{
    vocwdef   *v;
    int        l;
    int        len = strlen(wrd);
    vocseadef  search_ctx;
    int        try_plural;
    int        wrdtyp;

    /*
     *   get word type: figure out the correct part of speech, given by
     *   context, for a given word.  If it could count as only a
     *   noun/plural or only an adjective, we use that.  If it could count
     *   as either a noun/plural or an adjective, we will treat it as a
     *   noun/plural if it is the last word in the name or the last word
     *   before "of", otherwise as an adjective.  
     */
    try_plural = (typ & VOCT_PLURAL);

    if ((typ & (VOCT_NOUN | VOCT_PLURAL)) && (typ & VOCT_ADJ))
    {
        if (cur + 1 == last || cur == ofword - 1)
            wrdtyp = ((typ & VOCT_NOUN) ? PRP_NOUN : PRP_PLURAL);
        else
            wrdtyp = PRP_ADJ;
    }
    else if (typ & VOCT_NOUN)
        wrdtyp = PRP_NOUN;
    else
        wrdtyp = PRP_ADJ;

    if (ctx->voccxflg & VOCCXFDBG)
    {
	char buf[128];

	sprintf(buf, "... %s (treating as %s%s)\\n", wrd,
		(wrdtyp == PRP_ADJ ? "adjective" :
		 wrdtyp == PRP_NOUN ? "noun" : "plural"),
		(wrdtyp == PRP_NOUN && try_plural ? " + plural" : ""));
	tioputs(ctx->vocxtio, buf);
    }

    l = 0;
add_words:
    for (v = vocffw(ctx, wrd, len, (char *)0, 0, wrdtyp, &search_ctx)
         ; v ; v = vocfnw(ctx, &search_ctx))
    {
        list[l] = v->vocwobj;
	plurals[l] = (wrdtyp == PRP_PLURAL);
	++l;

        if (l >= VOCMAXAMBIG)
        {
            vocerr(ctx, 3, "The word \"%s\" refers to too many objects.",
                   wrd);
            list[ 0 ] = MCMONINV;
            return(0);
        }
    }

    /*
     *   if we're interpreting the word as a noun, and the word can be a
     *   plural, add in the plural interpretation as well 
     */
    if (try_plural && wrdtyp == PRP_NOUN)
    {
	wrdtyp = PRP_PLURAL;
	goto add_words;
    }

    /*
     *   If we're interpreting the word as an adjective, and it's
     *   numeric, include objects with "#" in their adjective list --
     *   these objects allow arbitrary numbers as adjectives.  Don't do
     *   this if there's only the one word.  
     */
    if (vocisdigit(wrd[0]) && wrdtyp == PRP_ADJ && first + 1 != last)
    {
	wrd = "#";
	len = 1;
	goto add_words;
    }

    list[l] = MCMONINV;
    return(l);
}

/*
 *   Add the user-defined word for "of" to a buffer.  If no such word is
 *   defined by the user (with the specialWords construct), add "of".  
 */
static void vocaddof(ctx, buf)
voccxdef *ctx;
char     *buf;
{
    if (ctx->voccxspp)
    {
	size_t len = ctx->voccxspp[1];
	size_t oldlen = strlen(buf);
	memcpy(buf + oldlen, ctx->voccxspp + 2, len);
	buf[len + oldlen] = '\0';
    }
    else
	strcat(buf, "of");
}

/*
 *   get 1 obj - attempts to figure out the limits of a single noun phrase.
 *   Aside from dealing with special words here ("all", "it", "them",
 *   string objects, numeric objects), we will accept a basic noun phrase
 *   of the form [article][adjective*][noun]["of" [noun-phrase]].  (Note
 *   that this is not actually recursive; only one "of" can occur in a
 *   noun phrase.)  If successful, we will construct a list of all objects
 *   that have all the adjectives and nouns in the noun phrase.  Note that
 *   plurals are treated basically like nouns, except that we will flag
 *   them so that the disambiguator knows to include all objects that work
 *   with the plural.
 *
 *   Note that we also allow the special constructs "all [of] <noun-phrase>"
 *   and "both [of] <noun-phrase>"; these are treated identically to normal
 *   plurals.
 */
static int vocg1o(ctx, cmd, typelist, cur, next, complain, nounlist, chkact)
voccxdef *ctx;
char     *cmd[];
int       typelist[];
int       cur;
int      *next;
int       complain; /* 0 ==> no complaints; 1==>all complaints; 2==>special */
vocoldef *nounlist;
int       chkact;
{
    int     l1;
    int     firstwrd;
    int     i;
    int     ofword = -1;
    int     outcnt = 0;
    objnum *list1;
    char   *plural1;
    objnum *list2;
    char   *plural2;
    char   *namebuf;
    int     has_any = FALSE;
    char   *save_sp;
    int     found_plural;
    int     trying_count = FALSE;
    int     retry_with_count;

    voc_enter(&save_sp);
    VOC_MAX_ARRAY(ctx, objnum, list1);
    VOC_MAX_ARRAY(ctx, char,   plural1);
    VOC_MAX_ARRAY(ctx, objnum, list2);
    VOC_MAX_ARRAY(ctx, char,   plural2);
    VOC_STK_ARRAY(ctx, char,   namebuf, VOCBUFSIZ);

    *next = cur;
    if (cur == -1 || !cmd[cur]) { VOC_RETVAL(save_sp, 0); }

    if (ctx->voccxflg & VOCCXFDBG)
	tioputs(ctx->vocxtio,
		chkact ? ". Checking for actor\\n"
		: ". Reading noun phrase\\n");

    /* check for a quoted string */
    if (*cmd[cur] == '"')
    {
	/* can't use a quoted string as an actor */
	if (chkact) { VOC_RETVAL(save_sp, 0); }
	
	if (ctx->voccxflg & VOCCXFDBG)
	    tioputs(ctx->vocxtio, "... found quoted string\\n");

        nounlist[outcnt].vocolobj = MCMONINV;
        nounlist[outcnt].vocolflg = VOCS_STR;
        nounlist[outcnt].vocolfst = nounlist[outcnt].vocollst = cmd[cur];
        *next = ++cur;
	++outcnt;
	VOC_RETVAL(save_sp, outcnt);
    }

    /* check for ALL/ANY/BOTH/EITHER [OF] <plural> contruction */
    if ((vocspec(cmd[cur], VOCW_ALL)
	 || vocspec(cmd[cur], VOCW_BOTH)
	 || vocspec(cmd[cur], VOCW_ANY)) &&
	cmd[cur+1] != (char *)0)
    {
        int nxt;
        int n = cur+1;
	int has_of;

	/* can't use ALL as an actor */
	if (chkact) { VOC_RETVAL(save_sp, 0); }

	/* remember whether we have "any" or "either" */
	has_any = vocspec(cmd[cur], VOCW_ANY);

        /* check for optional 'of' */
	if (voc_check_special(ctx, cmd[n], VOCW_OF))
        {
	    if (ctx->voccxflg & VOCCXFDBG)
		tioputs(ctx->vocxtio, "... found ALL/ANY/BOTH/EITHER OF\\n");

	    has_of = TRUE;
            n++;
            if (!cmd[n])
            {
                char *p;
                int   ver;
                
                if (vocspec(cmd[cur], VOCW_ALL))
                {
                    ver = 4;
                    p = "I think you left something out after \"all of\".";
                }
                else if (vocspec(cmd[cur], VOCW_ANY))
		{
		    ver = 29;
		    p = "I think you left something out after \"any of\".";
		}
		else
                {
                    ver = 5;
                    p = "There's something missing after \"both of\".";
                }
                vocerr(ctx, ver, p);
		VOC_RETVAL(save_sp, -1);
            }
        }
	else
	    has_of = FALSE;

        nxt = n;
        if (typelist[n] & VOCT_ARTICLE) ++n;        /* skip leading article */
        for ( ;; )
        {
            if (!cmd[n])
                break;

	    if (voc_check_special(ctx, cmd[n], VOCW_OF))
            {
                ++n;
                if (!cmd[n])
                {
                    vocerr(ctx, 6, "I expected a noun after \"of\".");
		    VOC_RETVAL(save_sp, -1);
                }
                if (*cmd[n] & VOCT_ARTICLE) ++n;
            }
            else if (typelist[n] & (VOCT_ADJ | VOCT_NOUN))
                ++n;
            else
                break;
        }

	/*
	 *   Accept the ALL if the last word is a plural.  Accept the ANY
	 *   if either we don't have an OF (ANY NOUN is okay even without
	 *   a plural), or if we have OF and a plural.  (More simply put,
	 *   accept the ALL or ANY if the last word is a plural, or if we
	 *   have ANY but not OF).  
	 */
        if (n > cur && ((typelist[n-1] & VOCT_PLURAL)
			|| (has_any && !has_of)))
        {
	    if (ctx->voccxflg & VOCCXFDBG)
		tioputs(ctx->vocxtio,
			"... found ALL/ANY/BOTH/EITHER + noun phrase\\n");

            cur = nxt;
	}
    }
    
    if (vocspec(cmd[cur], VOCW_ALL) && !has_any)
    {
	/* can't use ALL as an actor */
	if (chkact)
	{
	    VOC_RETVAL(save_sp, -1);
	}
	
	if (ctx->voccxflg & VOCCXFDBG)
	    tioputs(ctx->vocxtio, "... found ALL\\n");

        nounlist[outcnt].vocolobj = MCMONINV;
        nounlist[outcnt].vocolflg = VOCS_ALL;
        nounlist[outcnt].vocolfst = nounlist[outcnt].vocollst = cmd[cur];
        ++outcnt;
        ++cur;

        if (cmd[cur] && vocspec(cmd[cur], VOCW_BUT))
        {
            int       cnt;
            int       i;
            vocoldef *xlist;
	    char     *save_sp;

	    if (ctx->voccxflg & VOCCXFDBG)
		tioputs(ctx->vocxtio, "... found ALL EXCEPT\\n");

	    voc_enter(&save_sp);
	    VOC_MAX_ARRAY(ctx, vocoldef, xlist);

            cur++;
            cnt = vocgobj(ctx, cmd, typelist, cur, next, complain, xlist, 1, 
                          chkact);
            if (cnt < 0) { VOC_RETVAL(save_sp, cnt); }
            cur = *next;
            for (i = 0 ; i < cnt ; ++i)
            {
                OSCPYSTRUCT(nounlist[outcnt], xlist[i]);
                nounlist[outcnt].vocolflg |= VOCS_EXCEPT;
                ++outcnt;
            }

	    voc_leave(save_sp);
        }
        *next = cur;
        nounlist[outcnt].vocolobj = MCMONINV;
        nounlist[outcnt].vocolflg = 0;
	VOC_RETVAL(save_sp, outcnt);
    }
    
    switch(*cmd[cur])
    {
    case VOCW_IT:
        nounlist[outcnt].vocolflg = VOCS_IT;
        goto do_special;
    case VOCW_THEM:
        nounlist[outcnt].vocolflg = VOCS_THEM;
        goto do_special;
    case VOCW_HIM:
        nounlist[outcnt].vocolflg = VOCS_HIM;
        goto do_special;
    case VOCW_HER:
        nounlist[outcnt].vocolflg = VOCS_HER;
        /* FALLTHRU */
    do_special:
	if (ctx->voccxflg & VOCCXFDBG)
	    tioputs(ctx->vocxtio, "... found pronoun\\n");

        *next = cur + 1;
        nounlist[outcnt].vocolobj = MCMONINV;
	++outcnt;
	VOC_RETVAL(save_sp, outcnt);
    default:
        break;
    }

    if (((typelist[cur] & (VOCT_ARTICLE | VOCT_ADJ | VOCT_NOUN)) == 0)
        && !vocisdigit(*cmd[cur]))
    {
	VOC_RETVAL(save_sp, 0);
    }

    if (typelist[cur] & VOCT_ARTICLE)
    {
        ++cur;
        if (cmd[cur] == (char *)0
            || ((typelist[cur] & (VOCT_ADJ | VOCT_NOUN)) == 0
                && !vocisdigit(*cmd[cur])))
        {
            vocerr(ctx, 7, "An article must be followed by a noun.");
            *next = cur;
	    VOC_RETVAL(save_sp, -1);
        }
    }

    firstwrd = cur;

    for (found_plural = FALSE, l1 = 0 ; ; )
    {
        if (cmd[cur] == (char *)0)
            break;

        if (typelist[cur] & VOCT_ADJ)
            ++cur;
        else if (typelist[cur] & VOCT_NOUN)
        {
            ++cur;
            if (cmd[cur] == (char *)0) break;
            if (vocisdigit(*cmd[cur])) ++cur;
            if (cmd[cur] == (char *)0) break;
	    if (!voc_check_special(ctx, cmd[cur], VOCW_OF)) break;
        }
        else if (vocisdigit(*cmd[cur]))
            ++cur;
	else if (voc_check_special(ctx, cmd[cur], VOCW_OF))
        {
            ++cur;
            if (ofword != -1)
	    {
		/* there's already one 'of' - we must be done */
		--cur;
		break;
#ifdef NEVER
                vocerr(ctx, 8, "You used \"of\" too many times.");
                *next = cur;
		VOC_RETVAL(save_sp, -1);
#endif
            }
            ofword = cur-1;
            if (typelist[cur] & VOCT_ARTICLE)   /* allow article after "of" */
                ++cur;
        }
        else
            break;

	/* note whether we found anything that might be a plural */
	/*
	 * UNIX:  This fixes a bug where the plural check would
	 *        run off the end of the list of words and read
	 *        random memory.  -- dmb
	 */
	if (cmd[cur] &&	(typelist[cur] & VOCT_PLURAL))
	    found_plural = TRUE;
    }

#ifdef NEVER
    /*
     *   If we have just one word, and it's a number, remove it from
     *   consideration as a non-numeric object.  
     */
    if (cur == firstwrd+1 && vocisdigit(*cmd[firstwrd]))
    {
	nounlist[outcnt].vocolobj = MCMONINV;
	nounlist[outcnt].vocolflg = VOCS_NUM;
	nounlist[outcnt].vocolfst = nounlist[outcnt].vocollst = cmd[firstwrd];
	*next = firstwrd + 1;
	++outcnt;
	VOC_RETVAL(save_sp, outcnt);
    }
#endif /* NEVER */

try_again:
    for (i = firstwrd, namebuf[0] = '\0' ; i < cur ; ++i)
    {
	if (voc_check_special(ctx, cmd[i], VOCW_OF))
	    vocaddof(ctx, namebuf);
        else
            strcat(namebuf, cmd[i]);
        if (cmd[i][strlen(cmd[i])-1] == '.') strcat(namebuf, "\\");

        if (i + 1 < cur)
            strcat(namebuf, " ");
    }

    *next = cur;

    l1 = vocgol(ctx, list1, plural1, cmd[firstwrd],
                typelist[firstwrd], firstwrd, firstwrd, cur, ofword);

    /*
     *   Allow retrying with a count plus a plural if the first word is a
     *   number, and we have something plural in the list.  Only treat "1"
     *   this way if more words follow in the noun phrase.  
     */
    retry_with_count = ((vocisdigit(*cmd[firstwrd]) && found_plural)
			|| (vocisdigit(*cmd[firstwrd])
			    && cur != firstwrd+1
			    && atoi(cmd[firstwrd]) == 1));

    /* see if we found anything on the first word */
    if (l1 == 0)
    {
        if (chkact) { VOC_RETVAL(save_sp, 0); }

        if (vocisdigit(*cmd[firstwrd]))
        {
	    if (retry_with_count)
	    {
		/* interpret it as a count plus a plural */
		trying_count = TRUE;

		/* don't try this again */
	        retry_with_count = FALSE;
	    }
	    else
	    {
		/* not a plural - take the number as the entire noun phrase */
		nounlist[outcnt].vocolobj = MCMONINV;
		nounlist[outcnt].vocolflg = VOCS_NUM;
		nounlist[outcnt].vocolfst = nounlist[outcnt].vocollst =
		    cmd[firstwrd];
		*next = firstwrd + 1;
		++outcnt;
		VOC_RETVAL(save_sp, outcnt);
	    }
	}
        else
        {
            vocerr(ctx, 9, "I don't see any %s here.", namebuf);
	    VOC_RETVAL(save_sp, -1);
        }
    }

retry_exclude_first:
    for (i = firstwrd + 1 ; i < cur ; ++i)
    {
	int l2;
	
	if (voc_check_special(ctx, cmd[i], VOCW_OF)
            || (typelist[i] & VOCT_ARTICLE))
            continue;
        
        l2 = vocgol(ctx, list2, plural2, cmd[i],
		    typelist[i], firstwrd, i, cur, ofword);

	/*
	 *   Intersect the last list with the new list.  If the previous
	 *   list didn't have anything in it, it must mean that the word
	 *   list started with a number, in which case we're trying to
	 *   interpret this as a count plus a plural.  So, don't intersect
	 *   the list if there was nothing in the first list. 
	 */
	if (l1 == 0)
	{
	    /* just copy the new list */
	    l1 = l2;
	    memcpy(list1, list2, (size_t)((l1+1) * sizeof(list1[0])));
	    memcpy(plural1, plural2, (size_t)(l1 * sizeof(plural1[0])));
	}	
	else
	{
	    /* intersect the two lists */
	    l1 = vocisect_flags(list1, plural1, list2, plural2);
	}

	/*
	 *   If there's nothing in the list, it means that there's no
	 *   object that defines all of these words.  
	 */
        if (l1 == 0)
        {
	    if (ctx->voccxflg & VOCCXFDBG)
		tioputs(ctx->vocxtio,
			"... can't find any objects matching these words\\n");
	    /*
	     *   If there's an "of", remove the "of" and everything that
	     *   follows, and go back and reprocess the part up to the
	     *   "of" -- treat it as a sentence that has two objects, with
	     *   "of" as the preposition introducing the indirect object.
	     */
	    if (ofword != -1)
	    {
		if (ctx->voccxflg & VOCCXFDBG)
		    tioputs(ctx->vocxtio,
			    "... dropping the part after OF and retrying\\n");

		cur = ofword;
		goto try_again;
	    }

	    /*
	     *   Try again with the count + plural interpretation, if
	     *   possible 
	     */
	    if (retry_with_count)
	    {
		if (ctx->voccxflg & VOCCXFDBG)
		    tioputs(ctx->vocxtio,
			 "... treating the number as a count and retrying\\n");

		/* we've exhausted our retries */
		retry_with_count = FALSE;
		trying_count = TRUE;

		/* go try it */
		goto retry_exclude_first;
	    }

	    /*
	     *   If one of the words will work as a preposition, and we
	     *   took it as an adjective, go back and try the word again
	     *   as a preposition.  
	     */
	    for (i = cur - 1; i > firstwrd ; --i)
	    {
		if (typelist[i] & VOCT_PREP)
		{
		    if (ctx->voccxflg & VOCCXFDBG)
			tioputs(ctx->vocxtio,
				"... changing word to prep and retrying\\n");
		    cur = i;
		    goto try_again;
		}
	    }

	    /* if just checking actor, don't display an error */
            if (chkact) { VOC_RETVAL(save_sp, 0); }

	    /* tell the player about it, and return an error */
            vocerr(ctx, 9, "I don't see any %s here.", namebuf);
            VOC_RETVAL(save_sp, -1);
        }
    }

    /*
     *   We have one or more objects, so make a note of how we found
     *   them.
     */
    if (ctx->voccxflg & VOCCXFDBG)
	tioputs(ctx->vocxtio, "... found objects matching vocabulary:\\n");

    for (i = 0 ; i < l1 ; ++i)
    {
	if (ctx->voccxflg & VOCCXFDBG)
	{
	    tioputs(ctx->voccxtio, "..... ");
	    runppr(ctx->voccxrun, list1[i], PRP_SDESC, 0);
	    tioflushn(ctx->voccxtio, 1);
	}

        nounlist[outcnt].vocolfst = cmd[firstwrd];
        nounlist[outcnt].vocollst  = cmd[cur-1];
        nounlist[outcnt].vocolflg = (plural1[i] ? VOCS_PLURAL : 0)
	    + (trying_count ? VOCS_COUNT : 0);
	if (has_any) nounlist[outcnt].vocolflg |= VOCS_ANY;
        nounlist[outcnt++].vocolobj = list1[i];
        if (outcnt > VOCMAXAMBIG)
        {
            vocerr(ctx, 10,
                   "You're referring to too many objects with \"%s\".",
                   namebuf);
	    VOC_RETVAL(save_sp, -2);
        }
    }
    nounlist[outcnt].vocolobj = MCMONINV;
    nounlist[outcnt].vocolflg = 0;
    VOC_RETVAL(save_sp, outcnt);
}

/*
 *   get obj - gets one or more noun lists (a flag, "multi", says whether we
 *   should allow multiple lists).  We use vocg1o() to read noun lists one
 *   at a time, and keep going (if "multi" is true) as long as there are more
 *   "and <noun-phrase>" clauses.
 */
int vocgobj(ctx, cmd, typelist, cur, next, complain, nounlist,
            multi, chkact)
voccxdef *ctx;
char     *cmd[];
int       typelist[];
int       cur;
int      *next;
int       complain;
vocoldef *nounlist;
int       multi;
int       chkact;
{
    int       cnt;
    int       outcnt = 0;
    int       i;
    int       again = FALSE;
    int       lastcur;
    vocoldef *tmplist;
    char     *save_sp;

    voc_enter(&save_sp);
    VOC_MAX_ARRAY(ctx, vocoldef, tmplist);

    for ( ;; )
    {
        cnt = vocg1o(ctx, cmd, typelist, cur, next, complain,
                       tmplist, chkact);
        if (cnt < 0) { VOC_RETVAL(save_sp, cnt); }
        if (cnt > 0)
        {
            for (i = 0 ; i < cnt ; ++i)
            {
                OSCPYSTRUCT(nounlist[outcnt], tmplist[i]);
                if (++outcnt > VOCMAXAMBIG)
                {
                    vocerr(ctx, 11, "You're referring to too many objects.");
                    VOC_RETVAL(save_sp, -1);
                }
            }
        }
        if (cnt == 0)
        {
            if (again)
                *next = lastcur;
            break;
        }
        if (!multi) break;

        cur = *next;
        if (cur != -1 && cmd[cur] && vocspec(cmd[cur], VOCW_AND))
        {
            lastcur = cur;
            while (cmd[cur] && vocspec(cmd[cur], VOCW_AND)) ++cur;
            again = TRUE;
            if (complain) complain = 2;
        }
        else
            break;
    }
    nounlist[outcnt].vocolobj = MCMONINV;
    nounlist[outcnt].vocolflg = 0;
    VOC_RETVAL(save_sp, outcnt);
}

/*
 *   This routine gets an actor, which is just a single object reference at
 *   the beginning of a sentence.  We return 0 if we fail to find an actor;
 *   since this can be either a harmless or troublesome condition, we must
 *   return additional information.  The method used to return back ERROR/OK
 *   is to set *next != cur if there is an error, *next == cur if not.  So,
 *   getting back (objdef*)0 means that you should check *next.  If the return
 *   value is nonzero, then that object is the actor.
 */
static objnum vocgetactor(ctx, cmd, typelist, cur, next, cmdbuf)
voccxdef *ctx;
char     *cmd[];
int       typelist[];
int       cur;
int      *next;
char     *cmdbuf;                                /* original command buffer */
{
    int       l;
    vocoldef *nounlist;
    vocoldef *actlist;
    int       cnt;
    char     *save_sp;
    prpnum    valprop, verprop;

    voc_enter(&save_sp);
    VOC_MAX_ARRAY(ctx, vocoldef, nounlist);
    VOC_MAX_ARRAY(ctx, vocoldef, actlist);
    
    *next = cur;                              /* assume no error will occur */
    cnt = vocchknoun(ctx, cmd, typelist, cur, next, nounlist, TRUE);
    if (cnt > 0 && *next != -1 && cmd[*next] && vocspec(cmd[*next], VOCW_AND))
    {
	/*
	 *   if validActor is defined for any of the actors, use it;
	 *   otherwise, for compatibility with past versions, use the
	 *   takeVerb disambiguation mechanism 
	 */
	verprop = PRP_VERACTOR;
	if (objgetap(ctx->voccxmem, nounlist[0].vocolobj, PRP_VALIDACTOR,
		     (objnum *)0, FALSE))
	    valprop = PRP_VALIDACTOR;
	else
	    valprop = PRP_VALIDDO;
	
	/* disambiguate it using the selected properties */
        if (vocdisambig(ctx, actlist, nounlist, PRP_DODEFAULT,
			valprop, verprop, cmd, MCMONINV,
			ctx->voccxme, ctx->voccxvtk, MCMONINV, MCMONINV,
			cmdbuf, 0))
	{
	    VOC_RETVAL(save_sp, MCMONINV);
	}

        if ((l = voclistlen(actlist)) > 1)
        {
            vocerr(ctx, 12, "You can only speak to one person at a time.");
            *next = cur + 1;   /* error flag - return invalid but next!=cur */
	    VOC_RETVAL(save_sp, MCMONINV);
        }
        else if (l == 0) return(MCMONINV);

        if (cmd[*next] && vocspec(cmd[*next], VOCW_AND))
        {
            ++(*next);
	    VOC_RETVAL(save_sp, actlist[0].vocolobj);
        }
    }
    if (cnt < 0) 
        *next = cur + 1;                       /* error - make *next != cur */
    else
        *next = cur;               /* no error condition, but nothing found */

    VOC_RETVAL(save_sp, MCMONINV);    /* so return invalid and *next == cur */
}

/* figure out how many objects are in an object list */
int voclistlen( lst )
vocoldef *lst;
{
    int i;
    
    for (i = 0 ; lst->vocolobj != MCMONINV || lst->vocolflg != 0 ;
         ++lst, ++i);
    return(i);
}

/*
 *   check access - evaluates cmdVerb.verprop(actor, obj, seqno), and
 *   returns whatever it returns.  The seqno parameter is used for special
 *   cases, such as "ask", when the validation routine wishes to return
 *   "true" on the first object and "nil" on all subsequent objects which
 *   correspond to a particular noun phrase.  We expect to be called with
 *   seqno==0 on the first object, non-zero on others; we will pass
 *   seqno==1 on the first object to the validation property, higher on
 *   subsequent objects, to maintain consistency with the TADS language
 *   convention of indexing from 1 up (as seen by the user in indexing
 *   functions).  Note that if we're checking an actor, we'll just call
 *   obj.validActor() for the object itself (not the verb).
 */
int vocchkaccess(ctx, obj, verprop, seqno, cmdActor, cmdVerb)
voccxdef *ctx;
objnum    obj;
prpnum    verprop;
int       seqno;
objnum    cmdActor;
objnum    cmdVerb;
{
    /*runrst(ctx->voccxrun);*/
    if (verprop == PRP_VALIDACTOR)
    {
	/* call ValidActor in the object itself */
	runppr(ctx->voccxrun, obj, verprop, 0);
    }
    else
    {
	/* call ValidXo in the verb */
	runpnum(ctx->voccxrun, (long)(seqno + 1));
	runpobj(ctx->voccxrun, obj);
	runpobj(ctx->voccxrun, cmdActor == MCMONINV ? ctx->voccxme : cmdActor);
	runppr(ctx->voccxrun, cmdVerb, verprop, 3);
    }
    return runpoplog(ctx->voccxrun);
}

/* ask game if object is visible to the actor */
static int vocchkvis(ctx, obj, cmdActor)
voccxdef *ctx;
objnum    obj;
objnum    cmdActor;
{
    /*runrst(ctx->voccxrun);*/
    runpobj(ctx->voccxrun, cmdActor == MCMONINV ? ctx->voccxme : cmdActor);
    runppr(ctx->voccxrun, obj, PRP_ISVIS, 1);
    return(runpoplog(ctx->voccxrun));
}

/* set {numObj | strObj}.value, as appropriate */
void vocsetobj(ctx, obj, typ, val, inobj, outobj)
voccxdef *ctx;
objnum    obj;
dattyp    typ;
dvoid    *val;
vocoldef *inobj;
vocoldef *outobj;
{
    *outobj = *inobj;
    outobj->vocolobj = obj;
    objsetp(ctx->voccxmem, obj, PRP_VALUE, typ, val, ctx->voccxundo);
}

/* set up a vocoldef */
static void vocout(outobj, obj, flg, fst, lst)
vocoldef *outobj;
objnum    obj;
int       flg;
char     *fst;
char     *lst;
{
    outobj->vocolobj = obj;
    outobj->vocolflg = flg;
    outobj->vocolfst = fst;
    outobj->vocollst = lst;
}

/*
 *   Generate an appropriate error message saying that the objects in the
 *   command are visible, but can't be used with the command for some
 *   reason.  Use the cantReach method of the verb (the new way), or if
 *   there is no cantReach in the verb, of each object in the list. 
 */
static void vocnoreach(ctx, list1, cnt, actor, verb, prep, defprop)
voccxdef *ctx;
objnum   *list1;
int       cnt;
objnum    actor;
objnum    verb;
objnum    prep;
prpnum    defprop;
{
    uchar   *objlst;
    uint     objlstsiz;
    uchar   *p;
    int      i;
    runsdef  val;
    
    /* see if the verb has a cantReach method - use it if so */
    if (objgetap(ctx->voccxmem, verb, PRP_NOREACH, (objnum *)0, FALSE))
    {
	/* allocate a list for the objects */
	objlstsiz = 2 + cnt*3;
	runrst(ctx->voccxrun);
	runhres(ctx->voccxrun, objlstsiz, 0);
	objlst = ctx->voccxrun->runcxhp;
	oswp2(objlst, objlstsiz);

	/* build the list */
	for (i = 0, p = objlst + 2 ; i < cnt ; ++i)
	{
	    *p++ = DAT_OBJECT;
	    oswp2(p, list1[i]);
	    p += 2;
	}

	/* set heap top pointer past used space */
	ctx->voccxrun->runcxhp = p;

	/* build value structure for pushing onto stack */
	val.runstyp = DAT_LIST;
	val.runsv.runsvstr = (char*)objlst; //###cast

	/* push arguments:  (actor, dolist, iolist, prep) */
	runpobj(ctx->voccxrun, prep);
	if (defprop == PRP_DODEFAULT)
	{
	    runpnil(ctx->voccxrun);
	    runpush(ctx->voccxrun, DAT_LIST, &val);
	}
	else
	{
	    runpush(ctx->voccxrun, DAT_LIST, &val);
	    runpnil(ctx->voccxrun);
	}
	runpobj(ctx->voccxrun, actor);

	/* invoke the method in the verb */
	runppr(ctx->voccxrun, verb, PRP_NOREACH, 4);
    }
    else
    {
	/* use the old way - call obj.cantReach() for each object */
	for (i = 0 ; i < cnt ; ++i)
	{
	    if (cnt > 1)
	    {
		runrst(ctx->voccxrun);
		runppr(ctx->voccxrun, list1[i], PRP_SDESC, 0);
		vocerr(ctx, 200, ": ");
	    }
	    runrst(ctx->voccxrun);
	    runpobj(ctx->voccxrun,
		    actor == MCMONINV ? ctx->voccxme : actor);
	    runppr(ctx->voccxrun, list1[i], PRP_NOREACH, 1);
	    tioflush(ctx->voccxtio);
	}
    }
}

/* set it/him/her */
static int vocsetit(ctx, obj, accprop, actor, verb, prep, outobj, name, type,
		    defprop)
voccxdef *ctx;
objnum    obj;               /* value of "it", "him", "her", as appropriate */
int       accprop;                              /* access-checking property */
objnum    actor;                                           /* current actor */
objnum    verb;                                             /* current verb */
objnum    prep;
vocoldef *outobj;                           /* output vocoldef to be set up */
char     *name;                      /* name of object ("it", "him", "her") */
char      type;
prpnum    defprop;
{
    char        nambuf[40];
    
    if (obj == MCMONINV || !vocchkaccess(ctx, obj, accprop, 0, actor, verb))
    {
	int found = FALSE;

	if (ctx->voccxspp)
	{
	    char   *p;
	    char   *endp;
	    size_t  len;
	    
	    /* find appropriate user-defined word in specialWords list */
	    for (p = ctx->voccxspp, endp = p + ctx->voccxspl ;
	         p < endp ; )
	    {
		if (*p++ == type)
		{
		    found = TRUE;
		    len = *p++;
		    if (len + 1 > sizeof(nambuf)) len = sizeof(nambuf) - 1;
		    memcpy(nambuf, p, len);
		    nambuf[len] = '\0';
		    break;
		}
		p += *p + 1;
	    }
	}
	if (!found)
	{
	    strncpy(nambuf, name, (size_t)sizeof(nambuf));
	    nambuf[sizeof(nambuf) - 1] = '\0';
	}

	if (obj == MCMONINV)
	    vocerr(ctx, 13, "I don't know what you're referring to with '%s'.",
		   nambuf);
	else
	    vocnoreach(ctx, &obj, 1, actor, verb, prep, defprop);

        return(1);
    }
    
    vocout(outobj, obj, 0, name, name);
    return(0);
}

/*
 *   Get a new numbered object, given a number.  This is used for objects
 *   that define '#' as one of their adjectives; we call the object,
 *   asking it to create an object with a particular number.  The object
 *   can return nil, in which case we'll reject the command.  
 */
static objnum voc_new_num_obj(ctx, objn, actor, verb, num, plural)
voccxdef *ctx;
objnum    objn;
objnum    actor;
objnum    verb;
long      num;
int       plural;
{
    /* push the number - if we need a plural object, use nil instead */
    if (plural)
	runpnil(ctx->voccxrun);
    else
	runpnum(ctx->voccxrun, num);

    /* push the other arguments and call the method */
    runpobj(ctx->voccxrun, verb);
    runpobj(ctx->voccxrun, actor);
    runppr(ctx->voccxrun, objn, PRP_NEWNUMOBJ, 3);

    /* if it was rejected, return an invalid object, else return the object */
    if (runtostyp(ctx->voccxrun) == DAT_NIL)
    {
	rundisc(ctx->voccxrun);
	return MCMONINV;
    }
    else
	return runpopobj(ctx->voccxrun);
}

/*
 *   vocdisambig - determines which nouns in a noun list apply.  When this
 *   is called, we must know the verb that we are processing, so we delay
 *   disambiguation until quite late in the parsing of a sentence, opting
 *   to keep all relevant information around until such time as we can
 *   meaningfully disambiguate.
 *
 *   This routine resolves any "all [except...]", "it", and "them"
 *   references.  We determine if all of the objects listed are accessible
 *   (via verb.validDo, verb.validIo).  We finally try to determine which
 *   nouns apply when there are ambiguous nouns by using do.verDo<Verb>
 *   and io.verIo<Verb>.
 */
int vocdisambig(ctx, outlist, inlist, defprop, accprop, verprop, cmd,
                otherobj, cmdActor, cmdVerb, cmdPrep, cmdIobj,
		cmdbuf, tplflags)
voccxdef *ctx;
vocoldef *outlist;                                /* output list of objects */
vocoldef *inlist;                                  /* input list of objects */
prpnum    defprop;                       /* property to use to get defaults */
prpnum    accprop;                       /* property to use to check access */
prpnum    verprop;                  /* property to use to verify usefulness */
char     *cmd[];                         /* original user command word list */
objnum    otherobj;   /* indirect object if a call to verDo<Verb> is needed */
objnum    cmdActor;                             /* actor object for command */
objnum    cmdVerb;                                      /* verb for command */
objnum    cmdPrep;                                            /* prepositio */
objnum    cmdIobj;                                       /* indirect object */
char     *cmdbuf;                                /* original command buffer */
int       tplflags;                                       /* template flags */
{
    int       inpos;
    int       outpos;
    int       listlen = voclistlen(inlist);
    char     *disnewbuf;
    char     *disbuffer;
    char    **diswordlist;
    int      *distypelist;
    vocoldef *disnounlist;
    int       noreach = FALSE;
    prpnum    listprop;
    char     *save_sp;
    vocoldef *exclist;
    vocoldef *exclist2;
    objnum   *list1;
    char     *plural1;
    objnum   *list2;
    char     *plural2;
    objnum   *list3;
    char     *plural3;
    objnum   *list4;
    char     *plural4;
    char     *usrobj;
    uchar    *lstbuf;

    voc_enter(&save_sp);
    VOC_MAX_ARRAY(ctx, vocoldef, disnounlist);
    VOC_MAX_ARRAY(ctx, vocoldef, exclist);
    VOC_MAX_ARRAY(ctx, vocoldef, exclist2);
    VOC_MAX_ARRAY(ctx, objnum,   list1);
    VOC_MAX_ARRAY(ctx, objnum,   list2);
    VOC_MAX_ARRAY(ctx, objnum,   list3);
    VOC_MAX_ARRAY(ctx, objnum,   list4);
    VOC_MAX_ARRAY(ctx, char,     plural1);
    VOC_MAX_ARRAY(ctx, char,     plural2);
    VOC_MAX_ARRAY(ctx, char,     plural3);
    VOC_MAX_ARRAY(ctx, char,     plural4);
    VOC_STK_ARRAY(ctx, char,     disnewbuf,   VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     disbuffer,   2*VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char *,   diswordlist, VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, int,      distypelist, VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     usrobj,      VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, uchar,    lstbuf,      2 + VOCMAXAMBIG*3);

    memset(distypelist, 0, VOCBUFSIZ * sizeof(distypelist));

    for (inpos = outpos = 0 ; inpos < listlen ; ++inpos)
    {
        if (inlist[inpos].vocolflg == VOCS_STR)
        {
            vocsetobj(ctx, ctx->voccxstr, DAT_SSTRING,
                      inlist[inpos].vocolfst + 1,
		      &inlist[inpos], &outlist[outpos]);
	    ++outpos;
        }
        else if (inlist[inpos].vocolflg == VOCS_NUM)
        {
            long v1;
            long v2;
            
            v1 = atol(inlist[inpos].vocolfst);
            oswp4(&v2, v1);
            vocsetobj(ctx, ctx->voccxnum, DAT_NUMBER, &v2,
		      &inlist[inpos], &outlist[outpos]);
	    ++outpos;
        }
        else if (inlist[inpos].vocolflg == VOCS_IT ||
                 (inlist[inpos].vocolflg == VOCS_THEM && ctx->voccxthc == 0))
        {
            if (vocsetit(ctx, ctx->voccxit, accprop, cmdActor,
                         cmdVerb, cmdPrep, &outlist[outpos],
			 inlist[inpos].vocolflg == VOCS_IT ? "it" : "them",
		     inlist[inpos].vocolflg == VOCS_IT ? VOCW_IT : VOCW_THEM,
			 defprop))
	    {
		VOC_RETVAL(save_sp, 1);
	    }
            ++outpos;
        }
        else if (inlist[inpos].vocolflg == VOCS_HIM)
        {
            if (vocsetit(ctx, ctx->voccxhim, accprop, cmdActor, cmdVerb,
                         cmdPrep, &outlist[outpos], "him", VOCW_HIM, defprop))
	    {
		VOC_RETVAL(save_sp, 1);
	    }
            ++outpos;
        }
        else if (inlist[inpos].vocolflg == VOCS_HER)
        {
            if (vocsetit(ctx, ctx->voccxher, accprop, cmdActor, cmdVerb,
                         cmdPrep, &outlist[outpos], "her", VOCW_HER, defprop))
	    {
		VOC_RETVAL(save_sp, 1);
	    }
            ++outpos;
        }
        else if (inlist[inpos].vocolflg == VOCS_THEM)
        {
            int i;
            int thempos = outpos;
	    static char them_name[] = "them";

            for (i = 0 ; i < ctx->voccxthc ; ++i)
            {
                if (outpos >= VOCMAXAMBIG)
                {
                    vocerr(ctx, 11, "You're referring to too many objects.");
		    VOC_RETVAL(save_sp, 1);
                }
                
                /* add object only if it's still accessible */
                if (vocchkaccess(ctx, ctx->voccxthm[i], accprop, 0,
                                 cmdActor, cmdVerb))
                    vocout(&outlist[outpos++], ctx->voccxthm[i], VOCS_THEM,
                           them_name, them_name);
		else
		{
		    voc_multi_prefix(ctx, ctx->voccxthm[i]);
		    vocnoreach(ctx, &ctx->voccxthm[i], 1, cmdActor, cmdVerb,
			       cmdPrep, defprop);
		    tioflush(ctx->voccxtio);
		}
            }
            
            /* make sure we found at least one acceptable object  */
            if (outpos == thempos)
            {
                vocerr(ctx, 14, "I don't know what you're referring to.");
		VOC_RETVAL(save_sp, 1);
            }
        }
        else if (inlist[inpos].vocolflg == VOCS_ALL)
        {
            uchar    *l;
            int       exccnt = 0;
            int       allpos = outpos;
            int       excpos;
            int       k;
            uint      len;
	    static    char all_name[] = "all";

            /*runrst(ctx->voccxrun);*/
	    if (defprop != PRP_IODEFAULT)
		runpobj(ctx->voccxrun, otherobj);
            runpobj(ctx->voccxrun, cmdPrep);
            runpobj(ctx->voccxrun, cmdActor);
            runppr(ctx->voccxrun, cmdVerb, defprop,
		   defprop == PRP_DODEFAULT ? 3 : 2);
            
            if (runtostyp(ctx->voccxrun) == DAT_LIST)
            {
                l = runpoplst(ctx->voccxrun);
                len = osrp2(l) - 2;
                l += 2;
                
                while (len)
                {
                    /* add list element to output if it's an object */
                    if (*l == DAT_OBJECT)
                        vocout(&outlist[outpos++], osrp2(l+1), 0,
                               all_name, all_name);

                    /* move on to next list element */
		    lstadv(&l, &len);
                }
                
                vocout(&outlist[outpos], MCMONINV, 0, (char *)0, (char *)0);
            }
            else
                rundisc(ctx->voccxrun);           /* discard non-list value */

            /* if we didn't get anything, complain about it and quit */
            if (outpos <= allpos)
            {
                vocerr(ctx, 15, "I don't see what you're referring to.");
		VOC_RETVAL(save_sp, 1);
            }

            /* remove any items in "except" list */
            excpos = inpos + 1;
            while (inlist[inpos + 1].vocolflg & VOCS_EXCEPT)
            {
                OSCPYSTRUCT(exclist[exccnt], inlist[++inpos]);
                exclist[exccnt++].vocolflg &= ~VOCS_EXCEPT;
            }
            exclist[exccnt].vocolobj = MCMONINV;
            exclist[exccnt].vocolflg = 0;

            /* disambiguate "except" list */
            if (exccnt)
            {
                if (vocdisambig(ctx, exclist2, exclist, defprop, accprop,
                                verprop, &cmd[excpos], otherobj, cmdActor,
                                cmdVerb, cmdPrep, cmdIobj, cmdbuf, tplflags))
		{
		    VOC_RETVAL(save_sp, 1);
		}

                exccnt = voclistlen(exclist2);
                for (k = 0 ; k < exccnt ; ++k)
                {
                    int i;
                    for (i = allpos ; i < outpos ; ++i)
                    {
                        if (outlist[i].vocolobj == exclist2[k].vocolobj)
                        {
                            int j;
                            for (j = i ; j < outpos ; ++j)
                                outlist[j].vocolobj = outlist[j+1].vocolobj;
                            --i;
                            --outpos;
                            if (outpos <= allpos)
                            {
                                vocerr(ctx,  15,
                                    "I don't see what you're referring to.");
				VOC_RETVAL(save_sp, 1);
                            }
                        }
                    }
                }
	    }
	}
        else                         /* we have a (possibly ambiguous) noun */
        {
            int       lpos = inpos;
            int       i=0;
            int       cnt;
            char     *p;
            int       cnt2, cnt3, cnt4;
	    int       all_plural;
	    int       trying_again;
	    int       user_count = 0;
	    objnum   *cantreach_list;

            while (inlist[lpos].vocolfst == inlist[inpos].vocolfst
                   && lpos < listlen)
	    {
                list1[i] = inlist[lpos].vocolobj;
		plural1[i] = inlist[lpos].vocolflg
		    & (VOCS_PLURAL | VOCS_ANY | VOCS_COUNT);
                ++i;

		/* if there's a user count, note it */
		if (inlist[lpos].vocolflg & VOCS_COUNT)
		    user_count = atoi(inlist[lpos].vocolfst);

		/* move on to the next entry */
		++lpos;
	    }
            list1[i] = MCMONINV;
            cnt = i;
	    
	    /*
	     *   Use a new method to cut down on the time it will take to
	     *   iterate through the verprop's on all of those words.
	     *   We'll call the verb's validXoList method - it should
	     *   return a list containing all of the valid objects for the
	     *   verb (it's sort of a Fourier transform of validDo).
	     *   We'll intersect that list with the list we're about to
	     *   disambiguate, which should provide a list of objects that
	     *   are already qualified, in that validDo should return true
	     *   for every one of them.  
	     * 
	     *   The calling sequence is:
	     *       verb.validXoList(actor, prep, otherobj)
	     * 
	     *   For reverse compatibility, if the return value is nil,
	     *   we use the old algorithm and consider all objects
	     *   that match the vocabulary.  The return value must be
	     *   a list to be considered.
	     *
	     *   If disambiguating the actor, skip this phase, since
	     *   we don't have a verb yet.
	     */
            if (accprop != PRP_VALIDACTOR)
	    {
		if (defprop == PRP_DODEFAULT)
		    listprop = PRP_VALDOLIST;
		else
		    listprop = PRP_VALIOLIST;
		
		/* push the arguments:  the actor, prep, and other object */
		runpobj(ctx->voccxrun, otherobj);
		runpobj(ctx->voccxrun, cmdPrep);
		runpobj(ctx->voccxrun, cmdActor);
		runppr(ctx->voccxrun, cmdVerb, listprop, 3);
		if (runtostyp(ctx->voccxrun) == DAT_LIST)
		{
		    uchar *l;
		    uint   len;
		    
		    l = runpoplst(ctx->voccxrun);
		    len = osrp2(l) - 2;
		    l += 2;
		    
		    /*
		     *   For each element of the return value, see if
		     *   it's in list1.  If so, copy the object into
		     *   list2, unless it's already in list2.  
		     */
		    for (cnt2 = 0 ; len ; )
		    {
			
			if (*l == DAT_OBJECT)
			{
			    objnum o = osrp2(l+1);
			    
			    for (i = 0 ; i < cnt ; ++i)
			    {
				if (list1[i] == o)
				{
				    int j;
				    
				    /* check to see if o is already in list2 */
				    for (j = 0 ; j < cnt2 ; ++j)
					if (list2[j] == o) break;
				    
				    /* if o is not in list2 yet, add it */
				    if (j == cnt2)
				    {
					list2[cnt2] = o;
					plural2[cnt2] = plural1[i];
					++cnt2;
				    }
				    break;
				}
			    }
			}
			
			/* move on to next element */
			lstadv(&l, &len);
		    }
		    
		    /* copy list2 into list1 */
		    memcpy(list1, list2, (size_t)(cnt2 * sizeof(list1[0])));
		    memcpy(plural1, plural2, (size_t)cnt2);
		    cnt = cnt2;
		    list1[cnt] = MCMONINV;
		}
		else
		    rundisc(ctx->voccxrun);
	    }

            /*
             *   Submit each object to the accprop and verprop routines.
             *   Objects that check out with accprop are put into list3;
             *   those that check out with verprop too are put into list2.
             *   If there's anything in list2, we'll take those items,
             *   because they're better qualified (having been through
             *   the tougher check), but if there's nothing in list2, we'll
             *   use anything in list3 instead.
             */
            for (cnt2 = cnt3 = cnt4 = i = 0 ; list1[i] != MCMONINV ; ++i)
            {
                if (vocchkvis(ctx, list1[i], cmdActor))
		{
                    list4[cnt4] = list1[i];
		    plural4[cnt4] = plural1[i];
		    ++cnt4;
		}
                
                if (vocchkaccess(ctx, list1[i], accprop, i,
                                 cmdActor, cmdVerb))
                {
		    /* it checks out with accprop - put it in list3 */
		    list3[cnt3] = list1[i];
		    plural3[cnt3] = plural1[i];
		    ++cnt3;

		    /* run it by the appropriate sensible-object check */
		    if (accprop == PRP_VALIDACTOR)
		    {
			/* run it through preferredActor */
			runppr(ctx->voccxrun, list1[i], PRP_PREFACTOR, 0);
			if (runpoplog(ctx->voccxrun))
			{
			    list2[cnt2] = list1[i];
			    plural2[cnt2] = plural1[i];
			    ++cnt2;
			}
		    }
		    else
		    {
			/* run it through verXoVerb */
			tiohide(ctx->voccxtio);
			/*runrst(ctx->voccxrun);*/
			if (otherobj != MCMONINV)
			    runpobj(ctx->voccxrun, otherobj);
			runpobj(ctx->voccxrun, cmdActor);
			runppr(ctx->voccxrun, list1[i], verprop,
			       (otherobj != MCMONINV ? 2 : 1));
			
			/*
			 *   If that didn't result in a message, this
			 *   object passed the tougher test of ver?oX, so
			 *   include it in list2.  
			 */
			if (!tioshow(ctx->voccxtio))
			{
			    list2[cnt2] = list1[i];
			    plural2[cnt2] = plural1[i];
			    ++cnt2;
			}
		    }
                }
            }

            /*
             *   Construct a string consisting of the words the user typed
             *   to reference this object, in case we need to complain.
             */
            usrobj[0] = '\0';
            if (inlist[inpos].vocolfst && inlist[inpos].vocollst)
            {
                for (p = inlist[inpos].vocolfst ; p <= inlist[inpos].vocollst
                     ; p += strlen(p) + 1)
                {
		    if (voc_check_special(ctx, p, VOCW_OF))
			vocaddof(ctx, usrobj);
                    else
                        strcat(usrobj, p);
                    if (p[strlen(p)-1] == '.') strcat(usrobj, "\\");
                    strcat(usrobj, " ");
                }
            }

            /*
             *   Check if we found anything in either the YES or MAYBE lists.
             *   If there's nothing in either list, complain and return.
             *   If we have just a single number (no other nouns), act as
             *   though this was a VOCS_NUM and continue.
             */
            if (!cnt2 && !cnt3)
            {
                if (inlist[inpos].vocolfst
                    && inlist[inpos].vocolfst == inlist[inpos].vocollst
                    && vocisdigit(*inlist[inpos].vocolfst))
                {
                    long  v1;
                    long  v2;
                    
                    v1 = atol(inlist[inpos].vocolfst);
                    oswp4(&v2, v1);
                    vocsetobj(ctx, ctx->voccxnum, DAT_NUMBER, &v2,
                              &inlist[inpos], &outlist[outpos]);
		    outlist[outpos].vocolflg = VOCS_NUM;
		    ++outpos;

		    /* skip all objects that matched the number */
		    for ( ; inlist[inpos+1].vocolobj != MCMONINV
			 && inlist[inpos+1].vocolfst == inlist[inpos].vocolfst
			 ; ++inpos);
                    continue;
                }

                if (cnt4)
                {
		    cnt = cnt4;
		    cantreach_list = list4;
                    noreach = TRUE;
#ifdef NEVER
                    if (cnt4 == 1)
                        goto noreach1;
                    else
                        goto disnoreach;
#endif /* NEVER */
		    /* give the cantReach message, even for multiple objects */
		    goto noreach1;
                }
                else
                {
                    vocerr(ctx, 9, "I don't see any %s here.", usrobj);
		    VOC_RETVAL(save_sp, 1);
                }
            }

            /*
             *   If nothing passed the stronger test (objects passing which
             *   are in list2), use those passing the weaker test (in list3).
             */
            if (cnt2 == 0)
            {
		cnt2 = cnt3;
		memcpy(list2, list3, (size_t)(cnt2 * sizeof(list2[0])));
		memcpy(plural2, plural3, (size_t)cnt2);
            }

	    /* check for all plurals */
	    if (plural2[0])
	    {
		int i;
		
		for (all_plural = VOCS_PLURAL | VOCS_ANY | VOCS_COUNT, i = 0
		     ; i < cnt2 ; ++i)
		{
		    all_plural &= plural2[i];
		    if (!all_plural) break;
		}
	    }
	    else
		all_plural = FALSE;

            /*
	     *   If we found only 1 word, or a plural/ANY, we are
	     *   finished.  If we found a count, use that count if
	     *   possible. 
	     */
            if (cnt2 == 1 || all_plural)
            {
                int i;
		int flags;

		/*
		 *   Check for a generic numeric adjective ('#' in the
		 *   adjective list for the object) in each object.  If we
		 *   find it, we need to make sure there's a number in the
		 *   name of the object. 
		 */
		for (i = 0 ; i < cnt2 ; ++i)
		{
		    if (has_gen_num_adj(ctx, list2[i]))
		    {
			/*
			 *   If the object is plural, they mean to use
			 *   all of the objects, so a numeric adjective
			 *   isn't required -- set the numeric adjective
			 *   property in the object to nil to so indicate.
			 *   Otherwise, look for the number, and set the
			 *   numeric adjective property accordingly.  
			 */
			if (plural2[i] & (VOCS_ANY | VOCS_COUNT))
			{
			    int     n = (user_count ? user_count : 1);
			    int     j;
			    long    l;
			    char    buf[4];
			    objnum  objn = list2[i];

			    /* make room for n-1 new copies of this object */
			    if (i + 1 != cnt2 && n > 1)
			    {
				memmove(&list2[i + n - 1], &list2[i],
					(cnt2 - i) * sizeof(list2[i]));
				memmove(&plural2[i + n - 1], &list2[i],
					(cnt2 - i) * sizeof(plural2[i]));
			    }

			    /* create n copies of this object */
			    for (j = 0 ; j < n ; ++j)
			    {
				long l;
				
				/* generate a number for the new object */
				runpnum(ctx->voccxrun, (long)(j + 1));
				runppr(ctx->voccxrun, objn, PRP_ANYVALUE, 1);
				l = runpopnum(ctx->voccxrun);

				/* try creating the new object */
				list2[i+j] =
				    voc_new_num_obj(ctx, objn,
						    cmdActor, cmdVerb,
						    l, FALSE);
				if (list2[i+j] == MCMONINV)
				{
				    VOC_RETVAL(save_sp, 1);
				}
			    }
			}
			else if (plural2[i] & VOCS_PLURAL)
			{
			    /*
			     *   get the plural object by asking for the
			     *   numbered object with a nil number
			     *   parameter
			     */
			    list2[i] = voc_new_num_obj(ctx, list2[i],
						       cmdActor, cmdVerb,
						       (long)0, TRUE);
			    if (list2[i] == MCMONINV)
			    {
				VOC_RETVAL(save_sp, 1);
			    }
			}
			else
			{
			    char *p;
			    int   found;

			    /* make sure we have a number */
			    for (found = FALSE, p = inlist[inpos].vocolfst ;
				 p <= inlist[inpos].vocollst ;
				 p += strlen(p) + 1)
			    {
				/* did we find it? */
				if (vocisdigit(*p))
				{
				    long l;

				    /* get the number */
				    l = atol(p);
				    
				    /* create the object with this number */
				    list2[i] =
					voc_new_num_obj(ctx, list2[i],
							cmdActor, cmdVerb,
							l, FALSE);
				    if (list2[i] == MCMONINV)
				    {
					VOC_RETVAL(save_sp, 1);
				    }

				    /* the command looks to be valid */
				    found = TRUE;
				    break;
				}
			    }

			    /* if we didn't find it, stop now */
			    if (!found)
			    {
				vocerr(ctx, 160,
                    "You'll have to be more specific about which %s you mean.",
				       usrobj);
				VOC_RETVAL(save_sp, 1);
			    }
			}
		    }
		}

		/* keep only one of the objects if ANY was used */
		if (all_plural & VOCS_COUNT)
		{
		    if (user_count > cnt2)
		    {
			vocerr(ctx, 30, "I only see %d of those.", cnt2);
			VOC_RETVAL(save_sp, 1);
		    }
		    cnt2 = user_count;
		    flags = VOCS_ALL;
		}
		else if (all_plural & VOCS_ANY)
		{
		    cnt2 = 1;
		    flags = VOCS_ALL;
		}
		else
		    flags = 0;

		/* put the list */
                for (i = 0 ; i < cnt2 ; ++i)
                    vocout(&outlist[outpos++], list2[i], flags,
                           inlist[inpos].vocolfst, inlist[inpos].vocollst);
                inpos = lpos-1;
                continue;
            }

	    cnt = cnt2;
	    memcpy(list1, list2, (size_t)(cnt * sizeof(list1[0])));
	    memcpy(plural1, plural2, (size_t)cnt);
            list1[cnt] = MCMONINV;

            /*
             *  We still have an ambiguous word - ask the user which was meant
             */
        disnoreach:
	    trying_again = FALSE;
            for (;;)
            {
                int    wrdcnt;
                int    next;
		uchar *p;
		int    cleared_noun;
		int    diff_cnt;
		    
#ifdef NEVER
		/*
		 *   As a final effort, see if all the words we currently
		 *   have in the list refer to the same object.  If so,
		 *   reduce the list to a single instance of the word.  
		 */
		for (i = 1 ; i < cnt ; ++i)
		{
		    if (list1[i] != list1[0])
			break;
		}
		if (i == cnt)
		{
		    cnt = 1;
		    vocout(&outlist[outpos++], list1[0], 0,
			   inlist[inpos].vocolfst, inlist[inpos].vocollst);
		    break;
		}
#endif

		/*
		 *   Run through the list and count distinguishable
		 *   objects.  An object is distinguishable if it doesn't
		 *   have the special property marking it as one of a
		 *   group of equivalent objects (PRP_ISEQUIV), or if it
		 *   has the property but there is no object following it
		 *   in the list which has the same immediate superclass.
		 *   
		 */
		for (i = 0, diff_cnt = 0 ; i < cnt ; ++i)
		{
		    /* presume we will count this object */
		    ++diff_cnt;
		    
		    /* see if there's an equivalent object following */
		    runppr(ctx->voccxrun, list1[i], PRP_ISEQUIV, 0);
		    if (runpoplog(ctx->voccxrun))
		    {
			int     j;
			objnum  sc;
			int     found;
			
			/* get the superclass, if possible */
			sc = objget1sc(ctx->voccxmem, list1[i]);
			if (sc == MCMONINV)
			    continue;
			
			/* see if any equivalent objects follow */
			for (found = FALSE, j = i + 1 ; j < cnt ; ++j)
			{
			    /* see if it matches our object */
			    if (objget1sc(ctx->voccxmem, list1[j]) == sc)
			    {
				/* note that we've found such a word */
				found = TRUE;

				/* move it to follow the first word */
				if (j != i + 1)
				{
				    int   tmpobj;
				    uchar tmpflag;

				    tmpobj = list1[i+1];
				    list1[i+1] = list1[j];
				    list1[j] = tmpobj;

				    tmpflag = plural1[i+1];
				    plural1[i+1] = plural1[j];
				    plural1[j] = tmpflag;
				}
			    }
			}

			/*
			 *   if we found a match, don't count this object
			 *   after all 
			 */
			if (found)
			    --diff_cnt;
		    }
		}
		
		/*
		 *   If all the objects are equivalent (diff_cnt == 1),
		 *   arbitrarily pick the first one 
		 */
		if (diff_cnt == 1)
		{
		    static char one_name[] = "ones";
		    
		    vocout(&outlist[outpos++], list1[0], 0,
			   one_name, one_name);
		    break;
		}

		/* make sure output capturing is off */
		tiocapture(ctx->voccxtio, (mcmcxdef *)0, FALSE);
		tioclrcapture(ctx->voccxtio);
	    
		if (ctx->voccxpdis != MCMONINV)
		{
		    uint l;
		    
		    for (i = 0, p = lstbuf+2 ; i < cnt ; ++i, p += 2)
		    {
			*p++ = DAT_OBJECT;
			oswp2(p, list1[i]);
		    }
		    l = p - lstbuf;
		    oswp2(lstbuf, l);
		    /*runrst(ctx->voccxrun);*/
		    runpbuf(ctx->voccxrun, DAT_LIST, lstbuf);
		    runpstr(ctx->voccxrun, usrobj, (int)strlen(usrobj), 1);
		    runfn(ctx->voccxrun, ctx->voccxpdis, 2);
		}
		else
		{
		    /* display "again" message, if necessary */
		    if (trying_again)
			vocerr(ctx, 100, "Let's try it again: ");

		    /* ask the user about it */
		    vocerr(ctx, 101, "Which %s do you mean, ", usrobj);
		    for (i = 0 ; i < cnt ; )
		    {
			int    eqcnt;
			int    j;
			objnum sc;
			
			/*
			 *   See if we have multiple instances of an
			 *   identical object.  All such instances should
			 *   be grouped together (this was done above), so
			 *   we can just count the number of consecutive
			 *   equivalent objects. 
			 */
			eqcnt = 1;
			runppr(ctx->voccxrun, list1[i], PRP_ISEQUIV, 0);
			if (runpoplog(ctx->voccxrun))
			{
			    /* get the superclass, if possible */
			    sc = objget1sc(ctx->voccxmem, list1[i]);
			    if (sc != MCMONINV)
			    {
				/* count equivalent objects that follow */
				for (j = i + 1 ; j < cnt ; ++j)
				{
				    if (objget1sc(ctx->voccxmem, list1[j])
					== sc)
				        ++eqcnt;
				    else
					break;
				}
			    }
			}

			/*
			 *   Display this object's name.  If we have only
			 *   one such object, display its thedesc,
			 *   otherwise display its multidesc. 
			 */
			/*runrst(ctx->voccxrun);*/
			runppr(ctx->voccxrun, list1[i],
			       (eqcnt == 1 ? PRP_THEDESC : PRP_ADESC), 0);

			/* display the separator as appropriate */
			if (i + 1 < diff_cnt) vocerr(ctx, 102, ", ");
			if (i + 2 == diff_cnt) vocerr(ctx, 103, "or ");

			/* skip all equivalent items */
			i += eqcnt;
		    }
		    vocerr(ctx, 104, "?");
		}

	    read_disambig_response:
                vocread(ctx, disnewbuf, (int)VOCBUFSIZ, 2);
                wrdcnt = voctok(ctx, disnewbuf, disbuffer, diswordlist,
				TRUE, TRUE);
                if (wrdcnt == 0)
                {
                    /*runrst(ctx->voccxrun);*/
                    runfn(ctx->voccxrun, ctx->voccxprd, 0);
		    VOC_RETVAL(save_sp, 1);
                }
                if (wrdcnt < 0) { VOC_RETVAL(save_sp, 1); }
                diswordlist[wrdcnt] = 0;
                if (vocgtyp(ctx, diswordlist, distypelist, cmdbuf))
		{
		    VOC_RETVAL(save_sp, 1);
		}

                /*
                 *   Find the last word that can be an adj and/or a noun.
                 *   If it can be either (i.e., both bits are set), clear
                 *   the noun bit and make it just an adjective.  This is
                 *   because we're asking for an adjective for clarification,
                 *   and we most likely want it to be an adjective in this
                 *   context; if the noun bit is set, too, the object lister
                 *   will think it must be a noun, being the last word.
                 */
                for (i = 0 ; i < wrdcnt ; ++i)
                {
                    if (!(distypelist[i] &
                          (VOCT_ADJ | VOCT_NOUN | VOCT_ARTICLE)))
                        break;
                }
                
                if (i && (distypelist[i-1] & VOCT_ADJ)
                    && (distypelist[i-1] & VOCT_NOUN))
		{
		    /*
		     *   Note that we're clearing the noun flag.  If
		     *   we're unsuccessful in finding the object with the
		     *   noun flag cleared, we'll put the noun flag back
		     *   in and give it another try (by adding VOCT_NOUN
		     *   back into distypelist[cleared_noun], and coming
		     *   back to the label below). 
		     */
		    cleared_noun = i-1;
                    distypelist[i-1] &= ~VOCT_NOUN;
		}
		else
		    cleared_noun = -1;

	    try_current_flags:
                if (vocspec(diswordlist[0], VOCW_ALL)
                    || vocspec(diswordlist[0], VOCW_BOTH))
                {
		    char *nam;
		    static char all_name[] = "all";
		    static char both_name[] = "both";

		    if (vocspec(diswordlist[0], VOCW_ALL))
			nam = all_name;
		    else
			nam = both_name;
		    
                    for (i = 0 ; i < cnt ; ++i)
                        vocout(&outlist[outpos++], list1[i], 0, nam, nam);
                    if (noreach)
		    {
			cantreach_list = list1;
			goto noreach1;
		    }
                    break;
                }
		else if (vocspec(diswordlist[0], VOCW_ANY))
		{
		    static char *anynm = "any";

		    /* choose the first object arbitrarily */
		    vocout(&outlist[outpos++], list1[i], VOCS_ALL,
			   anynm, anynm);
		    break;
		}
                else if (((cnt2 = vocchknoun(ctx, diswordlist, distypelist,
                                             0, &next, disnounlist, FALSE))
                          > 0)
                         && (!diswordlist[next]
                             || vocspec(diswordlist[next], VOCW_ONE)
                             || vocspec(diswordlist[next], VOCW_ONES)
                             || vocspec(diswordlist[next], VOCW_THEN)))
                {
                    int cnt3;
		    int newcnt;

                    for (i = 0 ; i < cnt2 ; ++i)
		    {
                        list2[i] = disnounlist[i].vocolobj;
			plural2[i] = disnounlist[i].vocolflg
			    & (VOCS_PLURAL | VOCS_ANY | VOCS_COUNT);
		    }
                    list2[i] = MCMONINV;
                    newcnt = vocisect(list2, list1);
                    for (i = cnt3 = 0 ; i < cnt2 ; ++i)
                    {
                        ++cnt3;
                        if (disnounlist[i].vocolfst)
                        {
                            int j;

                            for (j = i + 1 ; disnounlist[i].vocolfst ==
                                 disnounlist[j].vocollst ; ++j);
                            i = j - 1;
                        }
                    }

		    /*
		     *   If the count of items in the intersection of the
		     *   original list and the typed-in list is no bigger
		     *   than the number of items specified in the
		     *   typed-in list, we've successfully disambiguated
		     *   the object, because the user's new list matches
		     *   only one object for each set of words the user
		     *   typed. 
		     */
                    if (newcnt
			&& (newcnt <= cnt3
			    || (diswordlist[next]
				&& vocspec(diswordlist[next], VOCW_ONES))))
                    {
			static char one_name[] = "ones";
			
                        for (i = 0 ; i < cnt ; ++i)
                            vocout(&outlist[outpos++], list2[i], 0,
                                   one_name, one_name);

                        if (noreach)
                        {
			    cnt = newcnt;
			    cantreach_list = list2;
                        noreach1:
			    if (accprop == PRP_VALIDACTOR)
			    {
				/* for actors, generate a special message */
				vocerr(ctx, 31, "You can't talk to that.");
			    }
			    else
			    {
				/* use the normal no-reach message */
				vocnoreach(ctx, cantreach_list, cnt, cmdActor,
					   cmdVerb, cmdPrep, defprop);
			    }
			    VOC_RETVAL(save_sp, 1);
                        }
                        break;
                    }
                    else if (newcnt == 0)
                    {
			/*
			 *   If we cleared the noun, maybe we actually
			 *   need to treat the word as a noun, so add the
			 *   noun flag back in and give it another go.  If
			 *   we didn't clear the noun, there's nothing
			 *   left to try, so explain that we don't see any
			 *   such object and give up.
			 */
			if (cleared_noun != -1)
			{
			    distypelist[cleared_noun] |= VOCT_NOUN;
			    cleared_noun = -1;
			    goto try_current_flags;
			}

			/* didn't find anything - complain and give up */
                        vocerr(ctx, 16, "I don't see that here.");
			VOC_RETVAL(save_sp, 1);
                    }

		    /*
		     *   If we get here, it means that we have still more
		     *   than one object per noun phrase typed in the
		     *   latest sentence.  Limit the list to the
		     *   intersection (by copying list2 to list1), and try
		     *   again. 
		     */
		    memcpy(list1, list2, (size_t)(newcnt * sizeof(list1[0])));
		    cnt = newcnt;
		    trying_again = TRUE;
		}
                else                     /* no good - must be a new command */
                {
                    strcpy(cmdbuf, disnewbuf);
                    if (cnt2 == 0 || accprop == PRP_VALIDACTOR)
			ctx->voccxredo = TRUE;
		    {
			VOC_RETVAL(save_sp, 1);
		    }
                }
	    }
            inpos = lpos - 1;
        }
    }
    
    vocout(&outlist[outpos], MCMONINV, 0, (char *)0, (char *)0);
    VOC_RETVAL(save_sp, 0);
}

/* vocready - see if at end of command, execute & return TRUE if so */
static int vocready(ctx, cmd, cur, cmdActor, cmdPrep, vverb, vprep, dolist,
                    iolist, errp, cmdbuf, first_word, preparse_list)
voccxdef *ctx;
char     *cmd[];
int       cur;
objnum    cmdActor;
objnum    cmdPrep;
char     *vverb;
char     *vprep;
vocoldef *dolist;
vocoldef *iolist;
int      *errp;
char     *cmdbuf;
int       first_word;
char    **preparse_list;
{
    if (cur != -1
	&& (cmd[cur] == (char *)0
	    || vocspec(cmd[cur], VOCW_AND) || vocspec(cmd[cur], VOCW_THEN)))
    {
	if (ctx->voccxflg & VOCCXFDBG)
	{
	    char buf[128];
	    
	    sprintf(buf, ". executing verb:  %s %s\\n",
		    vverb, vprep ? vprep : "");
	    tioputs(ctx->vocxtio, buf);
	}

        *errp = execmd(ctx, cmdActor, cmdPrep, vverb, vprep,
                       dolist, iolist, &cmd[first_word], cmdbuf,
		       cur - first_word, preparse_list);
        return(TRUE);
    }
    return(FALSE);
}

/* check if an object defines the special adjective '#' */
static int has_gen_num_adj(ctx, objn)
voccxdef *ctx;
objnum    objn;
{
    vocwdef   *v;
    vocseadef  search_ctx;

    /* scan the list of objects defined '#' as an adjective */
    for (v = vocffw(ctx, "#", 1, (char *)0, 0, PRP_ADJ, &search_ctx) ;
	 v ; v = vocfnw(ctx, &search_ctx))
    {
	/* if this is the object, return positive indication */
	if (v->vocwobj == objn)
	    return TRUE;
    }

    /* didn't find it */
    return FALSE;
}

/* execute a single command */
static int voc1cmd(ctx, cmd, cmdbuf, cmdActorp, first)
voccxdef *ctx;
char     *cmd[];
char     *cmdbuf;
objnum   *cmdActorp;
int       first;
{
    int       cur;
    int       next;
    objnum    o;
    vocwdef  *v;
    char     *vverb;
    int       vvlen;
    char     *vprep;
    int       cnt;
    int       err;
    vocoldef *dolist;
    vocoldef *iolist;
    int      *typelist;
    objnum    cmdActor = *cmdActorp;
    objnum    cmdPrep;
    int       swapObj;                        /* TRUE -> swap dobj and iobj */
    int       again;
    int       first_word;
    char     *preparse_list;
    struct
    {
	int    active;
	int    cur;
	char **cmd;
	char  *cmdbuf;
    } preparseCmd_stat;
    char    **newcmd;
    char     *newcmdbuf;
    char     *save_sp;

    voc_enter(&save_sp);
    VOC_MAX_ARRAY(ctx, vocoldef, dolist);
    VOC_MAX_ARRAY(ctx, vocoldef, iolist);
    VOC_STK_ARRAY(ctx, int,      typelist,  VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char *,   newcmd,    VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char,     newcmdbuf, VOCBUFSIZ);

    memset(typelist, 0, VOCBUFSIZ*sizeof(typelist[0]));
    
    if (vocgtyp(ctx, cmd, typelist, cmdbuf)) { VOC_RETVAL(save_sp, 1); }
    cur = next = 0;
    preparseCmd_stat.active = FALSE;
    for (again = FALSE, err = 0 ; ; again = TRUE)
    {
	/*
	 *   if preparseCmd sent us back a list, parse that list as a new
	 *   command 
	 */
	if (err == ERR_PREPRSCMDREDO)
	{
	    char   *src;
	    size_t  len;
	    size_t  curlen;
	    char   *dst;
	    int     cnt;

	    /* don't allow a preparseCmd to loop */
	    if (preparseCmd_stat.active)
	    {
		vocerr(ctx, 34, "Internal game error: preparseCmd loop");
		VOC_RETVAL(save_sp, 1);
	    }
	    
	    /* save our status prior to processing the preparseCmd list */
	    preparseCmd_stat.active = TRUE;
	    preparseCmd_stat.cur = cur;
	    preparseCmd_stat.cmd = cmd;
	    preparseCmd_stat.cmdbuf = cmdbuf;

	    /* set up with the new command */
	    cmd = newcmd;
	    cmdbuf = newcmdbuf;
	    cur = 0;

	    /* break up the list into the new command buffer */
	    src = preparse_list;
	    len = osrp2(src) - 2;
	    for (src += 2, dst = cmdbuf, cnt = 0 ; len ; )
	    {
		/* make sure the next element is a string */
	        if (*src != DAT_SSTRING)
		{
		    vocerr(ctx, 32,
                 "Internal game error: preparseCmd returned an invalid list");
		    VOC_RETVAL(save_sp, 1);
		}

		/* get the string */
		++src;
		curlen = osrp2(src) - 2;
		src += 2;

		/* make sure it will fit in the buffer */
		if (dst + curlen + 1 >= cmdbuf + VOCBUFSIZ)
		{
		    vocerr(ctx, 33,
   	                  "Internal game error: preparseCmd command too long");
		    VOC_RETVAL(save_sp, 1);
		}

		/* store the word */
		cmd[cnt++] = dst;
		memcpy(dst, src, curlen);
		dst[curlen] = '\0';

		/* move on to the next word */
		len -= 3 + curlen;
		src += curlen;
		dst += curlen + 1;
	    }

	    /* enter a null last word */
	    cmd[cnt] = 0;

	    /* generate the type list for the new list */
	    if (vocgtyp(ctx, cmd, typelist, cmdbuf))
	    {
		VOC_RETVAL(save_sp, 1);
	    }

	    /*
	     *   this is not a new command - it's just further processing
	     *   of the current command 
	     */
	    again = FALSE;

	    /* clear the erorr */
	    err = 0;
	}

	/* initialize locals */
	cmdPrep  = MCMONINV;                       /* assume no preposition */
	swapObj  = FALSE;                      /* assume no object swapping */
        dolist[0].vocolobj = iolist[0].vocolobj = MCMONINV;
        dolist[0].vocolflg = iolist[0].vocolflg = 0;

        /* check error return from vocready (which returns from execmd) */
        if (err)
	{
	    VOC_RETVAL(save_sp, err);
	}

    skip_leading_stuff:
	/* skip any leading THEN's and AND's */
        while (cmd[cur] && (vocspec(cmd[cur], VOCW_THEN)
                            || vocspec(cmd[cur], VOCW_AND)))
            ++cur;

	/* see if there's anything left to parse */
        if (cmd[cur] == 0)
	{
	    /*
	     *   if we've been off doing preparseCmd work, return to the
	     *   original command list 
	     */
	    if (preparseCmd_stat.active)
	    {
		/* restore the original status */
		cur = preparseCmd_stat.cur;
		cmd = preparseCmd_stat.cmd;
		cmdbuf = preparseCmd_stat.cmdbuf;
		preparseCmd_stat.active = FALSE;
		
		/* get the type list for the original list again */
		if (vocgtyp(ctx, cmd, typelist, cmdbuf))
		{
		    VOC_RETVAL(save_sp, 1);
		}

		/* try again */
		goto skip_leading_stuff;
	    }
	    else
	    {
		/* nothing to pop - we must be done */
		VOC_RETVAL(save_sp, 0);
	    }
	}


        if (again) outformat("\\b");            /* tioblank(ctx->voccxtio); */

#ifdef NEVER
	/* get actor the first time through */
	if (first && !again)
#endif
	{
	    if ((o = vocgetactor(ctx, cmd, typelist, cur, &next, cmdbuf))
		!= MCMONINV)
	    {
		cur = next;
		cmdActor = *cmdActorp = o;
	    }
	    if (cur != next)
	    {
		/* error getting actor */
		VOC_RETVAL(save_sp, 1);
	    }
	}

	first_word = cur;
        if ((cmd[cur] == (char *)0) || !(typelist[cur] & VOCT_VERB))
        {
            vocerr(ctx, 17, "There's no verb in that sentence!");
	    VOC_RETVAL(save_sp, 1);
        }
        vverb = cmd[cur++];                             /* this is the verb */
        vvlen = strlen(vverb);                   /* remember length of verb */
        vprep = 0;                            /* assume no verb-preposition */

        /* execute if the command is just a verb */
        if (vocready(ctx, cmd, cur, cmdActor, cmdPrep,
                     vverb, vprep, dolist, iolist, &err, cmdbuf,
		     first_word, &preparse_list))
            continue;

        /*
         *   If the next word is a preposition, and it makes sense to be
         *   aggregated with this verb, use it as such.
         */
        if (typelist[cur] & VOCT_PREP)
	{
            if (vocffw(ctx, vverb, vvlen, cmd[cur], (int)strlen(cmd[cur]),
		       PRP_VERB, (vocseadef *)0))
	    {
		vprep = cmd[cur++];
		if (vocready(ctx, cmd, cur, cmdActor, cmdPrep,
			     vverb, vprep, dolist, iolist, &err, cmdbuf,
			     first_word, &preparse_list))
		    continue;
	    }
	    else
	    {
		/*
		 *   If we have a preposition which can NOT be aggregated
		 *   with the verb, take command of this form: "verb prep
		 *   iobj dobj".  Note that we do *not* do this if the
		 *   word is also an adjective, and a noun (possibly
		 *   separated by one or more adjectives) follows.  
		 */
		if (v = vocffw(ctx, cmd[cur], (int)strlen(cmd[cur]),
			       (char *)0, 0, PRP_PREP, (vocseadef *)0))
		{
		    int swap_ok;

		    /* if it can be an adjective, check further */
		    if (typelist[cur] & VOCT_ADJ)
		    {
			int i;

			/* look for a noun, possibly preceded by adj's */
			for (i = cur + 1 ;
			     cmd[i] && (typelist[i] & VOCT_ADJ)
			     && !(typelist[i] & VOCT_NOUN) ; ++i) ;
			swap_ok = (!cmd[i] || !(typelist[i] & VOCT_NOUN));
		    }
		    else
		    {
			/* we can definitely allow this swap */
			swap_ok = TRUE;
		    }

		    if (swap_ok)
		    {
			cmdPrep = v->vocwobj;
			swapObj = TRUE;
			++cur;
		    }
		}
	    }
	}

    retry_swap:
	/* get the direct object if there is one */
        if ((cnt =
             vocchknoun(ctx, cmd, typelist, cur, &next, dolist, FALSE)) > 0)
            cur = next;
        else if (cnt < 0)
	{
	    VOC_RETVAL(save_sp, 1);
	}
        else
        {
	    /*
	     *   If we thought we were going to get a two-object
	     *   sentence, and we got a zero-object sentence, and it looks
	     *   like the word we took as a preposition is also an
	     *   adjective or noun, go back and treat it as such. 
	     */
	    if (swapObj &&
		((typelist[cur-1] & VOCT_NOUN)
		 || (typelist[cur-1] & VOCT_ADJ)))
	    {
		--cur;
		swapObj = FALSE;
		cmdPrep = MCMONINV;
		goto retry_swap;
	    }
	    
	bad_sentence:
	    /* find the last word */
	    while (cmd[cur]) ++cur;
	    
	    /* try running the sentence through preparseCmd */
	    err = try_preparse_cmd(ctx, &cmd[first_word], cur - first_word,
				   &preparse_list);
	    switch(err)
	    {
	    case 0:
		/* preparseCmd didn't do anything - the sentence fails */
		vocerr(ctx, 18, "I don't understand that sentence.");
		VOC_RETVAL(save_sp, 1);

	    case ERR_PREPRSCMDCAN:
		/* they cancelled - we're done with the sentence */
		VOC_RETVAL(save_sp, 0);

	    case ERR_PREPRSCMDREDO:
		/* reparse with the new sentence */
		continue;
	    }
        }

	/* see if we want to execute the command now */
        if (vocready(ctx, cmd, cur, cmdActor, cmdPrep,
                     vverb, vprep,
		     swapObj ? iolist : dolist,
		     swapObj ? dolist : iolist,
		     &err, cmdbuf, first_word, &preparse_list))
            continue;
        
        /*
         *   Check for an indirect object, which may or may not be preceded
         *   by a preposition.  (Note that the lack of a preposition implies
         *   that the object we already found is the indirect object, and the
         *   next object is the direct object.  It also implies a preposition
         *   of "to.")
         */
        if (cmdPrep == MCMONINV && (typelist[cur] & VOCT_PREP))
        {
            char *p1 = cmd[cur++];

	    /* if this is the end of the sentence, add the prep to the verb */
            if (cmd[cur] == (char *)0
                || vocspec(cmd[cur], VOCW_AND)
                || vocspec(cmd[cur], VOCW_THEN))
            {
                if (vocffw(ctx, vverb, vvlen, p1, (int)strlen(p1), PRP_VERB,
			   (vocseadef *)0)
                    && !vprep)
                    vprep = p1;
                else
                {
                    vocerr(ctx, 19,
                        "There are words after your command I couldn't use.");
		    VOC_RETVAL(save_sp, 1);
                }
                
                if (err = execmd(ctx, cmdActor, cmdPrep, vverb, vprep,
				 dolist, iolist,
				 &cmd[first_word], cmdbuf, cur - first_word,
				 &preparse_list))
		{
		    VOC_RETVAL(save_sp, 1);
		}
                continue;
            }

	    /*
	     *   If we have no verb preposition already, and we have
	     *   another prep-capable word following this prep-capable
	     *   word, and this preposition aggregates with the verb, take
	     *   it as a sentence of the form "pry box open with crowbar"
	     *   (where the current word is "with").  We also must have at
	     *   least one more word after that, since there will have to
	     *   be an indirect object.  
	     */
	    if (cmd[cur] && (typelist[cur] & VOCT_PREP) && cmd[cur+1]
		&& vprep == 0
		&& vocffw(ctx, vverb, vvlen, p1, (int)strlen(p1), PRP_VERB,
			  (vocseadef *)0))
	    {
		/* aggregate the first preposition into the verb */
		vprep = p1;

		/* use the current word as the object-introducing prep */
		p1 = cmd[cur++];
	    }

	    /* try for an indirect object */
            if ((cnt = vocgetnoun(ctx, cmd, typelist, cur, &next, iolist))
                > 0)
            {
                cur = next;
                v = vocffw(ctx, p1, (int)strlen(p1), (char *)0, 0, PRP_PREP,
			   (vocseadef *)0);
                if (v == (vocwdef *)0)
                {
                    vocerr(ctx, 20,
                        "I don't know how to use the word \"%s\" like that.",
                           p1);
		    VOC_RETVAL(save_sp, 1);
                }
                cmdPrep = v->vocwobj;

                if (vocready(ctx, cmd, cur, cmdActor, cmdPrep,
                             vverb, vprep, dolist, iolist, &err, cmdbuf,
			     first_word, &preparse_list))
                    continue;
                else if ((typelist[cur] & VOCT_PREP) &&
                         vocffw(ctx, vverb, vvlen, cmd[cur],
                                (int)strlen(cmd[cur]), PRP_VERB,
				(vocseadef *)0) && !vprep)
                {
                    vprep = cmd[cur++];
                    if (vocready(ctx, cmd, cur, cmdActor, cmdPrep, vverb,
                                 vprep, dolist, iolist, &err, cmdbuf,
				 first_word, &preparse_list))
                        continue;
                    else
                    {
                        vocerr(ctx, 19,
                        "There are words after your command I couldn't use.");
			VOC_RETVAL(save_sp, 1);
                    }
                }
                else
                {
                    vocerr(ctx, 19,
                  "There are words after your command that I couldn't use.");
		    VOC_RETVAL(save_sp, 1);
                }
            }
            else if (cnt < 0)
	    {
		VOC_RETVAL(save_sp, 1);
	    }
            else
            {
		goto bad_sentence;
            }
        }
        else if ((cnt = vocchknoun(ctx, cmd, typelist, cur,
                                   &next, iolist, FALSE)) > 0)
        {
	    /* look for prep at end of command */
            cur = next;
	    if (cmd[cur])
	    {
                if ((typelist[cur] & VOCT_PREP) &&
                    vocffw(ctx, vverb, vvlen, cmd[cur],
                           (int)strlen(cmd[cur]), PRP_VERB,
			   (vocseadef *)0) && !vprep)
		{
                    vprep = cmd[cur++];
		}
	    }

	    /* the command should definitely be done now */
	    if (cmd[cur])
	    {
		vocerr(ctx, 21,
		       "There appear to be extra words after your command.");
		VOC_RETVAL(save_sp, 1);
	    }
		
	    /*
	     *   If we don't have a preposition yet, we need to find the
	     *   verb's default.  If the verb object has a nilPrep
	     *   property defined, use that prep object; otherwise, look
	     *   up the word "to" and use that.  
	     */
	    if (cmdPrep == MCMONINV &&
		(v = vocffw(ctx, vverb, vvlen,
			    vprep, (vprep ? (int)strlen(vprep) : 0),
			    PRP_VERB, (vocseadef *)0)))
	    {
		runrst(ctx->voccxrun);
		runppr(ctx->voccxrun, v->vocwobj, PRP_NILPREP, 0);
		if (runtostyp(ctx->voccxrun) == DAT_OBJECT)
		    cmdPrep = runpopobj(ctx->voccxrun);
		else
		    rundisc(ctx->voccxrun);
	    }

	    /* if we didn't find anything with nilPrep, find "to" */
	    if (cmdPrep == MCMONINV)
	    {
		v = vocffw(ctx, "to", 2, (char *)0, 0, PRP_PREP,
			   (vocseadef *)0);
		if (v) cmdPrep = v->vocwobj;
	    }

	    /* execute the command */
	    err = execmd(ctx, cmdActor, cmdPrep, vverb, vprep,
			 iolist, dolist, &cmd[first_word], cmdbuf,
			 cur - first_word, &preparse_list);
            continue;
        }
        else if (cnt < 0)
        {
	    VOC_RETVAL(save_sp, 1);
        }
        else
        {
	    goto bad_sentence;
#ifdef NEVER
            cnt = vocchknoun(ctx, cmd, typelist, cur, &next, dolist, FALSE);
            if (cnt >= 0)
                vocerr(ctx, 18, "I don't understand that sentence.");
	    VOC_RETVAL(save_sp, 1);
#endif /* NEVER */
        }
    }
}

/* execute a player command */
int voccmd(ctx, cmd, cmdlen)
voccxdef *ctx;
char     *cmd;
uint      cmdlen;
{
    int      wrdcnt;
    int      cur;
    int      next;
    char    *buffer;
    char   **wordlist;
    objnum   cmdActor;
    int      first;

    /* make sure the stack is set up */
    voc_stk_ini(ctx, (uint)VOC_STACK_SIZE);

    VOC_STK_ARRAY(ctx, char,   buffer,   2*VOCBUFSIZ);
    VOC_STK_ARRAY(ctx, char *, wordlist, VOCBUFSIZ);
    
    /* until further notice, the actor for formatStrings is Me */
    tiosetactor(ctx->voccxtio, ctx->voccxme);

    /* clear the 'ignore' flag */
    ctx->voccxflg &= ~VOCCXFCLEAR;

    /* send to game function 'preparse' */
    if (ctx->voccxpre != MCMONINV)
    {
        int      typ;
        char    *s;
        size_t   len;
        
        runrst(ctx->voccxrun);
        runpstr(ctx->voccxrun, cmd, (int)strlen(cmd), 0);
        runfn(ctx->voccxrun, ctx->voccxpre, 1);
        
        typ = runtostyp(ctx->voccxrun);
        if (typ == DAT_SSTRING)
        {
            s = runpopstr(ctx->voccxrun);
            len = osrp2(s) - 2;
            s += 2;
            if (len > cmdlen - 1) len = cmdlen - 1;

            memcpy(cmd, s, len);
            cmd[len] = '\0';
        }
        else
        {
            rundisc(ctx->voccxrun);  /* discard whatever value was returned */
            if (typ == DAT_NIL) return(0);            /* ignore the command */
        }
    }

    /* break up into individual words */
    if ((wrdcnt = voctok(ctx, cmd, buffer, wordlist, TRUE, FALSE)) > 0)
    {
	for (cur = 0 ; cur < wrdcnt ; ++cur)
	{
	    if (!vocspec(wordlist[cur], VOCW_THEN)
		&& !vocspec(wordlist[cur], VOCW_AND))
		break;
	}
    }
	
    if (!wrdcnt || (wrdcnt > 0 && cur >= wrdcnt))
    {
        runrst(ctx->voccxrun);
        runfn(ctx->voccxrun, ctx->voccxprd, 0);
        return( 0 );
    }
    if (wrdcnt < 0) return( 0 );

    for (first = TRUE, cmdActor = MCMONINV ; cur < wrdcnt ;
	 ++cur, first = FALSE)
    {
	/* find the THEN that ends the command, if there is one */
        for (next = cur ; cur < wrdcnt && !vocspec(wordlist[cur], VOCW_THEN)
	     ; ++cur) ;
	wordlist[cur] = (char *)0;
        if (voc1cmd(ctx, &wordlist[next], cmd, &cmdActor, first)) return(1);

	/* if the rest of the command is to be ignored, ignore it */
	if (ctx->voccxflg & VOCCXFCLEAR) return(0);

	/* scan past any separating AND's and THEN's */
        while (cur + 1 < wrdcnt
               && (vocspec(wordlist[cur+1], VOCW_THEN)
                   || vocspec(wordlist[cur+1], VOCW_AND)))
            ++cur;
        if (cur+1 < wrdcnt)
	    outformat("\\b");                    /*tioblank(ctx->voccxtio); */
    }
    return(0);
}


/*
 *   Off-stack stack management 
 */

/* allocate/reset the stack */
void voc_stk_ini(ctx, siz)
voccxdef *ctx;
uint      siz;
{
    /* allocate it if it's not already allocated */
    if (voc_stk_ptr == 0)
    {
	voc_stk_ptr = (char*)mchalo(ctx->voccxerr, (ushort)siz, "voc_stk_ini"); //###cast
	voc_stk_end = voc_stk_ptr + siz;
    }
    
    /* reset the stack */
    voc_stk_cur = voc_stk_ptr;
}

/* allocate space from the off-stack stack */
dvoid *voc_stk_alo(ctx, siz)
voccxdef *ctx;
uint      siz;
{
    dvoid *ret;
    
    /* round size up to allocation units */
    siz = osrndsz(siz);

    /* if there's not space, signal an error */
    if (voc_stk_cur + siz > voc_stk_end)
	errsig(ctx->voccxerr, ERR_VOCSTK);

    /* save the return pointer */
    ret = voc_stk_cur;

    /* consume the space */
    voc_stk_cur += siz;

/*#define SHOW_HI*/
#ifdef SHOW_HI
{ static uint maxsiz;
  if (voc_stk_cur - voc_stk_ptr > maxsiz)
  {
    maxsiz = voc_stk_cur - voc_stk_ptr; os_printf1("%u\n", maxsiz); //###indep
  }
}
#endif


    /* return the space */
    return ret;
}


