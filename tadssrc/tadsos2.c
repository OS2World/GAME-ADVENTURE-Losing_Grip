/*
** TADSOS2.C
*/

#define INCL_PM
#define INCL_DOSPROCESS
#include <os2.h>
#include <stdlib.h>
#include "tadsos2.h"
#include "os2io.h"

/* Declare the global variables */
#define extern
#include "global.h"
#undef extern

extern VOID CreateMessageBox(HWND hwndParent);
extern VOID CreateStatus(VOID);
extern VOID SwapStatus(VOID);
extern VOID CreateScrollBar(VOID);
extern VOID ShowScrollBar(BOOL bFlag);
extern VOID TweakMenus(VOID);
extern VOID TweakRecentMenu(VOID);
extern VOID AddRecent(char *new);
extern VOID TweakBindingMenu(VOID);
extern VOID SetupMacroMenus(VOID);
extern VOID AdjustAccelerators(SHORT key, SHORT flags);
extern MRESULT EXPENTRY StatusWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern MRESULT EXPENTRY FindDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern MRESULT EXPENTRY StoryWindowDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern MRESULT EXPENTRY InterpreterDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern MRESULT EXPENTRY OptionsDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern MRESULT EXPENTRY AboutDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern VOID _System os_main_shell(ULONG parm);


MRESULT EXPENTRY FrameWndProc( HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2 );
MRESULT EXPENTRY TadsMainWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
LONG CalcSeparatorWidth( HWND hWnd );
VOID DrawSeparator(HWND hwnd, HPS hps, LONG lXStart, LONG lYStart);
SHORT UpdateFonts(HPS hps, BOOL fUpdate);
SHORT UpdateInputFont(HPS hps, BOOL fBold);
SHORT DefaultFont(VOID);
VOID HandleMenuCommand(HWND hwnd, USHORT menuItemID);
VOID StripFontName(PSZ pszFamily);
VOID GetFont(VOID);
BOOL QueryFile(CHAR *buf, SHORT bufsize, SHORT iOpen);
VOID DisplayMessage(PSZ pszString);
VOID DisplayInformation(PSZ pszString);
VOID DisplayError(PSZ pszString);

extern SHORT cmdkeylist[];		// Defined in os2ctls.c

/*
** Preferences functions
*/

/* SavePrefs updates the main preferences and saves them to the profile. It
   returns TRUE on success, FALSE on failure. */
BOOL SavePrefs(VOID)
{
	HINI	hini;
	CHAR	szProfileName[50],
			szPrefsName[50],
			szPrefsKeyName[50],
			szProfilePath[CCHMAXPATH];
	int	i;

/* Get the name of the profile, the name of the preferences, and the name
   of the key, all from a string resource */
	WinLoadString(hab, NULLHANDLE, strix_PrefsFileName, sizeof(szProfileName),
		szProfileName);
	WinLoadString(hab, NULLHANDLE, strix_PrefsName, sizeof(szPrefsName),
		szPrefsName);
	WinLoadString(hab, NULLHANDLE, strix_PrefsKeyName, sizeof(szPrefsKeyName),
		szPrefsKeyName);

/* Save the frame window's position */
	WinQueryWindowPos(hwndFrame, &prefsTADS.swpFrame);

/* If we're supposed to, save the macro data */
	if (prefsTADS.fStickyMacros) {
		for (i = 0; i < 12; i++) {
			if (keycmdargs[cmdkeylist[i] | keytype_virtual] != NULL) {
				strncpy(prefsTADS.szMacroText[i],
					keycmdargs[cmdkeylist[i] |
					keytype_virtual], 254);
				prefsTADS.szMacroText[i][254] = 0;
			}
		}
	}

/* Open the profile and write the data */
	strcpy(szProfilePath, pszHomePath);
	strcat(szProfilePath, szProfileName);
	hini = PrfOpenProfile(hab, szProfilePath);
	if (hini == NULLHANDLE)
		return FALSE;
	if (PrfWriteProfileData(hini, szPrefsName, szPrefsKeyName, &prefsTADS,
		sizeof(PREFS)) == FALSE)
		return FALSE;

/* Don't forget to close the profile */
	return PrfCloseProfile(hini);
}

/* RestorePrefs reads the preferences from the profile and applies them to
   the proper windows.  It returns TRUE on success, FALSE on failure. */
BOOL RestorePrefs(VOID)
{
	HINI	hini;
	ULONG	ulBufSize = sizeof(PREFS);
	CHAR	szProfileName[50],
			szPrefsName[50],
			szPrefsKeyName[50],
			szProfilePath[CCHMAXPATH];

/* Start out by zeroing out the preferences data block */
	memset((void *)&prefsTADS, 0, sizeof(PREFS));

/* Get the name of the profile, the name of the preferences, and the name
   of the key, all from a string resource */
	WinLoadString(hab, NULLHANDLE, strix_PrefsFileName, sizeof(szProfileName),
		szProfileName);
	WinLoadString(hab, NULLHANDLE, strix_PrefsName, sizeof(szPrefsName),
		szPrefsName);
	WinLoadString(hab, NULLHANDLE, strix_PrefsKeyName, sizeof(szPrefsKeyName),
		szPrefsKeyName);
	
/* Open the profile and read the data */
	strcpy(szProfilePath, pszHomePath);
	strcat(szProfilePath, szProfileName);
	hini = PrfOpenProfile(hab, szProfilePath);
	if (hini == NULLHANDLE)
		return FALSE;
	if (PrfQueryProfileData(hini, szPrefsName, szPrefsKeyName, &prefsTADS,
		&ulBufSize) == FALSE)
		return FALSE;
	if (PrfCloseProfile(hini) == FALSE)
		return FALSE;

/* Deal with macro key adjustments */
	if (prefsTADS.F1ismacro)
		AdjustAccelerators(VK_F1, AF_HELP);
	if (prefsTADS.F10ismacro)
		AdjustAccelerators(VK_F10, SC_APPMENU);
	
	return TRUE;
}

/* DefaultPrefs sets the preferences to my preferred default. */
VOID DefaultPrefs(VOID)
{
/* Zero out the preferences data block */
	memset((void *)&prefsTADS, 0, sizeof(PREFS));

/* Let the system set the size of the window */
	WinQueryTaskSizePos(hab, 0, &prefsTADS.swpFrame);
	
/* Set the margins */
	prefsTADS.marginx = 8;
	prefsTADS.marginy = 4;
	
/* Set the buffer */
	prefsTADS.buffersize = 4000;
	prefsTADS.bufferslack = 1000;
	
/* Set the history length */
	prefsTADS.historylength = 20;
	
/* Set all the flags */
	prefsTADS.fStatusSeparated = FALSE;
	prefsTADS.paging = TRUE;
	prefsTADS.fulljustify = TRUE;
	prefsTADS.clearbyscroll = FALSE;
	prefsTADS.doublespace = FALSE;
	prefsTADS.fBoldInput = TRUE;
	prefsTADS.F1ismacro = TRUE;
	prefsTADS.F10ismacro = TRUE;
	prefsTADS.fStickyPaths = TRUE;
	prefsTADS.fStickyMacros = TRUE;
	prefsTADS.fCloseOnEnd = TRUE;

/* Set the foreground and background colors */
	prefsTADS.ulFore = RGB_BLACK;
	prefsTADS.ulBack = RGB_WHITE;
	
/* Set the .gam/.sav paths to "" */
	prefsTADS.szGamePath[0] = 0;
	prefsTADS.szSavePath[0] = 0;
	
/* Set the fonts */
	strcpy(prefsTADS.szStatusFont, "12.Tms Rmn");
	DefaultFont();
	
/* Set the accelerators */
	AdjustAccelerators(VK_F1, AF_HELP);
	AdjustAccelerators(VK_F10, SC_APPMENU);
}


