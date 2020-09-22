# Makefile
VERSION = 3.02
CC      = /usr/bin/gcc
OBJ	 = postpuff.o 
CFLAGS  = -Wall
#CFLAGS  = -Wall -ggdb
LDFLAGS = -lm `pkg-config --cflags --libs gtk+-2.0`
PRG 	= post-puff

$(PRG): $(OBJ)
	$(CC) $(CFLAGS) -o $(PRG) $(OBJ) $(LDFLAGS)

%.o: %.c
	$(CC) $(CFLAGS) -c $< $(LDFLAGS)

clean:
	rm -f $(PRG) *~ *.o a.out
