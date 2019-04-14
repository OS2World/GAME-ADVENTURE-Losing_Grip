#define INCL_PM
#define DEBUGMSG(x)	WinMessageBox(HWND_DESKTOP, NULLHANDLE, \
x, "TADS/2 Message", 0, MB_OK)

#include <os2.h>
#include <string.h>

#include "os2io.h"
#include "global.h"

extern SHORT cmdkeylist[];		// Defined in os2ctls.c

stream keyboard_stream;

static cmdentry mastertable[] = {
	{xted_insert, -1, 0, "insert-self"},
	{xted_enter, op_Enter, 0, "enter"},

	{xted_movecursor, op_ForeChar, 0, "forward-char"},
	{xted_movecursor, op_BackChar, 0, "backward-char"},
	{xted_movecursor, op_ForeWord, 0, "forward-word"},
	{xted_movecursor, op_BackWord, 0, "backward-word"},
	{xted_movecursor, op_ForeLine, 0, "forward-line"},
	{xted_movecursor, op_BackLine, 0, "backward-line"},
	{xted_movecursor, op_BeginLine, 0, "beginning-of-line"},
	{xted_movecursor, op_EndLine, 0, "end-of-line"},

	{xted_movedot, op_ForeChar, 0, "dot-forward-char"},
	{xted_movedot, op_BackChar, 0, "dot-backward-char"},
	{xted_movedot, op_ForeWord, 0, "dot-forward-word"},
	{xted_movedot, op_BackWord, 0, "dot-backward-word"},
	{xted_movedot, op_ForeLine, 0, "dot-forward-line"},
	{xted_movedot, op_BackLine, 0, "dot-backward-line"},
	{xted_movedot, op_BeginLine, 0, "dot-beginning-of-line"},
	{xted_movedot, op_EndLine, 0, "dot-end-of-line"},

	{xted_scroll, op_DownPage, 0, "scroll-down"},
	{xted_scroll, op_UpPage, 0, "scroll-up"},
	{xted_scroll, op_DownLine, 0, "scroll-down-line"},
	{xted_scroll, op_UpLine, 0, "scroll-up-line"},
	{xted_scroll, op_ToBottom, 0, "scroll-to-bottom"},
	{xted_scroll, op_ToTop, 0, "scroll-to-top"},

	{xted_delete, op_ForeChar, 0, "delete-next-char"},
	{xted_delete, op_BackChar, 0, "delete-char"},
	{xted_delete, op_ForeWord, 0, "delete-next-word"},
	{xted_delete, op_BackWord, 0, "delete-word"},
	{xted_delete, op_Line, 0, "delete-line"},

	{xted_cutbuf, op_Yank, 0, "yank"},
	{xted_cutbuf, op_Wipe, 0, "kill-region"},
	{xted_cutbuf, op_Copy, 0, "copy-region"},
	{xted_cutbuf, op_YankReplace, 0, "yank-pop"},
	{xted_cutbuf, op_Kill, 0, "kill-line"},
	{xted_cutbuf, op_Untype, 0, "kill-input"},
	{xted_cutbuf, op_Erase, 0, "erase"},

	{xted_history, op_BackLine, 0, "backward-history"},
	{xted_history, op_ForeLine, 0, "forward-history"},

	{xted_macro, -1, 0, "macro"},
	{xted_macro_enter, -1, 0, "macro-enter"},

	{xtexted_meta, op_Cancel, 1, "cancel"},
	{xtexted_meta, op_Escape, 1, "escape"},
	{xtexted_meta, op_ExplainKey, 0, "explain-key"},
	{xtexted_meta, op_DefineMacro, 0, "define-macro"},

	{xted_noop, -1, 0, "no-op"},

	{NULL, 0, 0, NULL}
};

typedef struct binding_t {
	unsigned short key;
	short which; /* keytype_* */
	char *name;
} binding;

