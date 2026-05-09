module mult_8x8 #(
  parameter [0:0] REG_INPUT  = 1'b1,
  parameter [0:0] REG_OUTPUT = 1'b1,
  parameter       A_SIGNED   = 1'b0,
  parameter       B_SIGNED   = 1'b0
)(
  input  logic        clk,
  input  logic [ 7:0] in_a,
  input  logic [ 7:0] in_b,
  output logic [15:0] out
);
  logic [15:0] mac_in_a, mac_in_b;
  logic [31:0] mac_out;

  assign mac_in_a = {8'd0, in_a};
  assign mac_in_b = {8'd0, in_b};
  assign out = mac_out[15:0];

  SB_MAC16 #(
    .NEG_TRIGGER              (1'b0      ),  //          - Input clock polarity
    .C_REG                    (1'b1      ),  // C0       - Input C register control
    .A_REG                    (REG_INPUT ),  // C1       - Input A register control
    .B_REG                    (REG_INPUT ),  // C2       - Input B register control
    .D_REG                    (1'b1      ),  // C3       - Input D register control
    .TOP_8x8_MULT_REG         (1'b1      ),  // C4       - Top 8 x 8 multiplier output register control
    .BOT_8x8_MULT_REG         (REG_OUTPUT),  // C5       - Bottom 8 x 8 multiplier output register control
    .PIPELINE_16x16_MULT_REG1 (1'b1      ),  // C6       - 16 x 16 Multiplier pipeline register control
    .PIPELINE_16x16_MULT_REG2 (1'b1      ),  // C7       - 16 x 16 Multiplier output register control
    .TOPOUTPUT_SELECT         (2'b00     ),  // C9,  C8  - Top output select
    .TOPADDSUB_LOWERINPUT     (2'b00     ),  // C11, C10 - Input X of upper adder/subtractor
    .TOPADDSUB_UPPERINPUT     (1'b0      ),  // C12      - Input W of upper adder/subtractor
    .TOPADDSUB_CARRYSELECT    (2'b00     ),  // C14, C13 - Carry input select, Top adder/subtractor
    .BOTOUTPUT_SELECT         (2'b10     ),  // C16, C15 - Bottom output select
    .BOTADDSUB_LOWERINPUT     (2'b00     ),  // C18, C17 - Input Z of upper adder/subtractor
    .BOTADDSUB_UPPERINPUT     (1'b0      ),  // C19      - Input Y of upper adder/subtractor
    .BOTADDSUB_CARRYSELECT    (2'b00     ),  // C21, C20 - Carry input select, Bottom adder/subtractor
    .MODE_8x8                 (1'b1      ),  // C22      - Select 8 x 8 Multiplier mode
    .A_SIGNED                 (A_SIGNED  ),  // C23      - Input A sign
    .B_SIGNED                 (B_SIGNED  )   // C24      - Input B sign
  ) SB_MAC16_inst_8x8 (
    .CLK        (clk         ),  // i       - Clock input
    .CE         (1'b1        ),  // i       - Clock enable input
    .A          ({8'b0, in_a}),  // i[15:0] - Input data A
    .AHOLD      (1'b0        ),  // i       - Register A hold input
    .B          ({8'b0, in_b}),  // i[15:0] - Input data B
    .BHOLD      (1'b0        ),  // i       - Register B hold input
    .C          (16'd0       ),  // i[15:0] - Input data C
    .CHOLD      (1'b1        ),  // i       - Register C hold input
    .D          (16'd0       ),  // i[15:0] - Input data D
    .DHOLD      (1'b1        ),  // i       - Register D hold input
    .IRSTTOP    (1'b0        ),  // i       - Reset input to registers A and C
    .ORSTTOP    (1'b0        ),  // i       - Reset input to top accumulator register
    .OLOADTOP   (1'b0        ),  // i       - Load control input to top accumulator register
    .ADDSUBTOP  (1'b0        ),  // i       - Add/Subtract control input to top accumulator
    .OHOLDTOP   (1'b0        ),  // i       - Top accumulator output register hold input
    .IRSTBOT    (1'b0        ),  // i       - Reset input to registers A and C
    .ORSTBOT    (1'b0        ),  // i       - Reset input to bottom accumulator register
    .OLOADBOT   (1'b0        ),  // i       - Load control input to bottom accumulator register
    .ADDSUBBOT  (1'b0        ),  // i       - Add/Subtract control input to bottom accumulator
    .OHOLDBOT   (1'b0        ),  // i       - Bottom accumulator output register hold input
    .O          (mac_out     ),  // o[31:0] - Output Data
    .CI         (1'b0        ),  // i       - Cascaded adder/subtractor carry input from previous DSP block
    .CO         (            ),  // o       - Cascaded adder/subtractor carry output to next DSP block
    .ACCUMCI    (1'b0        ),  // i       - Cascaded accumulator carry input from previous DSP block
    .ACCUMCO    (            ),  // o       - Cascaded accumulator carry output to next DSP block
    .SIGNEXTIN  (1'b0        ),  // i       - Sign extension input from previous DSP block
    .SIGNEXTOUT (            )   // o       - Sign extension output to next DSP block
  );

endmodule

module mult_16x16 #(
  parameter [0:0] REG_INPUT    = 1'b1,
  parameter [0:0] REG_INTERNAL = 1'b1,
  parameter [0:0] REG_OUTPUT   = 1'b1,
  parameter       A_SIGNED     = 1'b0,
  parameter       B_SIGNED     = 1'b0
)(
  input  logic        clk,
  input  logic [15:0] in_a,
  input  logic [15:0] in_b,
  output logic [31:0] out
);

  SB_MAC16 #(
    .NEG_TRIGGER              (1'b0        ),  //          - Input clock polarity
    .C_REG                    (1'b1        ),  // C0       - Input C register control
    .A_REG                    (REG_INPUT   ),  // C1       - Input A register control
    .B_REG                    (REG_INPUT   ),  // C2       - Input B register control
    .D_REG                    (1'b1        ),  // C3       - Input D register control
    .TOP_8x8_MULT_REG         (REG_INTERNAL),  // C4       - Top 8 x 8 multiplier output register control
    .BOT_8x8_MULT_REG         (REG_INTERNAL),  // C5       - Bottom 8 x 8 multiplier output register control
    .PIPELINE_16x16_MULT_REG1 (REG_INTERNAL),  // C6       - 16 x 16 Multiplier pipeline register control
    .PIPELINE_16x16_MULT_REG2 (REG_OUTPUT  ),  // C7       - 16 x 16 Multiplier output register control
    .TOPOUTPUT_SELECT         (2'b11       ),  // C9,  C8  - Top output select
    .TOPADDSUB_LOWERINPUT     (2'b00       ),  // C11, C10 - Input X of upper adder/subtractor
    .TOPADDSUB_UPPERINPUT     (1'b0        ),  // C12      - Input W of upper adder/subtractor
    .TOPADDSUB_CARRYSELECT    (2'b00       ),  // C14, C13 - Carry input select, Top adder/subtractor
    .BOTOUTPUT_SELECT         (2'b11       ),  // C16, C15 - Bottom output select
    .BOTADDSUB_LOWERINPUT     (2'b00       ),  // C18, C17 - Input Z of upper adder/subtractor
    .BOTADDSUB_UPPERINPUT     (1'b0        ),  // C19      - Input Y of upper adder/subtractor
    .BOTADDSUB_CARRYSELECT    (2'b00       ),  // C21, C20 - Carry input select, Bottom adder/subtractor
    .MODE_8x8                 (1'b0        ),  // C22      - Select 8 x 8 Multiplier mode
    .A_SIGNED                 (A_SIGNED    ),  // C23      - Input A sign
    .B_SIGNED                 (B_SIGNED    )   // C24      - Input B sign
  ) SB_MAC16_inst_16x16 (
    .CLK        (clk         ),  // i       - Clock input
    .CE         (1'b1        ),  // i       - Clock enable input
    .A          (in_a        ),  // i[15:0] - Input data A
    .AHOLD      (1'b0        ),  // i       - Register A hold input
    .B          (in_b        ),  // i[15:0] - Input data B
    .BHOLD      (1'b0        ),  // i       - Register B hold input
    .C          (16'd0       ),  // i[15:0] - Input data C
    .CHOLD      (1'b1        ),  // i       - Register C hold input
    .D          (16'd0       ),  // i[15:0] - Input data D
    .DHOLD      (1'b1        ),  // i       - Register D hold input
    .IRSTTOP    (1'b0        ),  // i       - Reset input to registers A and C
    .ORSTTOP    (1'b0        ),  // i       - Reset input to top accumulator register
    .OLOADTOP   (1'b0        ),  // i       - Load control input to top accumulator register
    .ADDSUBTOP  (1'b0        ),  // i       - Add/Subtract control input to top accumulator
    .OHOLDTOP   (1'b0        ),  // i       - Top accumulator output register hold input
    .IRSTBOT    (1'b0        ),  // i       - Reset input to registers A and C
    .ORSTBOT    (1'b0        ),  // i       - Reset input to bottom accumulator register
    .OLOADBOT   (1'b0        ),  // i       - Load control input to bottom accumulator register
    .ADDSUBBOT  (1'b0        ),  // i       - Add/Subtract control input to bottom accumulator
    .OHOLDBOT   (1'b0        ),  // i       - Bottom accumulator output register hold input
    .O          (out         ),  // o[31:0] - Output Data
    .CI         (1'b0        ),  // i       - Cascaded adder/subtractor carry input from previous DSP block
    .CO         (            ),  // o       - Cascaded adder/subtractor carry output to next DSP block
    .ACCUMCI    (1'b0        ),  // i       - Cascaded accumulator carry input from previous DSP block
    .ACCUMCO    (            ),  // o       - Cascaded accumulator carry output to next DSP block
    .SIGNEXTIN  (1'b0        ),  // i       - Sign extension input from previous DSP block
    .SIGNEXTOUT (            )   // o       - Sign extension output to next DSP block
  );

endmodule