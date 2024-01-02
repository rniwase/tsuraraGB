SUBDIRS = mbc_128k_rom midi_sound_gen

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

