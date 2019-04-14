/*
** os2ctls.c -- Contains all the functions which handle the TADS/2 window
**              controls and dialogs.
*/

#define INCL_PM
#include "tadsos2.h"
#include <os2.h>
#include "os2io.h"
#include "global.h"

#define STATUS_EXTRA_HEIGHT	6
#define MB_TIMEOUT 3		/* Timeout of message in seconds */

MRESULT EXPENTRY MessageBoxWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
MRESULT EXPENTRY StatusFrameWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
MRESULT EXPENTRY StatusWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2);
extern SHORT UpdateInputFont(HPS hps, BOOL fBold);
static void appendmacro(char *buf, char *src);

MENUITEM	miMacros[15],		/* For holding the macro menu items */
		miRecent[10];		/* For holding recent games items */
static SHORT	fLastMacroMode = -1;/* Stores TRUE or FALSE, depending on whether
								   the menu is set up for macro-use (FALSE) or
								   macro-define (TRUE). Reset to -1 if the macro
								   set changes. */
BOOL		bClearMB = FALSE;	// Should we clear the message box?
SHORT cmdkeylist[12] = {
	VK_F1, VK_F2, VK_F3, VK_F4, VK_F5, VK_F6, VK_F7, VK_F8, VK_F9, VK_F10,
	VK_F11, VK_F12
};

static BOOL fPendingClear;	// Are we about to clear the status line?

/*
** Menu functions-------------------------------------------------------------
*/

/* A function to insert a menu item */
VOID InsertMenuItem(HWND hWndMenu, PMENUITEM pmiItem, PSZ pszText)
{
	WinSendMsg(hWndMenu, MM_INSERTITEM, MPFROMP(pmiItem),
		MPFROMP(pszText));
}

/* Another to remove a menu item */
VOID RemoveMenuItem(HWND hWndMenu, SHORT idMenuItem)
{
	WinSendMsg(hWndMenu, MM_REMOVEITEM, MPFROM2SHORT(idMenuItem, TRUE),
		0L);
}

/* And another to change a menu item's text */
VOID SetMenuItemText(HWND hWndMenu, SHORT idMenuItem, PSZ pszText)
{
	WinSendMsg(hWndMenu, MM_SETITEMTEXT, MPFROMSHORT(idMenuItem),
		MPFROMP(pszText));
}

/* Enable/disable cut/copy if the user hasn't made a selection. Also take
   care of the selections which are only available when the program is/isn't
   running */
VOID TweakMenus(VOID)
{
	BOOL	bCanCopy, bCanCut;
	HWND	hwndMenu = WinWindowFromID(hwndFrame, FID_MENU);
	ULONG	i;
	SHORT	fMacroMode;
	
	xted_option_capability(&bCanCut, &bCanCopy);
	WinEnableMenuItem(hwndMenu, IDM_CUT, bCanCut && fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_COPY, bCanCopy && fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_PASTE,
		WinQueryClipbrdFmtInfo(hab, CF_TEXT, &i) && fThreadRunning);
	
	WinEnableMenuItem(hwndMenu, IDM_LOAD, !fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_SAVE, fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_RESTORE, fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_BIND, fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_UNBIND, fThreadRunning);
	for (i = 0; i < 10, prefsTADS.szRecentGames[i][0] != 0; i++)
		WinEnableMenuItem(hwndMenu, IDM_RG1 + i, !fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_UNDO, fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_FIND, fThreadRunning);
	WinEnableMenuItem(hwndMenu, IDM_FINDAGAIN, fThreadRunning);
}

/* Adjust the binding menu */
VOID TweakBindingMenu(VOID)
{
	HWND		hwndMenu = WinWindowFromID(hwndFrame, FID_MENU);
	MENUITEM	mi;

	/* Get the handle of the file submenu */
	WinSendMsg(hwndMenu, MM_QUERYITEM, MPFROM2SHORT(IDM_FILEMENU, TRUE),
		MPFROMP(&mi));
	hwndMenu = mi.hwndSubMenu;
	
	if (validBinding)
		RemoveMenuItem(hwndMenu, IDM_BIND);
	else RemoveMenuItem(hwndMenu, IDM_UNBIND);
}

VOID TweakRecentMenu(VOID)
{
	HWND	hwndMenu = WinWindowFromID(hwndFrame, FID_MENU);
	int		i;
	char	s[1000], *p;
	MENUITEM	mi;
	
	// Get the handle of the file submenu
	WinSendMsg(hwndMenu, MM_QUERYITEM, MPFROM2SHORT(IDM_FILEMENU, TRUE),
		MPFROMP(&mi));
	hwndMenu = mi.hwndSubMenu;

	for (i = IDM_RG1; i <= IDM_RGSEP; i++)
		RemoveMenuItem(hwndMenu, i);

	if (validBinding) return;	// No "recent" menu for bound games
	
	mi.iPosition = 7;
	mi.afStyle = MIS_TEXT;
	mi.afAttribute = 0;
	mi.hwndSubMenu = NULLHANDLE;
	mi.hItem = 0;
	
	for (i = 0; i < 10 && prefsTADS.szRecentGames[i][0] != 0; i++) {
		p = prefsTADS.szRecentGames[i] +
			strlen(prefsTADS.szRecentGames[i]) - 1;
		while (*p != '\\' && p != prefsTADS.szRecentGames[i])
			p--;
		if (i == 9)
			sprintf(s, "1&0. %s", p+1);
		else sprintf(s, "~%i. %s", i+1, p+1);
		mi.id = IDM_RG1 + i;
		InsertMenuItem(hwndMenu, &mi, s);
		mi.iPosition++;
	}
	if (i != 0) {
		mi.afStyle = MIS_SEPARATOR;
		mi.id = IDM_RGSEP;
		InsertMenuItem(hwndMenu, &mi, "");
	}
}

