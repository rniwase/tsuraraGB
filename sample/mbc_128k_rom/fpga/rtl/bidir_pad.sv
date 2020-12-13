module bidir_pad #(
  parameter WIDTH = 8
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] d_in,
  output logic [WIDTH-1:0] d_out,
  input  logic [WIDTH-1:0] oe,
  inout  logic [WIDTH-1:0] pad
);

  logic [WIDTH-1:0] oe2pad;
  logic [WIDTH-1:0] or2pad;
  logic [WIDTH-1:0] pad2ir;

  genvar i;
  generate
    for(i = 0; i < WIDTH; i = i + 1) begin: gen_pad_primitive
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
    end
  endgenerate
endmodule
