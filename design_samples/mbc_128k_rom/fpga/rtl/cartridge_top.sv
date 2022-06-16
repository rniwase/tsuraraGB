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

  logic reset_n;
  reset_gen reset_gen_i (
    .clk         (clk_20M),
    .reset_n_out (reset_n)
  );

  logic [ 7:0] bus_D_in;
  logic [ 7:0] bus_D_out;
  logic [ 7:0] bus_D_oe;

  bidir_pad bidir_pad_i (
    .clk    (clk_20M  ),
    .d_in   (bus_D_out),
    .d_out  (bus_D_in ),
    .oe     (bus_D_oe ),
    .pad    (bus_D    )
  );

  logic load_done;
  logic [15:0] loader_addr;
  logic loader_we;
  logic loader_cs;
  logic [15:0] loader_d_write;

  flash2spram #(
    .SPI_LOAD_OFFSET  (24'h080000    ),
    .SPI_LOAD_SIZE    (24'h020000    )   // 128kB
  ) flash2spram_i (
    .clk              (clk_20M       ),
    .reset_n          (reset_n       ),
    .load_done        (load_done     ),
    .spram_addr       (loader_addr   ),
    .spram_we         (loader_we     ),
    .spram_cs         (loader_cs     ),
    .spram_d_write    (loader_d_write),
    .spi_ss           (SPI_ss        ),
    .spi_so           (SPI_so        ),
    .spi_si           (SPI_si        ),
    .spi_sck          (SPI_sck       )
  );

  logic [15:0] bus_A_s;
  pipe_buf #(
    .WIDTH     (     16),
    .NUM_STAGE (      4)
  ) sync_bus_A (
    .clk       (clk_20M),
    .din       (bus_A  ),
    .dout      (bus_A_s)
  );

  logic [20:0] bus_nWR_buf;
  always_ff @(posedge clk_20M)
    bus_nWR_buf <= {bus_nWR_buf[19:0], bus_nWR};

  logic wr_posedge;
  always_ff @(posedge clk_20M)
    wr_posedge <= ~bus_nWR_buf[3] & bus_nWR_buf[2];

  logic [7:0] bus_D_in_s;
  pipe_buf #(
    .WIDTH     (         8),
    .NUM_STAGE (         4)
  ) sync_bus_D_in (
    .clk       (clk_20M   ),
    .din       (bus_D_in  ),
    .dout      (bus_D_in_s)
  );

  logic [2:0] rom_bank;
  always_ff @(posedge clk_20M) begin
    if (~reset_n)
      rom_bank <= 3'd1;
    else if (wr_posedge & (bus_A_s[15:13] == 3'b001))  // bus : 2000 - 3FFF
      rom_bank <= (bus_D_in_s[2:0] == 3'd0) ? 3'd1 : bus_D_in_s[2:0];
    else
      rom_bank <= rom_bank;
  end

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
  logic [15:0] spram_dout;
  logic [15:0] cart_addr;
  logic [15:0] spram_addr;
  assign spram_addr = load_done ? cart_addr : loader_addr;
  assign cart_addr = {(bus_A_s[15:14] == 2'b00) ? 3'd0 :
                      rom_bank, bus_A_s[13:1]};

  SP256K_4x SP256K_4x_i (
    .CK       (clk_20M              ),
    .AD       (spram_addr           ),
    .DI       (loader_d_write       ),
    .MASKWE   (                 4'hF),
    .WE       (loader_we            ),
    .CS       (load_done | loader_cs),
    .STDBY    (                 1'b0),
    .SLEEP    (                 1'b0),
    .PWROFF_N (                 1'b1),
    .DO       (spram_dout           )
  );

  always_ff @(posedge clk_20M)
    cpu_reset <= ~load_done;

  // L: read (cartridge -> GB), H: write (GB -> cartridge)
  assign bus_D_dir = bus_nRD | bus_A[15];

  logic [7:0] bus_D_out_buf;
  always_ff @(posedge clk_20M)
    bus_D_out_buf <= bus_A_s[0] ? spram_dout[15:8] : spram_dout[7:0];

  assign bus_D_out = bus_D_out_buf;
  assign bus_D_oe = {8{~(bus_nRD | bus_A[15])}};

  led_driver led_driver_i (
    .din (rom_bank[2:0]),
    .pad (LED          )
  );

  assign IO0 = 1'bx;
  assign IO1 = 1'bx;
  assign vin = 1'bx;

endmodule
