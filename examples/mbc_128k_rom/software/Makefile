CC = /opt/gbdk/bin/lcc
CFLAGS = -Wa-l -Wl-m -Wl-j -Wl-yo8

build: mbc_128k_rom.c
	$(CC) $(CFLAGS) -o mbc_128k_rom.gb $<

.PHONY: clean
clean:
	rm -f *.map *.gb *.noi
