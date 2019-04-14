#include <string.h>
#include <time.h>

#define INCL_PM
#include <os2.h>
#include "tadsos2.h"
#include "os2io.h"
#include "global.h"
#include "os.h"
#include "run.h"

extern int trdmain(int argc, char *argv[]);
extern VOID TweakMenus(VOID);

VOID _System os_main_shell(ULONG parm);

VOID _System os_main_shell(ULONG parm)
{
	#define NUMOPTIONS (4)
	char *argv[NUMOPTIONS] = {NULL, NULL, NULL, NULL}; /* "-tp" for stress-testing */
	HMQ hmq;
	BOOL fSuccess;

	habThread = WinInitialize(0);
	hmq = WinCreateMsgQueue(habThread, 0);
	fSuccess = WinCancelShutdown(hmq, TRUE);
	
	if (fSuccess) {
		argv[0] = pszExecutable;
		argv[1] = "-m700000";	/* Size of the cache */
		argv[2] = prefsTADS.doublespace ? "-double+" : "-double-";

		/* This next bit is for handling bound games */
		if (zcodename[0] != 0)
			argv[NUMOPTIONS-1] = zcodename;
		
		fThreadRunning = TRUE;	// Let people know we're going
		TweakMenus();		// Get the menus set up
		initialize_screen();
		SetStatusTextRight("0/0");
		
		if (zcodename[0] != 0)
			trdmain(NUMOPTIONS, argv);
		else trdmain(NUMOPTIONS - 1, argv);

		reset_screen();			/* Print an exit message */
		fThreadRunning = FALSE;	// All done now
		if (validBinding || prefsTADS.fCloseOnEnd)
			WinPostMsg(hwndFrame, WM_CLOSE, MPVOID, MPVOID);
		else {					// Otherwise, reset the text engine
			xtext_end();
			xtext_init();
			mainwin_caret_changed(FALSE);
			ShowScrollBar(FALSE);
			ClearStatus();
		  	xtext_resize(0, 0, clientRect.xRight -
		  		clientRect.xLeft, lClientHeight);
			WinInvalidateRegion(hwndClient, NULLHANDLE, FALSE);
			TweakMenus();
		}
	} else {
		WinMessageBox(HWND_DESKTOP, hwndClient,
			"Error in TADS thread", "TADS/2 Error", 0,
			MB_OK);
		WinPostMsg(hwndClient, WM_CLOSE, MPVOID, MPVOID);
	}
	WinSetWindowText(hwndFrame, "TADS/2");
	WinDestroyMsgQueue(hmq);
	WinTerminate(habThread);
}

/* Do a printf() to the output buffer. */
void os_printf_real(char *f, long a1, long a2, long a3, long a4)
{
	char buf[256];
    sprintf(buf, f, a1, a2, a3, a4);
    display_string(buf);
}

/* Flush output. */
void os_flush()
{
    /*fflush( stdout ); No need under OS/2 */
}

/* Like gets(): return a string with no terminal newline. */
char *os_gets(char *buf, int buflen)
{
	int readpos;
	
	{
		extern void runstat(int flag);
		runstat(0); /* Pretend this was called from the TADS engine before os_gets() */
	}
	
	readpos = 0;
	input_line(buflen-1, buf, 0, &readpos);
	buf[readpos] = '\0';
    return buf;
}

/* Return the character which will be sucked from the output stream to indicate
	boldface on/off. 2 means on, 1 off. We just use \002 and \001. */
int os_hilite(int flag)
{
	if (flag == 2)
		return '\002';
	else
		return '\001';
}

void os_clear_screen()
{
	clear_text_window();
}

/* Put a random number into seed. It should be as random as possible, because it's
	used as a seed for TADS's RNG in non-deterministic mode. */
void os_rand(long *seed)
{
	time_t val = time(NULL);
	*seed = (long)val;
}

