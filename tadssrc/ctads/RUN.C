/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  run.c - code execution
Function
  Executes p-code
Notes
  Due to the highly mobile memory architecture of this version of TADS,
  objects and data within objects can move at certain junctures.  At
  these times, pointers to object data become invalid, and it's necessary
  to re-establish those pointers.  Two functions are provided to facilitate
  this.  runcpsav() is called prior to an operation that may move object
  data; it returns the offset within the object and property of the
  code being executed, and unlocks the object.  runcprst() is called
  after such an operation; it relocks the object, and returns a pointer
  to the property data.  Note that the special property number zero is
  used for functions; this indicates that no prpdef structuring is done
  on the object, but that its actual data start at offset 0.
Modified
  10/20/91 MJRoberts     - creation
*/

/* the following hack is required to work around a Think C capacity bug */
#ifdef THINK_C
#include "PreCompiled.h"
#endif

#ifdef RCSID
static char RCSid[] =
"$Header: d:/tads/tads2/RCS/run.c 1.7 96/10/14 16:10:45 mroberts Exp $";
#endif

#include <stdlib.h>
#include <string.h>

#include "run.h"
#include "dbg.h"
#include "lst.h"
#include "obj.h"
#include "voc.h"

/*
 *   Create a new object
 */
void run_new(ctx)
runcxdef *ctx;
{
    objnum   sc;
    objnum   objn;
    objdef  *objp;
    int      sccnt;
    vocidef *voci;
    
    /* get the superclass (nil means no superclass) */
    if (runtostyp(ctx) == DAT_NIL)
        sccnt = 0;
    else
    {
        /* get the superclass */
        sc = runpopobj(ctx);
        sccnt = 1;

        /* make sure it's not a dynamically-allocated object */
        voci = vocinh(ctx->runcxvoc, sc);
        if (voci->vociflg & VOCIFNEW)
            runsig(ctx, ERR_BADNEWSC);
    }

    /* create a new object and set its superclass */
    objp = objnew(ctx->runcxmem, sccnt, 64, &objn, FALSE);
    if (sccnt) oswp2(objsc(objp), sc);

    /* save undo for the object creation */
    vocdusave_newobj(ctx->runcxvoc, objn);

    /* touch and unlock the object */
    mcmtch(ctx->runcxmem, (mcmon)objn);
    mcmunlck(ctx->runcxmem, (mcmon)objn);

    /* add a vocabulary inheritance record for the new object */
    vociadd(ctx->runcxvoc, objn, MCMONINV, sccnt, &sc, VOCIFNEW | VOCIFVOC);

    /* set up its vocabulary, inheriting from the class */
    if (sccnt)
        supivoc1((struct supcxdef *)0, ctx->runcxvoc,
                 vocinh(ctx->runcxvoc, objn), objn, TRUE, VOCFNEW);

    /* run the constructor */
    runppr(ctx, objn, PRP_CONSTRUCT, 0);
#ifdef NEVER
    /*
     *   add it to its location's contents list by calling
     *   newobj.moveInto(newobj.location)
     */
    runppr(ctx, objn, PRP_LOCATION, 0);
    if (runtostyp(ctx) == DAT_OBJECT)
        runppr(ctx, objn, PRP_MOVEINTO, 1);
    else
        rundisc(ctx);
#endif

    /* return the new object */
    runpobj(ctx, objn);
}

/*
 *   Delete an object 
 */
void run_delete(ctx)
runcxdef *ctx;
{
    objnum    objn;
    vocidef  *voci;
    int       i;
    voccxdef *vctx = ctx->runcxvoc;

    /* get the object to be deleted */
    objn = runpopobj(ctx);

    /* make sure it was allocated with "new" */
    voci = vocinh(vctx, objn);
    if (!(voci->vociflg & VOCIFNEW))
        runsig(ctx, ERR_BADDEL);
    
    /* run the destructor */
    runppr(ctx, objn, PRP_DESTRUCT, 0);
#ifdef NEVER
    /* remove it from its location, if any, by using moveInto(nil) */
    runpnil(ctx);
    runppr(ctx, objn, PRP_MOVEINTO, 1);
#endif

    /* save undo for the object deletion */
    vocdusave_delobj(vctx, objn);

    /* delete the object's inheritance and vocabulary records */
    vocdel(vctx, objn);
    vocidel(vctx, objn);

    /* delete the memory manager object */
    mcmfre(ctx->runcxmem, (mcmon)objn);

    /* forget 'it' if the deleted object is 'it' (or 'them', etc) */
    if (vctx->voccxit == objn) vctx->voccxit = MCMONINV;
    if (vctx->voccxhim == objn) vctx->voccxhim = MCMONINV;
    if (vctx->voccxher == objn) vctx->voccxher = MCMONINV;
    for (i = 0 ; i < vctx->voccxthc ; ++i)
    {
        if (vctx->voccxthm[i] == objn)
        {
            /* forget the entire 'them' list when deleting from it */
            vctx->voccxthc = 0;
            break;
        }
    }

    /* forget the 'again' statistics if necessary */
    if (vctx->voccxlsd == objn || vctx->voccxlsa == objn
        || vctx->voccxlsv == objn || vctx->voccxlsp == objn
        || vctx->voccxlsa == objn)
        vctx->voccxlsv = MCMONINV;
}


void runfn(ctx, objn, argc)
runcxdef     *ctx;
noreg objnum  objn;
int           argc;                                       /* argument count */
{
    uchar *fn;
    int    err;
    
    NOREG((&objn))

    /* get a lock on the object */
    fn = mcmlck(ctx->runcxmem, objn);
    
    /* catch any errors, so we can unlock the object */
    ERRBEGIN(ctx->runcxerr)

    /* execute the object */
    runexe(ctx, fn, MCMONINV, objn, (prpnum)0, argc);

    /* in case of error, unlock the object and resignal the error */
    ERRCATCH(ctx->runcxerr, err)
        mcmunlck(ctx->runcxmem, objn);    /* release the lock on the object */
        if (err < ERR_RUNEXIT || err > ERR_RUNRESTART)
            dbgdump(ctx->runcxdbg);                       /* dump the stack */
        errrse(ctx->runcxerr);
    ERREND(ctx->runcxerr)
    
    /* we're done with the object, so unlock it */
    mcmunlck(ctx->runcxmem, objn);
}

/* compress the heap - remove unreferenced items */
void runhcmp(ctx, siz, below, val1, val2, val3)
runcxdef *ctx;
uint      siz;
uint      below;      /* number of elements below stack pointer to consider */
runsdef  *val1;
runsdef  *val2;
runsdef  *val3;
{
    uchar    *hp   = ctx->runcxheap; //###uchar
    uchar    *htop = ctx->runcxhp; //###uchar
    runsdef *stop = ctx->runcxsp + below;
    runsdef *stk  = ctx->runcxstk;
    runsdef *sp;
    uchar   *dst  = hp; //###uchar
    uchar   *hnxt; //###uchar
    int     ref;
    
    /* go through heap, finding references on stack */
    for ( ; hp < htop ; hp = hnxt)
    {
        hnxt = hp + osrp2(hp);                /* remember next heap element */

        for (ref = FALSE, sp = stk ; sp < stop ; ++sp)
        {
            switch(sp->runstyp)
            {
            case DAT_SSTRING:
            case DAT_LIST:
                if (sp->runsv.runsvstr == (char*)hp)    /* reference to this item? */ //###cast
                {
                    ref = TRUE;             /* this heap item is referenced */
                    sp->runsv.runsvstr = (char*)dst;      /* reflect imminent move */ //###cast
                }
                break;
                
            default:                /* other types do not refer to the heap */
                break;
            }
        }

        /* check the explicitly referenced value pointers as well */
#define CHECK_VAL(val) \
        if (val && val->runsv.runsvstr == (char*)hp) \
            ref = TRUE, val->runsv.runsvstr = (char*)dst; //###casts
        CHECK_VAL(val1);
        CHECK_VAL(val2);
        CHECK_VAL(val3);
#undef CHECK_VAL

        /* if referenced, copy it to dst and advance dst */
        if (ref)
        {
            if (hp != dst) memmove(dst, hp, (size_t)osrp2(hp));
            dst += osrp2(dst);
        }
    }

    /* set heap pointer based on shuffled heap */
    ctx->runcxhp = dst;
    
    /* check for space requested, and signal error if not available */
    if (ctx->runcxhtop - ctx->runcxhp < siz)
        runsig(ctx, ERR_HPOVF);
}

