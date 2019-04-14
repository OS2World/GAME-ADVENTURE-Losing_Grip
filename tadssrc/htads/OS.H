/*
$Header: d:/tads/tads2/RCS/os.h 1.9 96/10/14 16:10:38 mroberts Exp $
*/

/* Copyright (c) 1991 by Michael J. Roberts.  All Rights Reserved. */
/*
Name
  os.h - operating system definitions
Function
  Definitions that vary by operating system
Notes
  None
Modified
  08/13/91 MJRoberts     - creation
*/

#ifndef OS_INCLUDED
#define OS_INCLUDED

# define OS2

// It seems weird to be #defining MACintosh, but it is necessary to keep
// TADS from trying to do its own "[More]" handling. SRG
# define MAC

# define OS_SYSTEM_NAME  "OS/2"

/* maximum width of an output line buffer */
#define OS_MAXWIDTH 135

extern int stristr(char *p, char *q);
extern void tzset(void);

/* far pointer type qualifier (null on most platforms) */
#  define osfar_t
#  define far

/* maximum theoretical size of malloc argument */
#  define OSMALMAX ((size_t)0xffffffff)

/* cast an expression to void */
#  define DISCARD (void)

#  include <stdlib.h>
#  include <stdio.h>

/* display lines on which errors occur */
#  define OS_ERRLINE 1

/*
 *   If long cache-manager macros are NOT allowed, define
 *   OS_MCM_NO_MACRO.  This forces certain cache manager operations to be
 *   functions, which results in substantial memory savings.  
 */
#define OS_MCM_NO_MACRO

/* likewise for the error handling subsystem */
#define OS_ERR_NO_MACRO


/*
 *   If error messages are to be included in the executable, define
 *   OS_ERR_LINK_MESSAGES.  Otherwise, they'll be read from an external
 *   file that is to be opened with oserrop().
 */
#define OS_ERR_LINK_MESSAGES 
#define ERR_LINK_MESSAGES 

/* Don't print the cryptic "TADS-1000" error code in error messages. */
#define OS_SKIP_ERROR_CODES

/* round a size to worst-case alignment boundary */
#define osrndsz(s) (((s)+3) & ~3)

/* round a pointer to worst-case alignment boundary */
#define osrndpt(p) ((uchar *)((((ulong)(p)) + 3) & ~3))

/* void pointer type */
typedef void dvoid;

/* offset of a member inside a structure */
#ifndef offsetof
#define offsetof(typ, mem) ((uint)&(((typ *)0)->mem))
#endif

/* read unaligned portable 2-byte value, returning int */
#define osrp2(p) (*(unsigned short *)(p))

/* write int to unaligned portable 2-byte value */
#define oswp2(p, i) (*(unsigned short *)(p)=(i))

/* read unaligned portable 4-byte value, returning long */
#define osrp4(p) (*(unsigned long *)(p))

/* write long to unaligned portable 4-byte value */
#define oswp4(p, l) (*(unsigned long *)(p)=(l))

/* allocate storage - malloc where supported */
/*dvoid *osmalloc(size_t siz);*/
#define osmalloc malloc

/* free storage allocated with osmalloc */
/*void osfree(dvoid *block);*/
#define osfree free

/* copy a structure - dst and src are structures, not pointers */
#define OSCPYSTRUCT(dst, src) ((dst) = (src))

/* a full ANSI compiler -- at least, it supports "volatile". */
#define OSANSI

#define TRD_SETTINGS_DEFINED
#define TRD_HEAPSIZ  (65535)
#define TRD_STKSIZ   (1024)
#define TRD_UNDOSIZ  (60000)		/* WARNING: increasing to 65535 will cause crashes */

/* maximum length of a filename */
#define OSFNMAX  1024

/* normal path separator character. */
#define OSPATHCHAR '/'
/* alternate path separator characters */
#define OSPATHALT "\\"
/* character which separates directories in the path */
#define OSPATHSEP ';'

/* os file structure */
typedef FILE osfildef;

/* main program exit codes */
#define OSEXSUCC 0                                 /* successful completion */
#define OSEXFAIL 1                                        /* error occurred */