void os_defext(char *buf, char *ext)
{
    char *p, *n, tmp[1024];
    char *defpath;

    /*
     * Prepend default path
     */
   if (!stricmp(ext, "sav"))
	defpath = getenv("TADSSAVE");
   else if (!stricmp(ext, "gam"))
	defpath = getenv("TADSGAME");
   else
        defpath = NULL;

   if (defpath) {
   	/*
	 * Look for slashes.  If there are any, don't mess with name.
	 */
	n = buf;
	while (*n) {
		if (*n == '/')
			break;
		n++;
	}
	if (!*n) {
		strcpy(tmp, defpath);
		if (defpath[strlen(defpath)] != '/')
			strcat(tmp, "/");
		strcat(tmp, buf);
		strcpy(buf, tmp);
	}  
   }

   p = buf+strlen(buf);
   while ( p>buf )
     {
       p--;
       if ( *p=='.' ) return;      /* already has an extension */
       if ( *p=='/' || *p=='\\' || *p==':'
          ) break;    /* found a path */
     }
   strcat( buf, "." );              /* add a dot */
   strcat( buf, ext );              /* add the extension */
}


/* Opens the given .exe file and seeks to the end of the executable part of
	it, on the assumption that a datafile is to be found there. */
osfildef *os_exeseek(char *exefile, char *typ)
{
    FILE     *fp;
    unsigned  ofs, segcnt;
    unsigned  long seekpt;
    unsigned  long check;
    unsigned  long startofs;
    unsigned  long end;
    char      typbuf[4];

    /* If we're interested in seeing if the executable has a data file
       appended to it, well, TADS/2 has already taken care of that! */
    if (!(strcmp(exefile, pszExecutable) || memcmp(typ, "TGAM", 4))) {
    	if (!validBinding) return ((FILE *)0);
    	if (!(fp = fopen(exefile, "rb"))) return ((FILE *)0);
//    	fseek(fp, zcodepos + sizeof(check) + sizeof(typbuf), SEEK_SET);
	fseek(fp, zcodepos, SEEK_SET);
	fread(&check, sizeof(check), 1, fp);
        fread(typbuf, sizeof(typbuf), 1, fp);
        return fp; 
    }

    /* open the file and seek to the very end */
    if (!(fp = fopen(exefile, "rb"))) return((FILE *)0);
    fseek(fp, 0L, SEEK_END);

    /* look through tagged blocks until we find the type we want */
    for (;;)
    {
        /* seek back past the descriptor block */
        fseek(fp, -12L, SEEK_CUR);
        seekpt = ftell(fp);

        /* read the elements of the descriptor block */
        if (fread(&check, sizeof(check), 1, fp) != 1
            || fread(typbuf, sizeof(typbuf), 1, fp) != 1
            || fread(&startofs, sizeof(startofs), 1, fp) != 1)
            break;

        /* check the signature to make sure we're looking at a valid block */
        if (check != ~seekpt)
            break;

        /* seek to the start of the data for this resource */
        fseek(fp, startofs, SEEK_SET);

        /* if this is the one we want, return it, otherwise keep looking */
        if (!memcmp(typ, typbuf, sizeof(typbuf)))
        {
            /* check the header to make sure it matches */
            if (fread(&check, sizeof(check), 1, fp) != 1
                || fread(typbuf, sizeof(typbuf), 1, fp) != 1
                || check != ~startofs
                || memcmp(typ, typbuf, sizeof(typbuf)))
                break;
            return fp;
        }
    }

    /* we didn't find anything - close the file and return failure */
    fclose(fp);
    return((FILE *)0);
}

/* Open a (writable) swap file. Use filenm, or write a name into deffilenm if
	filenm is NULL. But this should *only* be called with filenm NULL. */
osfildef *os_create_tempfile(char *filenm, char *deffilenm)
{
	osfildef *fp;

    /* if a name wasn't provided, generate a name */
    if (filenm == 0)
    {
        int     try;
        size_t  len;
        time_t  timer;
        int     found;
        
        /* get the appropriate path for a temp file */
        os_get_tmp_path(deffilenm);
        len = strlen(deffilenm);

        /* get the current time, as a basis for a unique identifier */
        time(&timer);

        /* try until we find a non-existent filename */
        for (try = 0, found = FALSE ; try < 100 ; ++try)
        {
            /* generate a name based on time and try number */
            sprintf(deffilenm + len, "SW%06ld.%03d", (long)timer % 999999, try);

            /* if this file doesn't exist, we're done */
            if (osfacc(deffilenm))
            {
                found = TRUE;
                break;
            }
        }

        /* if all the files we tried existed already, give up */
        if (!found)
            return 0;

        /* use the buffer's contents as the name */
        filenm = deffilenm;
    }

    /* open the file */
    fp = osfoprwtb(filenm);

    /* set the file's type in the OS, if necessary */
    os_settype(filenm, OSFTSWAP);

    /* return the file pointer */
    return fp;
}

