INFO = mpdinfo
SLEEP = sleep
XMMS = xmmsinfo

CC = gcc
CFLAGS = -W -Wall -g -Wextra -O2
LDFLAGS = -llua5.3 -lmpdclient

OBJ = $(wildcard *.o) $(wildcard *.so) mpdinfo sleep xmmsinfo
SRC = $(wildcard *.c) $(wildcard *.h)

all: $(INFO) $(SLEEP) $(XMMS)

.PHONY: clean install uninstall tags

$(SLEEP): sleep.c
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so -llua $@.c `pkg-config --cflags --libs lua` -DPROGNAME="\"sleep\"" -DVERSION="\"0.1\"" -DDATE="\"`date -u`\""

tags:
	ctags $(SRC)

$(INFO): mpdinfo.c
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so $(LDFLAGS) $@.c `pkg-config --cflags --libs libmpdclient lua` -DPROGNAME="\"mpdinfo\"" -DVERSION="\"0.1\"" -DDATE="\"`date -u`\""

$(XMMS): xmmsinfo.c
	$(CC) $(CFLAGS) -shared -fPIC -o $@.so $< `pkg-config --cflags --libs xmms2-client-glib xmms2-client glib-2.0 lua` -DPROGNAME="\"xmmsinfo\"" -DVERSION="\"0.1\"" -DDATE="\"`date -u`\""

clean:
	rm $(OBJ)

install: $(INFO) $(SLEEP) $(XMMS)
	install -m755 mpdinfo.so /usr/lib/lua/5.2/
	install -m755 sleep.so /usr/lib/lua/5.2/
	install -m755 xmmsinfo.so /usr/lib/lua/5.2/

uninstall:
	rm -f /usr/lib/lua/5.2/mpdinfo.so
	rm -f /usr/lib/lua/5.2/sleep.so
	rm -f /usr/lib/lua/5.2/xmmsinfo.so