/*
** Calculate the width of the separator bar bet. the client & message box.
** It is the same width as the client, so we return the client's width - 1
*/
LONG CalcSeparatorWidth( HWND hwnd )
{
	RECTL rectl;
	LONG lWidth = 0;

	if ( WinQueryWindowRect( WinWindowFromID( hwnd, FID_CLIENT ), &rectl ) )
		lWidth = rectl.xRight - rectl.xLeft - 1;

	lWidth = (lWidth < 0) ? 0 : lWidth;
	return( lWidth );
}

/*
** Draw the separator bar, starting at the point lXStart, lYStart.
*/
VOID DrawSeparator(HWND hwnd, HPS hps, LONG lXStart, LONG lYStart)
{
	USHORT i;
	POINTL start[5],
		   end[5];

	LONG color[5] = { SYSCLR_BUTTONMIDDLE, SYSCLR_BUTTONMIDDLE,
                      SYSCLR_BUTTONMIDDLE, SYSCLR_BUTTONMIDDLE,
                      SYSCLR_BUTTONLIGHT };

	/******************************************************************/
	/* Init the POINTL arrays for drawing the horizontal separator    */
	/******************************************************************/
	LONG lSeparatorWidth = CalcSeparatorWidth( hwnd );

	start[0].x = start[1].x = start[2].x = start[3].x =
		start[4].x = lXStart;
	start[0].y = start[1].y = start[2].y = start[3].y =
		start[4].y = lYStart;
	start[1].y += 1;
	start[2].y += 2;
	start[3].y += 3;
	start[4].y += 4;
	end[0] = start[0];
	end[0].x += lSeparatorWidth;
	end[1] = start[1];
	end[1].x += lSeparatorWidth;
	end[2] = start[2];
	end[2].x += lSeparatorWidth;
	end[3] = start[3];
	end[3].x += lSeparatorWidth;
	end[4] = start[4];
	end[4].x += lSeparatorWidth;

	/******************************************************************/
	/* Draw the horizontal separator bar.                             */
	/******************************************************************/
	for (i=0; i< SEPARATOR_WIDTH; i++) {
		LONG lSysColor = WinQuerySysColor( HWND_DESKTOP, color[i], 0L );
		GpiSetColor( hps, GpiQueryColorIndex( hps, 0, lSysColor ) );
		GpiMove( hps, &start[i] );
		GpiLine( hps, &end[i] );
	}
}


/*
** Font functions
*/

/* UpdateFonts takes the fattrs in prefsTADS and tries to create both a
   regular font and a bold font. It returns TRUE if everything is ok,
   FALSE if no fonts could be created, and -1 if no bold font was created. */
SHORT UpdateFonts(HPS hps, BOOL fUpdate)
{
	LONG		lResult;
	FONTMETRICS	fm;
	BOOL		fC, fDefault = FALSE;
	CHAR		szBuffer[FACESIZE];

	/* Create the regular font */
	lResult = GpiCreateLogFont(hps, (PSTR8) NULL, lcidNorm,
		&prefsTADS.fattrs);
	if (lResult == GPI_ERROR)
		return FALSE;
	if (lResult == FONT_DEFAULT)
		fDefault = TRUE;

	/* Create the bold font */
	memcpy(&prefsTADS.fattrsBold, &prefsTADS.fattrs, sizeof(FATTRS));
	strcpy(szBuffer, prefsTADS.fattrsBold.szFacename);
	strcat(prefsTADS.fattrsBold.szFacename, " Bold");
	lResult = GpiCreateLogFont(hps, (PSTR8) NULL, lcidBold,
		&prefsTADS.fattrsBold);
	if (lResult == FONT_DEFAULT) {
		strcpy(prefsTADS.fattrsBold.szFacename, szBuffer);
		prefsTADS.fattrsBold.fsSelection |= FATTR_SEL_BOLD;
		lResult = GpiCreateLogFont(hps, (PSTR8) NULL, lcidBold,
			&prefsTADS.fattrsBold);
		if (lResult == FONT_DEFAULT)
			lResult = GpiCreateLogFont(hps, (PSTR8) NULL, lcidBold,
				&prefsTADS.fattrs);
	}

	/* Create the input font */
	UpdateInputFont(hps, prefsTADS.fBoldInput);

	/* If updating, update the lineheight (i.e. the height of a line of
	   text) */
	if (fUpdate) {
		XSetFont(hps, lcidNorm);
		GpiQueryFontMetrics(hps, sizeof(FONTMETRICS), &fm);
		lineheight_story = fm.lMaxBaselineExt;
		lineheightoff_story = fm.lMaxAscender;
	
		/* Update the # of pixels a space takes */
		XTextExtents(hps, lcidBold, " ", 1, &iBoldSpace);
		XTextExtents(hps, lcidNorm, " ", 1, &iNormSpace);

		/* Update the cursor */
		fC = fCursorOn;
		if (fC)
			XShowDot(hwndClient, FALSE);
		cursorHeight = lineheightoff_story + 1;
		if (fC)
			XShowDot(hwndClient, TRUE);

		/* Update the client window */
	  	xtext_resize(0, 0, clientRect.xRight - clientRect.xLeft,
	  		lClientHeight);
		WinInvalidateRegion(hwndClient, NULLHANDLE, FALSE);
	}
	
	if (lResult == GPI_ERROR)
		return FALSE;
	if (lResult == FONT_DEFAULT || fDefault) {
		DisplayInformation("Unable to create fonts");
		return (-1);
	}

	return TRUE;
}

/* UpdateInputFont updates the input font. */
SHORT UpdateInputFont(HPS hps, BOOL fBold)
{
	if (fBold)
		GpiCreateLogFont(hps, (PSTR8) NULL, lcidInput,
			&prefsTADS.fattrsBold);
	else GpiCreateLogFont(hps, (PSTR8) NULL, lcidInput,
		&prefsTADS.fattrs);
}

/* DefaultFont selects a default font for the program: Times New Roman 10pt.
   Its return values are the same as for UpdateFonts. */
SHORT DefaultFont(VOID)
{
	prefsTADS.fattrs.usRecordLength = sizeof(FATTRS);
	prefsTADS.fattrs.fsSelection = 0;
	prefsTADS.fattrs.lMatch = 0L;
	prefsTADS.fattrs.idRegistry = 0;
	prefsTADS.fattrs.usCodePage = 850;
	prefsTADS.fattrs.lMaxBaselineExt = 10L;
	prefsTADS.fattrs.lAveCharWidth = 10L;
	prefsTADS.fattrs.fsType = 0;
	prefsTADS.fattrs.fsFontUse = FATTR_FONTUSE_NOMIX;
	strcpy(prefsTADS.fattrs.szFacename, "Times New Roman");

	return UpdateFonts(hpsClient, TRUE);
}


/*
** Window routines
*/

/* SetupMainWindow takes care of all the piddling little details, like sizing
   and showing the window. */
