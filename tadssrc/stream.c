#define INCL_DOSPROCESS
#define INCL_WINTIMER

#include <os2.h>
#include <string.h>

#include "os2io.h"
#include "global.h"

VOID clear_stream(stream *st)
{
	while (st->bStreamLocked);
	st->curpos = 0;
}

VOID clear_num_stream(stream *st, LONG num)
{
	while (st->bStreamLocked);
	st->bStreamLocked = TRUE;
	if (num < (st->curpos)) {
		memmove(st->streambuf, st->streambuf + num,
			sizeof(st->streambuf[0]) * (st->curpos - num));
		st->curpos -= num;
	}
	else st->curpos = 0;
	st->bStreamLocked = FALSE;
}

/* Returns TRUE if there's a character in the stream */
BOOL char_waiting_in_stream(stream *st)
{
	return (st->curpos != 0);
}

/* Waits for a stream to become unlocked. Returns FALSE if we timeout */
BOOL wait_for_stream(stream *st, LONG outtime)
{
	while (st->bStreamLocked) {
		DosSleep(5);
		if (outtime && WinGetCurrentTime(habThread) > outtime)
			return FALSE;
	}
	return TRUE;
}

/* Waits for a character to appear in a stream. If outtime is nonzero, then
   the function will return FALSE if we timeout before we get a char */
BOOL wait_for_char_in_stream(stream *st, LONG outtime)
{
	while (!char_waiting_in_stream(st)) {
		DosSleep(5);	/* Wait for a bit */
		if (outtime && WinGetCurrentTime(habThread) > outtime)
			return FALSE;
	}
	return TRUE;
}

/* Returns (-1) on error */
short getch_stream(stream *st)
{
	short ch;
	
	if (st->curpos == 0)
		return (-1);
	ch = (short)st->streambuf[0];
	clear_num_stream(st, 1);
	return ch;
}

/* Get a char, or return (-1) if we timeout before we get a character */
short getch_wait_stream(stream *st, LONG outtime)
{
	if (!wait_for_char_in_stream(st, outtime))
		return (-1);
	return getch_stream(st);
}

/* Returns FALSE if the stream is full. */
BOOL putch_stream(stream *st, short c)
{
	wait_for_stream(st, 0);
	if (st->curpos == MAXBUF)
		return FALSE;
	st->bStreamLocked = TRUE;
	st->streambuf[st->curpos] = c;
	st->curpos++;
	st->bStreamLocked = FALSE;
}

/* Returns FALSE if the stream is full, -1 on timeout */
int putch_wait_stream(stream *st, short c, LONG outtime)
{
	if (!wait_for_stream(st, outtime))
		return (-1);
	if (st->curpos == MAXBUF)
		return FALSE;
	st->bStreamLocked = TRUE;
	st->streambuf[st->curpos] = c;
	st->curpos++;
	st->bStreamLocked = FALSE;
}
