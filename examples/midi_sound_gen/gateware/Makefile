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
	./rtl/midi_rx.sv \
	./rtl/uart_rx.sv \
	./rtl/midi_parser.sv \
	./rtl/poly2mono.sv \
	./rtl/ptcam.sv \
	./rtl/cartridge_top.sv
PCF = ../../common/gateware/pin.pcf
LDC = ../../common/gateware/pin.ldc

RADIANT_TCL = \
	prj_create \
		-name "$(PROJ)" \
		-impl "impl_1" \
		-dev iCE40UP5K-SG48I \
		-performance "High-Performance_1.2V" \
		-synthesis "lse"; \
	prj_add_source ./build_option.sv $(SRCS) $(LDC); \
	prj_run Synthesis -impl impl_1; \
	prj_run Map -impl impl_1; \
	prj_run PAR -impl impl_1; \
	prj_run Export -impl impl_1; \
	prj_save; \
	prj_close;

.SUFFIXES: .json .asc .bin .rpt

ifeq ($(USE_RADIANT),1)
all:
	echo "\`define USE_RADIANT" > build_option.sv
	echo "$(RADIANT_TCL)" | radiantc
else
all: $(PROJ).bin $(PROJ).rpt
endif

$(PROJ).json: $(SRCS)
	echo "" > build_option.sv
	yosys -p 'synth_ice40 -top $(TOP) -json $@' $^

.json.asc:
	nextpnr-ice40 --up5k --package sg48 --asc $@ --pcf $(PCF) --json $<

.asc.bin:
	icepack $< $@

.asc.rpt:
	icetime -d up5k -mtr $@ $<

.PHONY: clean
clean:
ifeq ($(USE_RADIANT),1)
	rm -rf *.rdf *.sty .*.ini *.xml *.html *.log .recovery *.dir/ impl_1/ build_option.sv
else
	rm *.bin *.json *.rpt build_option.sv
endif
