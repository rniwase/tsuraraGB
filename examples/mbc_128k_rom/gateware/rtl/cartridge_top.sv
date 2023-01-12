module cartridge_top (
  /* Clock input */
  input  logic        clk_20M,

  /* Cartridge bus interface */
  input  logic [15:0] bus_A,
  inout  logic [ 7:0] bus_D,
  output logic        bus_D_dir,
  input  logic        bus_nRD,
  input  logic        bus_nWR,
  output logic        cpu_reset,

  /* SPI flash memory */
  output logic        SPI_ss,
  output logic        SPI_so,
  input  logic        SPI_si,
  output logic        SPI_sck,

  /* LED */
  output logic [ 2:0] LED,

  /* unused */
  output logic        IO0,
  output logic        IO1,
  output logic        vin
);

  logic        reset_n;
  logic        load_done;

  logic        spi_enable;
  logic        spi_idle;
  logic [ 7:0] spi_tx_len;
  logic        spi_tx_fetch;
  logic [ 7:0] spi_tx_data;
  logic [23:0] spi_rx_len;
  logic        spi_rx_store;
  logic [ 7:0] spi_rx_data;

  logic [16:0] loader_addr;
  logic [ 7:0] loader_wd;
  logic        loader_we;

  logic [16:0] cart_addr;
  logic [ 7:0] cart_rd;

  logic [15:0] bus_A_s;
  logic [ 7:0] bus_D_in;
  logic [ 7:0] bus_D_in_s;
  logic [ 7:0] bus_D_out;
  logic [ 7:0] bus_D_oe;
  logic [20:0] bus_nWR_buf;
  logic        wr_posedge;
  logic [ 2:0] rom_bank;

  assign cart_addr = {(bus_A_s[15:14] == 2'b00) ? 3'd0 : rom_bank, bus_A_s[13:0]};
  assign bus_D_dir = bus_nRD | bus_A[15];  // L: read (cartridge -> GB), H: write (GB -> cartridge)
  assign bus_D_oe = {8{~bus_D_dir}};

  assign IO0 = 1'bx;
  assign IO1 = 1'bx;
  assign vin = 1'bx;

  always_ff @(posedge clk_20M) begin
    if (~reset_n)
      rom_bank <= 3'd1;
    else if (wr_posedge & (bus_A_s[15:13] == 3'b001))  // bus : 2000 - 3FFF
      rom_bank <= (bus_D_in_s[2:0] == 3'd0) ? 3'd1 : bus_D_in_s[2:0];
    else
      rom_bank <= rom_bank;
  end

  always_ff @(posedge clk_20M) begin
    cpu_reset <= ~load_done;
    bus_nWR_buf <= {bus_nWR_buf[19:0], bus_nWR};
    wr_posedge <= ~bus_nWR_buf[3] & bus_nWR_buf[2];
    bus_D_out <= cart_rd;
  end

  reset_gen reset_gen_inst (
    .clk         (clk_20M),
    .reset_n_out (reset_n)
  );

  spi_master #(
    .DIV_RATE   (8'd0        ),
    .INPUT_SYNC (4'd5        )
  ) spi_master_inst (
    .clk        (clk_20M     ),
    .reset_n    (reset_n     ),
    .enable     (spi_enable  ),
    .idle       (spi_idle    ),
    .tx_len     (spi_tx_len  ),
    .tx_fetch   (spi_tx_fetch),
    .tx_data    (spi_tx_data ),
    .rx_len     (spi_rx_len  ),
    .rx_store   (spi_rx_store),
    .rx_data    (spi_rx_data ),
    .spi_ss     (SPI_ss      ),
    .spi_so     (SPI_so      ),
    .spi_si     (SPI_si      ),
    .spi_sck    (SPI_sck     )
  );

  flash2spram #(
    .LOAD_OFFSET  (24'h080000  ),  // in bytes
    .LOAD_SIZE    (24'h020000  ),  // in bytes
    .RESET_TIME   (10'd700     )
  ) flash2spram_inst (
    .clk          (clk_20M     ),
    .reset_n      (reset_n     ),
    .load_done    (load_done   ),
    .spram_addr   (loader_addr ),
    .spram_we     (loader_we   ),
    .spram_wd     (loader_wd   ),
    .spi_enable   (spi_enable  ),
    .spi_idle     (spi_idle    ),
    .spi_tx_len   (spi_tx_len  ),
    .spi_tx_fetch (spi_tx_fetch),
    .spi_tx_data  (spi_tx_data ),
    .spi_rx_len   (spi_rx_len  ),
    .spi_rx_store (spi_rx_store),
    .spi_rx_data  (spi_rx_data )
  );

  /*
  bus : 0000 - 3FFF -> cart : 00000 - 01FFF
  bus : 4000 - 7FFF -> cart : 02000 - 03FFF (bank 0, 1)
                       cart : 04000 - 05FFF (bank 2)
                       cart : 06000 - 07FFF (bank 3)
                       cart : 08000 - 09FFF (bank 4)
                       cart : 0A000 - 0BFFF (bank 5)
                       ...
                       cart : 3E000 - 3FFFF (bank 31)
  */

  SP256K_4x SP256K_4x_inst (
    .clk        (clk_20M                            ),
    .addr       (load_done ? cart_addr : loader_addr),
    .din        (loader_wd                          ),
    .dout       (cart_rd                            ),
    .wren       (loader_we                          ),
    .cs         (1'b1                               ),
    .standby    (1'b0                               ),
    .sleep      (1'b0                               ),
    .poweroff_n (1'b1                               )
  );

  bidir_pad bus_D_pad (
    .clk       (clk_20M   ),
    .d_in      (bus_D_out ),
    .d_out     (bus_D_in  ),
    .oe        (bus_D_oe  ),
    .pad       (bus_D     )
  );

  pipe_buf #(
    .WIDTH     (        16),
    .NUM_STAGE (         4)
  ) sync_bus_A (
    .clk       (clk_20M   ),
    .din       (bus_A     ),
    .dout      (bus_A_s   )
  );

  pipe_buf #(
    .WIDTH     (         8),
    .NUM_STAGE (         4)
  ) sync_bus_D_in (
    .clk       (clk_20M   ),
    .din       (bus_D_in  ),
    .dout      (bus_D_in_s)
  );

  led_driver led_driver_inst (
    .din (rom_bank[2:0]),
    .pad (LED          )
  );

endmodule
