SIMS = \
	ptcam_testbench.vcd \
	poly2mono_testbench.vcd \
	midi_parser_testbench.vcd \
	midi_rx_testbench.vcd

IVERILOG = ../../../downloads/oss-cad-suite/bin/iverilog
VVP = ../../../downloads/oss-cad-suite/bin/vvp

.SUFFIXES: .sv .out .vcd

.PHONY: all prepare build clean

all: prepare build

prepare:
	@ cd ../../../; \
	$(MAKE) prepare

build: $(SIMS)

ptcam_testbench.out: ../rtl/ptcam.sv ptcam_testbench.sv
	$(IVERILOG) -g2012 $^ -o $@

poly2mono_testbench.out: ../rtl/ptcam.sv ../rtl/poly2mono.sv poly2mono_testbench.sv
	$(IVERILOG) -g2012 $^ -o $@

midi_parser_testbench.out: ../rtl/midi_parser.sv midi_parser_testbench.sv
	$(IVERILOG) -g2012 $^ -o $@

midi_rx_testbench.out: ../rtl/uart_rx.sv ../rtl/ptcam.sv ../rtl/poly2mono.sv ../rtl/midi_parser.sv ../rtl/midi_rx.sv uart_tx.sv midi_rx_testbench.sv
	$(IVERILOG) -g2012 $^ -o $@

.out.vcd:
	$(VVP) $<

clean:
	rm -f *.out *.vcd
