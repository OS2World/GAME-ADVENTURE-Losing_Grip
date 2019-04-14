/* Copyright (c) 1992 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  fio.c - file i/o functions
Function
  file i/o:  read game, write game, save game, restore game
Notes
  none
Modified
  04/02/92 MJRoberts     - creation
*/

/*
 *   The following horrible hack is required to work around a problem
 *   with Think C.  It will not compile this file without it, due to some
 *   strange capacity problem ("debug table overflow", even when debugging
 *   is off). 
 */
#ifdef THINK_C
# include "PreCompiled.h"
#else

#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/fio.c 1.9 96/10/14 16:10:30 mroberts Exp $";
#endif

#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "std.h"
#include "os.h"
#include "mch.h"
#include "mcm.h"
#include "mcl.h"
#include "tok.h"
#include "obj.h"
#include "voc.h"
#include "fio.h"
#include "dat.h"
#include "prs.h"

#endif /* THINK_C horible hack */


/* compare a resource string */
/* int fioisrsc(uchar *filbuf, char *refnam); */
#define fioisrsc(filbuf, refnam) \
  (((filbuf)[0] == strlen(refnam)) && \
   !memcmp(filbuf+1, refnam, (size_t)((filbuf)[0])))

/* callback to load an object on demand */
void OS_LOADDS fioldobj(ctx, handle, ptr, siz)
fiolcxdef *ctx;
mclhd      handle;
uchar     *ptr;
ushort     siz;
{
    ulong     seekpos = (ulong)handle;
    osfildef *fp = ctx->fiolcxfp;
    char      buf[7];
    errcxdef *ec = ctx->fiolcxerr;
    uint      rdsiz;
    
    /* figure out what type of object is to be loaded */
    osfseek(fp, seekpos + ctx->fiolcxst, OSFSK_SET);
    if (osfrb(fp, buf, 7)) errsig(ec, ERR_LDGAM);
    switch(buf[0])
    {
    case TOKSTFUNC:
        rdsiz = osrp2(buf + 3);
        break;

    case TOKSTOBJ:
        rdsiz = osrp2(buf + 5);
        break;
        
    case TOKSTFWDOBJ:
    case TOKSTFWDFN:
    default:
        errsig(ec, ERR_UNKOTYP);
    }
    
    if (siz < rdsiz) errsig(ec, ERR_LDBIG);
    if (osfrb(fp, ptr, rdsiz)) errsig(ec, ERR_LDGAM);
    if (ctx->fiolcxflg & FIOFCRYPT)
	fioxor(ptr, rdsiz, ctx->fiolcxseed, ctx->fiolcxinc);
}

/* shut down load-on-demand subsystem (close load file) */
void fiorcls(ctx)
fiolcxdef *ctx;
{
    if (ctx) osfcls(ctx->fiolcxfp);
}

/* read game from binary file */
static void fiord1(mctx, vctx, tctx, fp, setupctx, startofs, preinit,
		   flagp, path, fmtsp, fmtlp, pcntptr, flags)
