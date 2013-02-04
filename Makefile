INFO = mpdinfo
SLEEP = sleep

CC = gcc
CFLAGS = -Wall -g -Wextra -O2
LDFLAGS = -llua -lmpdclient

OBJ = $(wildcard *.o) $(wildcard *.so) mpdinfo sleep
SRC = $(wildcard *.c)

all: $(INFO) $(SLEEP)

$(SLEEP):
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so -llua $@.c

tags: $(SRC)
	ctags *.c *.h

$(INFO):
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so $(LDFLAGS) $@.c

clean:
	rm $(OBJ)

install: $(OUT) $(SLEEP)
	install -m755 mpdinfo.so /usr/lib/lua/5.2/
	install -m755 sleep.so /usr/lib/lua/5.2/
