module spi_master #(
  parameter    [ 7:0] DIV_RATE = 8'd1,
  parameter    [ 3:0] INPUT_SYNC = 4'd5
)(
  input  logic        clk,
  input  logic        reset_n,

  /* User interface */
  input  logic        enable,
  output logic        idle,
  input  logic [ 7:0] tx_len,
  output logic        tx_fetch,
  input  logic [ 7:0] tx_data,
  input  logic [23:0] rx_len,
  output logic        rx_store,
  output logic [ 7:0] rx_data,

  /* SPI pads */
  output logic        spi_ss,  // Slave select output
  output logic        spi_so,  // Master data output, slave data input
  input  logic        spi_si,  // Master data input, slave data output
  output logic        spi_sck  // Serial clock output
);

  typedef enum logic [2:0] {
    S_IDLE,
    S_WAIT,
    S_CS_ASSERT,
    S_TRANSMIT,
    S_RECEIVE,
    S_CS_NEGATE,
    S_DONE
  } s_spi;

  s_spi state;

  logic [ 7:0] tx_len_store;
  logic [23:0] rx_len_store;

  logic [ 7:0] tx_count;
  logic [ 7:0] tx_data_store;
  logic [ 7:0] divcount;
  logic [ 3:0] bitcount;
  logic [23:0] rx_count;
  logic [ 7:0] rx_data_shift;
  logic        spi_si_buf;
  logic [INPUT_SYNC-2:0] spi_si_pipe;
  logic        spi_si_sync;
  logic        divmatch;
  logic        bitend;

  logic        spi_sck_pre;
  logic        spi_so_pre;
  logic        spi_ss_pre;

  logic        sck_rise;
  logic [INPUT_SYNC:0] sck_rise_buf;
  logic        sck_rise_sync;

  logic [INPUT_SYNC+2:0] bitend_buf;

  logic [INPUT_SYNC+2:0] is_reveice_buf;

  assign idle = (state == S_IDLE);
  assign divmatch = (divcount == DIV_RATE);
  assign bitend = (&bitcount) & divmatch;
  assign tx_fetch = bitend & ((state == S_CS_ASSERT) | ((state == S_TRANSMIT) & (tx_count != (tx_len_store - 8'd1)))) & (|tx_len_store);
  assign spi_si_sync = spi_si_pipe[INPUT_SYNC-2];
  assign sck_rise = divmatch & spi_sck_pre;
  assign sck_rise_sync = sck_rise_buf[INPUT_SYNC];

  always_ff @(posedge clk) begin
    if (~reset_n)
      state <= S_IDLE;
    else begin
      case (state)
        S_IDLE: begin
          if (enable)
            state <= S_WAIT;
          else
            state <= S_IDLE;
        end

        S_WAIT: begin
          if ((~|tx_len_store) & (~|rx_len_store))
            state <= S_IDLE;
          else if (bitend)
            state <= S_CS_ASSERT;
          else
            state <= S_WAIT;
        end

        S_CS_ASSERT: begin
          if (bitend)
            state <= (~|tx_len_store) ? S_RECEIVE : S_TRANSMIT;
          else
            state <= S_CS_ASSERT;
        end

        S_TRANSMIT: begin
          if (bitend & (tx_count == (tx_len_store - 8'd1)))
            state <= (~|rx_len_store) ? S_CS_NEGATE : S_RECEIVE;
          else
            state <= S_TRANSMIT;
        end

        S_RECEIVE: begin
          if (bitend & (rx_count == (rx_len_store - 24'd1)))
            state <= S_CS_NEGATE;
          else
            state <= S_RECEIVE;
        end

        S_CS_NEGATE: begin
          if (bitend)
            state <= S_DONE;
          else
            state <= S_CS_NEGATE;
        end

        S_DONE:
          state <= S_IDLE;

        default:
          state <= S_IDLE;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (idle) begin
      tx_len_store <= tx_len;
      rx_len_store <= rx_len;
    end
    else begin
      tx_len_store <= tx_len_store;
      rx_len_store <= rx_len_store;
    end
  end

  always_ff @(posedge clk) begin
    if (idle) begin
      divcount <= 8'd0;
      bitcount <= 4'd0;
    end
    else begin
      divcount <= divmatch ? 8'd0 : divcount + 8'd1;
      bitcount <= divmatch ? bitcount + 4'd1 : bitcount;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_TRANSMIT)
      tx_count <= bitend ? tx_count + 4'd1 : tx_count;
    else
      tx_count <= 8'd0;
  end

  always_ff @(posedge clk) begin
    if (tx_fetch)
      tx_data_store <= tx_data;
    else
      tx_data_store <= tx_data_store;
  end

  always_ff @(posedge clk) begin
    if (state == S_RECEIVE)
      rx_count <= bitend ? rx_count + 4'd1 : rx_count;
    else
      rx_count <= 8'd0;
  end

  always_ff @(posedge clk) begin
    if (sck_rise_sync)
      rx_data_shift <= {rx_data_shift[6:0], spi_si_sync};
    else
      rx_data_shift <= rx_data_shift;
  end

  always_ff @(posedge clk) begin
    if (bitend_buf[INPUT_SYNC+2])
      rx_data <= rx_data_shift;
    else
      rx_data <= rx_data;
  end

  always_ff @(posedge clk) begin
    case (state)
      S_TRANSMIT, S_RECEIVE:
        spi_sck_pre <= bitcount[0];

      default:
        spi_sck_pre <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_TRANSMIT:
        spi_so_pre <= tx_data_store[3'd7 - bitcount[3:1]];

      default:
        spi_so_pre <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_ss_pre <= 1'b1;
    else begin
      case (state)
        S_IDLE, S_WAIT:
          spi_ss_pre <= 1'b1;

        default:
          spi_ss_pre <= 1'b0;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    spi_si_pipe <= {spi_si_pipe[INPUT_SYNC-3:0], spi_si_buf};
    sck_rise_buf <= {sck_rise_buf[INPUT_SYNC-1:0], sck_rise};
    bitend_buf <= {bitend_buf[INPUT_SYNC+1:0], bitend};
    is_reveice_buf <= {is_reveice_buf[INPUT_SYNC+1:0], state == S_RECEIVE};
    rx_store <= bitend_buf[INPUT_SYNC+2] & is_reveice_buf[INPUT_SYNC+2];
  end

  always_ff @(posedge clk) begin
    spi_sck <= spi_sck_pre;
    spi_si_buf <= spi_si;
    spi_so <= spi_so_pre;
    spi_ss <= spi_ss_pre;
  end

endmodule