mcmcxdef  *mctx;
voccxdef  *vctx;
tokcxdef  *tctx;
osfildef  *fp;
fiolcxdef *setupctx;                /* loader callback context to be set up */
ulong      startofs;                               /* fpos at start of file */
objnum    *preinit;
uint      *flagp;                      /* place to put flags read from file */
tokpdef   *path;
uchar    **fmtsp;
uint      *fmtlp;
uint      *pcntptr;
int        flags;             /* &1 ==> run preinit; &2 ==> preload objects */
{
    int         i;
    int         j;
    int         k;
    int         used;
    int         siz;
    uchar      *p;
    uchar       buf[TOKNAMMAX + 50];
    uchar       endbuf[4];
    ulong       endofs;
    errcxdef   *ec = vctx->voccxerr;
    ulong       fpos;
    ulong       endpos;
    int         obj;
    vocidef  ***vpg;
    vocidef   **v;
    objnum     *sc;
    ulong       curpos;
    runxdef    *ex;
    ulong       eof_reset = 0;             /* reset here at EOF if non-zero */
    int         xfcns_done = FALSE;                /* already loaded XFCN's */
    ulong       xfcn_pos = 0;          /* location of XFCN's if preloadable */
    uint        xor_seed = 17;                     /* seed value for fioxor */
    uint        xor_inc = 29;                 /* increment value for fioxor */

    /* set up loader callback context */
    setupctx->fiolcxfp = fp;
    setupctx->fiolcxerr = ec;
    setupctx->fiolcxst = startofs;
    setupctx->fiolcxseed = xor_seed;
    setupctx->fiolcxinc = xor_inc;

    /* check file and version headers, and get flags and timestamp */
    if (osfrb(fp, buf, (int)(sizeof(FIOFILHDR) + sizeof(FIOVSNHDR) + 2)))
        errsig(ec, ERR_RDGAM);
    if (memcmp(buf, FIOFILHDR, (size_t)sizeof(FIOFILHDR)))
	errsig(ec, ERR_BADHDR);
    if (memcmp(buf + sizeof(FIOFILHDR), FIOVSNHDR,
               (size_t)sizeof(FIOVSNHDR))
	&& memcmp(buf + sizeof(FIOFILHDR), FIOVSNHDR2,
	          (size_t)sizeof(FIOVSNHDR2))
	&& memcmp(buf + sizeof(FIOFILHDR), FIOVSNHDR3,
		  (size_t)sizeof(FIOVSNHDR3)))
        errsig(ec, ERR_BADVSN);
    if (osfrb(fp, vctx->voccxtim, (size_t)26)) errsig(ec, ERR_RDGAM);

    setupctx->fiolcxflg = 
    *flagp = osrp2(buf + sizeof(FIOFILHDR) + sizeof(FIOVSNHDR));
    
    /* now read resources from the file */
    for (;;)
    {
        /* read resource type and next-resource pointer */
        if (osfrb(fp, buf, 1)
            || osfrb(fp, buf + 1, (int)(buf[0] + 4)))
            errsig(ec, ERR_RDGAM);
        endpos = osrp4(buf + 1 + buf[0]);
        
        if (fioisrsc(buf, "OBJ"))
        {
	    /* skip regular objects if fast-load records are included */
	    if (*flagp & FIOFFAST)
	    {
		osfseek(fp, endpos + startofs, OSFSK_SET);
		continue;
	    }

            curpos = osfpos(fp) - startofs;
            while (curpos != endpos)
            {
                /* read type and object number */
                if (osfrb(fp, buf, 3)) errsig(ec, ERR_RDGAM);
                obj = osrp2(buf+1);

                switch(buf[0])
                {
                case TOKSTFUNC:
                case TOKSTOBJ:
                    if (osfrb(fp, buf + 3, 4)) errsig(ec, ERR_RDGAM);
                    mcmrsrv(mctx, osrp2(buf + 3), (mcmon)obj, (mclhd)curpos);
                    curpos += osrp2(buf + 5) + 7;
		    
		    /* load object if preloading */
		    if (flags & 2)
		    {
			(void)mcmlck(mctx, (mcmon)obj);
			mcmunlck(mctx, (mcmon)obj);
		    }

                    /* seek past this object */
                    osfseek(fp, curpos + startofs, OSFSK_SET);
                    break;
                    
                case TOKSTFWDOBJ:
                case TOKSTFWDFN:
		{
		    ushort  siz;
		    uchar  *p;
		    
		    if (osfrb(fp, buf+3, 2)) errsig(ec, ERR_RDGAM);
		    siz = osrp2(buf+3);
                    p = mcmalonum(mctx, siz, (mcmon)obj);
		    if (osfrb(fp, p, siz)) errsig(ec, ERR_RDGAM);
                    mcmunlck(mctx, (mcmon)obj);
                    curpos += 5 + siz;
                    break;
		}
                    
                case TOKSTEXTERN:
                    if (!vctx->voccxrun->runcxext)
                        errsig(ec, ERR_UNXEXT);
                    ex = &vctx->voccxrun->runcxext[obj];

                    if (osfrb(fp, buf + 3, 1)
                        || osfrb(fp, ex->runxnam, (int)buf[3]))
                        errsig(ec, ERR_RDGAM);
                    ex->runxnam[buf[3]] = '\0';
                    curpos += buf[3] + 4;
                    break;
                    
                default:
                    errsig(ec, ERR_UNKOTYP);
                }
            }
        }
	else if (fioisrsc(buf, "FST"))
	{
	    uchar *p;
	    uchar *bufp;
	    ulong  siz;
	    
	    if (!(*flagp & FIOFFAST))
	    {
		osfseek(fp, endpos + startofs, OSFSK_SET);
		continue;
	    }
	    
	    curpos = osfpos(fp) - startofs;
	    siz = endpos - curpos;
	    if (siz && siz < OSMALMAX && (bufp = p = osmalloc((size_t)siz)))
	    {
		uchar *p1;
		ulong  siz2;
		uint   sizcur;

		for (p1 = p, siz2 = siz ; siz2 ; siz2 -= sizcur, p1 += sizcur)
		{
		    sizcur = (siz2 > (uint)0xffff ? (uint)0xffff : siz2);
		    if (osfrb(fp, p1, sizcur)) errsig(ec, ERR_RDGAM);
		}

		while (siz)
		{
		    obj = osrp2(p + 1);
		    switch(*p)
		    {
		    case TOKSTFUNC:
		    case TOKSTOBJ:
			mcmrsrv(mctx, osrp2(p + 3), (mcmon)obj,
				(mclhd)osrp4(p + 7));
			p += 11;
			siz -= 11;
			
			/* preload object if desired */
			if (flags & 2)
			{
			    (void)mcmlck(mctx, (mcmon)obj);
			    mcmunlck(mctx, (mcmon)obj);
			}
			break;
			
		    case TOKSTEXTERN:
			if (!vctx->voccxrun->runcxext)
			    errsig(ec, ERR_UNXEXT);
			ex = &vctx->voccxrun->runcxext[obj];
			
			memcpy(ex->runxnam, p + 4, (size_t)p[3]);
			ex->runxnam[p[3]] = '\0';
			siz -= p[3] + 4;
			p += p[3] + 4;
			break;
			
		    default:
			errsig(ec, ERR_UNKOTYP);
		    }
		}
		
		/* done with temporary block; free it */
		osfree(bufp);
		osfseek(fp, endpos + startofs, OSFSK_SET);
	    }
	    else
	    {
		while (curpos != endpos)
		{
		    if (osfrb(fp, buf, 3)) errsig(ec, ERR_RDGAM);
		    obj = osrp2(buf + 1);
		    switch(buf[0])
		    {
		    case TOKSTFUNC:
		    case TOKSTOBJ:
			if (osfrb(fp, buf + 3, 8)) errsig(ec, ERR_RDGAM);
			mcmrsrv(mctx, osrp2(buf + 3), (mcmon)obj,
				(mclhd)osrp4(buf + 7));
			curpos += 11;
			
			/* preload object if desired */
			if (flags & 2)
			{
			    (void)mcmlck(mctx, (mcmon)obj);
			    mcmunlck(mctx, (mcmon)obj);
			    osfseek(fp, curpos + startofs, OSFSK_SET);
			}
			break;
			
		    case TOKSTEXTERN:
			if (!vctx->voccxrun->runcxext)
			    errsig(ec, ERR_UNXEXT);
			ex = &vctx->voccxrun->runcxext[obj];
			
			if (osfrb(fp, buf + 3, 1)
			    || osfrb(fp, ex->runxnam, (int)buf[3]))
			    errsig(ec, ERR_RDGAM);
			ex->runxnam[buf[3]] = '\0';
			curpos += buf[3] + 4;
			break;
			
		    default:
			errsig(ec, ERR_UNKOTYP);
		    }
		}
	    }

	    /* if we can preload xfcn's, do so now */
	    if (xfcn_pos)
	    {
		eof_reset = endpos;    /* remember to return here when done */
		osfseek(fp, xfcn_pos, OSFSK_SET);           /* go to xfcn's */
	    }
	}
        else if (fioisrsc(buf, "XFCN"))
        {
            if (!vctx->voccxrun->runcxext) errsig(ec, ERR_UNXEXT);

            /* read length and name of resource */
            if (osfrb(fp, buf, 3) || osfrb(fp, buf + 3, (int)buf[2]))
                errsig(ec, ERR_RDGAM);
            siz = osrp2(buf);

            /* look for an external function with the same name */
            for (i = vctx->voccxrun->runcxexc,  ex = vctx->voccxrun->runcxext
                 ; i ; ++ex, --i)
            {
                j = strlen(ex->runxnam);
                if (j == buf[2] && !memcmp(buf + 3, ex->runxnam, (size_t)j))
                    break;
            }

            /* if we found an external function of this name, load it */
            if (i && !xfcns_done)
            {
		int (*os_exfld(osfildef *fp, unsigned len))(); //###indep
		ex->runxptr = os_exfld(fp, (unsigned)siz);
#ifdef NEVER
                ex->runxptr = (int (*)())mchalo(ec, (ushort)siz, "XFCN");
                if (osfrb(fp, (uchar *)ex->runxptr, (uint)siz))
                    errsig(ec, ERR_RDGAM);
#endif
            }
            else
            {
                /* this XFCN isn't used; don't bother loading it */
                osfseek(fp, endpos + startofs, OSFSK_SET);
            }
        }
        else if (fioisrsc(buf, "INH"))
        {
	    uchar *p;
	    uchar *bufp;
	    ulong  siz;
	    
	    /* do it in a single file read, if we can, for speed */
            curpos = osfpos(fp) - startofs;
	    siz = endpos - curpos;
	    if (siz && siz < OSMALMAX && (bufp = p = osmalloc((size_t)siz)))
	    {
		uchar *p1;
		ulong  siz2;
		uint   sizcur;

		for (p1 = p, siz2 = siz ; siz2 ; siz2 -= sizcur, p1 += sizcur)
		{
		    sizcur = (siz2 > (uint)0xffff ? (uint)0xffff : siz2);
		    if (osfrb(fp, p1, sizcur)) errsig(ec, ERR_RDGAM);
		}

		while (siz)
		{
		    i = osrp2(p + 7);
		    obj = osrp2(p + 1);
		    
		    vociadd(vctx, obj, osrp2(p+3), i, (objnum *)(p + 9),
			    p[0] | VOCIFXLAT);
		    vocinh(vctx, obj)->vociilc = osrp2(p + 5);
		    
		    p += 9 + (2 * i);
		    siz -= 9 + (2 * i);
		}
		
		/* done with temporary block; free it */
		osfree(bufp);
	    }
	    else
	    {
		while (curpos != endpos)
		{
		    if (osfrb(fp, buf, 9)) errsig(ec, ERR_RDGAM);
		    i = osrp2(buf + 7);       /* get number of superclasses */
		    obj = osrp2(buf + 1);              /* get object number */
		    if (i && osfrb(fp, buf + 9, 2 * i)) errsig(ec, ERR_RDGAM);
		    
		    vociadd(vctx, obj, osrp2(buf+3), i, (objnum *)(buf + 9),
			    buf[0] | VOCIFXLAT);
		    vocinh(vctx, obj)->vociilc = osrp2(buf + 5);
                
		    curpos += 9 + (2 * i);
		}
	    }
        }
        else if (fioisrsc(buf, "REQ"))
        {
            curpos = osfpos(fp) - startofs;
	    siz = endpos - curpos;

            if (osfrb(fp, buf, (uint)siz)) errsig(ec, ERR_RDGAM);
            vctx->voccxme  = osrp2(buf);
            vctx->voccxvtk = osrp2(buf+2);
            vctx->voccxstr = osrp2(buf+4);
            vctx->voccxnum = osrp2(buf+6);
            vctx->voccxprd = osrp2(buf+8);
            vctx->voccxvag = osrp2(buf+10);
            vctx->voccxini = osrp2(buf+12);
            vctx->voccxpre = osrp2(buf+14);
            vctx->voccxper = osrp2(buf+16);
	    
	    /* if we have a cmdPrompt function, read it */
	    if (siz >= 20)
		vctx->voccxprom = osrp2(buf + 18);
	    else
		vctx->voccxprom = MCMONINV;

	    /* if we have the NLS functions, read them */
	    if (siz >= 26)
	    {
		vctx->voccxpdis = osrp2(buf + 20);
		vctx->voccxper2 = osrp2(buf + 22);
		vctx->voccxpdef = osrp2(buf + 24);
	    }
	    else
		vctx->voccxpdis =
		vctx->voccxper2 =
		vctx->voccxpdef = MCMONINV;

	    /* test for parseAskobj separately, as it was added later */
	    if (siz >= 28)
		vctx->voccxpask = osrp2(buf + 26);
	    else
		vctx->voccxpask = MCMONINV;

	    /* test for preparseCmd separately - it's another late comer */
	    if (siz >= 30)
		vctx->voccxppc = osrp2(buf + 28);
	    else
		vctx->voccxppc = MCMONINV;

	    /* check for parseAskobjActor separately - another late comer */
	    if (siz >= 32)
		vctx->voccxpask2 = osrp2(buf + 30);
	    else
		vctx->voccxpask2 = MCMONINV;

	    /*
	     *   We now have all information required to run the init
	     *   function.  If the game is being read for a normal session
	     *   (i.e., no debugging and not a precompiled header), run
	     *   init.  
	     */
	    if ((flags & 1) && !(*flagp & FIOFBIN) && !(*flagp & FIOFSYM))
	    {
		ulong oldpos = osfpos(fp);

		/* set the cursor to normal before running */
		os_csr_busy(FALSE);

		/* run the init function */
		tiosetactor(vctx->voccxtio, vctx->voccxme);
		runrst(vctx->voccxrun);
		runfn(vctx->voccxrun, (objnum)vctx->voccxini, 0);

		/* set the cursor back to "busy" mode */
		os_csr_busy(TRUE);
		
		/* restore seek position prior to running init */
		osfseek(fp, oldpos, OSFSK_SET);
	    }
        }
        else if (fioisrsc(buf, "VOC"))
        {
	    uchar *p;
	    uchar *bufp;
	    ulong  siz;
	    int    len1;
	    int	   len2;
	    
	    /* do it in a single file read, if we can, for speed */
            curpos = osfpos(fp) - startofs;
	    siz = endpos - curpos;
	    if (siz && siz < OSMALMAX && (bufp = p = osmalloc((size_t)siz)))
	    {
		uchar *p1;
		ulong  siz2;
		uint   sizcur;

		for (p1 = p, siz2 = siz ; siz2 ; siz2 -= sizcur, p1 += sizcur)
		{
		    sizcur = (siz2 > (uint)0xffff ? (uint)0xffff : siz2);
		    if (osfrb(fp, p1, sizcur)) errsig(ec, ERR_RDGAM);
		}
		
		while (siz)
		{
		    len1 = osrp2(p);
		    len2 = osrp2(p + 2);
		    if (*flagp & FIOFCRYPT)
			fioxor(p + 10, (uint)(len1 + len2),
			       xor_seed, xor_inc);
		    vocadd2(vctx, osrp2(p+4), osrp2(p+6), osrp2(p+8),
			    p+10, len1,
			    (len2 ? p + 10 + len1 : (uchar*)0), len2);
		    
		    p += 10 + len1 + len2;
		    siz -= 10 + len1 + len2;
		}
		
		/* done with the temporary block; free it up */
		osfree(bufp);
	    }
            else
	    {
		/* can't do it in one file read; do it the slow way */
		while (curpos != endpos)
		{
		    if (osfrb(fp, buf, 10)
			|| osfrb(fp, buf + 10,
			       (len1 = osrp2(buf)) + (len2 = osrp2(buf + 2))))
			errsig(ec, ERR_RDGAM);
                
		    if (*flagp & FIOFCRYPT)
			fioxor(buf + 10, (uint)(len1 + len2),
			       xor_seed, xor_inc);
		    vocadd2(vctx, osrp2(buf+4), osrp2(buf+6), osrp2(buf+8),
			    buf+10, len1,
			    (len2 ? buf + 10 + len1 : (uchar*)0), len2);
		    curpos += 10 + len1 + len2;
		}
	    }
        }
        else if (fioisrsc(buf, "FMTSTR"))
        {
            uchar *fmts;
            uint   fmtl;
            
            if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
            fmtl = osrp2(buf);
            fmts = mchalo(vctx->voccxerr, (ushort)fmtl, "fiord1");
            if (osfrb(fp, fmts, fmtl)) errsig(ec, ERR_RDGAM);
            if (*flagp & FIOFCRYPT) fioxor(fmts, fmtl, xor_seed, xor_inc);
            tiosetfmt(vctx->voccxtio, vctx->voccxrun, fmts, fmtl);
            
            if (fmtsp) *fmtsp = fmts;
            if (fmtlp) *fmtlp = fmtl;
        }
        else if (fioisrsc(buf, "CMPD"))
        {
            if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
            vctx->voccxcpl = osrp2(buf);
            vctx->voccxcpp = (char *)mchalo(vctx->voccxerr,
                                           (ushort)vctx->voccxcpl, "fiord1");
            if (osfrb(fp, vctx->voccxcpp, (uint)vctx->voccxcpl))
                errsig(ec, ERR_RDGAM);
            if (*flagp & FIOFCRYPT)
                fioxor(vctx->voccxcpp, (uint)vctx->voccxcpl,
		       xor_seed, xor_inc);
        }
	else if (fioisrsc(buf, "SPECWORD"))
	{
	    if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
	    vctx->voccxspl = osrp2(buf);
	    vctx->voccxspp = (char *)mchalo(vctx->voccxerr,
					   (ushort)vctx->voccxspl, "fiord1");
	    if (osfrb(fp, vctx->voccxspp, (uint)vctx->voccxspl))
		errsig(ec, ERR_RDGAM);
	    if (*flagp & FIOFCRYPT)
		fioxor(vctx->voccxspp, (uint)vctx->voccxspl,
		       xor_seed, xor_inc);
	}
        else if (fioisrsc(buf, "SYMTAB"))
        {
            tokthdef *symtab;
            
            /* if there's no debugger context, don't bother with this */
            if (!vctx->voccxrun->runcxdbg)
            {
                osfseek(fp, endpos + startofs, OSFSK_SET);
                continue;
            }
            
            if (!(symtab = vctx->voccxrun->runcxdbg->dbgcxtab))
            {
                symtab = (tokthdef *)mchalo(ec, (ushort)sizeof(tokthdef),
                                            "fiord:symtab");
                tokthini(ec, mctx, (toktdef *)symtab);
                vctx->voccxrun->runcxdbg->dbgcxtab = symtab;
            }
            
            /* read symbols until we find a zero-length symbol */
            for (;;)
            {
                int hash;
                
                if (osfrb(fp, buf, 4)) errsig(ec, ERR_RDGAM);
                if (buf[0] == 0) break;
                if (osfrb(fp, buf + 4, (int)buf[0])) errsig(ec, ERR_RDGAM);
                buf[4 + buf[0]] = '\0';
                hash = tokhsh(buf + 4);
                
                (*symtab->tokthsc.toktfadd)((toktdef *)symtab, buf + 4,
                                            (int)buf[0], (int)buf[1],
                                            osrp2(buf + 2), hash);
            }
        }
        else if (fioisrsc(buf, "SRC"))
        {
            /* skip source file id's if there's no debugger context */
            if (!vctx->voccxrun->runcxdbg)
            {
                osfseek(fp, endpos + startofs, OSFSK_SET);
                continue;
            }
            
            while ((osfpos(fp) - startofs) != endpos)
            {
                /* the only thing we know how to read is linfdef's */
                if (linfload(fp, vctx->voccxrun->runcxdbg, ec, path))
                    errsig(ec, ERR_RDGAM);
            }
        }
        else if (fioisrsc(buf, "PREINIT"))
        {
            if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
            *preinit = osrp2(buf);
        }
        else if (fioisrsc(buf, "ERRMSG"))
        {
            errini(ec, fp);
            osfseek(fp, endpos + startofs, OSFSK_SET);
        }
        else if (fioisrsc(buf, "EXTCNT"))
        {
            uchar  *p;
            ushort  len;
	    ulong   siz;
	    ulong   fcnpos;

            curpos = osfpos(fp) - startofs;
	    siz = endpos - curpos;
            if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
            i = osrp2(buf);

            len = i * sizeof(runxdef);
            p = mchalo(ec, len, "fiord:runxdef");
            memset(p, 0, (size_t)len);

            vctx->voccxrun->runcxext = (runxdef *)p;
            vctx->voccxrun->runcxexc = i;

	    /* see if start-of-XFCN information is present */
	    if (siz >= 6)
	    {
		/* get location of first XFCN, and seek there */
		if (osfrb(fp, buf, 4)) errsig(ec, ERR_RDGAM);
		xfcn_pos = osrp4(buf);
	    }

	    /* seek past this resource */
	    osfseek(fp, endpos + startofs, OSFSK_SET);
        }
        else if (fioisrsc(buf, "PRPCNT"))
        {
            if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
            if (pcntptr) *pcntptr = osrp2(buf);
        }
	else if (fioisrsc(buf, "TADSPP") && tctx != 0)
	{
	    tok_read_defines(tctx, fp, ec);
	}
	else if (fioisrsc(buf, "XSI"))
	{
	    if (osfrb(fp, buf, 2)) errsig(ec, ERR_RDGAM);
	    setupctx->fiolcxseed = xor_seed = buf[0];
	    setupctx->fiolcxinc = xor_inc = buf[1];
	    osfseek(fp, endpos + startofs, OSFSK_SET);
	}
        else if (fioisrsc(buf, "$EOF"))
	{
	    if (eof_reset)
	    {
		osfseek(fp, eof_reset, OSFSK_SET);     /* back after EXTCNT */
		eof_reset = 0;                   /* really done at next EOF */
		xfcns_done = TRUE;                 /* don't do XFCN's again */
	    }
	    else
		break;
	}
        else
            errsig(ec, ERR_UNKRSC);
    }
}

