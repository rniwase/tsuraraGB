module SP256K_4x (
  input  logic        CK,
  input  logic [15:0] AD,
  input  logic [15:0] DI,
  input  logic [ 3:0] MASKWE,
  input  logic        WE,
  input  logic        CS,
  input  logic        STDBY,
  input  logic        SLEEP,
  input  logic        PWROFF_N,
  output logic [15:0] DO
);

  logic [15:0] DO_array [0:3];

  genvar i;
  generate
    for (i = 0; i < 4; i = i + 1) begin: gen_SP256K_primitive
      SP256K SP256K_i (
        .*,
        .AD (AD[13:0]                  ),
        .CS (CS & (AD[15:14] == i[1:0])),
        .DO (DO_array[i]               )
      );
    end
  endgenerate

  assign DO = DO_array[AD[15:14]];

endmodule
