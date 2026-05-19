/* reset_gen.sv - Reset signal generator */

module reset_gen #(
  parameter ASSERT_LEN = 63
)(
  input  logic clk,
  output logic resetn_out
);

  localparam CNT_WIDTH = $clog2(ASSERT_LEN + 1);;

  logic [CNT_WIDTH-1:0] count;
  logic count_match;
  assign count_match = (count == ASSERT_LEN);

  initial begin
    count <= CNT_WIDTH'(0);
    resetn_out <= 1'b0;
  end

  always_ff @(posedge clk) begin
    count <= count_match ? count : count + CNT_WIDTH'(1);
    resetn_out <= count_match;
  end

endmodule