/* open text file for reading; returns NULL on error */
/* osfildef *osfoprt(char *fname); */
#define osfoprt(fname) fopen(fname, "r")

/* open source file for reading */
/* osfildef *osfoprs(char *fname); */
#define osfoprs(fname) osfoprt(fname)

/* open binary file for writing; returns NULL on error */
/* osfildef *osfopwb(char *fname); */
#define osfopwb(fname) fopen(fname, "wb")

/* open binary file for reading; returns NULL on erorr */
/* osfildef *osfoprb(char *fname); */
#define osfoprb(fname) fopen(fname, "rb")

/* open binary file for reading/writing; truncate; returns NULL on error */
/* osfildef *osfoprwb(char *fname); */
#define osfoprwtb(fname) fopen(fname, "w+b")

/* open binary file for reading/writing; don't truncate */
/* osfildef *osfoprwb(char *fname); */
#define osfoprwb(fname) fopen(fname, "r+b")

/* get a line of text from a text file (fgets semantics) */
/* char *osfgets(char *buf, size_t len, osfildef *fp); */
#define osfgets(buf, len, fp) fgets(buf, len, fp)

/* write bytes to file; TRUE ==> error */
/* int osfwb(osfildef *fp, uchar *buf, int bufl); */
#define osfwb(fp, buf, bufl) (fwrite(buf, bufl, 1, fp) != 1)

/* read bytes from file; TRUE ==> error */
/* int osfrb(osfildef *fp, uchar *buf, int bufl); */
#define osfrb(fp, buf, bufl) (fread(buf, bufl, 1, fp) != 1)

/* get position in file */
/* long osfpos(osfildef *fp); */
#define osfpos(fp) ftell(fp)

/* seek position in file; TRUE ==> error */
/* int osfseek(osfildef *fp, long pos, int mode); */
#define osfseek(fp, pos, mode) fseek(fp, pos, mode)
#define OSFSK_SET  SEEK_SET
#define OSFSK_CUR  SEEK_CUR
#define OSFSK_END  SEEK_END

/* close a file */
/* void osfcls(osfildef *fp); */
#define osfcls(fp) fclose(fp)

/* delete a file - TRUE if error */
/* int osfdel(char *fname); */
#define osfdel(fname) remove(fname)

/* access a file - 0 if file exists */
/* int osfacc(char *fname) */
#define osfacc(fname) access(fname, 0)

/* open error file, returning file handle, or null if not found */
osfildef *oserrop(/*_ void _*/);

/* clear the screen */
#define oscls() os_clear_screen()

/*
 *   os_settype(file, type) sets a file to the given type.  This is
 *   required for certain operating systems which like to classify
 *   their files through these type identifiers.  The OSFTxxx constants
 *   are the abstract types we use; the os_settype implementation must
 *   translate to an appropriate OS type.  (This routine is a no-op on
 *   many systems.)
 */
#define OSFTLOG  0
#define OSFTGAME 1
#define OSFTSAVE 2
#define OSFTSWAP 3

/* do nothing with OS_LOADDS definitions */
# define OS_LOADDS

/*
 *   Single/double quote matching macros.  Used to allow systems with
 *   extended character codes with weird quote characters (such as Mac) to
 *   match the weird characters. 
 */
#define os_squote(c) ((c) == '\'')
#define os_dquote(c) ((c) == '"')
#define os_qmatch(a, b) ((a) == (b))

/* Include declarations of os_ functions. */
#include "os_depend.h"

/*
 *  Set plain ascii mode - does nothing on the mac
 */
#define os_plain()


/*
 *   Create and open a temporary file.  Creates and opens a temporary
 *   file.  If 'swapname' is null, this routine must choose a file name
 *   and fill in 'buf' with the chosen name; if possible, the file should
 *   be in the conventional location for temporary files on this system,
 *   and should be unique (i.e., it shouldn't be the same as any existing
 *   file).  
 */
extern osfildef *os_create_tempfile(char *swapname, char *buf);

#endif /* OS_INCLUDED */
