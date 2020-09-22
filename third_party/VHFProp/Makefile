# Makefile for test VHFProp programs

# C compiler: gcc or clang
CC = gcc

CFLAGS = -O2 -g -I. -Wall
LIBS = -lncurses -lm

PROGRAMS = vhfprop

all: $(PROGRAMS)

vhfprop: vhfprop.ncurses.c
	$(CC) $(CFLAGS) -o $@ $< $(LIBS)

clean:
	rm -f $(PROGRAMS) *o