// Add a recently loaded file to the "recent games" menu. Also change the
//  main window title to reflect the new game.
VOID AddRecent(char *new)
{
	int	i, j;
	char	title[500], *p;
	
	p = new + strlen(new) - 1;
	while (*p != '\\' && p != new)
		p--;
	sprintf(title, "TADS/2 (%s)", p+1);
	WinSetWindowText(hwndFrame, title);
	for (i = 0; i < 10 && prefsTADS.szRecentGames[i][0] != 0; i++) {
		if (!stricmp(new, prefsTADS.szRecentGames[i])) {
			for (j = i; j > 0; j--)
				strcpy(prefsTADS.szRecentGames[j],
					prefsTADS.szRecentGames[j-1]);
			strcpy(prefsTADS.szRecentGames[0], new);
			TweakRecentMenu();
			return;
		}
	}
	if (i == 10)
		i--;
	while (i > 0) {
		strcpy(prefsTADS.szRecentGames[i],
			prefsTADS.szRecentGames[i-1]);
		i--;
	}
	strcpy(prefsTADS.szRecentGames[0], new);
	TweakRecentMenu();
}

void macrom_dirty_macrolist()
{
	fLastMacroMode = (-1);
	TweakMacroMenus();
}

/* Fix the macro menu */
VOID TweakMacroMenus(VOID)
{
	int		i, iPos;
	char		str[255], tempstr[255], *pStr;
	BOOL	fItems;
	HWND	hwndMenu = WinWindowFromID(hwndFrame, FID_MENU);
	SHORT	fMacroMode;
	MENUITEM	mi;
	
	/* Get the handle of the macro submenu */
	WinSendMsg(hwndMenu, MM_QUERYITEM, MPFROM2SHORT(IDM_MACROMENU, TRUE),
		MPFROMP(&mi));
	hwndMenu = mi.hwndSubMenu;

	if (xtexted_getmodifymode(FALSE) == op_DefineMacro)
		fMacroMode = TRUE;
	else fMacroMode = FALSE;

	if (fMacroMode == fLastMacroMode) return;
	
	fLastMacroMode = fMacroMode;
	for (i = IDM_DEFINE_MACRO; i <= IDM_MACRO12; i++)
		RemoveMenuItem(hwndMenu, i);

	/* Set starting position of the extra menu items */
	iPos = miMacros[0].iPosition + 2;

	if (fMacroMode) {		/* We're defining a macro */
		strcpy(str, "~Cancel Macro Define\tCtrl+D");
		InsertMenuItem(hwndMenu,
			&miMacros[IDM_DEFINE_MACRO - IDM_DEFINE_MACRO],
			str);
		/* Show every macro */
		for (i = 0; i < 12; i++) {
			// Skip F1/F10 if they're not macros
			if ((i == 0 && !prefsTADS.F1ismacro) ||
				(i == 9 && !prefsTADS.F10ismacro))
				continue;
			pStr = keycmdargs[cmdkeylist[i] | keytype_virtual];
			if (pStr && pStr[0]) {
				strcpy(tempstr, "Replace ");
				appendmacro(tempstr, pStr);
				sprintf(str, "%s\tF%i", tempstr, i+1);
			}
			else sprintf(str, "Define This Macro\tF%i", i+1);
			miMacros[IDM_MACRO1 + i - IDM_DEFINE_MACRO].iPosition =
				iPos++;
			InsertMenuItem(hwndMenu,
				&miMacros[IDM_MACRO1 + i - IDM_DEFINE_MACRO], str);
		}
	} else {
		strcpy(str, "~Define Macro\tCtrl+D");
		InsertMenuItem(hwndMenu,
			&miMacros[IDM_DEFINE_MACRO - IDM_DEFINE_MACRO], str);
		/* Only show the macros which exist */
		fItems = FALSE;
		for (i = 0; i < 12; i++) {
			// Skip F1/F10 if they're not macros
			if ((i == 0 && !prefsTADS.F1ismacro) ||
				(i == 9 && !prefsTADS.F10ismacro))
				continue;
			pStr = keycmdargs[cmdkeylist[i] | keytype_virtual];
			if (pStr && pStr[0]) {
				fItems = TRUE;
				strcpy(tempstr, "Macro ");
				appendmacro(tempstr, pStr);
				sprintf(str, "%s\tF%i", tempstr, i+1);
				miMacros[IDM_MACRO1 + i - IDM_DEFINE_MACRO].iPosition =
					iPos++;
				InsertMenuItem(hwndMenu,
					&miMacros[IDM_MACRO1 + i - IDM_DEFINE_MACRO], str);
			}
		}
		if (!fItems) {
			strcpy(str, "No Macros Defined");
			InsertMenuItem(hwndMenu,
				&miMacros[IDM_NO_MACROS - IDM_DEFINE_MACRO], str);
		}
	}
}

/* Set up the macro menu information for the first time */
VOID SetupMacroMenus(VOID)
{
	int		i;
	HWND	hwndMenu = WinWindowFromID(hwndFrame, FID_MENU);

	/* Save all the original menu information */
	for (i = IDM_DEFINE_MACRO; i <= IDM_MACRO12; i++) {
		WinSendMsg(hwndMenu, MM_QUERYITEM, MPFROM2SHORT(i, TRUE),
			MPFROMP(&miMacros[i - IDM_DEFINE_MACRO]));
	}
	
	/* Disable the "No Macros Defined" menu option */
	miMacros[IDM_NO_MACROS - IDM_DEFINE_MACRO].afAttribute |= MIA_DISABLED;
	
	/* Do the update */
	TweakMacroMenus();
}

/* Stick src onto the end of buf, trimming to 20
	characters, enclosing in quotes, skipping weird chars. */
static void appendmacro(char *buf, char *src)
{
	int ix, jx;
	
	ix = strlen(buf);
	
	buf[ix++] = '"';
	
	for (jx=0; src[jx]; jx++) {
		if (jx == 20) {
			buf[ix++] = '.';
			buf[ix++] = '.';
			buf[ix++] = '.';
			break;
		}
		buf[ix++] = src[jx];
	}
	
	buf[ix++] = '"';
	buf[ix] = 0;
}


