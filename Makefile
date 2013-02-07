INFO = mpdinfo
SLEEP = sleep

CC = gcc
CFLAGS = -W -Wall -g -Wextra -O2
LDFLAGS = -llua -lmpdclient

OBJ = $(wildcard *.o) $(wildcard *.so) mpdinfo sleep
SRC = $(wildcard *.c) $(wildcard *.h)

all: $(INFO) $(SLEEP)

.PHONY: clean install tags

$(SLEEP): sleep.c
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so -llua $@.c

tags:
	ctags $(SRC)

$(INFO): mpdinfo.c
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so $(LDFLAGS) $@.c

clean:
	rm $(OBJ)

install: $(INFO) $(SLEEP)
	install -m755 mpdinfo.so /usr/lib/lua/5.2/
	install -m755 sleep.so /usr/lib/lua/5.2/
