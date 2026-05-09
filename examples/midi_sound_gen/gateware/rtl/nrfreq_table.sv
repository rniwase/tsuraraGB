module nrfreq_table #(
  parameter OUTPUT_REG = 1'b1
)(
  input  logic        clk,
  input  logic [ 7:0] table_in,
  output logic [15:0] table_out
);

  logic [15:0] mem_rdata, table_out_reg;

  SB_RAM40_4K #(
    .WRITE_MODE (0),
    .READ_MODE  (0)
  ) SB_RAM40_4K_freq_table_inst (
    .RDATA (mem_rdata),
    .RCLK  (clk      ),
    .RCLKE (1'b1     ),
    .RE    (1'b1     ),
    .RADDR (table_in ),
    .WCLK  (clk      ),
    .WCLKE (1'b0     ),
    .WE    (1'b0     ),
    .WADDR (8'h00    ),
    .MASK  (16'h0000 ),
    .WDATA (16'h0000 )
  );

  `include "meminit_nrfreq_table.svh"

  always_ff @(posedge clk)
    table_out_reg <= mem_rdata;

  assign table_out = OUTPUT_REG ? table_out_reg : mem_rdata;

endmodule