#define INCL_PM

#include <stdio.h>
#include <string.h>
#include <ctype.h>
#include <os2.h>

#include "os2io.h"
#include "global.h"

extern stream keyboard_stream;

static BOOL screen_inited = FALSE;

static short escapemode = FALSE;
static short modifymode = op_Cancel;
short statusmode = 0;

static short procedures_legal = FALSE;

void do_nothing_1(void);
void set_attribute(int attr);

static void loop(int stringmode, int *killflag, int timeout);
void mainwin_handlekey(short key, short modifiers, int stringmode, int *killflag);

/*extern void set_kill_by_macro(BOOL newval);*/
void kbdloop(int stringmode, int *killflag, int timeout);

void do_nothing_1()
{
	/* for segment-loading */
}

void display_char(int ch)
{
	if (ch == '\002') {
		set_attribute(lcidBold);
		return;
	}
	if (ch == '\001') {
		set_attribute(lcidNorm);
		return;
	}
	
	if (statusmode == 0) {
		xtext_add(ch, -1);
	} else if (statusmode == 1) {
		StatusInsertLeft(ch);
	}
}

void display_string(char *str)
{
	int ch;
	
	while ((ch = *(str++)) != 0) {
		display_char(ch);
	}
}

/* timeout is in tenth-seconds; 0 means never timeout. 
	Returns char gotten, or -1 for timed-out. */
int input_character(int timeout)
{
	int killflag;

	killflag = (-1);
	loop(FALSE, &killflag, timeout);

	return killflag;
}

void xio_pause()
{
	int killflag;

	killflag = (-1);
	kbdloop(FALSE, &killflag, 0);
}

/* timeout is in tenth-seconds; 0 means never timeout. 
	Returns -1 for timed-out (and don't affect other vars). returns '\n' if
	enter is hit.
 	Buffer and readpos are set on entry and should be set on exit.
 	Cannot be called reentrantly. */
int input_line(int buflen, char *buffer, int timeout, int *readpos)
{
	int killflag;

	xted_init(buflen, buffer, readpos, &killflag);

	loop(TRUE, &killflag, timeout);

	if (killflag == (-1)) {
		xtext_line_timeout();
	}

	return killflag;
}

void initialize_screen()
{
	screen_inited = TRUE;
	mainwin_caret_changed(TRUE);
}

void restart_screen()
{
}

void reset_screen()
{
	static PSZ killmessage = "Hit any key to exit.";

	if (!screen_inited)
		return;

	SetMessageBoxText(killmessage, FALSE);
	/*set_kill_by_macro(FALSE);*/
	input_character(0);
	SetMessageBoxText(NULL, FALSE);
	
	screen_inited = FALSE;
}

void set_attribute(int attr)
{
	if (statusmode == 0) {
		xtext_setstyle(-1, attr);
	}
	else if (statusmode == 1) {
	}
}

void clear_line()
{
	/* ### do something! */
}

/* clear both text and status window */
void clear_screen()
{
	ClearStatus();
	xtext_clear_window();
}

void clear_text_window()
{
	xtext_clear_window();
}

void scroll_line()
{
	if (statusmode == 0) {
		display_char('\n');
	}
}

void select_status_mode(int mode)
{
	statusmode = mode;
}

/* do one round of iteration -- getchar, getline, whatever is relevant. return 
    -1 after timeout tenth-seconds (if timeout > 0).
 If stringmode==FALSE, return the first keystroke (immediately).
 Otherwise, do a line of input using loop_*, returning \n. */
static void loop(int stringmode, int *killflag, int timeout)
{
	xtext_adjust(); /* the biggie; everything has to be right after this */
	xtext_end_visible();

	kbdloop(stringmode, killflag, timeout);
	xtext_set_lastseen();
}