/* push a value onto the stack that's already been allocated in heap */
void runrepush(ctx, val)
runcxdef *ctx;
runsdef  *val;
{
    /* check for stack overflow */
    runstkovf(ctx);
    
    OSCPYSTRUCT(*(ctx->runcxsp), *val);

    /* increment stack pointer */
    ++(ctx->runcxsp);
}

/* push a counted-length string onto the stack */
void runpstr(ctx, str, len, sav)
runcxdef *ctx;
char     *str;
int       len;
int       sav;                          /* stack items to save (in runhres) */
{
    runsdef val;
    
    /* allocate space and set up new string */
    runhres(ctx, len+2, sav);
    oswp2(ctx->runcxhp, len+2);
    memcpy(ctx->runcxhp+2, str, (size_t)len);

    /* push return value */
    val.runsv.runsvstr = (char*)ctx->runcxhp; //###cast
    val.runstyp = DAT_SSTRING;
    ctx->runcxhp += len + 2;
    runrepush(ctx, &val);
}

/* push a value onto the stack */
void runpush(ctx, typ, val)
runcxdef *ctx;
dattyp    typ;
runsdef  *val;
{
    int len;

    /* check for stack overflow */
    runstkovf(ctx);
    
    OSCPYSTRUCT(*(ctx->runcxsp), *val);
    ctx->runcxsp->runstyp = typ;

    /* variable-length data must be copied into the heap */
    if (typ == DAT_SSTRING || typ == DAT_LIST)
    {
        len = osrp2(val->runsv.runsvstr);
        runhres(ctx, len, 0);                      /* reserve space in heap */
        memcpy(ctx->runcxhp, val->runsv.runsvstr, (size_t)len);
        ctx->runcxsp->runsv.runsvstr = (char*)ctx->runcxhp; //###cast
        ctx->runcxhp += len;
    }
    
    /* increment stack pointer */
    ++(ctx->runcxsp);
}

/* push a number onto the stack */
void runpnum(ctx, num)
runcxdef *ctx;
long      num;
{
    runsdef val;
    
    val.runsv.runsvnum = num;
    runpush(ctx, DAT_NUMBER, &val);
}

/* push an object onto the stack (or nil if obj is MCMONINV) */
void runpobj(ctx, obj)
runcxdef *ctx;
objnum    obj;
{
    runsdef val;
    
    if (obj == MCMONINV)
        runpnil(ctx);
    else
    {
        val.runsv.runsvobj = obj;
        runpush(ctx, DAT_OBJECT, &val);
    }
}

/* push nil */
void runpnil(ctx)
runcxdef *ctx;
{
    runsdef val;
    runpush(ctx, DAT_NIL, &val);
}

/* copy datatype + value from a runsdef into a buffer (such as list) */
void runputbuf(dstp, val)
uchar   *dstp;
runsdef *val;
{
    *dstp++ = val->runstyp;
    switch(val->runstyp)
    {
    case DAT_LIST:
    case DAT_SSTRING:
        memcpy(dstp, val->runsv.runsvstr, (size_t)osrp2(val->runsv.runsvstr));
        break;
        
    case DAT_NUMBER:
        oswp4(dstp, val->runsv.runsvnum);
        break;
        
    case DAT_PROPNUM:
        oswp2(dstp, val->runsv.runsvprp);
        break;
        
    case DAT_OBJECT:
    case DAT_FNADDR:
        oswp2(dstp, val->runsv.runsvobj);
        break;
    }
}

/* push a value from a buffer (list, property, etc) onto stack */
void runpbuf(ctx, typ, valp)
runcxdef *ctx;
int       typ;
dvoid    *valp;
{
    runsdef val;
    
    switch(typ)
    {
    case DAT_NUMBER:
        val.runsv.runsvnum = osrp4(valp);
        break;
        
    case DAT_OBJECT:
    case DAT_FNADDR:
        val.runsv.runsvobj = osrp2(valp);
        break;
        
    case DAT_PROPNUM:
        val.runsv.runsvprp = osrp2(valp);
        break;
        
    case DAT_SSTRING:
    case DAT_LIST:
        val.runsv.runsvstr = valp;
        break;
        
    case DAT_NIL:
    case DAT_TRUE:
        break;
    }
    runpush(ctx, typ, &val);
}

/* compare items at top of stack for equality; TRUE->equal, FALSE->unequal */
int runeq(ctx)
runcxdef *ctx;
{
    runsdef val1, val2;
    
    /* get values, and see if they have identical type; not equal if not */
    runpop(ctx, &val1);
    runpop(ctx, &val2);
    if (val1.runstyp != val2.runstyp) return(FALSE);
    
    /* types match, so check values */
    switch(val1.runstyp)
    {
    case DAT_NUMBER:
        return(val1.runsv.runsvnum == val2.runsv.runsvnum);
        
    case DAT_SSTRING:
    case DAT_LIST:
        return(osrp2(val1.runsv.runsvstr) == osrp2(val2.runsv.runsvstr)
               && !memcmp(val1.runsv.runsvstr, val2.runsv.runsvstr,
                          (size_t)osrp2(val1.runsv.runsvstr)));
        
    case DAT_PROPNUM:
        return(val1.runsv.runsvprp == val2.runsv.runsvprp);
        
    case DAT_OBJECT:
    case DAT_FNADDR:
        return(val1.runsv.runsvobj == val2.runsv.runsvobj);
        
    default:
        return(TRUE);
    }
}

/* compare magnitudes of numbers/strings at top of stack; strcmp-like value */
int runmcmp(ctx)
runcxdef *ctx;
{
    if (runtostyp(ctx) == DAT_NUMBER)
    {
        long num2 = runpopnum(ctx);
        long num1 = runpopnum(ctx);
        
        if (num1 > num2) return(1);
        else if (num1 < num2) return(-1);
        else return(0);
    }
    else if (runtostyp(ctx) == DAT_SSTRING)
    {
        char *str2 = runpopstr(ctx);
        char *str1 = runpopstr(ctx);
        uint  len1 = osrp2(str1) - 2;
        uint  len2 = osrp2(str2) - 2;
        
        str1 += 2;
        str2 += 2;
        while (len1 && len2)
        {
            if (*str1 < *str2) return(-1);   /* character from 1 is greater */
            else if (*str1 > *str2) return(1);       /* char from 1 is less */
            
            ++str1;
            ++str2;
            --len1;
            --len2;
        }
        if (len1) return(1);    /* match up to len2, but string 1 is longer */
        else if (len2) return(-1);  /* match up to len1, but str2 is longer */
        else return(0);                            /* strings are identical */
    }
    else
    {
        runsig(ctx, ERR_INVCMP);
    }
    return 0;
}

/* determine size of a runsdef item */
int runsiz(item)
runsdef *item;
{
    switch(item->runstyp)
    {
    case DAT_NUMBER:
        return(4);
    case DAT_SSTRING:
    case DAT_LIST:
        return(osrp2(item->runsv.runsvstr));
    case DAT_PROPNUM:
    case DAT_OBJECT:
    case DAT_FNADDR:
        return(2);
    default:
        return(0);
    }
}