/* Pause and wait for a keystroke. This is called between the display of a startup
	error and shutdown. */
void os_expause()
{
	reset_screen();
}

/* Pause and wait for a keystroke. This is called between normal game termination and
	shutdown. */
void os_waitc()
{
	reset_screen();
}

/* Wait for a character and return it. 0 means some strange circumstance I don't
	understand, so don't return it. */
unsigned char os_getc()
{
	return input_character(0);
}

/* This takes two arguments, an osfildef* and a length, and tries to suck an external code
	resource from the osfildef*. Return NULL for error. */
int (*os_exfld(osfildef *fp, unsigned len))(void)
{
	int (*result)(void); /* pointer to memory containing code */
	
	result = NULL;
	return result;
}

/* This takes one argument, a filename, and returns a pointer to a function
	int func(void). It is used for external code resources. Return NULL for error. */
int (*os_exfil(char *filenm))(void)
{
	int (*result)(void); /* pointer to memory containing code */
	
	result = NULL;
	return result;
}

/* Call the function. Return nonzero for error. */
int os_excall(int (*funcptr)(void), struct runuxdef *ux)
{
	return -1;
}

/* Check for any event that the user might send as a "break" signal. [TK] */
int os_break()
{
	return 0;
}

/* Set the cursor to or from a wait image. */
void os_csr_busy(int val)
{
	if (val)
		fWaitCursor = TRUE;
	else
		fWaitCursor = FALSE;
}

/* Set a file to a given type. */
void os_settype(char *filenm, int typeval)
{
	/* do nothing */
}

/* Check to see if a save file was specified for restoring at startup. If so,
	put its name in filbuf and return TRUE. Note: in TADS/2 this is
	unnecessary, as the front-end takes care of things */
int os_paramfile(char *filbuf)
{
	return 0;
}

/* Prompt the user for a filename, and store it in buf. Return nonzero for error. */
int os_askfile(char *prompt, char *buf, int bufsiz)
{
	SHORT type = 0; /* 0: save game; 1: restore game; 2: write script */
	BOOL  writing = FALSE, fReturn;
	PCHAR p;
	
	if (stristr(prompt, "save")) {
		writing = TRUE;
		if (stristr(prompt, "game")) {
			type = 0;
		}
	}
	if (stristr(prompt, "write")) {
		writing = TRUE;
		if (stristr(prompt, "script")) {
			type = 2;
		}
	}
	if (!writing) {
		if (stristr(prompt, "game") || stristr(prompt, "restore")) {
			type = 1;
		}
	}
	
	{
		BOOL QueryFile(CHAR *buf, SHORT bufsize, SHORT iOpen);
		fReturn = (QueryFile(buf, bufsiz, type) == FALSE);
	}
	if (!fReturn) {
		p = buf;		// Nasty hack: Change '\\' to '/' to
		while (*p != 0) {	//  avoid '\t' '\n' problems
			if (*p == '\\') {
				*p = '/';
			}
			p++;
		}
	}
	return fReturn;
}

/* Set right side of status line to "numer/denom" */
void os_score(int numer, int denom)
{
	char buf[64];

	if (denom < 0)
		strcpy(buf, "");
	else
		sprintf(buf, "%d/%d", numer, denom);
	os_strsc(buf);
}

/* Set right side of status line to str. */
void os_strsc(char *str)
{
	SetStatusTextRight(str);
}

/* 0: story window. 1: status line. 2: Ldesc mode? */
void os_status(int flag)
{
	select_status_mode(flag);
}

/*
 *   Get the temporary file path.  This should fill in the buffer with a
 *   path prefix (suitable for strcat'ing a filename onto) for a good
 *   directory for a temporary file, such as the swap file.  
 */
void os_get_tmp_path(char *s)
{
/*  int i;

  strcpy(s, tmpnam(NULL));
  for (i = strlen(s) - 1; i >= 0; i--)
    if (s[i] == '/' || s[i] == '\\')
      break;

  s[i + 1] = 0;*/
  strcpy(s, pszHomePath);
}