/* read binary file */
void fiord(mctx, vctx, tctx, fname, exename, setupctx, preinit, flagp, path,
           fmtsp, fmtlp, pcntptr, flags)
mcmcxdef  *mctx;
voccxdef  *vctx;
tokcxdef  *tctx;
char      *fname;                        /* name of input file to read from */
char      *exename;        /* current program being exe'd - use if no fname */
fiolcxdef *setupctx;                /* loader callback context to be set up */
objnum    *preinit;              /* preinit function, if it needs to be run */
uint      *flagp;                      /* place to put flags read from game */
tokpdef   *path;                                      /* source search path */
uchar    **fmtsp;                     /* format string pool pointer pointer */
uint      *fmtlp;                           /* format string length pointer */
uint      *pcntptr;                               /* property count pointer */
int        flags;             /* &1 ==> run preinit; &2 ==> preload objects */
{
    osfildef *fp;
    osfildef *os_exeseek();
    ulong     startofs;
    
    /* presume there will be no need to run preinit */
    *preinit = MCMONINV;
    
    /* open the file and read and check file header */
    fp = (fname ? osfoprb(fname) : os_exeseek(exename, "TGAM"));
    if (!fp) errsig(vctx->voccxerr, ERR_OPRGAM);

    /* remember starting location in file */
    startofs = osfpos(fp);

    ERRBEGIN(vctx->voccxerr)

    /* read the game file */
    fiord1(mctx, vctx, tctx, fp, setupctx, startofs, preinit, flagp, path,
           fmtsp, fmtlp, pcntptr, flags);

    ERRCLEAN(vctx->voccxerr)
        /* if an error occurs during read, clean up by closing the file */
        osfcls(fp);
    ERRENDCLN(vctx->voccxerr)
}