/*
** Accelerator functions------------------------------------------------------
*/
/* AdjustAccelerators looks for a certain accelerator and removes it if found */
VOID AdjustAccelerators(SHORT key, SHORT flags)
{
	HAB		hab;
	HACCEL		haccelOld, haccelNew;
	ULONG		sizeBuf;
	PACCELTABLE	pacct;
	int		i;
 
	/*
	 * Copy the current accelerator table
	 */
	haccelOld = WinQueryAccelTable(hab, NULLHANDLE);
	sizeBuf = WinCopyAccelTable(haccelOld, NULL, 0);
	pacct = (PACCELTABLE)malloc(sizeBuf);
	WinCopyAccelTable(haccelOld, pacct, sizeBuf);
 
	/*
	 * Search through the accelerator table.  Remove any entries
	 * that have the proper option.
	 */
	for (i = (pacct->cAccel - 1); i>=0; i--) {
		if (pacct->aaccel[i].key == key &&
			(pacct->aaccel[i].fs & flags) != 0) {
		/*
		 * Copy the last entry over this one.  Unless this is
		 * the last entry, of course.  Then decrement the
		 * count of entries.  This effectively removes it from
		 * the list.
		 */
			if (i != (pacct->cAccel-1)) {
				pacct->aaccel[i].fs  = pacct->aaccel[pacct->cAccel-1].fs;
				pacct->aaccel[i].key = pacct->aaccel[pacct->cAccel-1].key;
				pacct->aaccel[i].cmd = pacct->aaccel[pacct->cAccel-1].cmd;
			}
			pacct->cAccel--;
		}
	}
 
	/*
	 * Make a new HACCEL from the old accelerator table and
	 * replace the one our app is using with it.  Then clean up.
	 */
	haccelNew = WinCreateAccelTable(hab, pacct);
	WinSetAccelTable(hab, haccelNew, NULLHANDLE);
	WinDestroyAccelTable(haccelOld);
	free(pacct);
}


/*
** Message box functions------------------------------------------------------
*/

/* This function sets the text of the message box.  It prepends two spaces to the
   text for aesthetic purposes. If bTimeout is true, the message will vanish
   after MB_TIMEOUT seconds. */
VOID SetMessageBoxText(PSZ pszNewText, BOOL bTimeout)
{
	char		pszBuf[256];

	if (pszNewText)
		sprintf(pszBuf, "  %s", pszNewText);
	else pszBuf[0] = 0;
	WinSetWindowText(hwndMessageBox, pszBuf);
	if (bTimeout) {
		WinStartTimer(hab, hwndClient, ID_MBTIMER, MB_TIMEOUT * 1000);
		bClearMB = TRUE;
	}
	else bClearMB = FALSE;
}

/* Create the message box. hwndParent is the handle to the window which should
   be the message box's parent. */
VOID CreateMessageBox(HWND hwndParent)
{
	HPS			hpsMsgBoxPS;
	FONTMETRICS	fmOldFont;
	ULONG		ulColor;
	SWP			swpClientSizeNPos;

	/* Get the size of the client window for sizing the message box */
	WinQueryWindowPos(hwndClient, &swpClientSizeNPos);

	/* Create the message box */
	hwndMessageBox = WinCreateWindow(
		hwndParent,				/* Child of hwndParent */
		WC_STATIC,				/* We're a static window */
		NULL,					/* Window text to be filled in by SetMBText() */
		WS_VISIBLE		|		/* Visible window */
		SS_TEXT			|		/* Static text ctrl */
		DT_VCENTER,				/* Vertically center text */
		0, 0,					/* (x, y) position w/in parent */
		1,						/* Width (temporary) */
		1,						/* Height (temporary) */
		NULLHANDLE,				/* Owner window */
		HWND_TOP,				/* Put it on top of z-order */
		ID_MESSAGEBOX,			/* Window identifier */
		NULL, NULL);			/* Ctrl data, presentation parameters */

	/* Set the text of the message box */
	SetMessageBoxText("Welcome to TADS/2", TRUE);

	/* Set the foreground/bkgnd colors of the message box & its font */
	ulColor = CLR_PALEGRAY;
	WinSetPresParam(hwndMessageBox, PP_BACKGROUNDCOLORINDEX, sizeof(ulColor),
		&ulColor);
	ulColor = CLR_BLACK;
	WinSetPresParam(hwndMessageBox, PP_FOREGROUNDCOLORINDEX, sizeof(ulColor),
		&ulColor);
	WinSetPresParam(hwndMessageBox, PP_FONTNAMESIZE, sizeof("8.Helv")+1,
		"8.Helv");

	/* Set the size of the message box window */
	hpsMsgBoxPS = WinGetPS(hwndMessageBox);
	GpiQueryFontMetrics(hpsMsgBoxPS, sizeof(FONTMETRICS), &fmOldFont);
	lMessageBoxWidth = swpClientSizeNPos.cx;
	lMessageBoxHeight = fmOldFont.lEmHeight + 10;
	WinSetWindowPos(hwndMessageBox, 0, 0, 0, lMessageBoxWidth,
		lMessageBoxHeight, SWP_SIZE);
	WinReleasePS(hpsMsgBoxPS);
	
	/* Subclass the message box control */
	DefMBWndProc = WinSubclassWindow(hwndMessageBox, (PFNWP)MessageBoxWndProc);
}

/*
** MessageBoxWndProc processes the message box's WM_PAINT message to put a
** border around the thing.
*/
MRESULT EXPENTRY MessageBoxWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	switch (msg) {
	  case WM_PAINT: {
			/* Do the default drawing behavior */
			BOOL rc = (BOOL)DefMBWndProc( hwnd, msg, mp1, mp2 );

			/* Get presentation space handle for drawing */
			HPS hps = WinGetPS( hwnd );

			/* Set up the border rectangle */
			RECTL rclMB;

			WinQueryWindowRect(hwnd, &rclMB);

			/* Adjust the rectangle (the border is in by two pels) */
			rclMB.xLeft += 2;
			rclMB.yBottom += 2;
			rclMB.xRight -= 2;
			rclMB.yTop -= 2;

			/* Draw the border */
			WinDrawBorder(hps, &rclMB,
				1L, 1L,		/* Thickness */
				SYSCLR_BUTTONDARK, SYSCLR_BUTTONLIGHT, DB_DEPRESSED);

			/* Get rid of the presentation space */
			WinReleasePS(hps);

			return( (MRESULT)TRUE );
		}

	  default:
		return( DefMBWndProc(hwnd, msg, mp1, mp2) );
	}
}


/*
** Status window functions----------------------------------------------------
*/

