#define PROGRAMNAME "TADS/2"
/* Version number is in OEM.H */

#define MAXBUF 1000

/* #define DEBUG */

/* Regular messages */
#define  strix_RestoreGame 1
#define  strix_SaveGameAs 2
#define  strix_OpenGame 3
#define  strix_WriteScript 4
#define  strix_BindGame 5
#define  strix_UnbindGame 6
#define  strix_PrefsFileName 7
#define  strix_PrefsName 8
#define  strix_PrefsKeyName 9

#define curs_Arrow (0)
#define curs_Watch (1)
#define curs_Bar (2)

/* for cutbuf */
#define op_Yank 1
#define op_Wipe 2
#define op_Copy 3
#define op_YankReplace 4
#define op_Kill 5
#define op_Untype 6
#define op_Erase 7

/* for movecursor and delete */
#define op_ForeChar 1
#define op_BackChar 2
#define op_ForeWord 3
#define op_BackWord 4
#define op_ForeLine 5
#define op_BackLine 6
#define op_BeginLine 7
#define op_EndLine 8
#define op_Line 9

/* for scroll */
#define op_UpLine 1
#define op_DownLine 2
#define op_UpPage 3
#define op_DownPage 4
#define op_ToTop 5
#define op_ToBottom 6

#define op_Enter 1
/* for meta */
#define op_Cancel 1
#define op_Escape 2
#define op_DefineMacro 3
#define op_ExplainKey 4

#define gcblack (0)
#define gcwhite (1)
#define gcflip (2)

#define keytype_main (0)
#define keytype_virtual (0x100)
#define keytype_ctrl (0x200)
#define keytype_shift (0x400)
#define keytype_alt (0x800)
#define keytype_Mask (0xF00)
#define NUMCOMMANDS (4096) /* 16*256 */

#define   FONT_NORMAL (0)
#define   FONT_BOLD (1)
#define   FONT_INPUT (2)
#define NUMSTORYFONTS (3)
#define   FONT_STATUS (3)
#define NUMFONTS (4)

typedef void (*cmdfunc_ptr)(short operand);

typedef struct cmdentry_t {
    cmdfunc_ptr func;
    short operand;
    short ignoremods;
    char *name;
} cmdentry;

typedef struct stream_t {
	short	streambuf[MAXBUF];
	BOOL	bStreamLocked;	/* Is the stream in use? */
	LONG	curpos;			/* Where's the end of the stream? */
} stream;

extern void xio_pause(void);

extern VOID mySetRect(PRECTL prectl, LONG xL, LONG yT, LONG xR, LONG yB);

extern LONG TestBinding(PSZ pszTADS);
extern VOID _System BindCode(HWND hwndCaller);
extern VOID _System UnbindCode(HWND hwndCaller);

extern void xtext_init(void);
extern void xtext_free(void);
extern void xtext_add(char ch, long pos);
extern void xtext_replace(long pos, long oldlen, char *buf, long newlen);
extern void xtext_setstyle(long pos, short attr);
extern void xtext_adjust(void);
extern void xtext_resize(short xpos, short ypos, short width, short height);
extern void xtext_get_text_area(RECTL *box);
extern void xtext_redraw(HPS hps);
extern void xtext_hitdown(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum);
extern void xtext_hitmove(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum);
extern void xtext_hitup(short xpos, short ypos, unsigned short button, unsigned short mods, short clicknum);
extern void xtext_end_visible(void);
extern void xtext_set_lastseen(void);
extern void xtext_clear_window(void);
extern void xtext_line_timeout(void);
extern BOOL xtext_find(BOOL fForward, BOOL fCase, char *word);

extern void scroll_splat(short msg);
extern void scroll_to(long newscrollline);

extern char *xkey_get_key_name(short key);
extern void xkey_parse_bindings(char *str);
extern cmdentry *xkey_find_cmd_by_name(char *str);

extern BOOL stuff_kbd_stream(short c);
extern BOOL stuff_kbd_stream_with_string(char *str);

extern VOID SetStatusTextLeft(PSZ pszNewText);
extern VOID StatusInsertLeft(char c);
extern VOID SetStatusTextRight(PSZ pszNewText);
extern VOID ClearStatus(VOID);

extern void SetMessageBoxText(PSZ pszNewText, BOOL bTimeout);

extern void xted_init(int buflen, char *buffer, int *readpos, int *killflag);
extern void xted_insert(short ch);
extern void xted_delete(short op);
extern void xted_enter(short op);
extern void xted_scroll(short op);
extern void xted_movecursor(short op);
extern void xted_movedot(short op);
extern void xted_cutbuf(short op);
extern void xted_history(short op);
extern void xted_option_capability(BOOL *cuttable, BOOL *copyable);
extern void xted_noop(short op);
extern void xtexted_redraw(short op);
extern void xtexted_meta(short op);
extern void xted_macro(short op);
extern void xted_macro_enter(short op);
extern void xted_define_macro_text(short keynum, char *text);
extern void xted_define_macro(short keynum);
extern void xstat_reset_window_size(short op);
extern void xtexted_modify(short keynum, short op);
extern short xtexted_getmodifymode(BOOL clearit);

extern VOID TweakMacroMenus(VOID);

extern void copy_selec_to_clip(char *buf, long len);
extern PSZ copy_clip_to_string(VOID);

extern void XSetUpWindow(HWND win, HPS hps);
extern void XKnowIgnorance(void);
extern void XClearWindow(HPS hps);
extern void XSetFont(HPS hps, LONG font);
extern void XClearArea(HPS hps, LONG xpos, LONG ypos, LONG wid, LONG hgt);
extern void XClipToValid(HWND win, HPS hps);
extern void XDrawString(HPS hps, LONG font, short xpos, short ypos, char *buf, long len);
extern void XDrawReverseString(HPS hps, LONG font, short xpos, short ypos, short fieldwid,
		char *buf, long len);
extern void XFillRectangle(HPS hps, short pattern, short xpos, short ypos, short wid, short hgt);
extern void XFillRectangleColor(HPS hps, LONG lcol, short xpos, short ypos, 
		short wid, short hgt);
extern void XDrawRectangle(HPS hps, short xpos, short ypos, short wid, short hgt);
extern void XDrawLine(HPS hps, short xpos, short ypos, short xpos2, short ypos2);
extern void XCopyArea(HWND win, short xpos, short ypos, short wid, short hgt, 
		short destxpos, short destypos);
extern void XTextExtents(HPS hps, LONG font, char *buf, long len, short *width);
extern void XCharPos(HPS hps, LONG font, char *buf, long len, long *positions);
extern void XShowDot(HWND hwnd, BOOL bFlag);
extern void XDrawDot(HPS hps, short xpos, short ypos);
extern void XBlinkDot(HPS hps);
