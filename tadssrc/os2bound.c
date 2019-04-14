/*
** os2bound.c -- Handle binding and unbinding a .gam file to TADS/2. Also
**               take care of seeing if we have a properly-bound .gam file
**               hanging onto the executable like a leech.
*/

#define INCL_PM
#include <os2.h>

#include <stdio.h>

#include "os2io.h"
#include "global.h"
#include "tadsos2.h"

#define BUFSIZE	30*1024		// The size of the file buffer
#define GAMETYPE "TGAM"		// String identifier

/*
** For historical reasons, here's how I've decided to attach a game data
** file to TADS/2. First, I find the seek position of the end of the actual
** TADS/2 executable, i.e. where the new data will start. I write the one's
** complement of that seek position, then the string identifier GAMETYPE
** for good luck. The game data comes next, then the descriptor block.
** The descriptor block consists of the one's complement of the seek position
** of the descriptor block itself, the GAMETYPE identifier, and the seek
** position of the start of the data.
*/

// TestBinding checks to see if the file whose name it is given contains
// bound data. It returns the position of the bound data if the file is
// bound; 0L otherwise.
LONG TestBinding(PSZ pszTADS)
{
	CHAR	szType[4];
	FILE	*fpTADS;
	LONG	l, lDataOffset, lBlockOffset;

	if (!(fpTADS = fopen(pszTADS, "rb"))) {
		return 0L;
	}

	// Check the descriptor block--is everything ok?	
	fseek(fpTADS, 0L - sizeof(lDataOffset) - sizeof(szType) -
		sizeof(lBlockOffset), SEEK_END);
	l = ~ftell(fpTADS);
	if (fread(&lBlockOffset, sizeof(lBlockOffset), 1, fpTADS) != 1 ||
		fread(szType, sizeof(szType), 1, fpTADS) != 1 ||
		fread(&lDataOffset, sizeof(lDataOffset), 1, fpTADS) != 1) {
		lDataOffset = 0L;
		goto clean_up;
	}
	if (lBlockOffset != l || memcmp(szType, GAMETYPE, sizeof(szType))) {
		lDataOffset = 0L;
		goto clean_up;
	}
	
	// Make sure the data block is there
	fseek(fpTADS, lDataOffset, SEEK_SET);
	if (fread(&l, sizeof(l), 1, fpTADS) != 1 ||
		fread(szType, sizeof(szType), 1, fpTADS) != 1) {
		lDataOffset = 0L;
		goto clean_up;
	}
	if (l != ~lDataOffset || memcmp(szType, GAMETYPE, sizeof(szType))) {
		lDataOffset = 0L;
		goto clean_up;
	}
	
clean_up:
	fclose(fpTADS);
	return lDataOffset;
}

// BindCode does just what it says. It needs to know a) the pathname of the
// executable, b) the pathname of the .gam data, and c) the pathname of the
// resulting bound executable. All three of these things it gets from shared
// data via WinQueryWindowPtr. All error reporting is shuffled back to the
// main window.
VOID _System BindCode(HWND hwndCaller)
{
	static char	szError[255];
	FILE		*fpTADS, *fpData, *fpBound;
	CHAR		*pcBuffer, szMyData[CCHMAXPATH], szMyBound[CCHMAXPATH];
	size_t		size;
	LONG		l, lDataOffset, lBlockOffset;
	
	if (validBinding) {
		strcpy(szError, "This version of TADS/2 has already been bound");
		goto send_error;
	}
	szError[0] = 0;
	strcpy(szMyData, sShare.szData);
	strcpy(szMyBound, sShare.szOutput);
	os_defext(szMyData, "gam");
	os_defext(szMyBound, "exe");
	if (!(fpTADS = fopen(sShare.szTADS, "rb"))) {
		strcpy(szError,
			"Binding error: unable to open TADS/2 program file");
		goto send_error;
	}
	if (!(fpData = fopen(szMyData, "rb"))) {
		sprintf(szError,
			"Binding error: unable to open .gam file \"%s\"",
			sShare.szData);
		fclose(fpTADS);
		goto send_error;
	}
	if (!(fpBound = fopen(szMyBound, "wb"))) {
		sprintf(szError,
			"Binding error: unable to open output file \"%s\"",
			sShare.szOutput);
		fclose(fpData);
		fclose(fpTADS);
		goto send_error;
	}
	pcBuffer = (PCHAR)malloc(BUFSIZE);
	
	// Read in and write TADS/2
	while (TRUE) {
		if (!(size = fread(pcBuffer, 1, BUFSIZE, fpTADS)))
			break;
		if (fwrite(pcBuffer, 1, size, fpBound) != size) {
			strcpy(szError,	"Binding error while writing the \
executable portion");
			goto clean_up;
		}
	}
	
	// Write the initial seek position and game type identifier
	lDataOffset = ftell(fpBound);
	l = ~lDataOffset;
	if (fwrite(&l, sizeof(l), 1, fpBound) != 1 ||
		fwrite(GAMETYPE, sizeof(GAMETYPE)-1, 1, fpBound) != 1) {
		strcpy(szError, "Binding error while writing data offset");
		goto clean_up;
	}
	
	// Write the .gam data
	while (TRUE) {
		if (!(size = fread(pcBuffer, 1, BUFSIZE, fpData)))
			break;
		if (fwrite(pcBuffer, 1, size, fpBound) != size) {
			strcpy(szError, "Binding error while writing the \
data file");
			goto clean_up;
		}
	}
	
	// Write the descriptor block
	lBlockOffset = ~ftell(fpBound);
	if (fwrite(&lBlockOffset, sizeof(lBlockOffset), 1, fpBound) != 1 ||
		fwrite(GAMETYPE, sizeof(GAMETYPE)-1, 1, fpBound) != 1 ||
		fwrite(&lDataOffset, sizeof(lDataOffset), 1, fpBound) != 1) {
		strcpy(szError, "Binding error while writing descriptor block");
		goto clean_up;
	}
	
clean_up:
	free(pcBuffer);
	fclose(fpBound);
	fclose(fpData);
	fclose(fpTADS);
send_error:
	if (szError[0] != 0)
		WinPostMsg(hwndClient, WM_COMMAND, MPFROMSHORT(CMD_SHOWERROR),
			MPFROMP(szError));
}