/* save game header */
#define FIOSAVHDR "TADS2 save\012\015\032"

/* saved game format version string */
#define FIOSAVVSN "v2.2.0"

/* read fuse/daemon/alarm record */
static int fiorfda(fp, p, cnt)
osfildef *fp;
vocddef  *p;
uint      cnt;
{
    vocddef *q;
    uint     i;
    uchar    buf[14];
    
    /* start by clearing out entire record */
    for (i = 0, q = p ; i < cnt ; ++q, ++i)
        q->vocdfn = MCMONINV;
    
    /* now restore all the records from the file */
    for (;;)
    {
        /* read a record, and quit if it's the last one */
        if (osfrb(fp, buf, 13)) return(TRUE);
        if ((i = osrp2(buf)) == 0xffff) return(FALSE);
        
        /* restore this record */
        q = p + i;
        q->vocdfn = osrp2(buf+2);
        q->vocdarg.runstyp = buf[4];
        switch(buf[4])
        {
        case DAT_NUMBER:
            q->vocdarg.runsv.runsvnum = osrp4(buf+5);
            break;
        case DAT_OBJECT:
        case DAT_FNADDR:
            q->vocdarg.runsv.runsvobj = osrp2(buf+5);
            break;
        case DAT_PROPNUM:
            q->vocdarg.runsv.runsvprp = osrp2(buf+5);
            break;
        }
        q->vocdprp = osrp2(buf+9);
        q->vocdtim = osrp2(buf+11);
    }
}