VOID SetupMainWindow(VOID)
{
	extern short statusmode;		/* Defined in os2io.c */
	LONG	width, height;

	/* Prepare the text engine */
	xtext_init();
	statusmode = 0;

/* Apply the preferences to the size of the frame window.  Make sure we won't
   be bigger than the entire screen */
	width = WinQuerySysValue(HWND_DESKTOP, SV_CXSCREEN) - prefsTADS.swpFrame.x;
	height = WinQuerySysValue(HWND_DESKTOP, SV_CYSCREEN) - prefsTADS.swpFrame.y;

	if (width > prefsTADS.swpFrame.cx)
		width = prefsTADS.swpFrame.cx;
	if (height > prefsTADS.swpFrame.cy)
		height = prefsTADS.swpFrame.cy;
	
	WinSetWindowPos(hwndFrame, NULLHANDLE, prefsTADS.swpFrame.x,
		prefsTADS.swpFrame.y, width, height, SWP_MOVE | SWP_SIZE | SWP_SHOW);
}


/*
** Main section
*/

int main(int argc, char **argv, char **envp)
{
	HMQ			hmq;
	QMSG		qmsg;
	SWP			swpClient;
	PCHAR		p;

	ULONG flFrameFlags =
		FCF_TITLEBAR		|	/* Title bar */
		FCF_SIZEBORDER		|	/* Size border */
		FCF_MINMAX			|	/* Min & Max Button */
		FCF_SYSMENU			|	/* System Menu */
		FCF_SHELLPOSITION	|	/* System size & position */
		FCF_TASKLIST		|	/* Add name to tasklist */
		FCF_ACCELTABLE		|	/* Add accelerator table */
		FCF_ICON			|	/* Add icon */
		FCF_MENU;				/* Add menu */

	hab = WinInitialize(0);
	hmq = WinCreateMsgQueue(hab, 0);
	WinSetCp( hmq, 850 );		/* Set the code page */
	/* Register the main window class */
	WinRegisterClass(
		hab,					/* Anchor block handle */
		"TADS/2MainWindow",		/* Class name */
		(PFNWP)TadsMainWndProc,	/* Window procedure */
		CS_SIZEREDRAW,			/* Redraw us when we're resized */
		0);						/* Extra bytes to reserve */

	/* Register the separated status bar class */
	WinRegisterClass(
		hab,					/* Anchor block handle */
		"TADS/2Status",			/* Class name */
		(PFNWP)StatusWndProc,	/* Window procedure */
		CS_SIZEREDRAW,			/* Redraw us when we're resized */
		0);						/* Extra bytes to reserve */

	hwndFrame = WinCreateStdWindow(
		HWND_DESKTOP,			/* Parent is desktop */
		0,						/* Make us invisible */
		&flFrameFlags,			/* Frame flags */
		"TADS/2MainWindow",		/* Name of client window class */
		"TADS/2",				/* Window title */
		0,
		(HMODULE)0L,			/* Show that resources are in application */
		TADS2,				/* Load the accel&menu rsc */
		&hwndClient);			/* Save our client window handle */

	if (hwndFrame == NULLHANDLE) {
		DisplayError("Unable to create TADS/2 window");
		return TRUE;
	}

	hpsClient = WinGetPS(hwndClient);
	
	/* Set the IDs for the fonts--normal & bold */
	lcidNorm = 100;
	lcidBold = 101;
	lcidInput = 102;

	/* Set up the cursor */
	cursorX = cursorY = 0;
	cursorWidth = 1;
	fCursorOn = FALSE;

	/* Set up the initial path & executable names */
	strcpy(pszExecutable, argv[0]);
	strcpy(pszHomePath, argv[0]);
	p = pszHomePath + strlen(pszHomePath) - 2;
	while (p != pszHomePath && *p != '\\')
		p--;
	if (p != pszHomePath)
		*(p+1) = 0;

	/* Restore the preferences */
	if (!RestorePrefs()) {				/* If there's an error,     */
		DefaultPrefs();					/*  set the default prefs	*/
	}
	else UpdateFonts(hpsClient, TRUE);

	/* Set the colors */
	GpiCreateLogColorTable(hpsClient, 0L, LCOLF_RGB, 0L, 0L, NULL);
	XSetForeColor(prefsTADS.ulFore);
	XSetBackColor(prefsTADS.ulBack);

	/* Create the message box */
	CreateMessageBox(hwndFrame);

	/* Create the vertical scroll bar */
	CreateScrollBar();

	/* Subclass the frame control */
	DefFrameWndProc = WinSubclassWindow(hwndFrame, (PFNWP)FrameWndProc );

	/* Save all of the system pointers */
	hptrArrow = WinQuerySysPointer(HWND_DESKTOP, SPTR_ARROW, FALSE);
	hptrWait = WinQuerySysPointer(HWND_DESKTOP, SPTR_WAIT, FALSE);
	hptrText = WinQuerySysPointer(HWND_DESKTOP, SPTR_TEXT, FALSE);
	fWaitCursor = FALSE;		/* Start out not showing wait cursor */

	/* Set up the keyboard */
	{ extern VOID init_kbd(VOID); init_kbd(); }
	
	/* Now that the keyboard is set up, take care of the macro menu */
	SetupMacroMenus();
	
	/* Set up the status bar */
	SetStatusTextLeft("");
	SetStatusTextRight("");
	
	/* Set up flags */
	fMinimized = FALSE;

	/* Test binding */
	zcodepos = TestBinding(pszExecutable);
	zcodename[0] = 0;
	validBinding = (zcodepos != 0);
	TweakBindingMenu();	// Adjust binding options accordingly
	if (validBinding) {
		WinPostMsg(hwndClient, WM_COMMAND,
			MPFROMSHORT(CMD_STARTTADS), MPVOID);
	}
	else if (argc == 2) {	// Drag & drop, bay-bee!
		strcpy(zcodename, argv[1]);
		AddRecent(zcodename);
		WinPostMsg(hwndClient, WM_COMMAND,
			MPFROMSHORT(CMD_STARTTADS), MPVOID);
	}
	strcpy(sShare.szTADS, pszExecutable);
	strcpy(sShare.szData, zcodename);
	sShare.szOutput[0] = 0;
	
	TweakRecentMenu();

	/* Make us visible */
	SetupMainWindow();

	/* Create the status bar */
	CreateStatus();
	
	/* Prepare the thread semaphores */
	fThreadRunning = FALSE;
	
	WinStartTimer(hab, hwndClient, ID_CURSORTIMER, 500);

	while (WinGetMsg(hab, &qmsg, 0, 0, 0))
		WinDispatchMsg(hab, &qmsg);

	WinStopTimer(hab, hwndClient, ID_CURSORTIMER);


	SavePrefs();
	WinReleasePS(hpsClient);

	if (prefsTADS.fStatusSeparated)
		WinDestroyWindow(hwndStatusFrame);
	else WinDestroyWindow(hwndStatus);

	WinDestroyWindow(hwndFrame);
	WinDestroyMsgQueue(hmq);
	WinTerminate(hab);
	return FALSE;
}

