`include "build_option.sv"

module bidir_pad #(
  parameter WIDTH = 8
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out,
  input  logic [WIDTH-1:0] oe,
  inout  logic [WIDTH-1:0] pad
);

`ifdef USE_RADIANT
  logic [WIDTH-1:0] oe2pad;
  logic [WIDTH-1:0] or2pad;
  logic [WIDTH-1:0] pad2ir;
`endif

  genvar i;
  generate
    for(i = 0; i < WIDTH; i = i + 1) begin: gen_pad_primitive
`ifdef USE_RADIANT
      IOL_B u_IOL_B (
        .PADDI   (pad2ir[i]), // I, from pad to input register input
        .DO1     (     1'b0), // I
        .DO0     (  d_in[i]), // I, from fabric to output register input
        .CE      (     1'b1), // I, clock enable
        .IOLTO   (    oe[i]), // I, from fabric to oe/tristate control
        .HOLD    (     1'b0), // I
        .INCLK   (      clk), // I
        .OUTCLK  (      clk), // I
        .PADDO   (or2pad[i]), // O, from output register to pad
        .PADDT   (oe2pad[i]), // O, from oe/tristate output to pad
        .DI1     (         ), // O
        .DI0     ( d_out[i])  // O, from input register output to fabric
      );
      BB_B u_BB_B (
        .T_N     (oe2pad[i]), // I, from oe/tristate output to pad
        .I       (or2pad[i]), // I, from output register to pad
        .O       (pad2ir[i]), // O, from pad to input register input
        .B       (   pad[i])  // IO, bidirectional pad
      );
`else
      SB_IO #(
        .PIN_TYPE          (  6'b100000),
        .PULLUP            (       1'b0),
        .NEG_TRIGGER       (       1'b0),
        .IO_STANDARD       ("SB_LVCMOS")
      ) SB_IO_i (
        .PACKAGE_PIN       (  pad[i]),
        .LATCH_INPUT_VALUE (    1'b0),
        .CLOCK_ENABLE      (    1'b1),
        .INPUT_CLK         (     clk),
        .OUTPUT_CLK        (     clk),
        .OUTPUT_ENABLE     (   oe[i]),
        .D_OUT_0           ( d_in[i]),
        .D_OUT_1           ( d_in[i]),
        .D_IN_0            (d_out[i]),
        .D_IN_1            (        )
      );
`endif
    end
  endgenerate
endmodule