/* restore game: returns TRUE on failure */
int fiorso(vctx, fname)
voccxdef *vctx;
char     *fname;
{
    osfildef   *fp;
    vocidef  ***vpg;
    vocidef   **v;
    int         i;
    int         j;
    objnum      obj;
    uchar      *p;
    uchar      *mut;
    uint        mutsiz;
    uint        oldmutsiz;
    int         propcnt;
    mcmcxdef   *mctx = vctx->voccxmem;
    uchar       buf[sizeof(FIOSAVHDR) + sizeof(FIOSAVVSN)];
    ushort      newsiz;
    int         err = FALSE;
    char        timestamp[26];

    /* open the input file */
    if (!(fp = osfoprb(fname))) return(TRUE);
    
    /* read headers and check */
    if (osfrb(fp, buf, (int)(sizeof(FIOSAVHDR) + sizeof(FIOSAVVSN)))
        || memcmp(buf, FIOSAVHDR, (size_t)sizeof(FIOSAVHDR))
        || memcmp(buf + sizeof(FIOSAVHDR), FIOSAVVSN,
                  (size_t)sizeof(FIOSAVVSN)))
        goto ret_error;
    
    /* read timestamp and check */
    if (osfrb(fp, timestamp, 26)
        || memcmp(timestamp, vctx->voccxtim, (size_t)26))
        goto ret_error;
    
    /* first revert every object to original (post-compilation) state */
    vocrevert(vctx);

    /* go through file and load changed objects */
    for (;;)
    {
	/* get the header */
        if (osfrb(fp, buf, 7))
	    goto ret_error;

	/* get the object number from the header, and stop if we're done */
        obj = osrp2(buf+1);
        if (obj == MCMONINV)
	    break;

	/* if the object was dynamically allocated, recreate it */
	if (buf[0] == 1)
	{
	    int     sccnt;
	    objnum  sc;
	    int     wrdcnt;
	    
	    /* create the object */
	    mutsiz = osrp2(buf + 3);
	    p = mcmalonum(mctx, (ushort)mutsiz, (mcmon)obj);

	    /* read the object's contents */
	    if (osfrb(fp, p, mutsiz)) goto ret_error;

	    /* get the superclass data (at most one superclass) */
	    sccnt = objnsc(p);
	    if (sccnt) sc = osrp2(objsc(p));

	    /* create inheritance records for the object */
	    vociadd(vctx, obj, MCMONINV, sccnt, &sc, VOCIFNEW | VOCIFVOC);

#ifdef NEVER
	    /* read the object's vocabulary and add it back */
	    if (osfrb(fp, buf, 2)) goto ret_error;
	    wrdcnt = osrp2(buf);
	    while (wrdcnt--)
	    {
		int   len1;
		int   len2;
		char  wrd[80];

		/* read the header */
		if (osfrb(fp, buf, 6)) goto ret_error;
		len1 = osrp2(buf+2);
		len2 = osrp2(buf+4);

		/* read the word text */
		if (osfrb(fp, wrd, len1 + len2)) goto ret_error;
		
		/* add the word */
		vocadd2(vctx, buf[0], obj, buf[1], wrd, len1, wrd+len1, len2);
	    }
#endif
	}
	else
	{
            /* get the remaining data from the header */
	    propcnt = osrp2(buf + 3);
	    mutsiz = osrp2(buf + 5);
	
	    /* expand object if it's not big enough for mutsiz */
	    p = mcmlck(mctx, (mcmon)obj);
	    oldmutsiz = mcmobjsiz(mctx, (mcmon)obj) - objrst(p);
	    if (oldmutsiz < mutsiz)
	    {
		newsiz = mutsiz - oldmutsiz;
		p = (uchar *)objexp(mctx, obj, &newsiz);
	    }
            
	    /* reset statistics, and read mutable part from file */
	    mut = p + objrst(p);
	    objsnp(p, propcnt);
	    objsfree(p, mutsiz + objrst(p));
	    if (osfrb(fp, mut, mutsiz))
		err = TRUE;
        
	    /* reset ignore flags as needed */
	    objsetign(mctx, obj);
	}

	/* touch and unlock the object */
	mcmtch(mctx, (mcmon)obj);
        mcmunlck(mctx, (mcmon)obj);
        if (err)
	    goto ret_error;
    }
    
    /* read fuses/daemons/alarms */
    if (fiorfda(fp, vctx->voccxdmn, vctx->voccxdmc)
        || fiorfda(fp, vctx->voccxfus, vctx->voccxfuc)
        || fiorfda(fp, vctx->voccxalm, vctx->voccxalc))
        goto ret_error;

    /* read the dynamically added and deleted vocabulary */
    for (;;)
    {
	int     len1;
	int     len2;
	char    wrd[80];
	int     flags;
	int     typ;
	
	/* read the header */
	if (osfrb(fp, buf, 8)) goto ret_error;

	typ = buf[0];
	flags = buf[1];
	len1 = osrp2(buf+2);
	len2 = osrp2(buf+4);
	obj = osrp2(buf+6);

	/* check to see if this is the end marker */
	if (obj == MCMONINV) break;
	
	/* read the word text */
	if (osfrb(fp, wrd+2, len1)) goto ret_error;
	if (len2)
	{
	    wrd[len1 + 2] = ' ';
	    if (osfrb(fp, &wrd[len1 + 3], len2)) goto ret_error;
	    oswp2(wrd, len1 + len2 + 3);
	}
	else
	    oswp2(wrd, len1 + 2);
	
	/* add or delete the word as appropriate */
	if (flags & VOCFDEL)
	    vocdel1(vctx, obj, wrd, typ, FALSE, FALSE, FALSE);
	else
	    vocadd2(vctx, buf[0], obj, buf[1], wrd+2, len1, wrd+len1, len2);
    }

    /* done - close file and return success indication */
    osfcls(fp);
    return(FALSE);

    /* come here on failure - close file and return error indication */
ret_error:
    osfcls(fp);
    return(TRUE);
}