/*
** FrameWndProc processes the messages sent to the frame window, in order to
** handle the addition of the bottom status bar (the message box)
*/
MRESULT EXPENTRY FrameWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	switch(msg) {
	  case WM_FORMATFRAME:
		{
			/* Query the number of std frame controls */
			ULONG ulStdCtlCount = (ULONG)DefFrameWndProc( hwnd, msg, mp1, mp2 );
			ULONG ulIdx = ulStdCtlCount;

			/* Access the SWP array that is passed to us */
			ULONG i;
			PSWP swpArr = (PSWP)mp1;

			for (i=0; i < ulStdCtlCount; i++) {
				if ( WinQueryWindowUShort( swpArr[i].hwnd, QWS_ID ) ==
					FID_CLIENT ) {
				/**************************************************************/
				/* Initialize the SWP for our static text control.  Since     */
				/* the SWP array for the std frame controls is 0-based and    */
				/* occupy indexes 0 thru n-1 (where n is the total count),    */
				/* we use index n for our static text control                 */
				/**************************************************************/
				swpArr[ulIdx].fl = SWP_MOVE | SWP_SIZE | SWP_NOADJUST;
				swpArr[ulIdx].cy = lMessageBoxHeight;
				swpArr[ulIdx].cx = swpArr[i].cx;
				messageBoxPos.y = swpArr[ulIdx].y  = swpArr[i].y;
				messageBoxPos.x = swpArr[ulIdx].x = swpArr[i].x;
				swpArr[ulIdx].hwndInsertBehind = HWND_TOP;
				swpArr[ulIdx].hwnd = hwndMessageBox;

				/**************************************************************/
				/* Adjust the origin and height of the client to accomodate   */
				/* our static text control.  Remember to leave enough space   */
				/* for the separator bar.                                     */
				/**************************************************************/
				swpArr[i].y += swpArr[ulIdx].cy + SEPARATOR_WIDTH;
				swpArr[i].cy -= (swpArr[ulIdx].cy + SEPARATOR_WIDTH);
				
				/**************************************************************/
				/* If the status bar is hooked on the client frame, handle    */
				/* it as well.  We use index n+1 for the status bar           */
				/**************************************************************/
				if (prefsTADS.fStatusSeparated)
					break;

				ulIdx++;
				swpArr[ulIdx].fl = SWP_MOVE | SWP_SIZE | SWP_NOADJUST;
				swpArr[ulIdx].cy = lStatusHeight;
				swpArr[ulIdx].cx = swpArr[i].cx;
				statusPos.y = swpArr[ulIdx].y =
					swpArr[i].y + swpArr[i].cy - lStatusHeight;
				statusPos.x = swpArr[ulIdx].x = swpArr[i].x;
				swpArr[ulIdx].hwndInsertBehind = HWND_TOP;
				swpArr[ulIdx].hwnd = hwndStatus;

				/**************************************************************/
				/* Adjust the origin and height of the client to accomodate   */
				/* the status bar.  Remember to leave enough space for the    */
				/* separator bar.                                             */
				/**************************************************************/
				swpArr[i].cy -= (swpArr[ulIdx].cy + SEPARATOR_WIDTH);
				
				}
			}

			/******************************************************************/
			/* Increment the number of frame controls to include our new      */
			/* static test control.                                           */
			/******************************************************************/
			return( (MRESULT)(ulIdx + 1) );
		}
	  case WM_QUERYFRAMECTLCOUNT:
		{
			ULONG	ulAdd;
			
			/******************************************************************/
			/* Query the standard frame controls count and increment to       */
			/* include our message box (and status bar, if necessary)         */
			/******************************************************************/
			ulAdd = 1 + (prefsTADS.fStatusSeparated ? 0 : 1);

			return( (MRESULT)((ULONG)DefFrameWndProc( hwnd, msg, mp1, mp2 ) +
				ulAdd) );
		}

	  case WM_QUERYTRACKINFO:
		{
			/******************************************************************/
			/* Query the default tracking information for the standard frame  */
			/* control.                                                       */
			/******************************************************************/
			BOOL rc = (BOOL)DefFrameWndProc( hwnd, msg, mp1, mp2 );
			PTRACKINFO pTrackInfo = (PTRACKINFO)mp2;


			/******************************************************************/
			/* Calculate and set the minimum tracking width and height.       */
			/******************************************************************/
			pTrackInfo->ptlMinTrackSize.x = MINIMUM_WIDTH +
                                      (WinQuerySysValue( HWND_DESKTOP,
                                                         SV_CXSIZEBORDER ) * 2);
			pTrackInfo->ptlMinTrackSize.y = lMessageBoxHeight + SEPARATOR_WIDTH +
                                      WinQuerySysValue( HWND_DESKTOP,
                                      					SV_CYMENU) + 
                                      WinQuerySysValue( HWND_DESKTOP,
                                      					SV_CYTITLEBAR) +
                                      (WinQuerySysValue( HWND_DESKTOP,
                                                         SV_CYSIZEBORDER ) * 2);
			if (!prefsTADS.fStatusSeparated)
				pTrackInfo->ptlMinTrackSize.y += lStatusHeight + SEPARATOR_WIDTH;
			else {
				if (pTrackInfo->ptlMinTrackSize.x <
					(lStatusLeftWidth + lStatusRightWidth + 6 +
						WinQuerySysValue(HWND_DESKTOP, SV_CXSIZEBORDER) * 2))
					pTrackInfo->ptlMinTrackSize.x = lStatusLeftWidth +
						lStatusRightWidth + 6 +
						WinQuerySysValue(HWND_DESKTOP, SV_CXSIZEBORDER);
			}

			return( (MRESULT)TRUE );
		}

	  case WM_CALCFRAMERECT:
		{
			/******************************************************************/
			/* Calculate the rectl of the client                              */
			/* control.                                                       */
			/******************************************************************/
			BOOL rc = TRUE;
			PRECTL pRectl = (PRECTL)mp1;
			LONG lExtensionHeight = lMessageBoxHeight + SEPARATOR_WIDTH,
				 lTotalHeight = lExtensionHeight + (prefsTADS.fStatusSeparated ?
					0 : lStatusHeight + SEPARATOR_WIDTH);

			if ( SHORT1FROMMP(mp2) ) {
			/****************************************************************/
			/* Calculate the rectl of the client                            */
			/*--------------------------------------------------------------*/
			/* Call default window procedure to subtract child frame        */
			/* controls from the rectangle's height.                        */
			/****************************************************************/
				LONG lClientHeight;
				rc = (BOOL)DefFrameWndProc( hwnd, msg, mp1, mp2 );

			/****************************************************************/
			/* Position the static text frame extension below the client.   */
			/****************************************************************/
				lClientHeight = pRectl->yTop - pRectl->yBottom;
				if ( lTotalHeight  > lClientHeight  ) {
			/**************************************************************/
			/* Extension is taller than client, so set client height to 0.*/
			/**************************************************************/
					pRectl->yTop = pRectl->yBottom;
				}
				else {
			/**************************************************************/
			/* Set the origin of the client and shrink it based upon the  */
			/* static text control's height.                              */
			/**************************************************************/
					pRectl->yBottom += lExtensionHeight;
					pRectl->yTop -= lExtensionHeight;
				}
			}
			else {
			/****************************************************************/
			/* Calculate the rectl of the frame                             */
			/*--------------------------------------------------------------*/
			/* Call default window procedure to subtract child frame        */
			/* controls from the rectangle's height.                        */
			/* Set the origin of the frame and increase it based upon the   */
			/* static text control's height.                                */
			/****************************************************************/
				pRectl->yBottom -= lExtensionHeight;
				pRectl->yTop += lExtensionHeight;
			}
			return( (MRESULT)rc );
		}

	  case WM_PAINT:
		{
			/******************************************************************/
			/* Process WM_PAINT to draw the separator bar.                    */
			/******************************************************************/
			/******************************************************************/
			/* Allow default proc to draw all of the frame.                   */
			/******************************************************************/
			BOOL rc = (BOOL)DefFrameWndProc( hwnd, msg, mp1, mp2 );

			/******************************************************************/
			/* Get presentation space handle for drawing.                     */
			/******************************************************************/
			HPS hps = WinGetPS( hwnd );

			/******************************************************************/
			/* Draw the horizontal separator bar.                             */
			/******************************************************************/
			DrawSeparator(hwnd, hps, messageBoxPos.x,
				messageBoxPos.y + lMessageBoxHeight);
			
			/******************************************************************/
			/* If necessary, do it again for the status window.               */
			/******************************************************************/
			if (!prefsTADS.fStatusSeparated)
				DrawSeparator(hwnd, hps, statusPos.x,
					statusPos.y - SEPARATOR_WIDTH);

			/******************************************************************/
			/* Release presentation space handle.                             */
			/******************************************************************/
			WinReleasePS( hps );

			return( (MRESULT)TRUE );
		}

	  default:
		return( DefFrameWndProc(hwnd, msg, mp1, mp2) );
	}
}