/* SetStatusTextLeft changes the text which is printed on the left side of
   the status bar */
VOID SetStatusTextLeft(PSZ pszNewText)
{
	if (pszNewText)
		strcpy(szStatusLeft, pszNewText);
	else szStatusLeft[0] = 0;
	
	WinInvalidateRegion(hwndStatus, NULLHANDLE, FALSE);
}

/* StatusInsertLeft inserts a character at the left side of the status bar */
VOID StatusInsertLeft(char c)
{
	int i;
	
	/* CR or LF means clear the status bar next time */
	if (c == '\n' || c == '\r') {
		fPendingClear = TRUE;
		return;
	}

	if (fPendingClear) {
		fPendingClear = FALSE;
		i = 0;
	}
	else i = strlen(szStatusLeft);
	szStatusLeft[i] = c;
	szStatusLeft[i+1] = (char)NULL;
	
	WinInvalidateRegion(hwndStatus, NULLHANDLE, FALSE);
}

/* SetStatusTextRight changes the text which is printed on the right side of
   the status bar */
VOID SetStatusTextRight(PSZ pszNewText)
{
	if (pszNewText)
		strcpy(szStatusRight, pszNewText);
	else szStatusRight[0] = 0;
	
	WinInvalidateRegion(hwndStatus, NULLHANDLE, FALSE);
}

/* ClearStatus clears out the status */
VOID ClearStatus(VOID)
{
	SetStatusTextLeft(NULL);
	SetStatusTextRight(NULL);
}

/* SetSeparateStatusFont sets up the status bar's font and adjusts its
   size */
static VOID SetSeparateStatusFont(VOID)
{
	HPS	hpsStatusPS;
	FONTMETRICS	fmOldFont;
	SWP			swpClientSizeNPos;
	
	/* Get the size of the client window for sizing the status bar */
	WinQueryWindowPos(hwndClient, &swpClientSizeNPos);

	/* Set the size of the status bar */
	hpsStatusPS = WinGetPS(hwndStatus);
	GpiQueryFontMetrics(hpsStatusPS, sizeof(FONTMETRICS), &fmOldFont);
	lStatusHeight = fmOldFont.lEmHeight + STATUS_EXTRA_HEIGHT;
	WinReleasePS(hpsStatusPS);

	/* Get the size & position of the frame window */
	WinQueryWindowPos(hwndFrame, &swpClientSizeNPos);

	/* Adjust the size & location of the window surrounding the status bar */
	WinSetWindowPos(hwndStatusFrame, HWND_TOP, 0L, 0L,
		lStatusWidth + WinQuerySysValue(HWND_DESKTOP, SV_CXSIZEBORDER) * 2,
		lStatusHeight + WinQuerySysValue(HWND_DESKTOP, SV_CYTITLEBAR) +
		WinQuerySysValue(HWND_DESKTOP, SV_CYSIZEBORDER) * 2,
		SWP_ZORDER | SWP_SIZE | SWP_SHOW | SWP_ACTIVATE);

	WinSendMsg(hwndFrame, WM_UPDATEFRAME, (MPARAM)~0, NULL);
	WinSendMsg(hwndStatusFrame, WM_UPDATEFRAME, (MPARAM)~0, NULL);
}

/* CreateSeparateStatus creates a status bar which is contained in its own
   window, separate from the main window of TADS/2 */
static VOID CreateSeparateStatus(VOID)
{
	FRAMECDATA	fcdata;
	HPS			hpsStatusPS;
	FONTMETRICS	fmOldFont;
	ULONG		ulColor;
	SWP			swpClientSizeNPos;
	ULONG		ulCreateFlags =
		FCF_TITLEBAR	|		/* Title bar */
		FCF_SIZEBORDER;			/* Size border */

	/* Get the size of the client window for sizing the status bar */
	WinQueryWindowPos(hwndClient, &swpClientSizeNPos);

	hwndStatusFrame = WinCreateStdWindow(
		HWND_DESKTOP,			/* Parent is desktop */
		0,						/* Make us invisible */
		&ulCreateFlags,			/* Frame flags */
		"TADS/2Status",			/* Name of client window class */
		"TADS/2 Status",		/* Window title */
		WS_VISIBLE,				/* Make client win visible */
		(HMODULE)0L,			/* Show that resources are in application */
		0,						/* No resources */
		&hwndStatus);			/* Save our client window handle */

	/* Set the foreground/bkgnd colors of the status bar & its font */
	WinSetPresParam(hwndStatus, PP_BACKGROUNDCOLOR, sizeof(ULONG),
		&prefsTADS.ulBack);
	WinSetPresParam(hwndStatus, PP_FOREGROUNDCOLOR, sizeof(ULONG),
		&prefsTADS.ulFore);
	WinSetPresParam(hwndStatus, PP_FONTNAMESIZE,
		strlen(prefsTADS.szStatusFont)+2, prefsTADS.szStatusFont);
	
	/* Set the size of the status bar */
	hpsStatusPS = WinGetPS(hwndStatus);
	GpiQueryFontMetrics(hpsStatusPS, sizeof(FONTMETRICS), &fmOldFont);
	lStatusWidth = swpClientSizeNPos.cx;
	lStatusHeight = fmOldFont.lEmHeight + STATUS_EXTRA_HEIGHT;
	WinReleasePS(hpsStatusPS);

	/* Get the size & position of the frame window */
	WinQueryWindowPos(hwndFrame, &swpClientSizeNPos);

	/* Adjust the size & location of the window surrounding the status bar */
	WinSetWindowPos(hwndStatusFrame, HWND_TOP,
		swpClientSizeNPos.x,
		swpClientSizeNPos.y + swpClientSizeNPos.cy,
		lStatusWidth + WinQuerySysValue(HWND_DESKTOP, SV_CXSIZEBORDER) * 2,
		lStatusHeight + WinQuerySysValue(HWND_DESKTOP, SV_CYTITLEBAR) +
		WinQuerySysValue(HWND_DESKTOP, SV_CYSIZEBORDER) * 2,
		SWP_ZORDER | SWP_SIZE | SWP_MOVE | SWP_SHOW | SWP_ACTIVATE);

	/* Subclass the status bar frame */
	DefStatusWndProc = WinSubclassWindow(hwndStatusFrame,
		(PFNWP)StatusFrameWndProc );
}

