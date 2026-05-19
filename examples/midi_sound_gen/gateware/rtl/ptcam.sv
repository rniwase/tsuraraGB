/* ptcam.sv - Pseudo Ternary Content Addressable Memory */

module ptcam #(
  parameter DWIDTH = 16,
  parameter DEPTH = 16,
  localparam AWIDTH = $clog2(DEPTH)
)(
  input  logic              clk,
  input  logic              resetn,

  input  logic [AWIDTH-1:0] w_addr,      // Write address
  input  logic [DWIDTH-1:0] w_din,       // Write data input
  input  logic [DWIDTH-1:0] w_mask,      // Write data mask
  input  logic              w_en,        // Write enable

  input  logic [AWIDTH-1:0] r_addr,      // Read address
  output logic [DWIDTH-1:0] r_dout,      // Read data output

  input  logic [DWIDTH-1:0] s_din,       // Search data input
  input  logic [DWIDTH-1:0] s_mask,      // Search data mask
  input  logic              s_en,        // Search enable
  output logic              s_valid,     // Search result valid
  output logic [DWIDTH-1:0] s_dout,      // Search result data output
  output logic [AWIDTH-1:0] s_addr_out,  // Search result address
  output logic              s_notfound   // Search result not found
);

  int i;

  logic [DWIDTH-1:0] mem [0:DEPTH-1];
  logic [DWIDTH-1:0] s_din_str, s_mask_str;
  logic [AWIDTH-1:0] s_addr;
  logic search_match, end_of_mem;
  assign search_match = (mem[s_addr] & s_mask_str) == (s_din_str & s_mask_str);
  assign end_of_mem = (s_addr == DEPTH-1);

  typedef enum logic [1:0] {
    S_IDLE,
    S_SEARCH,
    S_MATCH,
    S_NOT_FOUND
  } t_state;

  t_state state;

  always_ff @(posedge clk) begin
    for (i = 0; i < DEPTH; i++) begin
      if (~resetn)
        mem[i] <= 'd0;
      else
        mem[i] <= w_en & (w_addr == i) ? (w_din & w_mask) | (mem[i] & ~w_mask) : mem[i];
    end
  end

  always_ff @(posedge clk)
    r_dout <= mem[r_addr];

  always_ff @(posedge clk) begin
    if (~resetn)
      state <= S_IDLE;
    else begin
      case (state)
        S_IDLE:
          state <= t_state'(s_en ? S_SEARCH : S_IDLE);
        S_SEARCH: begin
          if (search_match)
            state <= S_MATCH;
          else if (end_of_mem)
            state <= S_NOT_FOUND;
          else
            state <= S_SEARCH;
        end
        S_MATCH,
        S_NOT_FOUND:
          state <= S_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE) begin
      s_din_str <= s_din;
      s_mask_str <= s_mask;
    end
    else begin
      s_din_str <= s_din_str;
      s_mask_str <= s_mask_str;
    end
  end

  always_ff @(posedge clk) begin
    case (state)
      S_IDLE:
        s_addr <= 'd0;
      S_SEARCH:
        s_addr <= search_match ? s_addr : s_addr + AWIDTH'(1);
      default:
        s_addr <= s_addr;
    endcase
  end

  always_ff @(posedge clk) begin
    s_dout <= (state == S_MATCH) ? mem[s_addr] : s_dout;
    s_addr_out <= (state == S_MATCH) ? s_addr : s_addr_out;
    s_valid <= (state == S_MATCH) | (state == S_NOT_FOUND);
    s_notfound <= (state == S_NOT_FOUND);
  end

endmodule