/*
** TadsMainWndProc processes the messages sent to the client (main) window
*/
MRESULT EXPENTRY TadsMainWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	static BOOL	bTrackButton1;
	POINTL		ptlMouse;
	static HWND	hwndPop;
	
	switch(msg) {
	  case WM_CREATE:
		hwndPop = WinLoadMenu(hwnd, 0, POPUPMENU);
		break;

	  case WM_DESTROY:
		WinDestroyWindow(hwndPop);
		break;

	  case WM_PAINT: {
	  	RECTL	rclPaint;
	  	HPS		hpsPaint = WinBeginPaint(hwnd, hpsClient, &rclPaint);
		BOOL	fC;
	  	
		WinQueryWindowRect(hwnd, &rclPaint);
/* If the scroll bar is visible, adjust the border rectangle */
		if (fScrollVisible)
			rclPaint.xRight -= WinQuerySysValue(HWND_DESKTOP, SV_CXVSCROLL);

/* Clear the area. We have to swap coords from OS/2 to Mac (see os2emux.c) */
		XClearArea(hpsPaint, rclPaint.xLeft, lClientHeight - rclPaint.yTop,
			rclPaint.xRight - rclPaint.xLeft, rclPaint.yTop - rclPaint.yBottom);
		WinDrawBorder(hpsPaint, &rclPaint,
			1L, 1L,		/* Thickness */
			CLR_BLACK, 0, 0);
/* Only redraw the text if the program thread is running */
		if (fThreadRunning)
			xtext_redraw(hpsPaint);
		WinEndPaint(hpsPaint);
		break;
	  }
		
	  case WM_COMMAND:
	  	switch (SHORT1FROMMP(mp1)) {
	  	  case CMD_STARTTADS:
			if (DosCreateThread(&tidMachine, &os_main_shell, 0,
				CREATE_READY | STACK_COMMITTED, 0x100000) != 0)
				DisplayError("Unable to create TADS thread");
			else {
				extern stream keyboard_stream;	// From os2kbd.c
				clear_stream(&keyboard_stream);
			}
			break;
			
		  case CMD_SHOWERROR: {
			PCHAR	c;
			
			c = (PCHAR)PVOIDFROMMP(mp2);
			DisplayError(c);
			break;
		  }
		  
	  	  default:
			HandleMenuCommand(hwnd, SHORT1FROMMP(mp1));
		}
		break;

	  case WM_CONTEXTMENU:
		WinQueryPointerPos(HWND_DESKTOP, &ptlMouse);
		WinPopupMenu(HWND_DESKTOP, hwnd, hwndPop, ptlMouse.x, ptlMouse.y,
			0, PU_HCONSTRAIN | PU_VCONSTRAIN | PU_MOUSEBUTTON1 |
			PU_MOUSEBUTTON2 | PU_KEYBOARD);
		break;

/* Adjust the size & position of the scroll bar and the text window */
	  case WM_SIZE: {
	  	LONG	lScrollWidth = WinQuerySysValue(HWND_DESKTOP, SV_CXVSCROLL);

		if (fMinimized)
			break;
	  	WinSetWindowPos(hwndVertScroll, 0,
	  		SHORT1FROMMP(mp2) - lScrollWidth, 0,	/* new (x, y) pos */
	  		lScrollWidth, SHORT2FROMMP(mp2),		/* new (width, height) */
	  		SWP_SIZE | SWP_MOVE);
	  	clientRect.xLeft = clientRect.yBottom = 0;
	  	clientRect.xRight = SHORT1FROMMP(mp2);
	  	clientRect.yTop = lClientHeight = SHORT2FROMMP(mp2);
	  	xtext_resize(0, 0, clientRect.xRight - clientRect.xLeft,
	  		lClientHeight);
	  	if (fScrollVisible)
	  		clientRect.xRight -= lScrollWidth;
	  	break;
	  }
	  
/* Create & destroy the cursor when we gain & lose the focus */
	  case WM_SETFOCUS:
		if (SHORT1FROMMP(mp2)) {
			/* We're getting the focus */
			mainwin_activate(TRUE);
			if (fThreadRunning)
				mainwin_caret_changed(TRUE);
			else mainwin_caret_changed(FALSE);
			TweakMenus();
		}
		else {
			/* Lose the focus */
			mainwin_activate(FALSE);
			mainwin_caret_changed(FALSE);
		}
		break;

	  case WM_CHAR: {
		/* N.B. pchrmsg->cRepeat has the repeat code */
		PCHRMSG	pchrmsg = CHARMSG(&msg);
		SHORT	key;

		if (pchrmsg->fs & KC_KEYUP)
			return WinDefWindowProc(hwnd, msg, mp1, mp2);
		if (pchrmsg->fs & KC_VIRTUALKEY &&
			(pchrmsg->vkey != VK_CTRL && pchrmsg->vkey != VK_ALT &&
			pchrmsg->vkey != VK_SHIFT)) {
			if (pchrmsg->vkey == VK_SPACE) {	/* Handle spaces */
				pchrmsg->chr = ' ';
				pchrmsg->fs = (KC_VIRTUALKEY | KC_CHAR);
			}
			else {
				key = pchrmsg->vkey;
				key |= keytype_virtual;
				if (pchrmsg->fs & KC_CTRL)
					key |= keytype_ctrl;
				if (pchrmsg->fs & KC_SHIFT)
					key |= keytype_shift;
				if (pchrmsg->fs & KC_ALT)
					key |= keytype_alt;
				stuff_kbd_stream(key);
				break;
			}
		}
		if (pchrmsg->fs & KC_CHAR) {
			stuff_kbd_stream(pchrmsg->chr);
			break;
		}
		return WinDefWindowProc(hwnd, msg, mp1, mp2);
	  }

	  case WM_BUTTON1CLICK:
	  	if (fThreadRunning)
			xtext_hitdown(SHORT1FROMMP(mp1), lClientHeight - SHORT2FROMMP(mp1),
				1, 0, 1);
		TweakMenus();
		break;
		
	  case WM_BUTTON1DBLCLK:
	  	if (fThreadRunning)
			xtext_hitdown(SHORT1FROMMP(mp1), lClientHeight - SHORT2FROMMP(mp1),
				1, 0, 2);
		TweakMenus();
		break;
		
	  case WM_BUTTON1MOTIONSTART:
		if (fThreadRunning) {
			bTrackButton1 = TRUE;	/* Keep track of the mouse for us in WM_MOUSEMOVE */
			xtext_hitdown(SHORT1FROMMP(mp1), lClientHeight - SHORT2FROMMP(mp1),
				1, 0, 1);
		}
		break;
		
	  case WM_BUTTON1MOTIONEND:
		if (fThreadRunning) {
			bTrackButton1 = FALSE;
			xtext_hitup(SHORT1FROMMP(mp1), lClientHeight - SHORT2FROMMP(mp1),
				1, 0, 1);
		}
		TweakMenus();
		break;
		
/* When the pointer's in the client window, draw a text bar. Also, if
bTrackButton# is true, send messages to xtext_hitmove. */
	  case WM_MOUSEMOVE:
		if (fWaitCursor)
			WinSetPointer(HWND_DESKTOP, hptrWait);
		else WinSetPointer(HWND_DESKTOP, hptrText);
		if (bTrackButton1) {
			xtext_hitmove(SHORT1FROMMP(mp1), lClientHeight - SHORT2FROMMP(mp1),
				1, 0, 1);
		}
		return ((MRESULT) TRUE);

/* Handle the scroll bar */
	  case WM_VSCROLL:
		switch (SHORT2FROMMP(mp2)) {
		  case SB_LINEUP:
		  case SB_LINEDOWN:
		  case SB_PAGEUP:
		  case SB_PAGEDOWN:
			scroll_splat(SHORT2FROMMP(mp2));
			break;
			
		  case SB_SLIDERPOSITION:
			scroll_to(SHORT1FROMMP(mp2));
			break;
		}
		return ((MRESULT) TRUE);
		
	  case WM_TIMER:
		switch (SHORT1FROMMP(mp1)) {
		  case ID_MBTIMER: {
			extern BOOL bClearMB;	// Defined in os2ctls.c
			if (bClearMB)
				SetMessageBoxText(NULL, TRUE);
			WinStopTimer(hab, hwnd, ID_MBTIMER);
			break;
		  }
		  case ID_CURSORTIMER:
			if (fCursorOn)
				XBlinkDot(hpsClient);
			break;
		  default:
			return WinDefWindowProc(hwnd, msg, mp1, mp2);
		}
		break;
		
	  case WM_PRESPARAMCHANGED: {
	  	ULONG	lAttrFound, i;
	  	CHAR	szFontName[FACESIZE], szFontSize[FACESIZE];
	  	RGB	rgb;
	  	
	  	switch (LONGFROMMP(mp1)) {
	  	  case PP_FONTNAMESIZE:
	  		WinQueryPresParam(hwnd, PP_FONTNAMESIZE, 0L,
	  			&lAttrFound, sizeof(szFontName), szFontName,
	  			0L);
	  		if (lAttrFound != PP_FONTNAMESIZE) {
	  			DisplayInformation("Unable to change font");
	  			return WinDefWindowProc(hwnd, msg, mp1, mp2);
	  		}
	  		StripFontName(szFontName);
	  		for (i = 0; szFontName[i] != '.'; i++)
	  			szFontSize[i] = szFontName[i];
	  		szFontSize[i] = 0;
	  		strcpy(szFontName, szFontName + i + 1);
	  		strcpy(prefsTADS.fattrs.szFacename, szFontName);
	  		prefsTADS.fattrs.idRegistry = 0;
	  		prefsTADS.fattrs.usCodePage = 850;
			prefsTADS.fattrs.fsSelection = 0;
			prefsTADS.fattrs.fsFontUse = FATTR_FONTUSE_NOMIX;
			prefsTADS.fattrs.lMaxBaselineExt = atol(szFontSize);
			prefsTADS.fattrs.lAveCharWidth =
				prefsTADS.fattrs.lMaxBaselineExt;
	  		prefsTADS.fattrs.lMatch = 0;
	  		UpdateFonts(hpsClient, TRUE);
	  		break;

		  case PP_BACKGROUNDCOLOR:
			WinQueryPresParam(hwnd, PP_BACKGROUNDCOLOR, 0L,
				&lAttrFound, sizeof(RGB), &rgb, 0L);
			if (lAttrFound != PP_BACKGROUNDCOLOR) {
				DisplayInformation("Unable to change color");
				return WinDefWindowProc(hwnd, msg, mp1, mp2);
			}
			i = WinMessageBox(HWND_DESKTOP, hwnd,
"Do you want to apply the color to the foreground instead of the background?",
				"TADS/2 Message", 0L,
				MB_YESNOCANCEL | MB_QUERY);
			if (i == MBID_CANCEL)
				break;
			if (i == MBID_YES) {
				WinSetPresParam(hwndStatus, PP_FOREGROUNDCOLOR,
					sizeof(RGB), &rgb);
				prefsTADS.ulFore = (rgb.bRed * 65536) +
					(rgb.bGreen * 256) + rgb.bBlue;
				XSetForeColor(prefsTADS.ulFore);
			}
			else {
				WinSetPresParam(hwndStatus, PP_BACKGROUNDCOLOR,
					sizeof(RGB), &rgb);
				prefsTADS.ulBack = (rgb.bRed * 65536) +
					(rgb.bGreen * 256) + rgb.bBlue;
				XSetBackColor(prefsTADS.ulBack);
			}
			WinInvalidateRegion(hwndClient, NULLHANDLE, FALSE);
			WinInvalidateRegion(hwndStatus, NULLHANDLE, FALSE);
			break;

	  	  default:
	  	    return WinDefWindowProc(hwnd, msg, mp1, mp2);
	  	} }
		break;

	  case WM_MINMAXFRAME: {
		PSWP	pswp;
		
		pswp = PVOIDFROMMP(mp1);
		if (pswp->fl & SWP_MINIMIZE)
			fMinimized = TRUE;
		else fMinimized = FALSE;
		return ((MRESULT)FALSE);
	  }

	  default:
		return WinDefWindowProc(hwnd, msg, mp1, mp2);
	}
	return MRFROMSHORT(FALSE);
}