void kbdloop(int stringmode, int *killflag, int timeout)
{
	short	key, modifiers;
	
	procedures_legal = stringmode;

	while (TRUE) {
		key = getch_wait_stream(&keyboard_stream, timeout);
		if (key == -1) {
			*killflag = -1;
			procedures_legal = FALSE;
			return;
		}
/*		if (key == 0) {		// 0 indicates modifiers
			modifiers = TRUE;
			key = getch_wait_stream(&keyboard_stream, timeout);
			if (key == -1) {
				*killflag = -1;
				procedures_legal = FALSE;
				return;
			}
		}
		else modifiers = FALSE;*/
		if (key & keytype_Mask)
			modifiers = TRUE;
		else modifiers = FALSE;
		mainwin_handlekey(key, modifiers, stringmode, killflag);
		if (*killflag != (-1)) {
			procedures_legal = FALSE;
			return;
		}
	}
}

/* modifiers is TRUE if the passed command is a macro */
void mainwin_handlekey(short key, short modifiers, int stringmode, int *killflag)
{
	/* not yet set up to do keybindings */
	if (!stringmode) {
		/* only return for ascii chars */
		if (!key)
			return;
		switch (key) {
			default:
				*killflag = (unsigned char)key;
				break;
		}
	}
	else {
		cmdentry *command;
		short val, which, keynum, op;
		if (escapemode || modifiers)
			escapemode = FALSE;
		val = (key & 255);
		which = (key & keytype_Mask);
		keynum = (val | which);
		command = keycmds[keynum];
		if (modifymode != op_Cancel && !(command && command->ignoremods)) {
			op = modifymode;
			modifymode = op_Cancel;
			xtexted_modify(keynum, op);
		}
		else if (!command) {
			char buf[128];
			char *cx;
			cx = xkey_get_key_name(keynum);
			sprintf(buf, "Key <%s> is not bound", cx);
			SetMessageBoxText(buf, TRUE);
		}
		else {
			if (command->operand == (-1))
				op = keynum;
			else
				op = command->operand;
			(*(command->func))(op);
		}
	}
}

void xtexted_meta(short op)
{
	switch (op) {
		case op_Cancel:
			escapemode = FALSE;
			modifymode = op_Cancel;
			SetMessageBoxText("Cancelled.", TRUE);
			TweakMacroMenus();
			break;
		case op_DefineMacro:
			SetMessageBoxText("Select some text, and type a macro command key to define.", TRUE);
			modifymode = op_DefineMacro;
			TweakMacroMenus();
			break;
		case op_ExplainKey:
			SetMessageBoxText("Type a key to explain.", TRUE);
			modifymode = op_ExplainKey;
			break;
		case op_Escape:
			escapemode = !escapemode;
			break;
	}
}

/* This is a hack, pure and evil */
short xtexted_getmodifymode(BOOL clearit)
{
	if (clearit) {
		modifymode = op_Cancel;
	}
	return modifymode;
}

void xtexted_modify(short keynum, short op)
{
	char buf[128];
	char *cx;
	cmdentry *command;

	switch (op) {
		case op_DefineMacro:
			xted_define_macro(keynum);
			break;
		case op_ExplainKey:
			cx = xkey_get_key_name(keynum);
			command = keycmds[keynum];
			if (!command)
				sprintf(buf, "Key <%s> is not bound", cx);
			else if (!keycmdargs[keynum])
				sprintf(buf, "Key <%s>: %s", cx, command->name);
			else {
				if (strlen(keycmdargs[keynum]) < sizeof(buf) - 64)
					sprintf(buf, "Key <%s>: %s \"%s\"", cx, command->name, keycmdargs[keynum]);
				else {
					sprintf(buf, "Key <%s>: %s \"", cx, command->name);
					strncat(buf, keycmdargs[keynum], sizeof(buf) - 64);
					strcat(buf, "...\"");
				}
			}
			SetMessageBoxText(buf, TRUE);
			break;
		default:
			sprintf(buf, "Unknown key modifier (%d).", op);
			SetMessageBoxText(buf, TRUE);
			break;
	}
}
