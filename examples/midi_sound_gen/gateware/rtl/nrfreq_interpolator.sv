module nrfreq_interpolator (
  input  logic               clk,
  input  logic        [15:0] din,  // unsigned Q7.9 fixed point format for semitone step
  output logic signed [15:0] dout,
);

  logic        [ 7:0] din_h, din_l, din_h_delta;

  logic        [ 7:0] table_in;
  logic signed [15:0] table_out, table_out_0, table_out_1, table_out_delta, table_out_interpolated;

  logic signed [16:0] mult_in_a, mult_in_b;
  logic signed [31:0] mult_out;

  logic               toggle;

  assign din_h = din[15:8];
  assign din_l = din[ 7:0];

  nrfreq_table table_inst (
    .clk       (clk      ),
    .table_in  (table_in ),
    .table_out (table_out)
  );

  mult_16x16 #(
    .REG_INPUT    (1'b1),
    .REG_INTERNAL (1'b1),
    .REG_OUTPUT   (1'b1),
    .A_SIGNED     (1'b0),
    .B_SIGNED     (1'b0)
  ) mult_inst (
    .clk  (clk      ),
    .in_a (mult_in_a),
    .in_b (mult_in_b),
    .out  (mult_out )
  );

  always_ff @(posedge clk) begin
    toggle <= ~toggle;
    table_in <= toggle ? din_h + 7'd1 : din_h;
    table_out_0 <= toggle ? table_out : table_out_0;
    table_out_1 <= ~toggle ? table_out : table_out_1;
    table_out_delta <= table_out_1 - table_out_0;
    table_out_interpolated <= table_out_0 + mult_out[23:8];
    dout <= (table_out_interpolated < 0) ? 16'sd0 :
            (table_out_interpolated > 2047) ? 16'sd2047 : table_out_interpolated;
  end

  assign mult_in_a = table_out_delta;
  assign mult_in_b = {8'd0, din_l};

endmodule