/* SetTogetherStatusFont sets the font when the status bar is joined with
   the main client window */
static VOID SetTogetherStatusFont(VOID)
{
	HPS			hpsStatusPS;
	FONTMETRICS	fmOldFont;
	SWP			swpClientSizeNPos;
	
	/* Get the size of the client window for sizing the status bar */
	WinQueryWindowPos(hwndClient, &swpClientSizeNPos);

	/* Set the size of the status bar */
	hpsStatusPS = WinGetPS(hwndStatus);
	GpiQueryFontMetrics(hpsStatusPS, sizeof(FONTMETRICS), &fmOldFont);
	lStatusWidth = swpClientSizeNPos.cx;
	lStatusHeight = fmOldFont.lEmHeight + STATUS_EXTRA_HEIGHT;
	WinSetWindowPos(hwndStatus, 0, 0, swpClientSizeNPos.cy - lStatusHeight,
		lStatusWidth, lStatusHeight, SWP_SIZE | SWP_MOVE);
	WinReleasePS(hpsStatusPS);

	WinSendMsg(hwndFrame, WM_UPDATEFRAME, (MPARAM)~0, NULL);
}

/* CreateTogetherStatus creates a status bar which is contained within the main
   window of TADS/2 */
static VOID CreateTogetherStatus(VOID)
{
	HPS			hpsStatusPS;
	FONTMETRICS	fmOldFont;
	ULONG		ulColor;
	SWP			swpClientSizeNPos;

	/* Get the size of the client window for sizing the status bar */
	WinQueryWindowPos(hwndClient, &swpClientSizeNPos);

	/* Create the status bar */
	hwndStatus = WinCreateWindow(
		hwndFrame,				/* Child of hwndFrame */
		WC_STATIC,				/* We're a static window */
		NULL,					/* Window text is handled separately */
		WS_VISIBLE		|		/* Visible window */
		SS_TEXT,				/* Static text ctrl */
		0, 0,					/* (x, y) position w/in parent */
		1,						/* Width (temporary) */
		1,						/* Height (temporary) */
		NULLHANDLE,				/* Owner window */
		HWND_TOP,				/* Put it on top of z-order */
		ID_STATUS,				/* Window identifier */
		NULL, NULL);			/* Ctrl data, presentation parameters */

	/* Set the foreground/bkgnd colors of the status bar & its font */
	WinSetPresParam(hwndStatus, PP_BACKGROUNDCOLOR, sizeof(ULONG),
		&prefsTADS.ulBack);
	WinSetPresParam(hwndStatus, PP_FOREGROUNDCOLOR, sizeof(ULONG),
		&prefsTADS.ulFore);
	WinSetPresParam(hwndStatus, PP_FONTNAMESIZE,
		strlen(prefsTADS.szStatusFont)+2, prefsTADS.szStatusFont);

	/* Set the size of the status bar */
	hpsStatusPS = WinGetPS(hwndStatus);
	GpiQueryFontMetrics(hpsStatusPS, sizeof(FONTMETRICS), &fmOldFont);
	lStatusWidth = swpClientSizeNPos.cx;
	lStatusHeight = fmOldFont.lEmHeight + STATUS_EXTRA_HEIGHT;
	WinSetWindowPos(hwndStatus, 0, 0, swpClientSizeNPos.cy - lStatusHeight,
		lStatusWidth, lStatusHeight, SWP_SIZE | SWP_MOVE);
	WinReleasePS(hpsStatusPS);

	/* Subclass the status bar window */
	DefStatusWndProc = WinSubclassWindow(hwndStatus, (PFNWP)StatusWndProc );
}

/* CreateStatus creates the proper status bar.  It also updates the main menu */
VOID CreateStatus(VOID)
{
	/* Let there be status bar */
	if (prefsTADS.fStatusSeparated)
		CreateSeparateStatus();
	else CreateTogetherStatus();

	/* Check/uncheck the separated status menu item */
	WinCheckMenuItem(WinWindowFromID(hwndFrame, FID_MENU),
		IDM_SEPARATED_STATUS, prefsTADS.fStatusSeparated);

	/* Force an update of the windows via the frame. If we're separated, update
	   our own personal frame. */
	WinSendMsg(hwndFrame, WM_UPDATEFRAME, (MPARAM)~0, NULL);
	if (prefsTADS.fStatusSeparated)
		WinSendMsg(hwndStatusFrame, WM_UPDATEFRAME, (MPARAM)~0, NULL);
}

/* SwapStatus switches between a separated status bar and a joined one */
VOID SwapStatus(VOID)
{
	if (prefsTADS.fStatusSeparated)
		WinDestroyWindow(hwndStatusFrame);
	else WinDestroyWindow(hwndStatus);

	prefsTADS.fStatusSeparated = !prefsTADS.fStatusSeparated;

	CreateStatus();
}

VOID SetStatusFont(PSZ pszNewFont)
{
	strcpy(prefsTADS.szStatusFont, pszNewFont);
	if (prefsTADS.fStatusSeparated)
		SetSeparateStatusFont();
	else SetTogetherStatusFont();
}

/*
** StatusFrameWndProc processes the status bar's frame's messages to do...um...
** stuff.  Yeah, stuff.
** Okay, it actually keeps the user from vertically sizing the separate status
** bar, since its height is optimally set for its font.
*/
MRESULT EXPENTRY StatusFrameWndProc(HWND hwnd, ULONG msg, MPARAM mp1,
	MPARAM mp2)
{
	switch (msg) {
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
			pTrackInfo->ptlMaxTrackSize.y =
            	pTrackInfo->ptlMinTrackSize.y = lStatusHeight +
                                      WinQuerySysValue( HWND_DESKTOP,
                                      					SV_CYTITLEBAR) +
                                      (WinQuerySysValue( HWND_DESKTOP,
                                                         SV_CYSIZEBORDER ) * 2);
			pTrackInfo->ptlMinTrackSize.x = lStatusLeftWidth + lStatusRightWidth +
				WinQuerySysValue(HWND_DESKTOP, SV_CXSIZEBORDER) * 2 + 6;

			return( (MRESULT)TRUE );
		}

	  default:
		return DefStatusWndProc(hwnd, msg, mp1, mp2);
	}
}

