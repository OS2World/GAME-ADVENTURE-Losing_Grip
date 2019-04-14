#
# OS/2 with GCC and the EMX library
#
CC=gcc
#OPTIMIZE=-O2 -funroll-loops -fomit-frame-pointer -m486 
OPTIMIZE=
CFLAGS= $(OPTIMIZE) -DOS_2 -Zomf -Zsys
AFLAGS=
OVLFLG=
LIBS=
MAKEXEC=touch

#
# Places to look for include files.
#
INCLUDES=-I. -Ictads -Ihtads

#
# TADS files
#
# library object files
LIBOBJS= ler.obj

COMMONOBJS= $(LIBOBJS) mcm.obj mcs.obj mch.obj obj.obj cmd.obj \
            errmsg.obj dummy.obj fioxor.obj oserr.obj runstat.obj \
	    fio.obj getstr.obj

CMNRUNOBJS= $(COMMONOBJS) dat.obj lst.obj run.obj out.obj voc.obj bif.obj output.obj suprun.obj

# objects for run-time
RUNOBJS= vocab.obj execmd.obj ply.obj qas.obj

# extra objects for character-mode run-time
CHAROBJS= bifgdum.obj osgen.obj

TROBJS = $(CMNRUNOBJS) $(RUNOBJS) linfdum.obj $(CHAROBJS) trd.obj dbgtr.obj

MODULES = tadsos2.obj os2ctls.obj os2emux.obj os2text.obj clip.obj stream.obj os2kbd.obj os2io.obj \
	os_depend.obj os2bound.obj $(TROBJS)

.SUFFIXES: .c .obj .exe

all: tadsos2.exe

#tadsos2.exe: tadsos2 tadsos2.res
#	emxbind -bp -rtadsos2.res /emx/bin/emxl tadsos2

tadsos2.exe: $(MODULES) tadsos2.res
	$(CC) $(CFLAGS) $(MODULES) tadsos2.def tadsos2.res $(LIBS)

tadsos2.res: tadsos2.rc tadsos2.h
	rc -i \emx\include -r tadsos2.rc

.c.obj:
	$(CC) -c $(CFLAGS) $(INCLUDES) $*.c

#.c.o:
#	$(CC) -c $(OPTIMIZE) $(UNIXPATCHLEVEL) $(CFLAGS) $(INCLUDES) $*.c

#
# Copy in the files we need
#
bif.c: ctads\bif.c
	copy ctads\bif.c bif.c
bifgdum.c: ctads\bifgdum.c
	copy ctads\bifgdum.c bifgdum.c
cmd.c: ctads\cmd.c
	copy ctads\cmd.c cmd.c
dat.c: ctads\dat.c
	copy ctads\dat.c dat.c
dbgtr.c: ctads\dbgtr.c
	copy ctads\dbgtr.c dbgtr.c
dummy.c: ctads\dummy.c
	copy ctads\dummy.c dummy.c
errmsg.c: ctads\errmsg.c
	copy ctads\errmsg.c errmsg.c
execmd.c: ctads\execmd.c
	copy ctads\execmd.c execmd.c
fio.c: ctads\fio.c
	copy ctads\fio.c fio.c
fioxor.c: ctads\fioxor.c
	copy ctads\fioxor.c fioxor.c
getstr.c: ctads\getstr.c
	copy ctads\getstr.c getstr.c
ler.c: ctads\ler.c
	copy ctads\ler.c ler.c
linfdum.c: ctads\linfdum.c
	copy ctads\linfdum.c linfdum.c
lst.c: ctads\lst.c
	copy ctads\lst.c lst.c
mch.c: ctads\mch.c
	copy ctads\mch.c mch.c
mcm.c: ctads\mcm.c
	copy ctads\mcm.c mcm.c
mcs.c: ctads\mcs.c
	copy ctads\mcs.c mcs.c
obj.c: ctads\obj.c
	copy ctads\obj.c obj.c
oserr.c: ctads\oserr.c
	copy ctads\oserr.c oserr.c
osgen.c: ctads\osgen.c
	copy ctads\osgen.c osgen.c
out.c: ctads\out.c
	copy ctads\out.c out.c
output.c: ctads\output.c
	copy ctads\output.c output.c
ply.c: ctads\ply.c
	copy ctads\ply.c ply.c
qas.c: ctads\qas.c
	copy ctads\qas.c qas.c
run.c: ctads\run.c
	copy ctads\run.c run.c
runstat.c: ctads\runstat.c
	copy ctads\runstat.c runstat.c
suprun.c: ctads\suprun.c
	copy ctads\suprun.c suprun.c
trd.c: ctads\trd.c
	copy ctads\trd.c trd.c
voc.c: ctads\voc.c
	copy ctads\voc.c voc.c
vocab.c: ctads\vocab.c
	copy ctads\vocab.c vocab.c

#
# Clean up. 
#
# In addition to removing .obj's and binaries, this
# also removes files copied from the general source directory.
#
clean:
	del *.obj
#	del tadsc tadsr tdb
#	del tadsc.static tadsr.static
#	del tadsc.notstripped tadsr.notstripped tdb.notstripped
#	del tadsc.exe tadsr.exe tdb.exe
	del bif.c
	del bifgdum.c
	del cmd.c
	del dat.c
	del dbgtr.c
	del dummy.c
	del errmsg.c
	del execmd.c
	del fio.c
	del fioxor.c
	del getstr.c
	del ler.c
	del linfdum.c
	del lst.c
	del mch.c
	del mcm.c
	del mcs.c
	del obj.c
	del oserr.c
	del osgen.c
	del out.c
	del output.c
	del ply.c
	del qas.c
	del run.c
	del runstat.c
	del suprun.c
	del trd.c
	del voc.c
	del vocab.c