// UnbindCode removes any bound data. It needs to know a) the pathname of the
// executable and b) the pathname of the resulting unbound executable, both
// of which it learns from window data. All error handling is left to the
// main window.
VOID _System UnbindCode(HWND hwndCaller)
{
	static char	szError[255];
	CHAR		szType[4], szMyUnbound[CCHMAXPATH];
	FILE		*fpTADS, *fpUnbound;
	PCHAR		pcBuffer;
	size_t		size;
	LONG		l, lDataOffset, lBlockOffset, lReadLen;
	
	if (!validBinding) {
		strcpy(szError, "This version of TADS/2 is not bound");
		goto send_error;
	}
	szError[0] = 0;
	strcpy(szMyUnbound, sShare.szOutput);
	os_defext(szMyUnbound, "exe");
	if (!(fpTADS = fopen(sShare.szTADS, "rb"))) {
		strcpy(szError,
			"Binding error: unable to open TADS/2 program file");
		goto send_error;
	}
	if (!(fpUnbound = fopen(szMyUnbound, "wb"))) {
		sprintf(szError,
			"Binding error: unable to open output file \"%s\"",
			sShare.szOutput);
		fclose(fpTADS);
		goto send_error;
	}
	pcBuffer = (PCHAR)malloc(BUFSIZE);

	// Check the descriptor block--is everything ok?	
	fseek(fpTADS, 0L - sizeof(lDataOffset) - sizeof(szType) -
		sizeof(lBlockOffset), SEEK_END);
	l = ~ftell(fpTADS);
	if (fread(&lBlockOffset, sizeof(lBlockOffset), 1, fpTADS) != 1 ||
		fread(szType, sizeof(szType), 1, fpTADS) != 1 ||
		fread(&lDataOffset, sizeof(lDataOffset), 1, fpTADS) != 1) {
		strcpy(szError,
			"Binding error while reading the descriptor block");
		goto clean_up;
	}
	if (lBlockOffset != l || memcmp(szType, GAMETYPE, sizeof(szType))) {
		strcpy(szError, "Binding error: this program's descriptor \
block is corrupt");
		goto clean_up;
	}
	
	// Make sure the data block is there
	fseek(fpTADS, lDataOffset, SEEK_SET);
	if (fread(&l, sizeof(l), 1, fpTADS) != 1 ||
		fread(szType, sizeof(szType), 1, fpTADS) != 1) {
		strcpy(szError, "Binding error while finding the data portion \
of the program");
		goto clean_up;
	}
	if (l != ~lDataOffset || memcmp(szType, GAMETYPE, sizeof(szType))) {
		strcpy(szError, "Binding error: this program's data portion \
is corrupt");
		goto clean_up;
	}
	fseek(fpTADS, 0L, SEEK_SET);	// Back to the beginning
	
	// Read in and write the TADS/2 portion of the executable
	while (TRUE) {
		l = ftell(fpTADS);
		if (l + BUFSIZE >= lDataOffset)
			lReadLen = lDataOffset - l;
		else lReadLen = BUFSIZE;
		if (!(size = fread(pcBuffer, 1, lReadLen, fpTADS)))
			break;
		if (fwrite(pcBuffer, 1, size, fpUnbound) != size) {
			strcpy(szError,	"Binding error while writing the \
unbound executable");
			goto clean_up;
		}
	}
	
clean_up:
	free(pcBuffer);
	fclose(fpUnbound);
	fclose(fpTADS);
send_error:
	if (szError[0] != 0)
		WinPostMsg(hwndClient, WM_COMMAND, MPFROMSHORT(CMD_SHOWERROR),
			MPFROMP(szError));
}