/*
** HandleMenuCommand, given the menu item ID from TadsMainWndProc, performs
** whatever is necessary for the menu item.
*/
VOID HandleMenuCommand(HWND hwnd, USHORT menuItemID)
{
	CHAR		message[CCHMAXPATH];
	static FINDDATA	fd = { "", FALSE, FALSE };
	TID		tid;
	HOBJECT		hobj;

	switch (menuItemID) {
	  case IDM_LOAD:
		if (QueryFile(zcodename, CCHMAXPATH, 3)) {
			if (hwnd != hwndClient) DisplayError("Wrong hwnd!");
			strcpy(sShare.szData, zcodename);
			WinPostMsg(hwndClient, WM_COMMAND,
				MPFROMSHORT(CMD_STARTTADS), MPVOID);
		}
		break;

	  case IDM_SAVE:
		stuff_kbd_stream(VK_ESC | keytype_virtual);
		stuff_kbd_stream_with_string("save\n");
		break;

	  case IDM_RESTORE:
		stuff_kbd_stream(VK_ESC | keytype_virtual);
		stuff_kbd_stream_with_string("restore\n");
		break;
		
	  case IDM_BIND:
	  	if (QueryFile(sShare.szOutput, CCHMAXPATH, 4)) {
			if (DosCreateThread(&tid, &BindCode, hwnd, 0,
				8192) != 0)
				DisplayError("Unable to create BindCode thread");
	  	}
	  	break;

	  case IDM_UNBIND:
	  	if (QueryFile(sShare.szOutput, CCHMAXPATH, 5)) {
			if (DosCreateThread(&tid, &UnbindCode, hwnd, 0,
				8192) != 0)
				DisplayError("Unable to create BindCode thread");
	  	}
	  	break;

	  case IDM_RG1:
	  case IDM_RG2:
	  case IDM_RG3:
	  case IDM_RG4:
	  case IDM_RG5:
	  case IDM_RG6:
	  case IDM_RG7:
	  case IDM_RG8:
	  case IDM_RG9:
	  case IDM_RG10:
		if (fThreadRunning) return;
		strcpy(zcodename, prefsTADS.szRecentGames[menuItemID - IDM_RG1]);
		strcpy(sShare.szData, zcodename);
		AddRecent(zcodename);
		WinPostMsg(hwnd, WM_COMMAND, MPFROMSHORT(CMD_STARTTADS),
			MPVOID);
		break;

	  case IDM_QUIT:
	  	if (fThreadRunning) {
		stuff_kbd_stream(VK_ESC | keytype_virtual);
	  		stuff_kbd_stream_with_string("quit\n");
	  	}
		else WinPostMsg(hwnd, WM_CLOSE, MPVOID, MPVOID);
		break;
		
	  case IDM_UNDO:
		stuff_kbd_stream(VK_ESC | keytype_virtual);
		stuff_kbd_stream_with_string("undo\n");
		break;
		
	  case IDM_CUT:
	  	xted_cutbuf(op_Wipe);
		break;
		
	  case IDM_COPY:
		xted_cutbuf(op_Copy);
		break;
		
	  case IDM_PASTE:
	  	{
	  		static PSZ	pszLocal = NULL;

			pszLocal = copy_clip_to_string();
	  		if (pszLocal) {
	  			stuff_kbd_stream_with_string(pszLocal);
	  			free(pszLocal);
	  			pszLocal = NULL;
	  		}
		}
		break;
		
	  case IDM_FIND:
		WinDlgBox(HWND_DESKTOP, hwnd, (PFNWP)FindDialogProc, 0, DLG_FIND,
			&fd);
		if (fd.findText[0] != 0) {
			if (!xtext_find(!fd.fBack, fd.fCase, fd.findText)) {
				sprintf(message, "\"%s\" not found", fd.findText);
				//WinAlarm(HWND_DESKTOP, WA_ERROR);
				DisplayError(message);
			}
		}
		break;
		
	  case IDM_FINDAGAIN:
	  	if (fd.findText[0] == 0)
	  		DisplayError("No previous find was executed");
	  	else if (!xtext_find(!fd.fBack, fd.fCase, fd.findText)) {
	  		sprintf(message, "\"%s\" not found", fd.findText);
	  		DisplayError(message);
	  	}
		break;
		
	  case IDM_STORY_WINDOW:
		WinDlgBox(HWND_DESKTOP, hwnd, (PFNWP)StoryWindowDialogProc, 0,
			DLG_STORYWINDOW, NULL);
		break;

	  case IDM_INTERPRETER:
		WinDlgBox(HWND_DESKTOP, hwnd, (PFNWP)InterpreterDialogProc, 0,
			DLG_INTERPRETER, NULL);
		break;

	  case IDM_PROGRAM:
		WinDlgBox(HWND_DESKTOP, hwnd, (PFNWP)OptionsDialogProc, 0,
			DLG_OPTIONS, NULL);
		break;

	  case IDM_SET_MAIN_FONT:
		GetFont();
		break;
	
	  case IDM_SET_STATUS_FONT:
		hobj = WinQueryObject("<WP_FNTPAL>");
		if (hobj != NULLHANDLE)
			if (WinSetObjectData(hobj, "OPEN=DEFAULT"))
				break;
		DisplayError("Unable to open font palette");
		break;
		
	  case IDM_SET_COLORS:
		hobj = WinQueryObject("<WP_HIRESCLRPAL>");
		if (hobj != NULLHANDLE)
			if (WinSetObjectData(hobj, "OPEN=DEFAULT"))
				break;
		hobj = WinQueryObject("<WP_LORESCLRPAL>");
		if (hobj != NULLHANDLE)
			if (WinSetObjectData(hobj, "OPEN=DEFAULT"))
				break;
		DisplayError("Unable to open color palettes");
		break;
		
	  case IDM_SEPARATED_STATUS:
		SwapStatus();
		break;
		
	  case IDM_DEFINE_MACRO:
	  	if (xtexted_getmodifymode(FALSE) != op_DefineMacro)
	  		xtexted_meta(op_DefineMacro);
		else xtexted_meta(op_Cancel);
		break;
		
	  case IDM_MACRO1:
	  case IDM_MACRO2:
	  case IDM_MACRO3:
	  case IDM_MACRO4:
	  case IDM_MACRO5:
	  case IDM_MACRO6:
	  case IDM_MACRO7:
	  case IDM_MACRO8:
	  case IDM_MACRO9:
	  case IDM_MACRO10:
	  case IDM_MACRO11:
	  case IDM_MACRO12:
		stuff_kbd_stream(cmdkeylist[menuItemID - IDM_MACRO1] | keytype_virtual);
		break;
		
	  case IDM_ABOUT:
		WinDlgBox(HWND_DESKTOP, hwnd, (PFNWP)AboutDialogProc, 0,
			DLG_ABOUT, NULL);
		break;
	}
}

