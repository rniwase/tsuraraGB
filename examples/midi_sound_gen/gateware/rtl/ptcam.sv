/* Pseudo Ternary CAM */

module ptcam #(
  parameter DWIDTH = 19,
  parameter MEMSIZE = 16
)(
  input  logic              clk,
  input  logic              reset_n,

  input  logic [$clog2(MEMSIZE)-1:0] w_addr,
  input  logic [DWIDTH-1:0         ] w_din,
  input  logic [DWIDTH-1:0         ] w_mask,
  input  logic                       w_en,
  input  logic [$clog2(MEMSIZE)-1:0] r_addr,
  output logic [DWIDTH-1:0         ] r_dout,

  input  logic [DWIDTH-1:0         ] search_din,
  input  logic [DWIDTH-1:0         ] search_mask,
  input  logic                       search_en,
  output logic                       search_valid,
  output logic [DWIDTH-1:0         ] search_dout,
  output logic [$clog2(MEMSIZE)-1:0] search_addr_out,
  output logic                       search_notfound
);

  integer i;

  logic [DWIDTH-1:0] mem [0:MEMSIZE-1];

  always_ff @(posedge clk) begin
    if (~reset_n) begin
      for (i=0; i<MEMSIZE; i=i+1)
        mem[i] <= 0;
    end
    else if (w_en)
      mem[w_addr] <= (w_din & w_mask) | (mem[w_addr] & ~w_mask);
  end

  always_ff @(posedge clk)
    r_dout <= mem[r_addr];

  logic [DWIDTH-1:0] search_din_str;
  logic [DWIDTH-1:0] search_mask_str;
  logic [$clog2(MEMSIZE)-1:0] search_addr;
  logic search_busy;

  logic search_match, end_of_search;
  assign search_match = (mem[search_addr] & search_mask_str) == (search_din_str & search_mask_str);
  assign end_of_search = search_addr == MEMSIZE-1;

  always_ff @(posedge clk) begin
    if (~search_busy & search_en) begin
      search_din_str <= search_din;
      search_mask_str <= search_mask;
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      search_busy <= 1'b0;
    else if (search_busy & (search_match | end_of_search))
      search_busy <= 1'b0;
    else if (~search_busy & search_en)
      search_busy <= 1'b1;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      search_addr <= 0;
    else if (search_busy) begin
      if (search_match | end_of_search)
        search_addr <= 0;
      else
        search_addr <= search_addr + 1;
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      search_dout <= 0;
    else if (search_match)
      search_dout <= mem[search_addr];
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      search_addr_out <= 0;
    else if (search_match)
      search_addr_out <= search_addr;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      search_notfound <= 1'b0;
    else if (search_match)
      search_notfound <= 1'b0;
    else if (end_of_search)
      search_notfound <= 1'b1;
  end

  always_ff @(posedge clk)
    search_valid <= search_busy & (end_of_search | search_match);

endmodule
