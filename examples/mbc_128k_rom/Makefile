SUBDIRS = gateware software

.PHONY: build
build:
	@ for d in $(SUBDIRS); do \
		cd $$d; \
		$(MAKE); \
		cd ..; \
	done

.PHONY: clean
clean:
	@ for d in $(SUBDIRS); do \
		cd $$d; \
		$(MAKE) $@; \
		cd ..; \
	done

.PHONY: prog
prog:
ifeq ($(USE_RADIANT),1)
	python3 ../../programmer/tgb-prog.py \
	--file ./gateware/impl_1/mbc_128k_rom_impl_1.bin ./software/rom_bank_switch.gb \
	--offset 0x000000 0x080000 \
	--erase --verify
else
	python3 ../../programmer/tgb-prog.py \
	--file ./gateware/mbc_128k_rom.bin ./software/rom_bank_switch.gb \
	--offset 0x000000 0x080000 \
	--erase --verify
endif
