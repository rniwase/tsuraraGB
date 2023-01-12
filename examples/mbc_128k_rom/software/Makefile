CC = lcc
CFLAGS = -Wa-l -Wl-m -Wl-j -Wl-yo8

build: rom_bank_switch.c
	$(CC) $(CFLAGS) -o rom_bank_switch.gb $<

.PHONY: clean
clean:
	rm -f *.map *.gb *.noi
