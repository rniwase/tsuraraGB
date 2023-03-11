/* radiant_prims.sv - Wrapper modules to convert primitives from iCEcube2 (or yosys) to Radiant */

// Note: This file is loaded only if the environment variable USE_RAIDANT=1 is set.
//       Only primitives necessary for the example are implemented, and propagation of some parameters is ignored.

module SB_IO #(
  parameter [5:0] PIN_TYPE    = 6'b100000,
  parameter       PULLUP      = 1'b0,
  parameter       NEG_TRIGGER = 1'b0,
  parameter       IO_STANDARD = "SB_LVCMOS"
)(
  inout  logic PACKAGE_PIN,
  input  logic LATCH_INPUT_VALUE,
  input  logic CLOCK_ENABLE,
  input  logic INPUT_CLK,
  input  logic OUTPUT_CLK,
  input  logic OUTPUT_ENABLE,
  input  logic D_OUT_0,
  input  logic D_OUT_1,
  output logic D_IN_0,
  output logic D_IN_1
);

  logic oe2pad, or2pad, pad2ir;

  IOL_B u_IOL_B (
    .PADDI   (pad2ir           ),  // I, from pad to input register input
    .DO1     (D_OUT_1          ),  // I
    .DO0     (D_OUT_0          ),  // I, from fabric to output register input
    .CE      (CLOCK_ENABLE     ),  // I, clock enable
    .IOLTO   (OUTPUT_ENABLE    ),  // I, from fabric to oe/tristate control
    .HOLD    (LATCH_INPUT_VALUE),  // I
    .INCLK   (INPUT_CLK        ),  // I
    .OUTCLK  (OUTPUT_CLK       ),  // I
    .PADDO   (or2pad           ),  // O, from output register to pad
    .PADDT   (oe2pad           ),  // O, from oe/tristate output to pad
    .DI1     (D_IN_1           ),  // O
    .DI0     (D_IN_0           )   // O, from input register output to fabric
  );

  BB_B u_BB_B (
    .T_N     (oe2pad           ),  // I, from oe/tristate output to pad
    .I       (or2pad           ),  // I, from output register to pad
    .O       (pad2ir           ),  // O, from pad to input register input
    .B       (PACKAGE_PIN      )   // IO, bidirectional pad
  );

endmodule

module SB_RGBA_DRV #(
  parameter CURRENT_MODE = "0b0",
  parameter RGB0_CURRENT = "0b111111",
  parameter RGB1_CURRENT = "0b111111",
  parameter RGB2_CURRENT = "0b111111"
) (
  input  logic CURREN,
  input  logic RGBLEDEN,
  input  logic RGB0PWM,
  input  logic RGB1PWM,
  input  logic RGB2PWM,
  output logic RGB0,
  output logic RGB1,
  output logic RGB2
);

  RGB #(
    .CURRENT_MODE (CURRENT_MODE == "0b0" ? 0 : 1),
    .RGB0_CURRENT (RGB0_CURRENT),
    .RGB1_CURRENT (RGB1_CURRENT),
    .RGB2_CURRENT (RGB2_CURRENT)
  ) RGB_inst (
    .CURREN   (CURREN  ),
    .RGBLEDEN (RGBLEDEN),
    .RGB0PWM  (RGB0PWM ),
    .RGB1PWM  (RGB1PWM ),
    .RGB2PWM  (RGB2PWM ),
    .RGB0     (RGB0    ),
    .RGB1     (RGB1    ),
    .RGB2     (RGB2    )
  );

endmodule

module SB_SPRAM256KA (
  input  logic [13:0] ADDRESS,
  input  logic [15:0] DATAIN,
  input  logic [ 3:0] MASKWREN,
  input  logic        WREN,
  input  logic        CHIPSELECT,
  input  logic        CLOCK,
  input  logic        STANDBY,
  input  logic        SLEEP,
  input  logic        POWEROFF,
  output logic [15:0] DATAOUT
);

  SP256K SP256K_inst (
    .CK         (CLOCK     ),
    .AD         (ADDRESS   ),
    .DI         (DATAIN    ),
    .MASKWE     (MASKWREN  ),
    .WE         (WREN      ),
    .CS         (CHIPSELECT),
    .STDBY      (STANDBY   ),
    .SLEEP      (SLEEP     ),
    .PWROFF_N   (POWEROFF  ),
    .DO         (DATAOUT   )
  );

endmodule