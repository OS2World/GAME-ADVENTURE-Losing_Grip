/*
$Header: d:/tads/tads2/RCS/prp.h 1.5 96/10/14 16:10:44 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  prp.h - property definitions
Function
  Defines the structure of properties
Notes
  A property structure must be binary-portable, because properties are
  stored in objects, which must be binary-portable.  Hence, the internal
  structure of a property header is not a C structure, but a portable
  sequence of bytes.  Multi-byte quantities are stored in Intel format.
  
    property number    - 2 bytes
    property datatype  - 1 byte
    property size      - 2 bytes
    property flags     - 1 byte
    
  This header is followed immediately by the property value.  For
  convenience, a set of macros is defined to provide access to the
  fields of a property header.
Modified
  12/16/92 MJRoberts     - TADS/Graphic properties
  08/11/91 MJRoberts     - creation
*/

#ifndef PRP_INCLUDED
#define PRP_INCLUDED

#ifndef DAT_INCLUDED
#include "dat.h"
#endif

/* a property number, used to look up all properties */
typedef ushort prpnum;

/* a property definition, used to associate data with properties */
/*
typedef struct prpdef prpdef;
struct prpdef
{
    prpnum  prpprop;                    /o property number of this property o/
    dattyp  prptype;                      /o datatype of the property value o/
    ushort  prpsize;                         /o size of the property's data o/
    ushort  prpflg;                               /o flags for the property o/
    uchar   prpval[1];             /o value of the property (if applicable) o/
};
*/
typedef uchar prpdef;                   /* prpdef is just an array of bytes */
#define PRPHDRSIZ 6           /* "sizeof(prpdef)" - size of property header */

/* Macros to provide access to property header entries */
#define prpprop(p) osrp2((uchar *)(p))
#define prptype(p) (*(((uchar *)(p)) + 2))
#define prpsize(p) osrp2((((uchar *)(p)) + 3))
#define prpflg(p)  (*(((uchar *)(p)) + 5))
#define prpvalp(p) (((uchar *)(p)) + 6)

#define prpsetprop(p,n) oswp2((uchar *)(p), n)
#define prpsetsize(p,s) oswp2((((uchar *)(p)) + 3), s)

/* property flag values */
#define PRPFORG   0x01                /* property is original startup value */
#define PRPFIGN   0x02               /* ignore this prop (has been changed) */

/* certain property types are special, and are reserved here */
#define PRP_DOACTION    1                              /* doAction property */

/* vocabulary properties - keep these contiguous, and must start at 2 */
#define PRP_VERB        2                      /* verb vocabulary property  */
#define PRP_NOUN        3                       /* noun vocabulary property */
#define PRP_ADJ         4                  /* adjective vocabulary property */
#define PRP_PREP        5                /* preposition vocabulary property */
#define PRP_ARTICLE     6                    /* article vocabulary property */
#define PRP_PLURAL      7                     /* plural vocabulary property */

/* determine if a property is a vocab property */
/* int prpisvoc(prpnum p); */
#define prpisvoc(p) ((p) >= PRP_VERB && (p) <= PRP_PLURAL)

/* more properties... */
#define PRP_SDESC       8
#define PRP_THEDESC     9
#define PRP_DODEFAULT   10
#define PRP_IODEFAULT   11
#define PRP_IOACTION    12
#define PRP_LOCATION    13
#define PRP_VALUE       14
#define PRP_ROOMACTION  15
#define PRP_ACTORACTION 16
#define PRP_CONTENTS    17
#define PRP_TPL         18           /* special built-in TEMPLATE structure */
#define PRP_PREPDEFAULT 19
#define PRP_VERACTOR    20
#define PRP_VALIDDO     21
#define PRP_VALIDIO     22
#define PRP_LOOKAROUND  23
#define PRP_ROOMCHECK   24
#define PRP_STATUSLINE  25
#define PRP_LOCOK       26
#define PRP_ISVIS       27
#define PRP_NOREACH     28
#define PRP_ISHIM       29
#define PRP_ISHER       30
#define PRP_ACTION      31                                 /* action method */
#define PRP_VALDOLIST   32                                   /* validDoList */
#define PRP_VALIOLIST   33                                   /* validIoList */
#define PRP_IOBJGEN     34                                       /* iobjGen */
#define PRP_DOBJGEN     35                                       /* dobjGen */
#define PRP_NILPREP     36                                       /* nilPrep */
#define PRP_REJECTMDO   37                               /* rejectMultiDobj */
#define PRP_MOVEINTO    38                                      /* moveInto */
#define PRP_CONSTRUCT   39                                     /* construct */
#define PRP_DESTRUCT    40                                      /* destruct */
#define PRP_VALIDACTOR  41                                    /* validActor */
#define PRP_PREFACTOR   42                                /* preferredActor */
#define PRP_ISEQUIV     43                                  /* isEquivalent */
#define PRP_ADESC       44
#define PRP_MULTISDESC  45
#define PRP_TPL2        46         /* new-style built-in TEMPLATE structure */
#define PRP_ANYVALUE    47   /* anyvalue(n) - value to use for '#' with ANY */
#define PRP_NEWNUMOBJ   48   /* newnumbered(n) - create new numbered object */

/* properties used by TADS/Graphic */
#define PRP_GP_PIC      100                                   /* gp_picture */
#define PRP_GP_NAME     101                                      /* gp_name */
#define PRP_GP_DEFVERB  102                                   /* gp_defverb */
#define PRP_GP_ACTIVE   103                                    /* gp_active */
#define PRP_GP_HOTLIST  104                                   /* gp_hotlist */
#define PRP_GP_ICON     105                                      /* gp_icon */
#define PRP_GP_DEFVERB2 106                                  /* gp_defverb2 */
#define PRP_GP_DEFPREP  107                                   /* gp_defprep */
#define PRP_GP_HOTID    108                                     /* gp_hotid */
#define PRP_GP_OVERLAY  109                                   /* gp_overlay */
#define PRP_GP_HOTX     110                                      /* gp_hotx */
#define PRP_GP_HOTY     111                                      /* gp_hoty */

/* highest reserved property number - must match last one above */
#define PRP_LASTRSV     111

#endif /* PRP_INCLUDED */
