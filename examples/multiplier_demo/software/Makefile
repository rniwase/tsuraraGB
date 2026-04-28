PROJ = multiplier_demo
GBDK_HOME = ../../downloads/gbdk
CC = $(GBDK_HOME)/bin/lcc
CFLAGS = -Wa-l -Wl-m -Wl-j

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
