#define INCL_WINCLIPBOARD

#include <os2.h>
#include <stdlib.h>
#include <string.h>

#include "os2io.h"
#include "global.h"

VOID copy_selec_to_clip(char *buf, long len);
PSZ copy_clip_to_string(VOID);

VOID copy_selec_to_clip(char *buf, long len)
{
	char	*cx;
	long	lx;
	PSZ	pszDest;
	
	if (len <= 0) return;

	if (WinOpenClipbrd(habThread)) { 

		/* Allocate a shared memory object for the text data. */ 
		if (!DosAllocSharedMem( 
			(PVOID)&pszDest,	/* Pointer to shared memory object */ 
			NULL,				/* Use unnamed shared memory       */ 
			len+1,				/* Amount of memory to allocate    */ 
			PAG_WRITE  |		/* Allow write access              */ 
			PAG_COMMIT |		/* Commit the shared memory        */ 
			OBJ_GIVEABLE)) {	/* Make pointer giveable           */ 

			strncpy(pszDest, buf, len);
			pszDest[len] = 0;

			WinSetClipbrdData(habThread, (ULONG) pszDest, CF_TEXT, CFI_POINTER);
		}
		WinCloseClipbrd(habThread); 	
	}
}

/* N.B. this function allocates pszRetn. Make sure to free it when done. */
PSZ copy_clip_to_string(VOID)
{
	static PSZ	pszFromClip, pszRetn;

	if (WinOpenClipbrd(habThread)) {
		if (pszFromClip = (PSZ)WinQueryClipbrdData(habThread, CF_TEXT)) {
			pszRetn = (char *)malloc(sizeof(char)*(strlen(pszFromClip)+1));
			strcpy(pszRetn, pszFromClip);
		}
		WinCloseClipbrd(habThread);
	}
	return pszRetn;
}