/*
** StripFontName takes care of removing any "Bold" or "Italic" from a font
** family name.
*/
VOID StripFontName(PSZ pszFamily)
{
	PCHAR	p, q;
	
	/* Strip off "... Bold" or "... Italic" if appended to the font name */
	p = strstr(pszFamily, "Bold");
	if (p != NULL) {
		if (*(p-1) == ' ')
			strcpy(p-1, p+4);
		else strcpy(p, p + 4);
	}
	q = strstr(pszFamily, "Italic");
	if (q != NULL) {
		if (*(q-1) == ' ')
			strcpy(q-1, q+6);
		strcpy(q, q + 6);
	}
}

/*
** GetFont prepares and creates a font dialog for the user to select a font.
*/
VOID GetFont(VOID)
{
	FONTDLG		fontdlg;
	FONTMETRICS	fm;
	CHAR		szFamily[CCHMAXPATH], *p, *q;
	static CHAR	szTitle[] = "TADS/2 Fonts";
	static CHAR szPreview[] = "You are standing in an open field west of \
a white house...";
	HWND		hwndDlg;

	XSetFont(hpsClient, lcidNorm);
	GpiQueryFontMetrics(hpsClient, sizeof(FONTMETRICS), &fm);
	
	memset((void *)&fontdlg, 0, sizeof(FONTDLG));
	fontdlg.cbSize = sizeof(FONTDLG);
	fontdlg.hpsScreen = WinGetScreenPS(HWND_DESKTOP);
	fontdlg.hpsPrinter = NULLHANDLE;
	fontdlg.pfnDlgProc = NULL;
	fontdlg.pszTitle = szTitle;
	fontdlg.pszPreview = szPreview;
	strcpy(szFamily, fm.szFamilyname);
	fontdlg.pszFamilyname = szFamily;
	fontdlg.usFamilyBufLen = sizeof(szFamily);
	fontdlg.fxPointSize = MAKEFIXED(fm.sNominalPointSize/10, 0);
	fontdlg.fl = FNTS_CENTER | FNTS_HELPBUTTON |
		FNTS_INITFROMFATTRS |
		FNTS_NOSYNTHESIZEDFONTS |
		FNTS_RESETBUTTON;
	fontdlg.sNominalPointSize = fm.sNominalPointSize;
	fontdlg.flType = (LONG) fm.fsType;
	fontdlg.clrFore = CLR_NEUTRAL;
	fontdlg.clrBack = CLR_BACKGROUND;
	fontdlg.usWeight = fm.usWeightClass;
	fontdlg.usWidth = fm.usWidthClass;
	
	hwndDlg = WinFontDlg(HWND_DESKTOP, hwndClient, &fontdlg);

	if (hwndDlg != TRUE) {
		DisplayError("Font window error");
		return;
	}
	
	if (fontdlg.lReturn == DID_CANCEL)
		return;

	fontdlg.fAttrs.usCodePage = 850;
	fontdlg.fAttrs.fsType = 0;
	fontdlg.fAttrs.fsFontUse = FATTR_FONTUSE_NOMIX;
	fontdlg.fAttrs.fsSelection = 0;
	memcpy(&prefsTADS.fattrs, &fontdlg.fAttrs, sizeof(FATTRS));

	/* Strip off "... Bold" or "... Italic" if appended to the font name */
	strcpy(szFamily, prefsTADS.fattrs.szFacename);
	StripFontName(szFamily);
	strcpy(prefsTADS.fattrs.szFacename, szFamily);
	
	UpdateFonts(hpsClient, TRUE);
}