static binding defaultbindings[] = {
	{VK_F1, keytype_virtual, "macro"},
	{VK_F2, keytype_virtual, "macro"},
	{VK_F3, keytype_virtual, "macro"},
	{VK_F4, keytype_virtual, "macro"},
	{VK_F5, keytype_virtual, "macro"},
	{VK_F6, keytype_virtual, "macro"},
	{VK_F7, keytype_virtual, "macro"},
	{VK_F8, keytype_virtual, "macro"},
	{VK_F9, keytype_virtual, "macro"},
	{VK_F10, keytype_virtual, "macro"},
	{VK_F11, keytype_virtual, "macro"},
	{VK_F12, keytype_virtual, "macro"},

	{VK_ESC, keytype_virtual, "delete-line"},
	{VK_PAGEUP, keytype_virtual, "scroll-up"},
	{VK_PAGEDOWN, keytype_virtual, "scroll-down"},
	{VK_END, keytype_virtual, "end-of-line"},
	{VK_HOME, keytype_virtual, "beginning-of-line"},
	{VK_LEFT, keytype_virtual, "backward-char"},
	{VK_RIGHT, keytype_virtual, "forward-char"},
	{VK_UP, keytype_virtual, "backward-history"},
	{VK_DOWN, keytype_virtual, "forward-history"},
	{VK_INSERT, keytype_virtual, "no-op"},
	{VK_DELETE, keytype_virtual, "delete-next-char"},
	{VK_BACKSPACE, keytype_virtual, "delete-char"},
	{VK_ENTER, keytype_virtual, "enter"},
	{VK_NEWLINE, keytype_virtual, "enter"},
	{'\n', keytype_main, "enter"},
	{'\r', keytype_main, "enter"},
	{VK_UP, keytype_virtual | keytype_ctrl, "scroll-up-line"},
	{VK_DOWN, keytype_virtual | keytype_ctrl, "scroll-down-line"},
	{VK_END, keytype_virtual | keytype_ctrl, "scroll-to-bottom"},
	{VK_HOME, keytype_virtual | keytype_ctrl, "scroll-to-top"},
	{VK_LEFT, keytype_virtual | keytype_ctrl, "backward-word"},
	{VK_RIGHT, keytype_virtual | keytype_ctrl, "forward-word"},
	{VK_LEFT, keytype_virtual | keytype_shift, "dot-backward-char"},
	{VK_RIGHT, keytype_virtual | keytype_shift, "dot-forward-char"},
	{VK_LEFT, keytype_virtual | keytype_shift | keytype_ctrl,
		"dot-backward-word"},
	{VK_RIGHT, keytype_virtual | keytype_shift | keytype_ctrl,
		"dot-forward-word"},
	{VK_HOME, keytype_virtual | keytype_shift, "dot-beginning-of-line"},
	{VK_END, keytype_virtual | keytype_shift, "dot-end-of-line"},

	{0, 0, NULL}
};

typedef struct _keyname {
	SHORT key;
	char *name;
} keyname;

static keyname virtualKeyNames[] = {
	{VK_F1, "F1"},
	{VK_F2, "F2"},
	{VK_F3, "F3"},
	{VK_F4, "F4"},
	{VK_F5, "F5"},
	{VK_F6, "F6"},
	{VK_F7, "F7"},
	{VK_F8, "F8"},
	{VK_F9, "F9"},
	{VK_F10, "F10"},
	{VK_F11, "F11"},
	{VK_F12, "F12"},
	{VK_ESC, "Esc"},
	{VK_PAGEUP, "PageUp"},
	{VK_PAGEDOWN, "PageDown"},
	{VK_END, "End"},
	{VK_HOME, "Home"},
	{VK_LEFT, "Left Arrow"},
	{VK_RIGHT, "Right Arrow"},
	{VK_UP, "Up Arrow"},
	{VK_DOWN, "Down Arrow"},
	{VK_INSERT, "Insert"},
	{VK_DELETE, "Delete"},
	{VK_BACKSPACE, "Backspace"},
	{VK_ENTER, "Enter"},
	{VK_NEWLINE, "Enter"},
	{VK_BREAK, "Break"},
	{0, NULL}
}; 

