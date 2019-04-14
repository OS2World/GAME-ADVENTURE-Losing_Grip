/*
** global.h -- All of the globally defined variables.  To define them "for
**             real" simply "#define extern" before you #include this file,
**             then "#undef extern" after you include it.
*/

/* Preferences structure */
typedef struct _PREFS {
	SWP		swpFrame;
	FATTRS	fattrs, fattrsBold;
	BOOL	fStatusSeparated,
			paging,					/* Use "[MORE]" and pause while paging? */
			fulljustify,			/* Full-justify the text? */
			clearbyscroll,			/* Should we clear window by scrolling? */
			doublespace,			/* 2 spaces after a period? */
			fBoldInput,			/* Is the input bold? */
			F1ismacro,			/* F1 is a macro key? */
			F10ismacro,			/* F10 is a macro key? */
			fStickyPaths,			/* Do I remember the last path? */
			fStickyMacros,			/* Do I remember macros? */
			fCloseOnEnd;			/* Do I quit after running a game? */
	short	marginx, marginy,		/* Size of the margins */
			historylength;			/* How many command lines should we save? */
	long	buffersize,				/* The minimum amount to save */
			bufferslack;			/* How much to save before trimming */
	ULONG	ulFore,				/* Foreground color */
			ulBack;				/* Background color */
	CHAR	szGamePath[CCHMAXPATH],	/* Last path to .gam files */
			szSavePath[CCHMAXPATH],	/* Last path to .sav files */
			szStatusFont[FACESIZE],	/* Name of the status font */
			szMacroText[12][255],
			szRecentGames[10][CCHMAXPATH];	/* Recently-opened games */
} PREFS, *PPREFS;

/* "Find" dialog data structure */
typedef struct _FINDDATA {
	CHAR	findText[256];
	BOOL	fCase,
		fBack;
} FINDDATA;

/* Window data struct which threads may use for communication w/the mother ship */
typedef struct _SHARED {
	CHAR	szTADS[CCHMAXPATH];
	CHAR	szData[CCHMAXPATH];
	CHAR	szOutput[CCHMAXPATH];
} SHARED, *PSHARED;

extern HAB		hab,				/* Handle to anchor block */
			habThread;			/* The thread's hab */
extern HPS		hpsClient;			/* HPS to the client */
extern HWND		hwndFrame,			/* Frame window */
				hwndClient,			/* Main client window */
				hwndVertScroll,		/* Vertical scroll bar */
				hwndMessageBox,		/* The message box */
				hwndStatus,			/* The status window */
				hwndStatusFrame;	/* The frame around the status window */
extern PFNWP	DefFrameWndProc,	/* Old Frame Control Subclass Procedure */
				DefMBWndProc,		/* Old Message Box subclass procedure */
				DefStatusWndProc;	/* Old Status Bar subclass procedure */
extern LONG		lMessageBoxWidth,	/* Width of the message box */
				lMessageBoxHeight,	/* Height of the message box */
				lStatusWidth,		/* Width of the status bar */
				lStatusHeight,		/* Height of the status bar */
				lClientHeight;		/* Height of the client window */
extern POINTL	messageBoxPos,		/* Message Box position */
				statusPos;			/* Status bar position */
extern RECTL	clientRect;			/* Size of the client window */
extern CHAR		szStatusLeft[256],	/* Text on the left side of the status bar */
				szStatusRight[256];	/* Text on the right side of the status bar */
extern LONG		lStatusLeftWidth,	/* Width (in pels) of the left status text */
				lStatusRightWidth;	/* "                    " right status text */
extern HPOINTER	hptrArrow,			/* Storage for arrow ptr */
				hptrWait,			/* Wait pointer */
				hptrText,			/* I-beam text pointer */
				hptrOld,			/* Old pointer */
				hptrCurrent;		/* Current pointer */
extern LONG		cursorX, cursorY,	/* Cursor (x, y) position */
				cursorWidth,		/* Cursor width */
				cursorHeight;		/* Cursor height */
extern LONG		lcidNorm,			/* Normal text font id # */
				lcidBold,			/* Bold text font id # */
				lcidInput;			/* Text input id # */
extern PREFS	prefsTADS;			/* Preferences for the program */
extern BOOL		fScrollVisible,		/* Is the scroll bar visible? */
				fWaitCursor,		/* Should we display the wait cursor? */
				fCursorOn,		/* Is the cursor on? */
				fMinimized;		/* Are we minimizing? */
extern LONG		lineheight_story,	/* Height of lines in the client window */
				lineheightoff_story;	/* Vertical offset bet. lines */
extern SHORT	iNormSpace,			/* # of pixels a space takes up in normal font */
				iBoldSpace;			/* # of pixels ' ' takes up in bold */
extern CHAR		zcodename[CCHMAXPATH],	/* Path & filename of the game to play */
			pszExecutable[CCHMAXPATH],	/* Path & filename of the executable */
			pszHomePath[CCHMAXPATH];	/* Path of the executable */
extern SHARED		sShare;				/* Data shared w/window & binding threads */
extern LONG		zcodepos;			/* Position of any bound data */
extern BOOL		validBinding;			/* TRUE if there's data at the end of TADS/2 */
extern TID		tidMachine;			/* The thread ID of the TADS virt. machine */

extern cmdentry	*keycmds[NUMCOMMANDS];
extern char		*keycmdargs[NUMCOMMANDS];

/* Semaphores */
extern BOOL		fThreadRunning;