/* write fuse/daemon/alarm block */
static int fiowfda(fp, p, cnt)
osfildef *fp;
vocddef  *p;
uint      cnt;
{
    uchar buf[14];
    uint  i;
    
    for (i = 0 ; i < cnt ; ++i, ++p)
    {
        if (p->vocdfn == MCMONINV) continue;            /* not set - ignore */
        
        oswp2(buf, i);                        /* element in array to be set */
        oswp2(buf+2, p->vocdfn);       /* object number for function/target */
        buf[4] = p->vocdarg.runstyp;                    /* type of argument */
        switch(buf[4])
        {
        case DAT_NUMBER:
            oswp4(buf+5, p->vocdarg.runsv.runsvnum);
            break;
        case DAT_OBJECT:
        case DAT_FNADDR:
            oswp2(buf+5, p->vocdarg.runsv.runsvobj);
            break;
        case DAT_PROPNUM:
            oswp2(buf+5, p->vocdarg.runsv.runsvprp);
            break;
        }
        oswp2(buf+9, p->vocdprp);
        oswp2(buf+11, p->vocdtim);
        
        /* write this record to file */
        if (osfwb(fp, buf, 13)) return(TRUE);
    }
    
    /* write end record - -1 for array element number */
    oswp2(buf, 0xffff);
    return(osfwb(fp, buf, 13));
}