/* find a sublist within a list */
uchar *runfind(lst, item)
uchar   *lst;
runsdef *item;
{
    uint len;
    uint curlen;
    
    for (len = osrp2(lst) - 2, lst += 2 ; len ; lst += curlen, len -= curlen)
    {
        if (*lst == item->runstyp)
        {
            switch(*lst)
            {
            case DAT_LIST:
            case DAT_SSTRING:
                if (osrp2(lst+1) == osrp2(item->runsv.runsvstr) &&
                   !memcmp(lst+1, item->runsv.runsvstr, (size_t)osrp2(lst+1)))
                    return(lst);
                break;
            case DAT_NUMBER:
                if (osrp4(lst+1) == item->runsv.runsvnum)
                    return(lst);
                break;

            case DAT_TRUE:
            case DAT_NIL:
                return(lst);

            case DAT_OBJECT:
            case DAT_FNADDR:
                if (osrp2(lst+1) == item->runsv.runsvobj)
                    return(lst);
                break;

            case DAT_PROPNUM:
                if (osrp2(lst+1) == item->runsv.runsvprp)
                    return(lst);
                break;
            }
        }
        curlen = datsiz(*lst, lst+1) + 1;
    }
    return((uchar *)0);
}

/* add values */
void runadd(ctx, val, val2, below)
runcxdef *ctx;
runsdef  *val;                           /* first operand, also destination */
runsdef  *val2;                                           /* second operand */
uint      below;        /* number of items on stack to save during compress */
{
    if (val->runstyp == DAT_LIST)
    {
        int     len1 = osrp2(val->runsv.runsvstr);
        int     len2 = runsiz(val2);
        runsdef val3;
        int     newlen;

        /* if concatenating a list, take out length + datatype from 2nd */
        if (val2->runstyp == DAT_LIST)
            newlen = len1 + len2 - 2;          /* leave out second list len */
        else
            newlen = len1 + len2 + 1;             /* add in datatype header */

        /* get space in heap, copy first list, and set new length */
        runhres2(ctx, newlen, below, val, val2);
        memcpy(ctx->runcxhp, val->runsv.runsvstr, (size_t)len1);
        oswp2(ctx->runcxhp, newlen);

        /* append the new element or list of elements */
        if (val2->runstyp == DAT_LIST)
            memcpy(ctx->runcxhp + len1, val2->runsv.runsvstr + 2,
                   (size_t)(len2 - 2));
        else
            runputbuf(ctx->runcxhp + len1, val2);

        /* set up return value and update heap pointer */
        val->runsv.runsvstr = (char*)ctx->runcxhp; //###cast
        ctx->runcxhp += newlen;
    }
    else if (val->runstyp==DAT_SSTRING && val2->runstyp==DAT_SSTRING)
    {
        int len1 = osrp2(val->runsv.runsvstr);
        int len2 = osrp2(val2->runsv.runsvstr);

        /* reserve space, and concatenate the two strings */
        runhres2(ctx, len1 + len2 - 2, below, val, val2);
        memcpy(ctx->runcxhp, val->runsv.runsvstr, (size_t)len1);
        memcpy(ctx->runcxhp + len1, val2->runsv.runsvstr + 2,
               (size_t)len2 - 2);

        /* set length to sum of two lengths, minus 2nd length word */
        oswp2(ctx->runcxhp, len1 + len2 - 2);
        val->runsv.runsvstr = (char*)ctx->runcxhp; //###cast
        ctx->runcxhp += len1 + len2 - 2;
    }
    else if (val->runstyp == DAT_NUMBER && val2->runstyp == DAT_NUMBER)
        val->runsv.runsvnum += val2->runsv.runsvnum;
    else
        runsig(ctx, ERR_INVADD);
}

/* returns TRUE if value changed */
int runsub(ctx, val, val2, below)
runcxdef *ctx;
runsdef  *val;                           /* first operand, also destination */
runsdef  *val2;                                           /* second operand */
uint      below;            /* number of stack elements to save in compress */
{
    if (val->runstyp == DAT_LIST)
    {
        uchar *sublist;
        int    subsize;
        int    listsize;
        int    part1sz;

        if (val2->runstyp == DAT_LIST)
        {
            uchar *p1;
            uchar *p2;
            uint   rem1;
            uint   rem2;
            uchar *dst;

            /* reserve space for another copy of first list */
            listsize = runsiz(val);
            runhres2(ctx, listsize, below, val, val2);
            dst = ctx->runcxhp + 2;

            /* get pointer to first list */
            p1 = (uchar*)val->runsv.runsvstr; //###cast
            rem1 = osrp2(p1) - 2;
            p1 += 2;

            /*
             *   loop through left list, copying elements to output if
             *   not in the right list 
             */
            for ( ; rem1 ; lstadv(&p1, &rem1))
            {
                int found = FALSE;
                
                /* find current element of first list in second list */
                p2 = (uchar*)val2->runsv.runsvstr; //###cast
                rem2 = osrp2(p2) - 2;
                p2 += 2;
                for ( ; rem2 ; lstadv(&p2, &rem2))
                {
                    if (*p1 == *p2)
                    {
                        int siz1 = datsiz(*p1, p1+1);
                        int siz2 = datsiz(*p2, p2+1);

                        if (siz1 == siz2 &&
                            (siz1 == 0 || !memcmp(p1+1, p2+1, (size_t)siz1)))
                        {
                            found = TRUE;
                            break;
                        }
                    }
                }

                /* if this element wasn't found, copy to output list */
                if (!found)
                {
                    uint siz;
                    
                    *dst++ = *p1;
                    if (siz = datsiz(*p1, p1+1))
                    {
                        memcpy(dst, p1+1, siz);
                        dst += siz;
                    }
                }
            }

            /* we've built the list; write size and we're done */
            oswp2(ctx->runcxhp, dst - ctx->runcxhp);
            val->runsv.runsvstr = (char*)ctx->runcxhp; //###cast
            ctx->runcxhp = dst;
        }
        else if (sublist = runfind(val->runsv.runsvstr, val2))
        {
            subsize = datsiz(*sublist, sublist + 1) + 1;
            listsize = runsiz(val);
            part1sz = sublist - (uchar *)val->runsv.runsvstr;

            runhres2(ctx, listsize - subsize, below, val, val2);
            memcpy(ctx->runcxhp, val->runsv.runsvstr, (size_t)part1sz);
            memcpy(ctx->runcxhp + part1sz, sublist + subsize,
                   (size_t)(listsize - subsize - part1sz));
            oswp2(ctx->runcxhp, listsize - subsize);
            val->runsv.runsvstr = (char*)ctx->runcxhp; //###cast
            ctx->runcxhp += listsize - subsize;
        }
        else
        {
            return(FALSE);            /* no change - value can be re-pushed */
        }
    }
    else if (val->runstyp == DAT_NUMBER && val2->runstyp == DAT_NUMBER)
        val->runsv.runsvnum -= val2->runsv.runsvnum;
    else
        runsig(ctx, ERR_INVSUB);

    return(TRUE);                 /* value has changed; must be pushed anew */
}

/* return code pointer offset */
uint runcpsav(ctx, cp, obj, prop)
runcxdef *ctx;
uchar    *cp;
objnum    obj;
prpnum    prop;
{
    uint ofs;
    
    VARUSED(prop);
    
    /* get offset from start of object */
    ofs = cp - mcmobjptr(ctx->runcxmem, (mcmon)obj);

    /* unlock the object, and return the derived offset */
    mcmunlck(ctx->runcxmem, (mcmon)obj);
    return(ofs);
}

/* restore code pointer based on object.property */
uchar *runcprst(ctx, ofs, obj, prop)
runcxdef *ctx;
uint      ofs;
objnum    obj;
prpnum    prop;
{
    uchar *ptr;
    
    VARUSED(prop);
    
    /* lock object, and get pointer based on offset */
    ptr = mcmlck(ctx->runcxmem, (mcmon)obj) + ofs;
    
    return(ptr);
}

/* get offset of an element within a list */
uint runindofs(ctx, indx, lstp)
runcxdef *ctx;
uint      indx;
uchar    *lstp;
{
    uint   cursiz;
    uint   lstsiz;
    uchar *orgp = lstp;
    
    /* verify that index is in range */
    if (indx <= 0) runsig(ctx, ERR_LOWINX);

    /* get list's size, and point to its data string */
    lstsiz = osrp2(lstp) - 2;
    lstp += 2;

    /* skip the first indx-1 elements */
    for (--indx ; indx && lstsiz ; --indx) lstadv(&lstp, &lstsiz);
    
    /* if we ran out of list, the index is out of range */
    if (!lstsiz) runsig(ctx, ERR_HIGHINX);
    
    /* return the offset */
    return((uint)(lstp - orgp));
}

