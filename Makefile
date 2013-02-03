INFO = mpdinfo
SLEEP = sleep

CC = gcc
CFLAGS = -Wall -g -Wextra -O2
LDFLAGS = -llua -lmpdclient

OBJ = $(wildcard *.o) $(wildcard *.so) mpdinfo sleep
SRC = $(wildcard *.c)

all: $(OUT) $(SLEEP)

$(SLEEP):
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so -llua $@.c

tags: $(SRC)
	ctags *.c *.h

$(INFO):
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so $(LDFLAGS) $@.c

clean:
	rm $(OBJ)