VOID init_kbd(VOID)
{
	short		i, keynum;
	char		*cx;
	cmdentry	*cmd;
	binding		*bx;
	
	/* Set up the keyboard stream */
	keyboard_stream.curpos = 0;
	keyboard_stream.bStreamLocked = FALSE;
	
	/* Initialize the bindings */
	for (i = 0; i < NUMCOMMANDS; i++) {
		keycmds[i] = NULL;
		keycmdargs[i] = NULL;
	}
	
	/* Set up the standard keys */
	cmd = xkey_find_cmd_by_name("insert-self");
	for (i=' '; i<='~'; i++) {
		keycmds[i | keytype_main] = cmd;
	}
	for (i=128; i<=255; i++) {
		keycmds[i | keytype_main] = cmd;
	}

	for (bx=defaultbindings; bx->name; bx++) {
		i = (bx->key & 255);
		cmd = xkey_find_cmd_by_name(bx->name);
		if (!cmd) {
			char str[255];
			
			sprintf(str, "Unknown function <%s> in default bindings",
				bx->name);
			DEBUGMSG(str);
		}
		else {
			keynum = i | bx->which;
			if (keycmds[keynum]) {
				char str[255];
				
				sprintf(str, "Key <%s> (%d) defined twice in default bindings",
					xkey_get_key_name(keynum), i);
				DEBUGMSG(str);
			}
			keycmds[keynum] = cmd;
		}
	}
	
	/* Restore macros if necessary */
	if (prefsTADS.fStickyMacros) {
		for (i = 0; i < 12; i++) {
			cx = prefsTADS.szMacroText[i];
			if (cx[0] == 0)
				continue;
			xted_define_macro_text(cmdkeylist[i] | keytype_virtual,
				cx);
		}
	}
}

/* Returns FALSE if the keyboard buffer is full */
BOOL stuff_kbd_stream(short c)
{
	int i;
	
	i = putch_wait_stream(&keyboard_stream, c,
		WinGetCurrentTime(hab) + 100);	/* Don't wait for more than 1/10 sec */
	if (i == -1) {
		DEBUGMSG("Timed out in stuff_kbd_stream");
		return FALSE;
	}
	return i;
}

BOOL stuff_kbd_stream_with_string(char *str)
{
	int i, len;
	BOOL	ret = TRUE;
	
	len = strlen(str);
	for (i = 0; i < len; i++) {
		ret = stuff_kbd_stream((int)str[i]);
		if (!ret) break;
	}
	return ret;
}

char *xkey_get_key_name(short key)
{
	static char buf[256], prefix[256];
	char *name;
	short which, key2;
	int i;

	which = key & keytype_Mask;
	key = key & 255;

	prefix[0] = 0;
	if (which != 0) {
		if (which & keytype_ctrl)
			strcat(prefix, "Ctrl+");
		if (which & keytype_shift)
			strcat(prefix, "Shift+");
		if (which & keytype_alt)
			strcat(prefix, "Alt+");
		if (which & keytype_virtual) {
			for (i = 0; virtualKeyNames[i].name != NULL; i++) {
				if (virtualKeyNames[i].key == key) {
					sprintf(buf, "%s%s", prefix,
						virtualKeyNames[i].name);
					return buf;
				}
			}
		}
	}

	if (iscntrl(key)) {
		sprintf(buf, "%sCtrl+%c", prefix, key+'A'-1);		
	}
	else {
		sprintf(buf, "%s%c", prefix, key);
	}

	return buf;
}

cmdentry *xkey_find_cmd_by_name(char *str)
{
	cmdentry *retval;

	for (retval = mastertable; retval->func; retval++) {
		if (!strcmp(str, retval->name))
			return retval;
	}
	return NULL;
}
