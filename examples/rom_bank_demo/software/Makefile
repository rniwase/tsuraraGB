PROJ = rom_bank_demo
GBDK_HOME = ../../downloads/gbdk
CC = $(GBDK_HOME)/bin/lcc
CFLAGS = -Wa-l -Wl-m -Wl-j -Wm-yo16 -Wm-ya0

.PHONY: all prepare build clean

all: prepare build

prepare:
	@ cd ../../; \
	$(MAKE) prepare

build: $(PROJ).gb

%.gb: %.c
	$(CC) $(CFLAGS) -o $@ $<

clean:
	rm -f *.map *.gb *.noi