/*
** QueryFile asks the user for a file. iOpen = 0 for save game, 1 for restore
** game, 2 for write script, 3 for load .gam file, 4 for bind game, 5 for
** unbind game. The function returns TRUE if everything went ok, FALSE
** otherwise.
*/
BOOL QueryFile(CHAR *buf, SHORT bufsize, SHORT iOpen)
{
	FILEDLG		filedlg;
	CHAR		szTitle[50];
	PCHAR		szDefPath, p;
	static CHAR	szOpenOK[] = "Open",
				szSaveOK[] = "Save",
				szWriteOK[] = "Write",
				szBindOK[] = "Bind",
				szUnbindOK[] = "Unbind",
				szLastSave[CCHMAXPATH] = "",
				szLastWrite[CCHMAXPATH] = "",
				szLastRestore[CCHMAXPATH] = "";
	HWND		hwndDlg;

	memset((void *)&filedlg, 0, sizeof(FILEDLG));
	filedlg.cbSize = sizeof(FILEDLG);
	if (iOpen == 1) {
		WinLoadString(hab, NULLHANDLE, strix_RestoreGame, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_OPEN_DIALOG;
		filedlg.pszOKButton = szOpenOK;
		if (szLastRestore[0] == 0) {
			if (prefsTADS.szSavePath[0] != 0 &&
				prefsTADS.fStickyPaths) {
				strcpy(szLastRestore, prefsTADS.szSavePath);
			}
			else {
				szDefPath = getenv("TADSSAVE");
				if (szDefPath != NULL) {
					strcpy(szLastRestore, szDefPath);
					if (szLastRestore[strlen(szDefPath)-1] != '\\')
						strcat(szLastRestore, "\\");
				}
			}
		}
		strcpy(filedlg.szFullFile, szLastRestore);
		strcat(filedlg.szFullFile, "*.sav");
	} else if (iOpen == 0) {
		WinLoadString(hab, NULLHANDLE, strix_SaveGameAs, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_SAVEAS_DIALOG | FDS_ENABLEFILELB;
		filedlg.pszOKButton = szSaveOK;
		if (szLastSave[0] == 0) {
			if (prefsTADS.szSavePath[0] != 0 &&
				prefsTADS.fStickyPaths) {
				strcpy(szLastSave, prefsTADS.szSavePath);
				strcat(szLastSave, "*.sav");
			}
			else {
				szDefPath = getenv("TADSSAVE");
				if (szDefPath != NULL) {
					strcpy(szLastSave, szDefPath);
					if (szLastSave[strlen(szDefPath)-1] != '\\')
						strcat(szLastSave, "\\");
				}
			}
		}
		strcpy(filedlg.szFullFile, szLastSave);
	} else if (iOpen == 3) {
		WinLoadString(hab, NULLHANDLE, strix_OpenGame, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_OPEN_DIALOG;
		filedlg.pszOKButton = szOpenOK;
		if (prefsTADS.szGamePath[0] != 0 && prefsTADS.fStickyPaths) {
			strcpy(filedlg.szFullFile, prefsTADS.szGamePath);
			strcat(filedlg.szFullFile, "*.gam");
		}
		else {
			szDefPath = getenv("TADSGAME");
			if (szDefPath == NULL)
				filedlg.szFullFile[0] = 0;
			else {
				strcpy(filedlg.szFullFile, szDefPath);
				if (filedlg.szFullFile[strlen(szDefPath)-1] != '\\')
					strcat(filedlg.szFullFile, "\\");
			}
			strcat(filedlg.szFullFile, "*.gam");
		}
	} else if (iOpen == 2) {
		WinLoadString(hab, NULLHANDLE, strix_WriteScript, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_SAVEAS_DIALOG;
		filedlg.pszOKButton = szWriteOK;
		strcpy(filedlg.szFullFile, szLastWrite);
	} else if (iOpen == 4) {
		WinLoadString(hab, NULLHANDLE, strix_BindGame, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_SAVEAS_DIALOG;
		filedlg.pszOKButton = szBindOK;
	} else if (iOpen == 5) {
		WinLoadString(hab, NULLHANDLE, strix_UnbindGame, sizeof(szTitle),
			szTitle);
		filedlg.fl = FDS_SAVEAS_DIALOG;
		filedlg.pszOKButton = szUnbindOK;
	}
	filedlg.pszTitle = szTitle;
	filedlg.fl |= FDS_CENTER;
	
	hwndDlg = WinFileDlg(HWND_DESKTOP, hwndClient, &filedlg);
	
	if (hwndDlg != TRUE) {
		DisplayError("File window error");
		return FALSE;
	}
	
	if (filedlg.lReturn == DID_CANCEL)
		return FALSE;
	if (strlen(filedlg.szFullFile) >= bufsize) {
		strncpy(buf, filedlg.szFullFile, bufsize-1);
		buf[bufsize-1] = NULL;
	}
	else strcpy(buf, filedlg.szFullFile);

	if (iOpen == 0) {
		strcpy(szLastSave, filedlg.szFullFile);
		strcpy(prefsTADS.szSavePath, filedlg.szFullFile);
		p = prefsTADS.szSavePath + strlen(prefsTADS.szSavePath) - 2;
		while (p != prefsTADS.szSavePath && *p != '\\')
			p--;
		if (*p == '\\')
			*(p+1) = 0;
	}
	else if (iOpen == 1) {
		strcpy(szLastRestore, filedlg.szFullFile);
		p = szLastRestore + strlen(szLastRestore) - 2;
		while (p != szLastRestore && *p != '\\')
			p--;
		if (*p == '\\')
			*(p+1) = 0;
		strcpy(prefsTADS.szSavePath, szLastRestore);
	}
	else if (iOpen == 3) {
		strcpy(prefsTADS.szGamePath, filedlg.szFullFile);
		AddRecent(filedlg.szFullFile);
		p = prefsTADS.szGamePath + strlen(prefsTADS.szGamePath) - 2;
		while (p != prefsTADS.szGamePath && *p != '\\')
			p--;
		if (*p == '\\')
			*(p+1) = 0;
	}
	
	return TRUE;
}

VOID DisplayMessage(PSZ pszString)
{
	WinMessageBox(HWND_DESKTOP, hwndClient, pszString, "TADS/2 Message", 0,
		MB_OK);
}

VOID DisplayInformation(PSZ pszString)
{
	WinAlarm(HWND_DESKTOP, WA_WARNING);
	WinMessageBox(HWND_DESKTOP, hwndClient, pszString, "TADS/2 Information",
		0, MB_INFORMATION | MB_OK);
}

VOID DisplayError(PSZ pszString)
{
	WinAlarm(HWND_DESKTOP, WA_ERROR);
	WinMessageBox(HWND_DESKTOP, hwndClient, pszString, "TADS/2 Error", 0,
		MB_ERROR | MB_OK);
}