/* context for vocabulary saver callback function */
struct fiosav_cb_ctx
{
    int       err;
    osfildef *fp;
};

#ifdef NEVER
/*
 *   callback for vocabulary saver - called by voc_iterate for each word
 *   defined for a particular object, allowing us to write all the words
 *   attached to a dynamically allocated object to the save file 
 */
static void fiosav_cb(ctx, voc, vocw)
struct fiosav_cb_ctx *ctx;
vocdef               *voc;
vocwdef              *vocw;
{
    char buf[10];
    
    /* write the part of speech, flags, and word lengths */
    buf[0] = vocw->vocwtyp;
    buf[1] = vocw->vocwflg;
    oswp2(buf+2, voc->voclen);
    oswp2(buf+4, voc->vocln2);
    if (osfwb(ctx->fp, buf, 6)) ctx->err = TRUE;

    /* write the words */
    if (osfwb(ctx->fp, voc->voctxt, voc->voclen + voc->vocln2))
	ctx->err = TRUE;
}
#endif

/*
 *   Callback for vocabulary saver - called by voc_iterate for every
 *   word.  We'll write the word if it was dynamically added or deleted,
 *   so that we can restore that status when the game is restored.  
 */
static void fiosav_voc_cb(ctx, voc, vocw)
struct fiosav_cb_ctx *ctx;
vocdef               *voc;
vocwdef              *vocw;
{
    char buf[10];
    
    /* if the word was dynamically allocated or deleted, save it */
    if ((vocw->vocwflg & VOCFNEW) || (vocw->vocwflg & VOCFDEL))
    {
	/* write the header information */
	buf[0] = vocw->vocwtyp;
	buf[1] = vocw->vocwflg;
	oswp2(buf+2, voc->voclen);
	oswp2(buf+4, voc->vocln2);
	oswp2(buf+6, vocw->vocwobj);
	if (osfwb(ctx->fp, buf, 8)) ctx->err = TRUE;

	/* write the words */
	if (osfwb(ctx->fp, voc->voctxt, voc->voclen + voc->vocln2))
	    ctx->err = TRUE;
    }
}


