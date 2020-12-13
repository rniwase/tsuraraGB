module flash2spram #(
  parameter SPI_LOAD_OFFSET = 24'h080000,  // in bytes
  parameter SPI_LOAD_SIZE   = 24'h020000   // in bytes
)(
  input  logic         clk,
  input  logic         reset_n,
  output logic         load_done,

  /* SPRAM 4x interface */
  output logic  [15:0] spram_addr,
  output logic         spram_we,
  output logic         spram_cs,
  output logic  [15:0] spram_d_write,

  /* SPI Flash interface */
  output logic         spi_ss,
  output logic         spi_so,
  input  logic         spi_si,
  output logic         spi_sck
);

  localparam STATE_IDLE = 2'd0, STATE_WRITE_COMMAND = 2'd1;
  localparam STATE_READ_DATA = 2'd2, STATE_READ_DONE = 2'd3;

  logic [1:0] state;
  logic [4:0] spi_tx_count;
  logic spi_sck_pre;
  logic spi_sck_buf;
  logic store_tmg_pre;
  logic [23:0] a_count;

  always_ff @(posedge clk) begin
    if (~reset_n)
      state <= STATE_IDLE;
    else if (state == STATE_IDLE)
      state <= STATE_WRITE_COMMAND;
    else if ((state == STATE_WRITE_COMMAND) & (spi_tx_count == 0) & ~spi_sck_pre)
      state <= STATE_READ_DATA;
    else if ((state == STATE_READ_DATA) & spi_sck_buf & (a_count == ((SPI_LOAD_SIZE/2)-1)))
      state <= STATE_READ_DONE;
    else
      state <= state;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_sck_pre <= 1'b0;
    else if ((state != STATE_WRITE_COMMAND) & (state != STATE_READ_DATA))
      spi_sck_pre <= 1'b0;
    else
      spi_sck_pre <= ~spi_sck_pre;
  end
  always_ff @(posedge clk)
    spi_sck <= spi_sck_pre;


  always_ff @(posedge clk)
    spi_sck_buf <= spi_sck;

  localparam SPI_FLASH_READ_INST = 8'h03;
  logic [31:0] spi_dout_inst;
  assign spi_dout_inst = {SPI_FLASH_READ_INST, SPI_LOAD_OFFSET};

  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_tx_count <= 5'd31;
    else if (state == STATE_IDLE)
      spi_tx_count <= 5'd31;
    else if ((state == STATE_WRITE_COMMAND) & ~spi_sck_pre)
      spi_tx_count <= spi_tx_count - 5'd1;
    else
      spi_tx_count <= spi_tx_count;
  end

  logic spi_so_pre;
  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_so_pre <= 1'b0;
    else if (state == STATE_WRITE_COMMAND)
      spi_so_pre <= spi_dout_inst[spi_tx_count];
    else
      spi_so_pre <= 1'b0;
  end

  always_ff @(posedge clk)
    spi_so <= spi_so_pre;

  logic spi_ss_pre;
  always_ff @(posedge clk) begin
    if (~reset_n)
      spi_ss_pre <= 1'b1;
    else if (state != STATE_READ_DONE)
      spi_ss_pre <= 1'b0;
    else
      spi_ss_pre <= 1'b1;
  end

  always_ff @(posedge clk)
    spi_ss <= spi_ss_pre;

  logic spi_si_buf;
  always_ff @(posedge clk)
    spi_si_buf <= spi_si;

  logic [3:0] b_count;
  always_ff @(posedge clk) begin
    if (~reset_n)
      b_count <= 4'd15;
    else if (state == STATE_IDLE)
      b_count <= 4'd15;
    else if ((state == STATE_READ_DATA) & ~spi_sck_buf)
      b_count <= b_count - 4'd1;
  end

  logic [15:0] si_shift_logic;
  always_ff @(posedge clk) begin
    if (~spi_sck_buf)
      si_shift_logic <= {si_shift_logic[14:0], spi_si_buf};
    else
      si_shift_logic <= si_shift_logic;
  end

  assign store_tmg_pre = spi_sck_buf & (b_count == 4'd0);
  logic [3:0] store_tmg_pipe;
  always_ff @(posedge clk)
    store_tmg_pipe <= {store_tmg_pipe[2:0], store_tmg_pre};

  logic store_tmg;
  assign store_tmg = store_tmg_pipe[3];

  logic [15:0] store_logic;
  always_ff @(posedge clk) begin
    if (store_tmg)
      store_logic <= {si_shift_logic[7:0], si_shift_logic[15:8]};
    else
      store_logic <= store_logic;
  end

  logic write_tmg;
  always_ff @(posedge clk)
    write_tmg <= store_tmg;

  always_ff @(posedge clk) begin
    spram_we <= write_tmg;
    spram_cs <= write_tmg;
    spram_d_write <= store_logic;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      a_count <= 24'd0;
    else if (state == STATE_IDLE)
      a_count <= 24'd0;
    else if (store_tmg_pre)
      a_count <= a_count + 24'd1;
  end

  logic [15:0] spram_addr_pre;
  always_ff @(posedge clk) begin
    if (~reset_n)
      spram_addr_pre <= 16'd0;
    else if (state == STATE_IDLE)
      spram_addr_pre <= 16'd0;
    else if (write_tmg)
      spram_addr_pre <= spram_addr_pre + 16'd1;
    else
      spram_addr_pre <= spram_addr_pre;
  end

  always_ff @(posedge clk)
    spram_addr <= spram_addr_pre;

  logic [6:0] load_done_pre;
  always_ff @(posedge clk) begin
    if (~reset_n)
      load_done_pre <= 7'd0;
    else
      load_done_pre <= {load_done_pre[5:0], state == STATE_READ_DONE};
  end

  always_ff @(posedge clk)
    load_done <= load_done_pre[6];

endmodule