/* push an indexed element of a list; index is tos, list is next on stack */
void runpind(ctx, indx, lstp)
runcxdef *ctx;
uint      indx;
uchar    *lstp;
{
    uchar   *ele;
    runsdef  val;

    /* find the element we want to push */
    ele = lstp + runindofs(ctx, indx, lstp);

    /* reserve space first, in case lstp gets moved around */
    val.runstyp = DAT_LIST;
    val.runsv.runsvstr = (char*)lstp; //###cast
    runhres1(ctx, datsiz(*ele, ele + 1), 0, &val);
    if (val.runsv.runsvstr != (char*)lstp) //###cast
        ele = (uchar*)val.runsv.runsvstr + runindofs(ctx, indx, val.runsv.runsvstr); //###cast

    /* push the operand */
    runpbuf(ctx, *ele, ele+1);
}

/* push an object's property */
void runpprop(ctx, codepp, callobj, callprop, obj, prop, inh, argc, self)
runcxdef      *ctx;
uchar        **codepp;          /* pointer to code pointer (may be changed) */
objnum         callobj;           /* target object being executed by caller */
prpnum         callprop; /* prop being executed in caller (0 for functions) */
noreg objnum   obj;                /* object whose property is to be pushed */
prpnum         prop;                                    /* property to push */
int            inh;   /* flag: TRUE --> inheriting only, FALSE --> obj.prop */
int            argc;                                      /* argument count */
objnum         self;                               /* current 'self' object */
{
    uint     pofs;
    uint     saveofs;
    objdef  *objptr;
    prpdef  *prpptr;
    uchar   *val;
    int      typ;
    runsdef  sval;
    objnum   target;
    int      times_through = 0;
    int      err;
    objnum   otherobj;
    
    if (obj == MCMONINV) runsig(ctx, ERR_RUNNOBJ);
    
    NOREG((&obj))
        
startover:
    pofs = objgetap(ctx->runcxmem, obj, prop, &target, inh);
    
    /* if nothing was found, push nil */
    if (!pofs)
    {
        runpush(ctx, DAT_NIL, &sval);
        return;
    }

    /* found a property; get the prpdef, and the value and type of data */
    objptr = (objdef*)mcmlck(ctx->runcxmem, target); //###cast
    ERRBEGIN(ctx->runcxerr)         /* catch errors so we can unlock object */

    prpptr = (prpdef *)(((uchar *)objptr) + pofs);
    val = prpvalp(prpptr);
    typ = prptype(prpptr);

    /* determine what to do based on property type */
    switch(typ)
    {
    case DAT_CODE:
        /* save caller's code offset - caller's object may move */
        if (codepp)
            saveofs = runcpsav(ctx, *codepp, callobj, callprop);
        
        /* execute the code */
        runexe(ctx, val, self, target, prop, argc);
        
        /* restore caller's code pointer in case object moved */
        if (codepp)
            *codepp = runcprst(ctx, saveofs, callobj, callprop);
        break;

    case DAT_REDIR:
        otherobj = osrp2(val);
        break;

    case DAT_DSTRING:
        outfmt(ctx->runcxtio, val);
        break;
        
    case DAT_DEMAND:
        break;
        
    default:
        runpbuf(ctx, typ, val);
        break;
    }

    /* we're done - unlock the object */
    mcmunlck(ctx->runcxmem, target);

    /* if it's redirected, redirect it now */
    if (typ == DAT_REDIR)
    {
        runpprop(ctx, codepp, callobj, callprop, otherobj, prop,
                 FALSE, argc, otherobj);
    }

    /* if an error occurs, unlock the object, and resignal the error */
    ERRCATCH(ctx->runcxerr, err)
        mcmunlck(ctx->runcxmem, target);
        if (err < ERR_RUNEXIT || err > ERR_RUNRESTART)
            dbgdump(ctx->runcxdbg);                       /* dump the stack */
        errrse(ctx->runcxerr);
    ERREND(ctx->runcxerr)

    /* apply special handling for set-on-first-use data */
    if (typ == DAT_DEMAND)
    {
        /*
         *   if we've already done this, the property isn't being set by
         *   the callback, so we'll never get out of this loop - abort if
         *   so 
         */
        if (++times_through != 1)
            runsig(ctx, ERR_DMDLOOP);

        /* save caller's code offset - caller's object may move */
        if (codepp)
            saveofs = runcpsav(ctx, *codepp, callobj, callprop);

        /* invoke the callback to set the property on demand */
        (*ctx->runcxdmd)(ctx->runcxdmc, obj, prop);

        /* restore caller's code pointer */
        if (codepp)
            *codepp = runcprst(ctx, saveofs, callobj, callprop);

        /* try again now that it's been set up */
        goto startover;
    }
}

/* ======================================================================== */
/*
 *   user exit callbacks 
 */

int runuftyp(ctx)
runuxdef *ctx;
{
    return(runtostyp(ctx->runuxctx));
}

long runufnpo(ctx)
runuxdef *ctx;
{
    return(runpopnum(ctx->runuxctx));
}

char *runufspo(ctx)
runuxdef *ctx;
{
    return(runpopstr(ctx->runuxctx));
}

void runufdsc(ctx)
runuxdef *ctx;
{
    rundisc(ctx->runuxctx);
}

void runufnpu(ctx, num)
runuxdef *ctx;
long      num;
{
    runpnum(ctx->runuxctx, num);
}

void runufspu(ctx, str)
runuxdef *ctx;
char     *str;
{
    runsdef val;
    
    val.runstyp = DAT_SSTRING;
    val.runsv.runsvstr = str - 2;
    runrepush(ctx->runuxctx, &val);
}

void runufcspu(ctx, str)
runuxdef *ctx;
char     *str;
{
    runpstr(ctx->runuxctx, str, (int)strlen(str), ctx->runuxargc);
}

char *runufsal(ctx, len)
runuxdef *ctx;
int       len;
{
    char *ret;
    
    len += 2;
    runhres(ctx->runuxctx, len, ctx->runuxargc);
    ret = (char*)ctx->runuxctx->runcxhp; //###cast
    oswp2(ret, len);
    ret += 2;
    
    ctx->runuxctx->runcxhp += len;
    return(ret);
}

void runuflpu(ctx, typ)
runuxdef *ctx;
int       typ;
{
    runsdef val;
    
    val.runstyp = typ;
    runrepush(ctx->runuxctx, &val);
}



/* convert an osrp2 value to a signed short value */
#define runrp2s(p) ((short)(ushort)osrp2(p))


/* ======================================================================== */
/*
 *   execute p-code 
 */