/* save game; returns TRUE on failure */
int fiosav(vctx, fname)
voccxdef *vctx;
char     *fname;
{
    osfildef   *fp;
    vocidef  ***vpg;
    vocidef   **v;
    int         i;
    int         j;
    objnum      obj;
    uchar      *p;
    uchar      *mut;
    uint        mutsiz;
    int         propcnt;
    mcmcxdef   *mctx = vctx->voccxmem;
    uchar       buf[7];
    int         err = FALSE;
    int         wrdcnt;
    struct fiosav_cb_ctx  fnctx;

    /* open the output file */
    if (!(fp = osfopwb(fname))) return(TRUE);
    
    /* write save game header and timestamp */
    if (osfwb(fp, FIOSAVHDR, (int)sizeof(FIOSAVHDR))
        || osfwb(fp, FIOSAVVSN, (int)sizeof(FIOSAVVSN))
        || osfwb(fp, vctx->voccxtim, 26))
        goto ret_error;

    /* go through each object, and write if it's been changed */
    for (vpg = vctx->voccxinh, i = 0 ; i < VOCINHMAX ; ++vpg, ++i)
    {
        if (!*vpg) continue;
        for (v = *vpg, obj = (i << 8), j = 0 ; j < 256 ; ++v, ++obj, ++j)
        {
            if (*v)
            {
                /* write object if it's dirty */
                if (mcmobjdirty(mctx, (mcmon)obj))
                {
                    p = mcmlck(mctx, (mcmon)obj);
                    mut = p + objrst(p);
                    propcnt = objnprop(p);
                    mutsiz = objfree(p) - objrst(p);
		    if (objflg(p) & OBJFINDEX) mutsiz += propcnt * 4;

		    /*
		     *   If the object was dynamically allocated, write
		     *   the whole object.  Otherwise, write just the
		     *   mutable part. 
		     */
		    if ((*v)->vociflg & VOCIFNEW)
		    {
			/* indicate that the object is dynamic */
			buf[0] = 1;
			oswp2(buf + 1, obj);

			/* write the entire object */
			mutsiz = objfree(p);
			oswp2(buf + 3, mutsiz);
			if (osfwb(fp, buf, 7)
			    || osfwb(fp, p, mutsiz))
			    err = TRUE;

#ifdef NEVER
			/* count the words, and write the count */
			voc_count(vctx, obj, 0, &wrdcnt, (int *)0);
			oswp2(buf, wrdcnt);
			if (osfwb(fp, buf, 2)) err = TRUE;

			/* write the words */
			fnctx.err = 0;
			fnctx.fp = fp;
			voc_iterate(vctx, obj, fiosav_cb, &fnctx);
			if (fnctx.err) err = TRUE;
#endif
		    }
		    else if (mutsiz)
                    {
                        /* write number of properties, size of mut, and mut */
			buf[0] = 0;   /* indicate that the object is static */
                        oswp2(buf + 1, obj);
                        oswp2(buf + 3, propcnt);
                        oswp2(buf + 5, mutsiz);
                        if (osfwb(fp, buf, 7)
                            || osfwb(fp, mut, mutsiz))
                            err = TRUE;
                    }
                    
                    mcmunlck(mctx, (mcmon)obj);
                    if (err) goto ret_error;
                }
            }
        }
    }

    /* write end-of-objects indication */
    buf[0] = 0;
    oswp2(buf + 1, MCMONINV);
    oswp4(buf + 3, 0);
    if (osfwb(fp, buf, 7)) goto ret_error;

    /* write fuses/daemons/alarms */
    if (fiowfda(fp, vctx->voccxdmn, vctx->voccxdmc)
        || fiowfda(fp, vctx->voccxfus, vctx->voccxfuc)
        || fiowfda(fp, vctx->voccxalm, vctx->voccxalc))
        goto ret_error;

    /* write run-time vocabulary additions and deletions */
    fnctx.fp = fp;
    fnctx.err = 0;
    voc_iterate(vctx, MCMONINV, fiosav_voc_cb, &fnctx);
    if (fnctx.err) goto ret_error;

    /* write end marker for vocabulary additions and deletions */
    oswp2(buf+6, MCMONINV);
    if (osfwb(fp, buf, 8)) goto ret_error;
    
    /* done - close file and return success indication */
    osfcls(fp);
    os_settype(fname, OSFTSAVE);
    return(FALSE);

    /* come here on failure - close file and return error indication */
ret_error:
    osfcls(fp);
    return(TRUE);
}
