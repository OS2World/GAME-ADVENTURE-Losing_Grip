/* open text file for reading; returns NULL on error */
/* osfildef *osfoprt(char *fname); */
#define osfoprt(fname) fopen(fname, "r")

/* open source file for reading */
/* osfildef *osfoprs(char *fname); */
#define osfoprs(fname) osfoprt(fname)

/* open binary file for writing; returns NULL on error */
/* osfildef *osfopwb(char *fname); */
#define osfopwb(fname) fopen(fname, "wb")

/* open binary file for reading; returns NULL on erorr */
/* osfildef *osfoprb(char *fname); */
#define osfoprb(fname) fopen(fname, "rb")

/* open binary file for reading/writing; truncate; returns NULL on error */
/* osfildef *osfoprwb(char *fname); */
#define osfoprwtb(fname) fopen(fname, "w+b")

/* open binary file for reading/writing; don't truncate */
/* osfildef *osfoprwb(char *fname); */
#define osfoprwb(fname) fopen(fname, "r+b")

/* open text file for reading */
#define osfoprt(fname) fopen(fname, "r")

/* open text file for writing */
#define osfopwt(fname) fopen(fname, "w")

/* get a line of text from a text file (fgets semantics) */
/* char *osfgets(char *buf, size_t len, osfildef *fp); */
#define osfgets(buf, len, fp) fgets(buf, len, fp)

/* get a character from a file */
#define osfgetc(fp) fgetc(fp)

/* write bytes to file; TRUE ==> error */
/* int osfwb(osfildef *fp, uchar *buf, int bufl); */
#define osfwb(fp, buf, bufl) (fwrite(buf, bufl, 1, fp) != 1)

/* read bytes from file; TRUE ==> error */
/* int osfrb(osfildef *fp, uchar *buf, int bufl); */
#define osfrb(fp, buf, bufl) (fread(buf, bufl, 1, fp) != 1)

/* get position in file */
/* long osfpos(osfildef *fp); */
#define osfpos(fp) ftell(fp)

/* seek position in file; TRUE ==> error */
/* int osfseek(osfildef *fp, long pos, int mode); */
#define osfseek(fp, pos, mode) fseek(fp, pos, mode)
#define OSFSK_SET  SEEK_SET
#define OSFSK_CUR  SEEK_CUR
#define OSFSK_END  SEEK_END

/* close a file */
/* void osfcls(osfildef *fp); */
#define osfcls(fp) fclose(fp)

/* delete a file - TRUE if error */
/* int osfdel(char *fname); */
#define osfdel(fname) remove(fname)

/* access a file - 0 if file exists */
/* int osfacc(char *fname) */
#define osfacc(fname) access(fname, 0)

/* Random options for this OS */
#define USE_PATHSEARCH

#define os_printf(f) (os_printf_real((f), 0, 0, 0, 0))
#define os_printf1(f, a1) (os_printf_real((f), (long)(a1), 0, 0, 0))
#define os_printf2(f, a1, a2) (os_printf_real((f), (long)(a1), (long)(a2), 0, 0))
#define os_printf3(f, a1, a2, a3) (os_printf_real((f), (long)(a1), (long)(a2), (long)(a3), 0))
#define os_printf4(f, a1, a2, a3, a4) (os_printf_real((f), (long)(a1), (long)(a2), (long)(a3), (long)(a4)))

extern void os_printf_real(char *f, long a1, long a2, long a3, long a4);

extern void os_flush(void);

extern char *os_gets(char *s, int buflen);

extern int os_hilite(int flag);

extern void os_clear_screen(void);

extern void os_rand(long *seed);

extern void os_defext(char *buf, char *ext);

extern osfildef *os_exeseek(char *filenm, char *ext);

extern osfildef *os_create_tempfile(char *filenm, char *deffilenm);

extern void os_expause(void);

extern void os_waitc(void);

extern unsigned char os_getc(void);

extern int (*os_exfld(osfildef *fp, unsigned len))(void);

extern int (*os_exfil(char *filenm))(void);

/*extern int os_excall(int (*funcptr)(void), struct runuxdef *ux);*/

extern int os_break(void);

extern void os_csr_busy(int flag);

extern void os_settype(char *filenm, int typeval);

extern int os_paramfile(char *filbuf);

extern int os_askfile(char *prompt, char *buf, int bufsiz);

extern void os_score(int numer, int denom);

extern void os_strsc(char *str);

extern void os_status(int flag);

extern void os_get_tmp_path(char *s);