/*
** StatusWndProc processes the status bar's WM_PAINT message to print the two
** sides of the status bar.
*/
MRESULT EXPENTRY StatusWndProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	ULONG	lAttrFound;
	CHAR	szFontName[FACESIZE];
	MRESULT	mRet;
	
	switch (msg) {
	  case WM_PAINT:
		{
			BOOL rc;
			/* Rectangles for containing the size of the status bar & text */
			RECTL	rclStatus, rclLeft, rclRight;

			/* Get presentation space handle for drawing */
			HPS	hps = WinGetPS(hwnd);

			/* The lengths of the two lines of text */
			LONG	lLlen, lRlen;

			if (prefsTADS.fStatusSeparated)
				rc = (BOOL)WinDefWindowProc( hwnd, msg, mp1, mp2 );
			else rc = (BOOL)DefStatusWndProc( hwnd, msg, mp1, mp2 );
			
			/* Set the HPS into RGB mode */
			GpiCreateLogColorTable(hps, 0L, LCOLF_RGB, 0L,
				0L, NULL);
			
 			/* Draw the border */
			WinQueryWindowRect(hwnd, &rclStatus);
			if (prefsTADS.fStatusSeparated)		/* Blank the win if separated */
				WinFillRect(hps, &rclStatus, prefsTADS.ulBack);
			WinDrawBorder(hps, &rclStatus,
				1L, 1L,		/* Thickness */
				RGB_BLACK, 0, 0);

			/* Move the window rectangle in by two to avoid the border */
			rclStatus.xLeft += 2;
			rclStatus.yBottom += 2;
			rclStatus.xRight -= 2;
			rclStatus.yTop -= 2;

			/* Copy these rectangles into rclLeft and rclRight */
			memcpy(&rclLeft, &rclStatus, sizeof(RECTL));
			memcpy(&rclRight, &rclStatus, sizeof(RECTL));

			/* Get the size required for the LHS & RHS text */
			WinDrawText(hps, -1, szStatusLeft, &rclLeft, 0L, 0L,
				DT_QUERYEXTENT | DT_VCENTER);
			WinDrawText(hps, -1, szStatusRight, &rclRight, 0L, 0L,
				DT_QUERYEXTENT | DT_RIGHT | DT_VCENTER);

			/* Adjust the reported size of the LHS & RHS text */
			lStatusLeftWidth = rclLeft.xRight - rclLeft.xLeft;
			lStatusRightWidth = rclRight.xRight - rclRight.xLeft;

			/* Adjust the sizes if necessary */
			if (rclLeft.xRight >= rclRight.xLeft)
				rclLeft.xRight = rclRight.xLeft - 2;

			WinDrawText(hps, -1, szStatusLeft, &rclLeft, 
				prefsTADS.ulFore, prefsTADS.ulBack,
				DT_VCENTER);
			WinDrawText(hps, -1, szStatusRight, &rclRight,
				prefsTADS.ulFore, prefsTADS.ulBack,
				DT_RIGHT | DT_VCENTER);

			WinReleasePS(hps);
			return ((MRESULT) TRUE);
		}
		
	  case WM_PRESPARAMCHANGED:
		if (LONGFROMMP(mp1) == PP_FONTNAMESIZE) {
	  		WinQueryPresParam(hwnd, PP_FONTNAMESIZE, 0L,
	  			&lAttrFound, sizeof(szFontName), szFontName,
	  			0L);
	  		if (lAttrFound != PP_FONTNAMESIZE)
	  			DisplayInformation("Unable to change font");
	  		else {
	  			if (prefsTADS.fStatusSeparated)
	  				mRet = WinDefWindowProc(hwnd, msg,
	  					mp1, mp2);
	  			else mRet = DefStatusWndProc(hwnd, msg,
	  				mp1, mp2);
	  			SetStatusFont(szFontName);
				return (mRet);
	  		}
		}
		if (prefsTADS.fStatusSeparated)
			return (WinDefWindowProc(hwnd, msg, mp1, mp2));
		else return (DefStatusWndProc(hwnd, msg, mp1, mp2));

	  case WM_CHAR:
	  	WinPostMsg(hwndClient, msg, mp1, mp2);
	  	WinSetFocus(HWND_DESKTOP, hwndClient);
		if (prefsTADS.fStatusSeparated)
			return (WinDefWindowProc(hwnd, msg, mp1, mp2));
		else return (DefStatusWndProc(hwnd, msg, mp1, mp2));

	  default:
		if (prefsTADS.fStatusSeparated)
			return (WinDefWindowProc(hwnd, msg, mp1, mp2));
		else return (DefStatusWndProc(hwnd, msg, mp1, mp2));
	}
}


/*
** Scroll bar functions-------------------------------------------------------
*/

/* Create the vertical scroll bar. */
VOID CreateScrollBar(VOID)
{
	SWP		swpClient;
	LONG	lScrollWidth = WinQuerySysValue(HWND_DESKTOP, SV_CXVSCROLL);

	/* Get the size of the client */
	WinQueryWindowPos(hwndClient, &swpClient);

	/* Set the visible flag to FALSE */
	fScrollVisible = FALSE;
	
	hwndVertScroll = WinCreateWindow(
		hwndClient,			/* Parent is client */
		WC_SCROLLBAR,		/* Scroll bar class */
		NULL,				/* No text */
		SBS_VERT | SBS_THUMBSIZE,
		swpClient.cx - 		/* x location */
			lScrollWidth,
		0,					/* y location */
		lScrollWidth,		/* width */
		swpClient.cy,		/* height */
		hwndClient,			/* The client owns us */
		HWND_TOP,			/* Make us on top of the z-order */
		ID_VSCROLL,			/* Our ID */
		NULL, NULL);		/* Default data struct, no pres. params */
}

/* Turn on/off the scroll bar */
VOID ShowScrollBar(BOOL bFlag)
{
	fScrollVisible = bFlag;
	WinShowWindow(hwndVertScroll, bFlag);
	WinInvalidateRegion(hwndClient, NULLHANDLE, FALSE);
}


