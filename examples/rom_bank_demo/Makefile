PROJ = rom_bank_demo
SUBDIRS = gateware software
PYTHON = ../downloads/oss-cad-suite/py3bin/python3
TGBFLASH = ../tools/tgbflash.py

.PHONY: all prepare build clean flash

all: build

prepare:
	@ cd ../; \
	$(MAKE) prepare

build:
	@ for d in $(SUBDIRS); do \
		cd $$d; \
		$(MAKE); \
		cd ..; \
	done

clean:
	@ for d in $(SUBDIRS); do \
		cd $$d; \
		$(MAKE) $@; \
		cd ..; \
	done

flash: prepare
	$(PYTHON) $(TGBFLASH) \
	--file ./gateware/$(PROJ).bin ./software/$(PROJ).gb \
	--offset 0x000000 0x080000 \
	--erase --verify
