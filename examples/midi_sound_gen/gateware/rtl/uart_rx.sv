/* uart_rx.sv - UART receiver, Num. of stop bit: 1, No parity bit */

module uart_rx #(
  parameter NUM_SYNC_STAGE = 5,    // Number of input synchronizer stages (>=2)
  parameter BAUDGEN_PERIOD = 640   // System clock frequency / UART Baud rate
                                   // (e.g.) 20[MHz] / 31.25[kbps] = 640
)(
  input  logic       clk,      // System clock input
  input  logic       reset_n,  // Reset input
  input  logic       rx_in,    // UART RX input
  output logic       valid,    // Data valid output
  output logic [7:0] d_out,    // Data output
  output logic       f_error   // Flaming error output
);

  localparam BAUDGEN_PERIOD_HALF = BAUDGEN_PERIOD / 2;

  logic [NUM_SYNC_STAGE-1:0] rx_buf;
  logic                      rx_sync;
  logic                      baudgen_valid;
  logic [              15:0] baudgen_t_count;
  logic [               4:0] baudgen_b_count;
  logic                      baudgen_t_match, endofrx;
  logic                      sample_tmg;
  logic [               8:0] d_shiftreg;  // 8(data) + 1(stop bit)

  assign rx_sync = rx_buf[NUM_SYNC_STAGE-1];
  assign baudgen_t_match = baudgen_t_count == BAUDGEN_PERIOD_HALF-1;
  assign endofrx = baudgen_valid & baudgen_b_count == 5'd19;
  assign sample_tmg = baudgen_t_match & ~baudgen_b_count[0];

  always_ff @(posedge clk)
    rx_buf <= {rx_buf[NUM_SYNC_STAGE-2:0], rx_in};

  always_ff @(posedge clk) begin
    if (~reset_n)
      baudgen_valid <= 1'b0;
    else if (endofrx)
      baudgen_valid <= 1'b0;
    else if (~baudgen_valid & ~rx_sync)
      baudgen_valid <= 1'b1;
    else
      baudgen_valid <= baudgen_valid;
  end

  always_ff @(posedge clk) begin
    if (~baudgen_valid)
      baudgen_t_count <= 16'd0;
    else
      baudgen_t_count <= baudgen_t_match ? 16'd0 : baudgen_t_count + 16'd1;
  end

  always_ff @(posedge clk) begin
    if (~baudgen_valid)
      baudgen_b_count <= 5'd0;
    else
      baudgen_b_count <= baudgen_t_match ? baudgen_b_count + 5'd1 : baudgen_b_count;
  end

  always_ff @(posedge clk)
    d_shiftreg <= sample_tmg ? {rx_sync, d_shiftreg[8:1]} : d_shiftreg;

  always_ff @(posedge clk) begin
    if (~reset_n)
      d_out <= 8'd0;
    else
      d_out <= endofrx ? d_shiftreg[7:0] : d_out;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      f_error <= 1'b0;
    else
      f_error <= endofrx ? ~d_shiftreg[8] : f_error;
  end

  always_ff @(posedge clk)
    valid <= endofrx;

endmodule