/*
** Dialog procedures----------------------------------------------------------
*/

MRESULT EXPENTRY FindDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	FINDDATA *fd;
	
	fd = (FINDDATA *)WinQueryWindowPtr(hwnd, 0);
	
	switch (msg) {
	  case WM_INITDLG:
		fd = (FINDDATA *)PVOIDFROMMP(mp2);
		WinSetWindowPtr(hwnd, 0, (PVOID)fd);
		WinSendDlgItemMsg(hwnd, IDD_FIND_TEXT, EM_SETTEXTLIMIT,
			MPFROMSHORT(sizeof(fd->findText)), 0);
	 	WinSetDlgItemText(hwnd, IDD_FIND_TEXT, fd->findText);
	 	WinSendDlgItemMsg(hwnd, IDD_FIND_TEXT, EM_SETSEL,
	 		MPFROM2SHORT(0, strlen(fd->findText)), 0);
		WinSendDlgItemMsg(hwnd, IDD_CAREABOUTCASE, BM_SETCHECK,
			MPFROMSHORT(fd->fCase), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_SEARCHBACKWARDS, BM_SETCHECK,
			MPFROMSHORT(fd->fBack), MPFROMSHORT(0));
		break;

	  case WM_COMMAND:
		switch (SHORT1FROMMP(mp1)) {
		  case DID_OK:
			WinQueryDlgItemText(hwnd, IDD_FIND_TEXT,
				sizeof(fd->findText), fd->findText);
			fd->fCase = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_CAREABOUTCASE, BM_QUERYCHECK,
				MPFROMSHORT(0), MPFROMSHORT(0)));
			fd->fBack = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_SEARCHBACKWARDS, BM_QUERYCHECK,
				MPFROMSHORT(0), MPFROMSHORT(0)));
			WinDismissDlg(hwnd, TRUE);

		  default:
			return WinDefDlgProc(hwnd, msg, mp1, mp2);
		}
	}
	return WinDefDlgProc(hwnd, msg, mp1, mp2);
}

MRESULT EXPENTRY StoryWindowDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	BOOL	fRefresh = FALSE, fTemp;
	LONG	lTemp;
	
	switch (msg) {
	  case WM_INITDLG:
		WinSendDlgItemMsg(hwnd, IDD_LRMARGINS, SPBM_SETLIMITS,
			MPFROMSHORT(99), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_LRMARGINS, SPBM_SETCURRENTVALUE,
			MPFROMSHORT(prefsTADS.marginx), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_TBMARGINS, SPBM_SETLIMITS,
			MPFROMSHORT(99), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_TBMARGINS, SPBM_SETCURRENTVALUE,
			MPFROMSHORT(prefsTADS.marginy), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_JUSTIFYTEXT, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.fulljustify), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_DOUBLESPACE, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.doublespace), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_BOLDINPUT, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.fBoldInput), 0);
		break;

	  case WM_COMMAND:
		switch (SHORT1FROMMP(mp1)) {
		  case DID_OK:
		  	WinSendDlgItemMsg(hwnd,	IDD_LRMARGINS,
		  		SPBM_QUERYVALUE, MPFROMP(&lTemp), 0);
		  	if (lTemp != prefsTADS.marginx) {
		  		prefsTADS.marginx = lTemp;
		  		fRefresh = TRUE;
		  	}
		  	WinSendDlgItemMsg(hwnd,	IDD_TBMARGINS,
		  		SPBM_QUERYVALUE, MPFROMP(&lTemp), 0);
		  	if (lTemp != prefsTADS.marginy) {
		  		prefsTADS.marginy = lTemp;
		  		fRefresh = TRUE;
		  	}
			fTemp = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_JUSTIFYTEXT, BM_QUERYCHECK, 0, 0));
			if (fTemp != prefsTADS.fulljustify) {
				prefsTADS.fulljustify = fTemp;
				fRefresh = TRUE;
			}
			fTemp = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_DOUBLESPACE, BM_QUERYCHECK, 0, 0));
			if (fTemp != prefsTADS.doublespace) {
				extern int	doublespace;
				
				prefsTADS.doublespace = fTemp;
				doublespace = fTemp;
			}
			fTemp = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_BOLDINPUT, BM_QUERYCHECK, 0, 0));
			if (fTemp != prefsTADS.fBoldInput) {
				prefsTADS.fBoldInput = fTemp;
				UpdateInputFont(hpsClient, fTemp);
				fRefresh = TRUE;
			}
			if (fRefresh) {
			  	xtext_resize(0, 0, clientRect.xRight -
			  		clientRect.xLeft, lClientHeight);
				WinInvalidateRegion(hwndClient, NULLHANDLE,
				FALSE);
			}
			WinDismissDlg(hwnd, TRUE);

		  default:
			return WinDefDlgProc(hwnd, msg, mp1, mp2);
		}
	}
	return WinDefDlgProc(hwnd, msg, mp1, mp2);
}

