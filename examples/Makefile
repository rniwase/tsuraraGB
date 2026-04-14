SUBDIRS = mbc_128k_rom midi_sound_gen
OCS_URL = "https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-04-12/oss-cad-suite-linux-x64-20260412.tgz"
GBDK_URL = "https://github.com/gbdk-2020/gbdk-2020/releases/download/4.5.0/gbdk-linux64.tar.gz"
DL_PATH = ./downloads
PYTHON = $(DL_PATH)/oss-cad-suite/py3bin/python3

.PHONY: all prepare build clean

all: prepare build

prepare:
	@ mkdir -p $(DL_PATH)
	@ if [ ! -e $(DL_PATH)/oss-cad-suite ]; then \
		echo "--- OSS CAD Suite not found. Downloading."; \
		mkdir -p $(DL_PATH); \
		wget -c $(OCS_URL) -O - | tar -xz -C $(DL_PATH); \
	fi
	@ if [ ! -e $(DL_PATH)/gbdk ]; then \
		echo "--- GBDK not found. Downloading."; \
		mkdir -p $(DL_PATH); \
		wget -c $(GBDK_URL) -O - | tar -xz -C $(DL_PATH); \
	fi
	@ if [ ! -e $(DL_PATH)/oss-cad-suite/lib/python3.11/site-packages/pyftdi ]; then \
		echo "--- PyFtdi not found. Downloading."; \
		$(PYTHON) -W ignore -m pip install --disable-pip-version-check pyftdi==0.57.1; \
	fi

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
