`timescale 1 ns / 1 ns

module poly2mono_testbench;

  initial begin
    $dumpfile("poly2mono_testbench.vcd");
    $dumpvars;
  end

  parameter CLK_CYCLE = 50;
  parameter MAX_VOICE = 8;

  logic       clk;
  logic       reset_n;
  logic       busy;
  logic       v_valid_in;
  logic       v_noteon_in;
  logic       v_noteoff_in;
  logic [6:0] v_note_num_in;
  logic [6:0] v_note_vel_in;
  logic       note_act_out;
  logic [6:0] note_num_out;
  logic [6:0] note_vel_out;

  logic       fail;

  integer i;

  poly2mono #(.MAX_VOICE(MAX_VOICE)) poly2mono_inst (.*);

  task update_input (
    input logic       noteon,
    input logic       noteoff,
    input logic [6:0] num,
    input logic [6:0] vel
  );
    v_valid_in <= 1'b1;
    v_noteon_in <= noteon;
    v_noteoff_in <= noteoff;
    v_note_num_in <= num;
    v_note_vel_in <= vel;
    @(posedge clk);
    v_valid_in <= 1'b0;
    @(posedge clk);
    $display(
      "   input: noteon=%b, noteoff=%b, num=%x, vel=%x",
      v_noteon_in, v_noteoff_in, v_note_num_in, v_note_vel_in
    );
  endtask

  task check_output (
    input logic       act,
    input logic [6:0] num,
    input logic [6:0] vel
  );
    logic int_fail;
    int_fail = 1'b0;
    wait (~busy);
    @(posedge clk);
    if (act)
      int_fail = (note_act_out != act) | (note_num_out != num) | (note_vel_out != vel);
    else
      int_fail = (note_act_out != act);
    fail = fail | int_fail;
    @(posedge clk);
    $display(
      "  output:    act=%b,            num=%x, vel=%x (%s)",
      note_act_out, note_num_out, note_vel_out, int_fail ? "FAIL" : "PASS"
    );
  endtask

  initial begin
    clk <= 1'b1;
    forever
      #(CLK_CYCLE/2) clk <= ~clk;
  end

  initial begin
    v_valid_in <= 1'b0;
    v_noteon_in <= 1'b0;
    v_note_num_in <= 7'h0;
    v_note_vel_in <= 7'h0;
    reset_n <= 1'b0;
    fail <= 1'b0;

    repeat (10) @(posedge clk);
    reset_n <= 1'b1;
    repeat (10) @(posedge clk);

    $display("Check reset status");
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    $display("Note on (1,1) -> (1,1)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h01), .vel(7'h01));
    check_output(.act   (1'b1),                 .num(7'h01), .vel(7'h01));

    $display("Note on (1,2) -> (1,2) : update velocity");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h01), .vel(7'h02));
    check_output(.act   (1'b1),                 .num(7'h01), .vel(7'h02));

    $display("Note on (2,3) -> [1,2],(2,3)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h02), .vel(7'h03));
    check_output(.act   (1'b1),                 .num(7'h02), .vel(7'h03));

    $display("Note on (3,4) -> [1,2],[2,3],(3,4)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h03), .vel(7'h04));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note off (3,4) -> [1,2],(2,3)");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h03), .vel(7'hxx));
    check_output(.act   (1'b1),                 .num(7'h02), .vel(7'h03));

    $display("Note on (3,4) -> [1,2],[2,3],(3,4)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h03), .vel(7'h04));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note off (2,3) -> [1,2],(3,4)");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h02), .vel(7'hxx));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note on (2,3) -> [1,2],[3,4],(2,3)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h02), .vel(7'h03));
    check_output(.act   (1'b1),                 .num(7'h02), .vel(7'h03));

    $display("Note off (2,3) -> [1,2],(3,4)");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h02), .vel(7'hxx));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note on (4,5) -> [1,2],[3,4],(4,5)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h04), .vel(7'h05));
    check_output(.act   (1'b1),                 .num(7'h04), .vel(7'h05));

    $display("Note off (4,5) -> [1,2],(3,4)");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h04), .vel(7'hxx));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note off (1,2) -> (3,4)");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h01), .vel(7'hxx));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h04));

    $display("Note off (3,4) -> no activities");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h03), .vel(7'hxx));
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    $display("Testing maximum voices with ascending ordered note off");
    for (i = 0; i < MAX_VOICE; i = i + 1) begin
      update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h10 + i), .vel(7'h7F));
      check_output(.act   (1'b1),                 .num(7'h10 + i), .vel(7'h7F));
    end
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h7F                ), .vel(7'h7F));  // MAX_VOICE + 1 -> ignore
    check_output(.act   (1'b1),                 .num(7'h10 + MAX_VOICE - 1), .vel(7'h7F));

    for (i = 0; i < MAX_VOICE - 1; i = i + 1) begin
      repeat (10) @(posedge clk);
      update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h10 + i            ), .vel(7'hxx));
      check_output(.act   (1'b1),                 .num(7'h10 + MAX_VOICE - 1), .vel(7'h7F));
    end
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h10 + MAX_VOICE - 1), .vel(7'hxx));
    check_output(.act   (1'b0),                 .num(7'hxx                ), .vel(7'hxx));

    $display("Testing maximum voices with descending ordered note off");
    for (i = 0; i < MAX_VOICE; i = i + 1) begin
      update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h10 + i), .vel(7'h7F));
      check_output(.act   (1'b1),                 .num(7'h10 + i), .vel(7'h7F));
    end
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h7F        ), .vel(7'h7F));  // MAX_VOICE + 1 -> ignore
    check_output(.act   (1'b1),                 .num(7'h10 + i - 1), .vel(7'h7F));

    for (i = MAX_VOICE - 1; i > 0; i = i - 1) begin
      repeat (10) @(posedge clk);
      update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h10 + i    ), .vel(7'hxx));
      check_output(.act   (1'b1),                 .num(7'h10 + i - 1), .vel(7'hFF));
    end
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h10), .vel(7'hxx));
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    $display("Note on (1,1) -> (1,1)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h01), .vel(7'h01));
    check_output(.act   (1'b1),                 .num(7'h01), .vel(7'h01));

    $display("Note on and off (1,1) using note-on with zero velocity -> no activity");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h01), .vel(7'h00));
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    $display("Note on (2,2) -> (2,2)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h02), .vel(7'h02));
    check_output(.act   (1'b1),                 .num(7'h02), .vel(7'h02));

    $display("Reset and check status");
    reset_n <= 1'b0;
    @(posedge clk);
    reset_n <= 1'b1;
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    $display("Note on (3,3) -> (3,3)");
    update_input(.noteon(1'b1), .noteoff(1'b0), .num(7'h03), .vel(7'h03));
    check_output(.act   (1'b1),                 .num(7'h03), .vel(7'h03));

    $display("Note off (3,3) -> no activities");
    update_input(.noteon(1'b0), .noteoff(1'b1), .num(7'h03), .vel(7'hxx));
    check_output(.act   (1'b0),                 .num(7'hxx), .vel(7'hxx));

    repeat (10) @(posedge clk);

    if (fail)
      $fatal(0, "Test FAILED");

    $display("Test PASSED");
    $finish;
  end

endmodule
