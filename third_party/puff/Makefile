X11LIBDIR = /usr/X11R6/lib
PASCALCOMPILER = fpc
CC = gcc
CFLAGS = -O2 -g

POBJS =	puff.o pfart.o pffft.o pfmsc.o pfrw.o pfst.o pfun1.o pfun2.o pfun3.o xgraph.o

# Find the ARCH and use the corresponding lcl-unit path
ARCH := $(shell uname -m)

puff:	$(POBJS) puff_c.o ppas.sh
	sed 's/.res -e _start/.res puff_c.o -lX11 -e _start/' <ppas.sh  >ppasx.sh
	sh ppasx.sh

%.o:	%.pas
	$(PASCALCOMPILER) -g $< -Cn -Fu/usr/lib/lazarus/2.?.?/components/lazutils/lib/$(ARCH)-linux/

ppas.sh:	puff.pas
	$(PASCALCOMPILER) -g -s -a -T puff.pas

# version: 20160612

clean:
	rm -rf puff
	rm -rf *.o
	rm -rf *.s
	rm -rf *.ppu
	rm -rf link*.res
	rm -rf ppas.sh ppasx.sh
