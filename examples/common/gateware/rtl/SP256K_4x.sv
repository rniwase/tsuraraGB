module SP256K_4x (
  input  logic        clk,
  input  logic [16:0] addr,
  input  logic [ 7:0] din,
  input  logic        wren,
  input  logic        cs,
  input  logic        standby,
  input  logic        sleep,
  input  logic        poweroff_n,
  output logic [ 7:0] dout
);

  logic [15:0] dout_array [0:3];
  logic [15:0] dout_pre;

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin: gen_SP256K_primitive
      SB_SPRAM256KA SB_SPRAM256KA_inst (
        .ADDRESS    (addr[14:1]                            ),
        .DATAIN     ({din, din}                            ),
        .MASKWREN   ({addr[0], addr[0], ~addr[0], ~addr[0]}),
        .WREN       (wren                                  ),
        .CHIPSELECT (cs & (addr[16:15] == i[1:0])          ),
        .CLOCK      (clk                                   ),
        .STANDBY    (standby                               ),
        .SLEEP      (sleep                                 ),
        .POWEROFF   (poweroff_n                            ),
        .DATAOUT    (dout_array[i[1:0]]                    )
      );
    end
  endgenerate

  assign dout_pre = dout_array[addr[16:15]];
  assign dout = addr[0] ? dout_pre[15:8] : dout_pre[7:0];

endmodule
