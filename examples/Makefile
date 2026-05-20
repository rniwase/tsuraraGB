SUBDIRS := rom_bank_demo midi_sound_gen multiplier_demo

OCS_REL := 2026-04-12
GBDK_VER := 4.5.0
PYFTDI_VER := 0.57.1

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

ifeq ($(UNAME_S),Linux)
  ifeq ($(UNAME_M),x86_64)
    OCS_FNAME := oss-cad-suite-linux-x64-$(subst -,,$(OCS_REL)).tgz
    GBDK_FNAME := gbdk-linux64.tar.gz
  endif
  ifeq ($(UNAME_M),aarch64)
    OCS_FNAME := oss-cad-suite-linux-arm64-$(subst -,,$(OCS_REL)).tgz
    GBDK_FNAME := gbdk-linux-arm64.tar.gz
  endif
endif
ifeq ($(UNAME_S),Darwin)
  ifeq ($(UNAME_M),x86_64)
    OCS_FNAME := oss-cad-suite-darwin-x64-$(subst -,,$(OCS_REL)).tgz
    GBDK_FNAME := gbdk-macos.tar.gz
  endif
  ifeq ($(UNAME_M),arm64)
    OCS_FNAME := oss-cad-suite-darwin-arm64-$(subst -,,$(OCS_REL)).tgz
    GBDK_FNAME := gbdk-macos-arm64.tar.gz
  endif
endif
ifeq ($(OCS_FNAME),)
  $(error unsupported OS: $(UNAME_S) $(UNAME_M))
endif

OCS_URL := https://github.com/YosysHQ/oss-cad-suite-build/releases/download/$(OCS_REL)/$(OCS_FNAME)
GBDK_URL := https://github.com/gbdk-2020/gbdk-2020/releases/download/$(GBDK_VER)/$(GBDK_FNAME)
DL_PATH := ./downloads
PYTHON := $(DL_PATH)/oss-cad-suite/py3bin/python3

.PHONY: all prepare build clean

all: prepare build

prepare:
	@ mkdir -p $(DL_PATH)
	@ if [ ! -e $(DL_PATH)/oss-cad-suite ]; then \
	  echo "--- OSS CAD Suite not found. Downloading."; \
	  curl -L $(OCS_URL) | tar -xz -C $(DL_PATH); \
	fi
	@ if [ ! -e $(DL_PATH)/gbdk ]; then \
	  echo "--- GBDK not found. Downloading."; \
	  curl -L $(GBDK_URL) | tar -xz -C $(DL_PATH); \
	fi
	@ if [ ! -e $(DL_PATH)/oss-cad-suite/lib/python3.11/site-packages/pyftdi ]; then \
	  echo "--- PyFtdi not found. Downloading."; \
	  $(PYTHON) -W ignore -m pip install --disable-pip-version-check pyftdi==$(PYFTDI_VER); \
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
