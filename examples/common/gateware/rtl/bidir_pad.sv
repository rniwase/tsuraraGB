module bidir_pad #(
  parameter WIDTH = 8
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out,
  input  logic [WIDTH-1:0] oe,
  inout  logic [WIDTH-1:0] pad
);

  genvar i;
  generate
    for(i = 0; i < WIDTH; i = i + 1) begin: gen_pad_primitive
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
    end
  endgenerate

endmodule
