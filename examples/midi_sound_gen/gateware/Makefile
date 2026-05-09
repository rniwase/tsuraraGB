PROJ = midi_sound_gen
TOP = cartridge_top
SRCS = \
	../../common/gateware/rtl/led_driver.sv \
	../../common/gateware/rtl/bidir_pad.sv \
	../../common/gateware/rtl/spi_master.sv \
	../../common/gateware/rtl/flash2spram.sv \
	../../common/gateware/rtl/SP256K_4x.sv \
	../../common/gateware/rtl/pipe_buf.sv \
	../../common/gateware/rtl/reset_gen.sv \
	../../common/gateware/rtl/mac.sv \
	./rtl/midi_rx.sv \
	./rtl/uart_rx.sv \
	./rtl/midi_parser.sv \
	./rtl/poly2mono.sv \
	./rtl/ptcam.sv \
	./rtl/nrfreq_table.sv \
	./rtl/nrfreq_interpolator.sv \
	./rtl/cartridge_top.sv
PCF = ../../common/gateware/pin.pcf
OCSBIN = ../../downloads/oss-cad-suite/bin
YOSYS = $(OCSBIN)/yosys
NEXTPNR = $(OCSBIN)/nextpnr-ice40
ICEPACK = $(OCSBIN)/icepack
ICETIME = $(OCSBIN)/icetime
PYTHON = ../../downloads/oss-cad-suite/py3bin/python3

.SUFFIXES: .json .asc .bin .rpt

.PHONY: all prepare build clean

all: prepare build

prepare:
	@ cd ../../; \
	$(MAKE) prepare

build: meminit_nrfreq_table.svh $(PROJ).bin $(PROJ).rpt

meminit_nrfreq_table.svh: scripts/create_nrfreq_table.py
	$(PYTHON) $^ > $@

$(PROJ).json: $(SRCS)
	$(YOSYS) -p 'synth_ice40 -top $(TOP) -json $@' $^

.json.asc:
	$(NEXTPNR) --up5k --package sg48 --asc $@ --pcf $(PCF) --json $<

.asc.bin:
	$(ICEPACK) $< $@

.asc.rpt:
	$(ICETIME) -d up5k -mtr $@ $<

clean:
	rm -f meminit_nrfreq_table.svh *.bin *.json *.rpt