MRESULT EXPENTRY InterpreterDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	BOOL	fRefresh = FALSE, fTemp;
	LONG	lTemp;
	
	switch (msg) {
	  case WM_INITDLG:
		WinSendDlgItemMsg(hwnd, IDD_HISTORYLENGTH, SPBM_SETLIMITS,
			MPFROMSHORT(99), MPFROMSHORT(2));
		WinSendDlgItemMsg(hwnd, IDD_HISTORYLENGTH, SPBM_SETCURRENTVALUE,
			MPFROMSHORT(prefsTADS.historylength), 0);
		WinSendDlgItemMsg(hwnd, IDD_BUFFERSIZE, SPBM_SETLIMITS,
			MPFROMSHORT(30000), MPFROMSHORT(400));
		WinSendDlgItemMsg(hwnd, IDD_BUFFERSIZE, SPBM_SETCURRENTVALUE,
			MPFROMSHORT(prefsTADS.buffersize), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_BUFFERSLACK, SPBM_SETLIMITS,
			MPFROMSHORT(5000), MPFROMSHORT(100));
		WinSendDlgItemMsg(hwnd, IDD_BUFFERSLACK, SPBM_SETCURRENTVALUE,
			MPFROMSHORT(prefsTADS.bufferslack), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_PAGING, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.paging), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_CLEARBYSCROLL, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.clearbyscroll), MPFROMSHORT(0));
		break;

	  case WM_COMMAND:
		switch (SHORT1FROMMP(mp1)) {
		  case DID_OK:
		  	WinSendDlgItemMsg(hwnd,	IDD_HISTORYLENGTH,
		  		SPBM_QUERYVALUE, MPFROMP(&lTemp), 0);
		  	if (lTemp != prefsTADS.historylength) {
		  		prefsTADS.historylength = lTemp;
		  		fRefresh = TRUE;
		  	}
		  	WinSendDlgItemMsg(hwnd,	IDD_BUFFERSIZE,
		  		SPBM_QUERYVALUE, MPFROMP(&lTemp), 0);
		  	if (lTemp != prefsTADS.buffersize) {
		  		prefsTADS.buffersize = lTemp;
		  		fRefresh = TRUE;
		  	}
		  	WinSendDlgItemMsg(hwnd,	IDD_BUFFERSLACK,
		  		SPBM_QUERYVALUE, MPFROMP(&lTemp), 0);
		  	if (lTemp != prefsTADS.bufferslack) {
		  		prefsTADS.bufferslack = lTemp;
		  		fRefresh = TRUE;
		  	}
			fTemp = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_PAGING, BM_QUERYCHECK, 0, 0));
			if (fTemp != prefsTADS.paging)
				prefsTADS.paging = fTemp;
			fTemp = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_CLEARBYSCROLL, BM_QUERYCHECK, 0, 0));
			if (fTemp != prefsTADS.clearbyscroll)
				prefsTADS.clearbyscroll = fTemp;
			if (fRefresh) {
			  	xtext_resize(0, 0, clientRect.xRight -
			  		clientRect.xLeft, lClientHeight);
				WinInvalidateRegion(hwndClient, NULLHANDLE,
				FALSE);
			}
			WinDismissDlg(hwnd, TRUE);

		  default:
			return WinDefDlgProc(hwnd, msg, mp1, mp2);
		}
	}
	return WinDefDlgProc(hwnd, msg, mp1, mp2);
}

MRESULT EXPENTRY OptionsDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	switch (msg) {
	  case WM_INITDLG:
		WinSendDlgItemMsg(hwnd, IDD_F1ISMACRO, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.F1ismacro), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_F10ISMACRO, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.F10ismacro), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_STICKYPATHS, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.fStickyPaths), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_STICKYMACROS, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.fStickyMacros), MPFROMSHORT(0));
		WinSendDlgItemMsg(hwnd, IDD_CLOSEONEND, BM_SETCHECK,
			MPFROMSHORT(prefsTADS.fCloseOnEnd), MPFROMSHORT(0));
		break;

	  case WM_COMMAND:
		switch (SHORT1FROMMP(mp1)) {
		  case DID_OK:
			prefsTADS.F1ismacro = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_F1ISMACRO, BM_QUERYCHECK, 0, 0));
			prefsTADS.F10ismacro = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_F10ISMACRO, BM_QUERYCHECK, 0, 0));
			prefsTADS.fStickyPaths = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_STICKYPATHS, BM_QUERYCHECK, 0, 0));
			prefsTADS.fStickyMacros = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_STICKYMACROS, BM_QUERYCHECK, 0, 0));
			prefsTADS.fCloseOnEnd = SHORT1FROMMP(WinSendDlgItemMsg(hwnd,
				IDD_CLOSEONEND, BM_QUERYCHECK, 0, 0));
			WinDismissDlg(hwnd, TRUE);

		  default:
			return WinDefDlgProc(hwnd, msg, mp1, mp2);
		}
	}
	return WinDefDlgProc(hwnd, msg, mp1, mp2);
}

MRESULT EXPENTRY AboutDialogProc(HWND hwnd, ULONG msg, MPARAM mp1, MPARAM mp2)
{
	CHAR	szBuffer[1024],
		*paragraphs[] = {
"TADS/2 is a derivative work based on the TADS source code. It was \
written by Stephen Granade (sgranade@phy.duke.edu).",

"\r\n\r\nTADS is copyright (c) 1992, 1996 Michael J. Roberts. All Rights \
Reserved.",

"\r\n\r\n--==Freeware License==--",

"\r\n\r\nTADS/2 is provided as \"freeware.\"  There is no fee attached to \
using it. However, it is NOT public domain software. You must abide \
by the terms of this license when you use it.",

"\r\n\r\nYou may use, reproduce, and distribute TADS/2 freely, so long as \
you do not modify TADS/2.",

"\r\n\r\nIf you build a stand-alone (\"bound\") TADS/2 application with a \
TADS game file to which you own the copyright, you may use the \
stand-alone application as you wish. You may impose any restrictions \
or conditions you want on its use, and you may distribute it any \
way you want, including commercially. However, you may not modify \
the TADS runtime software in any way. In particular, you may not \
modify the copyright notice or this license, and you may not \
interfere with the user's right or ability to build an unbound \
TADS/2 application from your stand-alone application.",

"\r\n\r\nIn other words, we don't want others to make a profit from selling \
TADS itself, but we want TADS game developers to be able to share \
or sell their games (which necessarily must include a TADS \
run-time engine) in any way they please.",

"\r\n\r\nAnyone unable or unwilling to comply with any of the terms and \
conditions of this license must destroy or otherwise discard all \
copies of this software in his or her possession."
		};
	SHORT	iNumlines = sizeof(paragraphs)/sizeof(paragraphs[0]),
		i;
	IPT	ipt = 0;

	switch (msg) {
	  case WM_INITDLG:
		WinSendDlgItemMsg(hwnd, IDD_MLE, MLM_SETIMPORTEXPORT,
			MPFROMP(szBuffer), MPFROMLONG(sizeof(szBuffer)));
		for (i = 0; i < iNumlines; i++) {
			strcpy(szBuffer, paragraphs[i]);
			WinSendDlgItemMsg(hwnd, IDD_MLE, MLM_IMPORT,
				MPFROMP(&ipt), MPFROMLONG(strlen(szBuffer)));
		}
		break;
	}
	return WinDefDlgProc(hwnd, msg, mp1, mp2);
}