void runexe(ctx, p, self, target, targprop, argc)
runcxdef *ctx;
uchar    *p;                              /* pointer to code being executed */
objnum    self;                                     /* 'self' object number */
objnum    target;             /* object whose code we're actually executing */
prpnum    targprop;         /* property being executed (zero for functions) */
int       argc;                                           /* argument count */
{
    uchar     opc;                     /* opcode we're currently working on */
    runsdef   val;                           /* stack element (for pushing) */
    runsdef   val2;     /* another one (for popping in two-op instructions) */
    uint      ofs;                   /* offset in code of current execution */
    prpnum    prop;                         /* property number, when needed */
    objnum    obj;                            /* object number, when needed */
    runsdef  *rstsp;              /* sp to reset to on DISCARD instructions */
    uchar    *lstp;                                         /* list pointer */
    uint      lstsiz;                                       /* size of list */
    int       nargc;                   /* argument count of called function */
    runsdef  *valp;
    runsdef  *stkval;
    int       i;
    int       brkchk;
    
    /* save entry SP - this is reset point until ENTER */
    rstsp = ctx->runcxsp;
    
    for (brkchk = 0 ;; ++brkchk)
    {
        /* check for break - signal if user has hit break */
        if (brkchk == 1000)
        {
            brkchk = 0;
            if (os_break()) runsig(ctx, ERR_USRINT);
        }
        
        opc = *p++;

        switch(opc)
        {
        case OPCPUSHNUM:
            val.runsv.runsvnum = osrp4(p);
            runpush(ctx, DAT_NUMBER, &val);
            p += 4;
            break;
            
        case OPCPUSHOBJ:
            val.runsv.runsvobj = osrp2(p);
            runpush(ctx, DAT_OBJECT, &val);
            p += 2;
            break;
            
        case OPCPUSHSELF:
            val.runsv.runsvobj = self;
            runpush(ctx, DAT_OBJECT, &val);
            break;
            
        case OPCPUSHSTR:
            val.runsv.runsvstr = (char*)p; //###cast
            runpush(ctx, DAT_SSTRING, &val);
            p += osrp2(p);                              /* skip past string */
            break;
            
        case OPCPUSHLST:
            val.runsv.runsvstr = (char*)p; //###cast
            runpush(ctx, DAT_LIST, &val);
            p += osrp2(p);                                /* skip past list */
            break;
            
        case OPCPUSHNIL:
            runpush(ctx, DAT_NIL, &val);
            break;
            
        case OPCPUSHTRUE:
            runpush(ctx, DAT_TRUE, &val);
            break;
            
        case OPCPUSHFN:
            val.runsv.runsvobj = osrp2(p);
            runpush(ctx, DAT_FNADDR, &val);
            p += 2;
            break;
            
        case OPCPUSHPN:
            val.runsv.runsvprp = osrp2(p);
            runpush(ctx, DAT_PROPNUM, &val);
            p += 2;
            break;
            
        case OPCNEG:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = -runpopnum(ctx);
            runrepush(ctx, &val);
            break;
            
        case OPCBNOT:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = ~runpopnum(ctx);
            runrepush(ctx, &val);
            break;
            
        case OPCNOT:
            if (runtoslog(ctx))
                runpush(ctx, runclog(!runpoplog(ctx)), &val);
            else
                runpush(ctx, runclog(runpopnum(ctx)), &val);
            break;
            
        case OPCADD:
            runpop(ctx, &val2);    /* right op is pushed last -> popped 1st */
            runpop(ctx, &val);
            runadd(ctx, &val, &val2, 2);
            runrepush(ctx, &val);
            break;
            
        case OPCSUB:
            runpop(ctx, &val2);    /* right op is pushed last -> popped 1st */
            runpop(ctx, &val);
            (void)runsub(ctx, &val, &val2, 2);
            runrepush(ctx, &val);
            break;

        case OPCMUL:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = runpopnum(ctx) * runpopnum(ctx);
            runrepush(ctx, &val);
            break;
            
        case OPCBAND:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = runpopnum(ctx) & runpopnum(ctx);
            runrepush(ctx, &val);
            break;
            
        case OPCBOR:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = runpopnum(ctx) | runpopnum(ctx);
            runrepush(ctx, &val);
            break;

        case OPCSHL:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = runpopnum(ctx);
            val.runsv.runsvnum = runpopnum(ctx) << val.runsv.runsvnum;
            runrepush(ctx, &val);
            break;

        case OPCSHR:
            val.runstyp = DAT_NUMBER;
            val.runsv.runsvnum = runpopnum(ctx);
            val.runsv.runsvnum = runpopnum(ctx) >> val.runsv.runsvnum;
            runrepush(ctx, &val);
            break;
            
        case OPCXOR:
            /* allow logical ^ logical or number ^ number */
            if (runtoslog(ctx))
            {
                int a, b;

                /* logicals - return a logical value */
                a = runpoplog(ctx);
                b = runpoplog(ctx);
                val.runstyp = runclog(a ^ b);
            }
            else
            {
                /* numeric value - return binary xor */
                val.runstyp = DAT_NUMBER;
                val.runsv.runsvnum = runpopnum(ctx) ^ runpopnum(ctx);
            }
            runrepush(ctx, &val);
            break;
            
        case OPCDIV:
            val.runsv.runsvnum = runpopnum(ctx);
            if (val.runsv.runsvnum == 0)
                runsig(ctx, ERR_DIVZERO);
            val.runsv.runsvnum = runpopnum(ctx) / val.runsv.runsvnum;
            val.runstyp = DAT_NUMBER;
            runrepush(ctx, &val);
            break;

        case OPCMOD:
            val.runsv.runsvnum = runpopnum(ctx);
            if (val.runsv.runsvnum == 0)
                runsig(ctx, ERR_DIVZERO);
            val.runsv.runsvnum = runpopnum(ctx) % val.runsv.runsvnum;
            val.runstyp = DAT_NUMBER;
            runrepush(ctx, &val);
            break;
            
#ifdef NEVER
        case OPCAND:
            if (runtostyp(ctx) == DAT_LIST)
                runlstisect(ctx);
            else
                runpush(ctx, runclog(runpoplog(ctx) && runpoplog(ctx)), &val);
            break;
            
        case OPCOR:
            runpush(ctx, runclog(runpoplog(ctx) || runpoplog(ctx)), &val);
            break;
#endif /* NEVER */

        case OPCEQ:
            runpush(ctx, runclog(runeq(ctx)), &val);
            break;
            
        case OPCNE:
            runpush(ctx, runclog(!runeq(ctx)), &val);
            break;
            
        case OPCLT:
            runpush(ctx, runclog(runmcmp(ctx) < 0), &val);
            break;
            
        case OPCLE:
            runpush(ctx, runclog(runmcmp(ctx) <= 0), &val);
            break;
            
        case OPCGT:
            runpush(ctx, runclog(runmcmp(ctx) > 0), &val);
            break;
            
        case OPCGE:
            runpush(ctx, runclog(runmcmp(ctx) >= 0), &val);
            break;
            
        case OPCCALL:
            {
                objnum o;
                
                nargc = *p++;
            
                /* object could move--save offset to restore 'p' after call */
                o = osrp2(p);
                ofs = runcpsav(ctx, p, target, targprop);

                /* execute the function */
                runfn(ctx, o, nargc);

                /* restore code pointer in case target object moved */
                p = runcprst(ctx, ofs, target, targprop) + 2;
                break;
            }
        
        case OPCGETP:
            nargc = *p++;
            prop = osrp2(p);
            p += 2;
            obj = runpopobj(ctx);
            runpprop(ctx, &p, target, targprop, obj, prop, FALSE, nargc,
                     obj);
            break;

        case OPCGETDBLCL:
            {
                objnum   frobj;
                uint     frofs;
                runsdef *otherbp;
                
                frobj = osrp2(p);
                frofs = osrp2(p + 2);
                otherbp = dbgfrfind(ctx->runcxdbg, frobj, frofs);
                runrepush(ctx, otherbp + runrp2s(p + 4) - 1);
                p += 6;
            }
            break;

        case OPCGETLCL:
            runrepush(ctx, ctx->runcxbp + runrp2s(p) - 1);
            p += 2;
            break;
            
        case OPCRETURN:
            runleave(ctx, argc /* was: osrp2(p) */);
            dbgleave(ctx->runcxdbg, DBGEXRET);
            return;
            
        case OPCRETVAL:
            /* if there's nothing on the stack, return nil */
            if (runtostyp(ctx) != DAT_BASEPTR)
                runpop(ctx, &val);
            else
                val.runstyp = DAT_NIL;
            
            runleave(ctx, argc /* was: osrp2(p) */);
            runrepush(ctx, &val);
            dbgleave(ctx->runcxdbg, DBGEXVAL);
            return;
            
        case OPCENTER:
            /* push old base pointer and set up new one */
            ctx->runcxsp = rstsp;
            val.runsv.runsvstr = (char *)ctx->runcxbp; //###cast
            runpush(ctx, DAT_BASEPTR, &val);
            ctx->runcxbp = ctx->runcxsp;
    
            /* add a trace record */
            dbgenter(ctx->runcxdbg, ctx->runcxbp, self, target, targprop,
                     0, argc);

            /* initialize locals to nil */
            for (i = osrp2(p) ; i ; --i) runpush(ctx, DAT_NIL, &val);
            p += 2;                         /* skip the local count operand */
            
            /* save stack pointer - reset sp to this value on DISCARD */
            rstsp = ctx->runcxsp;
            break;
            
        case OPCDISCARD:
            ctx->runcxsp = rstsp;
            break;
            
        case OPCSWITCH:
        {
            int      i;
            int      tostyp;
            int      match, typmatch;
            
            runpop(ctx, &val);
            tostyp = val.runstyp;
            switch(tostyp)
            {
            case DAT_SSTRING:
                tostyp = OPCPUSHSTR;
                break;
            case DAT_LIST:
                tostyp = OPCPUSHLST;
                break;
            case DAT_PROPNUM:
                tostyp = OPCPUSHPN;
                break;
            case DAT_FNADDR:
                tostyp = OPCPUSHFN;
                break;
            case DAT_TRUE:
                tostyp = OPCPUSHTRUE;
                break;
            case DAT_NIL:
                tostyp = OPCPUSHNIL;
                break;
            }
            
            p += osrp2(p);                         /* find the switch table */
            i = osrp2(p);                            /* get number of cases */

            /* look for a matching case */
            for (match = FALSE ; i && !match ; --i)
            {
                p += 2;                     /* skip previous jump/size word */
                typmatch = (*p == tostyp);
                switch(*p++)
                {
                case OPCPUSHNUM:
                    match = (typmatch
                             && val.runsv.runsvnum == osrp4(p));
                    p += 4;
                    break;
                        
                case OPCPUSHLST:
                case OPCPUSHSTR:
                    match = (typmatch
                             && osrp2(val.runsv.runsvstr) == osrp2(p)
                             && !memcmp(val.runsv.runsvstr,
                                        p, (size_t)osrp2(p)));
                    p += runrp2s(p);
                    break;
                        
                case OPCPUSHPN:
                    match = (typmatch
                             && val.runsv.runsvprp == osrp2(p));
                    p += 2;
                    break;
                        
                case OPCPUSHOBJ:
                case OPCPUSHFN:
                    match = (typmatch
                             && val.runsv.runsvobj == osrp2(p));
                    p += 2;
                    break;
                    
                case OPCPUSHSELF:
                    match = (typmatch && val.runsv.runsvobj == self);
                    break;
                        
                case OPCPUSHTRUE:
                case OPCPUSHNIL:
                    match = typmatch;
                    break;
                }
            }

            if (!match) p += 2;         /* if default, skip to default case */
            p += runrp2s(p);      /* wherever we left off, p points to jump */
            break;
        }

        case OPCJMP:
            p += runrp2s(p);
            break;
            
        case OPCJT:
            if (runtoslog(ctx))
                p += (runpoplog(ctx) ? runrp2s(p) : 2);
            else
                p += (runpopnum(ctx) != 0 ? runrp2s(p) : 2);
            break;
            
        case OPCJF:
            if (runtoslog(ctx))
                p += ((!runpoplog(ctx)) ? runrp2s(p) : 2);
            else if (runtostyp(ctx) == DAT_NUMBER)
                p += ((runpopnum(ctx) == 0) ? runrp2s(p) : 2);
            else                      /* consider any other type to be true */
            {
                rundisc(ctx);  /* throw away the item considered to be true */
                p += 2;
            }
            break;
            
        case OPCSAY:
            outfmt(ctx->runcxtio, p);
            p += osrp2(p);                              /* skip past string */
            break;
            
        case OPCBUILTIN:
            {
                int      binum;
                runsdef *stkp;

                nargc = *p++;
                binum = osrp2(p);
                ofs = runcpsav(ctx, p, target, targprop);
                stkp =  ctx->runcxsp - nargc;

                dbgenter(ctx->runcxdbg, ctx->runcxsp + 1, MCMONINV, MCMONINV,
                         (prpnum)0, binum, nargc);
                (*ctx->runcxbi[binum])(ctx->runcxbcx, nargc);
                dbgleave(ctx->runcxdbg,
                         ctx->runcxsp != stkp ? DBGEXVAL : DBGEXRET);

                p = runcprst(ctx, ofs, target, targprop);
                p += 2;
                break;
            }
            
        case OPCPTRCALL:
            nargc = *p++;
            ofs = runcpsav(ctx, p, target, targprop);
            runfn(ctx, runpopfn(ctx), nargc);
            p = runcprst(ctx, ofs, target, targprop);
            break;
            
        case OPCINHERIT:
            nargc = *p++;
            prop = osrp2(p);
            p += 2;
            runpprop(ctx, &p, target, targprop, target, prop, TRUE, nargc,
                     self);
            break;
            
        case OPCPTRINH:
            nargc = *p++;
            prop = runpopprp(ctx);
            runpprop(ctx, &p, target, targprop, target, prop, TRUE, nargc,
                     self);
            break;
            
        case OPCPTRGETP:
            nargc = *p++;
            prop = runpopprp(ctx);
            obj = runpopobj(ctx);
            runpprop(ctx, &p, target, targprop, obj, prop, FALSE, nargc,
                     obj);
            break;
            
        case OPCPASS:
            prop = osrp2(p);
            runleave(ctx, 0);
            dbgleave(ctx->runcxdbg, DBGEXPASS);
            runpprop(ctx, &p, target, targprop, target, prop, TRUE, argc,
                     self);
            return;
            
        case OPCEXIT:
            errsig(ctx->runcxerr, ERR_RUNEXIT);
            /* NOTREACHED */
            
        case OPCABORT:
            errsig(ctx->runcxerr, ERR_RUNABRT);
            /* NOTREACHED */
            
        case OPCASKDO:
            errsig(ctx->runcxerr, ERR_RUNASKD);
            /* NOTREACHED */
            
        case OPCASKIO:
            errsig1(ctx->runcxerr, ERR_RUNASKI, ERRTINT, osrp2(p));
            /* NOTREACHED */
            
        case OPCJE:
            p += (runeq(ctx) ? runrp2s(p) : 2);
            break;
            
        case OPCJNE:
            p += (!runeq(ctx) ? runrp2s(p) : 2);
            break;
            
        case OPCJGT:
            p += (runmcmp(ctx) > 0 ? runrp2s(p) : 2);
            break;
            
        case OPCJGE:
            p += (runmcmp(ctx) >= 0 ? runrp2s(p) : 2);
            break;
            
        case OPCJLT:
            p += (runmcmp(ctx) < 0 ? runrp2s(p) : 2);
            break;
            
        case OPCJLE:
            p += (runmcmp(ctx) <= 0 ? runrp2s(p) : 2);
            break;
            
        case OPCJNAND:
            p += (!(runpoplog(ctx) && runpoplog(ctx)) ? runrp2s(p) : 2);
            break;
            
        case OPCJNOR:
            p += (!(runpoplog(ctx) || runpoplog(ctx)) ? runrp2s(p) : 2);
            break;
            
        case OPCGETPSELF:
            nargc = *p++;
            prop = osrp2(p);
            p += 2;
            runpprop(ctx, &p, target, targprop, self, prop, FALSE, nargc,
                     self);
            break;
            
        case OPCGETPPTRSELF:
            nargc = *p++;
            prop = runpopprp(ctx);
            runpprop(ctx, &p, target, targprop, self, prop, FALSE, nargc,
                     self);
            break;
            
        case OPCGETPOBJ:
            nargc = *p++;
            obj = osrp2(p);
            prop = osrp2(p+2);
            p += 4;
            runpprop(ctx, &p, target, targprop, obj, prop, FALSE, nargc,
                     obj);
            break;
            
        case OPCINDEX:
            i = runpopnum(ctx);                                /* get index */
            lstp = runpoplst(ctx);                          /* get the list */
            runpind(ctx, i, lstp);
            break;
            
        case OPCJST:
            if (runtostyp(ctx) == DAT_TRUE)
                p += runrp2s(p);
            else
            {
                (void)runpoplog(ctx);
                p += 2;
            }
            break;
            
        case OPCJSF:
            if (runtostyp(ctx) == DAT_NIL ||
                (runtostyp(ctx) == DAT_NUMBER &&
                 (ctx->runcxsp - 1)->runsv.runsvnum == 0))
                p += runrp2s(p);
            else
            {
                runpop(ctx, &val);
                p += 2;
            }
            break;
            
        case OPCCALLEXT:
            {
                static runufdef uf =
                {
                    runuftyp,  runufnpo,  runufspo,  runufdsc,
                    runufnpu,  runufspu,  runufcspu, runufsal,
                    runuflpu
                };
                int        fn;
                runxdef   *ex;
                runuxdef   ux;
                int      (*os_exfil(/*_ char *name _*/))(/*_ void _*/);
                
                /* set up callback context */
                ux.runuxctx  = ctx;
                ux.runuxvec  = &uf;
                ux.runuxargc = *p++;

                fn = osrp2(p);
                p += 2;
                ex = &ctx->runcxext[fn];
                
                if (!ex->runxptr)
                {
                    if (!(ex->runxptr = os_exfil(ex->runxnam)))
                        runsig1(ctx, ERR_EXTLOAD, ERRTSTR, ex->runxnam);
                }
                if (os_excall(ex->runxptr, &ux))
                    runsig1(ctx, ERR_EXTRUN, ERRTSTR, ex->runxnam);
            }
            break;
            
        case OPCDBGRET:
            return;
            
        case OPCCONS:
            {
                uint    totsiz;
                uint    oldsiz;
                uint    tot;
                uint    cursiz;
                runsdef lstend;
                
                tot = i = osrp2(p);    /* get # of items to build into list */
                p += 2;

                /* reserve space for initial list (w/length word only) */
                runhres(ctx, 2, 0);
                
                /*
                 *   Set up value to point to output list, making room
                 *   for length prefix.  Remember size-so-far separately.
                 */
                lstend.runstyp = DAT_LIST;
                lstend.runsv.runsvstr = (char*)ctx->runcxhp; //###cast
                ctx->runcxhp += 2;
                totsiz = 2;

                while (i--)
                {
                    runpop(ctx, &val);          /* get next value off stack */
                    cursiz = runsiz(&val);

                    /*
                     *   Set up to allocate space.  Before doing so, make
                     *   sure the list under construction is valid, to
                     *   ensure that it stays around after garbage
                     *   collection. 
                     */
                    oldsiz = totsiz;
                    totsiz += cursiz + 1;
                    oswp2(lstend.runsv.runsvstr, oldsiz);
                    ctx->runcxhp = (uchar*)lstend.runsv.runsvstr + oldsiz; //###cast
                    runhres2(ctx, cursiz + 1, tot - i, &val, &lstend);

                    /* write this item to the list */
                    runputbuf(lstend.runsv.runsvstr + oldsiz, &val);
                }
                oswp2(lstend.runsv.runsvstr, totsiz);
                ctx->runcxhp = (uchar*)lstend.runsv.runsvstr + totsiz; //###cast
                runrepush(ctx, &lstend);
            }
            break;
            
        case OPCARGC:
            val.runsv.runsvnum = argc;
            runpush(ctx, DAT_NUMBER, &val);
            break;
            
        case OPCCHKARGC:
            if ((*p & 0x80) ? argc < (*p & 0x7f) : argc != *p)
                runsig(ctx, ERR_ARGC);
            ++p;
            break;
            
        case OPCLINE:
        case OPCBP:
            {
                uchar *ptr = mcmobjptr(ctx->runcxmem, (mcmon)target);
                uint   ofs;
                
                dbgframe(ctx->runcxdbg, osrp2(p+1), p - ptr);
                ctx->runcxlofs = ofs = (p + 2 - ptr);
                dbgssi(ctx->runcxdbg, ofs, *(p-1), 0);
                p += *p;                            /* skip the line record */
                break;
            }
            
        case OPCFRAME:
            /* this is a frame record - just jump past it */
            p += osrp2(p);
            break;
            
        case OPCASI_MASK | OPCASIDIR | OPCASILCL:
            runpop(ctx, &val);
            OSCPYSTRUCT(*(ctx->runcxbp + runrp2s(p) - 1), val);
            stkval = &val;
            p += 2;
            goto no_assign;
            
        case OPCASI_MASK | OPCASIDIR | OPCASIPRP:
            obj = runpopobj(ctx);
            prop = osrp2(p);
            p += 2;
            runpop(ctx, &val);
            stkval = valp = &val;
            goto assign_property;

        case OPCASI_MASK | OPCASIDIR | OPCASIPRPPTR:
            prop = runpopprp(ctx);
            obj = runpopobj(ctx);
            runpop(ctx, &val);
            stkval = valp = &val;
            goto assign_property;

        case OPCNEW:
            run_new(ctx);
            break;
            
        case OPCDELETE:
            run_delete(ctx);
            break;
            
        default:
            if ((opc & OPCASI_MASK) == OPCASI_MASK)
            {
                runsdef  val3;
                int      asityp;
                int      asiext;
                
                valp = &val;
                stkval = &val;

                asityp = (opc & OPCASITYP_MASK);
                if (asityp == OPCASIEXT)
                    asiext = *p++;
                
                /* get list element/property number if needed */
                switch(opc & OPCASIDEST_MASK)
                {
                case OPCASIPRP:
                    obj = runpopobj(ctx);
                    prop = osrp2(p);
                    p += 2;
                    break;

                case OPCASIPRPPTR:
                    prop = runpopprp(ctx);
                    obj = runpopobj(ctx);
                    break;
                    
                case OPCASIIND:
                    i = runpopnum(ctx);
                    lstp = runpoplst(ctx);
                    break;
                }
                
                if (asityp != OPCASIDIR)
                {
                    /* we have an <op>= operator - get lval, modify, & set */
                    switch(opc & OPCASIDEST_MASK)
                    {
                    case OPCASILCL:
                        OSCPYSTRUCT(val, *(ctx->runcxbp + runrp2s(p) - 1));
                        break;
                        
                    case OPCASIPRP:
                    case OPCASIPRPPTR:
                        runpprop(ctx, &p, target, targprop, obj, prop,
                                 FALSE, 0, obj);
                        runpop(ctx, &val);
                        break;

                    case OPCASIIND:
                        runpind(ctx, i, lstp);
                        runpop(ctx, &val);
                        break;
                    }
                    
                    /* if saving pre-inc/dec value, get the value now */
                    if ((opc & OPCASIPRE_MASK) == OPCASIPOST)
                    {
                        OSCPYSTRUCT(val3, val);
                        stkval = &val3;
                    }
                }
                
                /* get rvalue, except for inc/dec operations */
                if (asityp != OPCASIINC && asityp != OPCASIDEC)
                    runpop(ctx, &val2);
                
                /* now apply operation to lvalue using rvalue */
                switch(asityp)
                {
                case OPCASIADD:
                    runadd(ctx, &val, &val2, 2);
                    break;
                    
                case OPCASISUB:
                    if (!runsub(ctx, &val, &val2, 2)) goto no_assign;
                    break;
                    
                case OPCASIMUL:
                    if (val.runstyp != DAT_NUMBER
                        || val2.runstyp != DAT_NUMBER)
                        runsig(ctx, ERR_REQNUM);
                    val.runsv.runsvnum *= val2.runsv.runsvnum;
                    break;
                    
                case OPCASIDIV:
                    if (val.runstyp != DAT_NUMBER
                        || val2.runstyp != DAT_NUMBER)
                        runsig(ctx, ERR_REQNUM);
                    if (val2.runsv.runsvnum == 0)
                        runsig(ctx, ERR_DIVZERO);
                    val.runsv.runsvnum /= val2.runsv.runsvnum;
                    break;
                    
                case OPCASIINC:
                    if (val.runstyp != DAT_NUMBER)
                        runsig(ctx, ERR_REQNUM);
                    ++(val.runsv.runsvnum);
                    break;
                    
                case OPCASIDEC:
                    if (val.runstyp != DAT_NUMBER)
                        runsig(ctx, ERR_REQNUM);
                    --(val.runsv.runsvnum);
                    break;
                    
                case OPCASIDIR:
                    valp = stkval = &val2;
                    break;

                case OPCASIEXT:
                    switch (asiext)
                    {
                    case OPCASIMOD:
                        if (val.runstyp != DAT_NUMBER
                            || val2.runstyp != DAT_NUMBER)
                            runsig(ctx, ERR_REQNUM);
                        if (val2.runsv.runsvnum == 0)
                            runsig(ctx, ERR_DIVZERO);
                        val.runsv.runsvnum %= val2.runsv.runsvnum;
                        break;

                    case OPCASIBAND:
                        if ((val.runstyp == DAT_TRUE
                             || val.runstyp == DAT_NIL)
                            && (val2.runstyp == DAT_TRUE
                                || val2.runstyp == DAT_NIL))
                        {
                            int a, b;

                            a = (val.runstyp == DAT_TRUE ? 1 : 0);
                            b = (val2.runstyp == DAT_TRUE ? 1 : 0);
                            val.runstyp = runclog(a && b);
                        }
                        else if (val.runstyp == DAT_NUMBER
                                 && val2.runstyp == DAT_NUMBER)
                            val.runsv.runsvnum &= val2.runsv.runsvnum;
                        else
                            runsig(ctx, ERR_REQNUM);
                        break;
                        
                    case OPCASIBOR:
                        if ((val.runstyp == DAT_TRUE
                             || val.runstyp == DAT_NIL)
                            && (val2.runstyp == DAT_TRUE
                                || val2.runstyp == DAT_NIL))
                        {
                            int a, b;

                            a = (val.runstyp == DAT_TRUE ? 1 : 0);
                            b = (val2.runstyp == DAT_TRUE ? 1 : 0);
                            val.runstyp = runclog(a || b);
                        }
                        else if (val.runstyp == DAT_NUMBER
                                 && val2.runstyp == DAT_NUMBER)
                            val.runsv.runsvnum |= val2.runsv.runsvnum;
                        else
                            runsig(ctx, ERR_REQNUM);
                        break;
                        
                    case OPCASIXOR:
                        if ((val.runstyp == DAT_TRUE || val.runstyp == DAT_NIL)
                            && (val2.runstyp == DAT_TRUE
                                || val2.runstyp == DAT_NIL))
                        {
                            int a, b;

                            a = (val.runstyp == DAT_TRUE ? 1 : 0);
                            b = (val2.runstyp == DAT_TRUE ? 1 : 0);
                            val.runstyp = runclog(a ^ b);
                        }
                        else if (val.runstyp == DAT_NUMBER
                                 && val2.runstyp == DAT_NUMBER)
                            val.runsv.runsvnum ^= val2.runsv.runsvnum;
                        else
                            runsig(ctx, ERR_REQNUM);
                        break;

                    case OPCASISHL:
                        if (val.runstyp != DAT_NUMBER
                            || val2.runstyp != DAT_NUMBER)
                            runsig(ctx, ERR_REQNUM);
                        val.runsv.runsvnum <<= val2.runsv.runsvnum;
                        break;
                        
                    case OPCASISHR:
                        if (val.runstyp != DAT_NUMBER
                            || val2.runstyp != DAT_NUMBER)
                            runsig(ctx, ERR_REQNUM);
                        val.runsv.runsvnum >>= val2.runsv.runsvnum;
                        break;
                        
                    default:
                        runsig(ctx, ERR_INVOPC);
                    }
                    break;

                default:
                    runsig(ctx, ERR_INVOPC);
                }
                
                /* write the rvalue at *valp to the lvalue */
                switch(opc & OPCASIDEST_MASK)
                {
                case OPCASILCL:
                    OSCPYSTRUCT(*(ctx->runcxbp + runrp2s(p) - 1), *valp);
                    p += 2;
                    break;
                    
                case OPCASIPRP:
                case OPCASIPRPPTR:
                assign_property:
                    {
                        dvoid   *valbuf;
                        uchar    outbuf[4];
                        
                        switch(valp->runstyp)
                        {
                        case DAT_LIST:
                        case DAT_SSTRING:
                            valbuf = valp->runsv.runsvstr;
                            break;
                            
                        case DAT_NUMBER:
                            valbuf = outbuf;
                            oswp4(outbuf, valp->runsv.runsvnum);
                            break;
                            
                        case DAT_OBJECT:
                        case DAT_FNADDR:
                            valbuf = outbuf;
                            oswp2(outbuf, valp->runsv.runsvobj);
                            break;
                            
                        case DAT_PROPNUM:
                            valbuf = outbuf;
                            oswp2(outbuf, valp->runsv.runsvprp);
                            break;
                            
                        default:
                            valbuf = &valp->runsv;
                            break;
                        }
                        
                        ofs = runcpsav(ctx, p, target, targprop);
                        objsetp(ctx->runcxmem, obj, prop, valp->runstyp,
                                valbuf, ctx->runcxundo);
                        p = runcprst(ctx, ofs, target, targprop);
                        break;
                    }
                    
                case OPCASIIND:
                    {
                        uint   newtot;
                        uint   newsiz;
                        uint   remsiz;
                        uint   delsiz;
                        uchar *delp;
                        uchar *remp;
                        
                        /* compute sizes and pointers to various parts */
                        ofs = runindofs(ctx, i, lstp);
                        delp = lstp + ofs;        /* ptr to item to replace */
                        delsiz = datsiz(*delp, delp + 1);  /* size of *delp */
                        remp = lstp + ofs + delsiz + 1;        /* remainder */
                        remsiz = osrp2(lstp) - ofs - delsiz - 1;
                        newsiz = runsiz(valp);          /* size of new item */
                        newtot = osrp2(lstp) + newsiz - delsiz;  /* new tot */
                    
                        /* reserve space for the new list & copy first part */
                        {
                            runsdef val3;

                            /* make sure lstp stays valid before and after */
                            val3.runstyp = DAT_LIST;
                            val3.runsv.runsvstr = (char*)lstp; //###cast
                            runhres3(ctx, newtot, 3, &val, &val2, &val3);
                            lstp = (uchar*)val3.runsv.runsvstr; //###cast
                        }
                        memcpy(ctx->runcxhp + 2, lstp + 2, (size_t)(ofs - 2));
                        
                        /* set size of new list */
                        oswp2(ctx->runcxhp, newtot);
                        
                        /* copy new item into buffer */
                        runputbuf(ctx->runcxhp + ofs, valp);
                        
                        /* copy remainder and update heap pointer */
                        memcpy(ctx->runcxhp + ofs + newsiz + 1, remp,
                               (size_t)remsiz);
                        val.runstyp = DAT_LIST;
                        val.runsv.runsvstr = (char*)ctx->runcxhp; //###cast
                        stkval = &val;
                        ctx->runcxhp += newtot;
                        break;
                    }
                }
                
            no_assign:   /* skip assignment - operation didn't change value */
                if (*p == OPCDISCARD)
                {
                    /* next assignment is DISCARD - deal with it now */
                    ++p;
                    ctx->runcxsp = rstsp;
                }
                else
                    runrepush(ctx, stkval);
            }
            else
                errsig(ctx->runcxerr, ERR_INVOPC);
        }
    }
}

/*
 *   Signal a run-time error.  This function first calls the debugger
 *   single-step function to allow the debugger to trap the error, then
 *   signals the error as usual when the debugger returns.  
 */
void runsign(ctx, err)
runcxdef *ctx;
int       err;
{
    dbgssi(ctx->runcxdbg, ctx->runcxlofs, OPCLINE, err);
    errsign(ctx->runcxerr, err, "TADS");
}

