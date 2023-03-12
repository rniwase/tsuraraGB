/* flash2spram.sv - SPI flash memory to SPRAM loader */

module flash2spram #(
  parameter [23:0] LOAD_OFFSET = 24'h080000,  // in bytes
  parameter [23:0] LOAD_SIZE   = 24'h020000,  // in bytes
  parameter [ 9:0] RESET_TIME  = 10'd700  // 35 us @ clk:20MHz
)(
  input  logic        clk,
  input  logic        reset_n,
  output logic        load_done,

  /* SPRAM 4x interface */
  output logic [16:0] spram_addr,
  output logic        spram_we,
  output logic [ 7:0] spram_wd,

  /* SPI user interface */
  output logic        spi_enable,
  input  logic        spi_idle,
  output logic [ 7:0] spi_tx_len,
  input  logic        spi_tx_fetch,
  output logic [ 7:0] spi_tx_data,
  output logic [23:0] spi_rx_len,
  input  logic        spi_rx_store,
  input  logic [ 7:0] spi_rx_data
);

  typedef enum logic [2:0] {
    S_IDLE,
    S_ENABLE_RESET,
    S_RESET,
    S_WAIT,
    S_READ,
    S_DONE
  } s_f2s;

  s_f2s state;

  logic [ 7:0] CMD_ENABLE_RESET;
  logic [ 7:0] CMD_RESET;
  logic [ 7:0] CMD_READ [0:3];
  logic [ 9:0] wait_count;
  logic [ 1:0] tx_count;
  logic [23:0] rx_count;
  logic [24:0] spram_addr_pre;
  logic        spi_idle_buf;
  logic        spi_idle_rise;
  logic        spi_idle_rise_buf;

  assign CMD_ENABLE_RESET = 8'h66;
  assign CMD_RESET = 8'h99;
  assign CMD_READ[0] = 8'h03;  // Read operation
  assign CMD_READ[1] = LOAD_OFFSET[23:16];  // address [23:16]
  assign CMD_READ[2] = LOAD_OFFSET[15: 8];  // address [15: 8]
  assign CMD_READ[3] = LOAD_OFFSET[ 7: 0];  // address [ 7: 0]

  assign load_done = (state == S_DONE);
  assign spram_addr = spram_addr_pre[16:0];
  assign spi_idle_rise = spi_idle & ~spi_idle_buf;

  always_ff @(posedge clk) begin
    if (~reset_n)
      state <= S_IDLE;

    else begin
      case (state)
        S_IDLE:
          state <= S_ENABLE_RESET;

        S_ENABLE_RESET:
          state <= spi_idle_rise ? S_RESET : S_ENABLE_RESET;

        S_RESET:
          state <= spi_idle_rise ? S_WAIT : S_RESET;

        S_WAIT:
          state <= (wait_count == RESET_TIME) ? S_READ : S_WAIT;

        S_READ:
          state <= spi_idle_rise ? S_DONE : S_READ;

        S_DONE:
          state <= S_DONE;

        default:
          state <= S_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    case (state)
      S_WAIT, S_READ:
        spi_tx_len <= 8'd4;
      default:
        spi_tx_len <= 8'd1;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_WAIT, S_READ:
        spi_rx_len <= LOAD_SIZE;
      default:
        spi_rx_len <= 24'd0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_enable <= 1'b0;
    else begin
      case (state)
        S_IDLE:
          spi_enable <= 1'b1;
        S_ENABLE_RESET:
          spi_enable <= spi_idle_rise;
        S_WAIT:
          spi_enable <= (wait_count == RESET_TIME);
        default:
          spi_enable <= 1'b0;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      tx_count <= 2'd0;
    else if (spi_tx_fetch & (state == S_READ))
      tx_count <= (tx_count == 2'd3) ? tx_count : tx_count + 2'd1;
  end

  always_ff @(posedge clk) begin
    case (state)
      S_IDLE:
        spi_tx_data <= CMD_ENABLE_RESET;

      S_ENABLE_RESET:
        spi_tx_data <= CMD_ENABLE_RESET;

      S_RESET:
        spi_tx_data <= CMD_RESET;

      S_WAIT, S_READ:
        spi_tx_data <= CMD_READ[tx_count];

      default:
        spi_tx_data <= 8'h00;
    endcase
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      rx_count <= 24'd0;
    else
      rx_count <= spi_rx_store ? rx_count + 24'd1 : rx_count;
  end
  
  always_ff @(posedge clk) begin
    spi_idle_buf <= spi_idle;
    wait_count <= (state == S_WAIT) ? wait_count + 10'd1 : 10'd0;
    spram_wd <= spi_rx_data;
    spram_we <= spi_rx_store;
    spram_addr_pre <= spi_rx_store ? rx_count + LOAD_OFFSET : spram_addr_pre;
    spi_idle_rise_buf <= spi_idle_rise;
  end

endmodule
