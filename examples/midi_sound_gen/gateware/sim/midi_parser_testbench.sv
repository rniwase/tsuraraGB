`timescale 1 ns / 1 ns

module midi_parser_testbench;

  initial begin
    $dumpfile("midi_parser_testbench.vcd");
    $dumpvars;
  end

  parameter CLK_CYCLE = 50;

  int i;

  logic        clk;
  logic        resetn;

  logic [ 7:0] d_in;               // Data input
  logic        d_valid;            // Data valid input
  logic        v_valid;            // Voice message is valid
  logic [ 3:0] v_channel;          // Channel number
  logic        v_noteoff;          // Voice message is note-off
  logic        v_noteon;           // Voice message is note-on
  logic [ 6:0] v_note_num;         // Note number
  logic [ 6:0] v_note_vel;         // Note velocity
  logic        v_keypressure;      // Voice message is polyphonic key pressure
  logic [ 6:0] v_keypressure_num;  // Polyphonic key pressure note number
  logic [ 6:0] v_keypressure_val;  // Polyphonic key pressure value
  logic        v_control;          // Voice message is control change
  logic [ 6:0] v_control_num;      // Control change number
  logic [ 6:0] v_control_val;      // Control change value
  logic        v_program;          // Voice message is program change
  logic [ 6:0] v_program_num;      // Program change number
  logic        v_aftertouch;       // Voice message is aftertouch (channel pressure)
  logic [ 6:0] v_aftertouch_val;   // Aftertouch value
  logic        v_pitchbend;        // Voice message is pitch bend
  logic [13:0] v_pitchbend_val;    // Pitch bend value

  logic        fail;

  midi_perser midi_perser_inst (.*);

  task update_input (
    input byte data[]
  );
    int i;
    d_valid <= 1'b1;
    $write("   input: ");
    for (i = 0; i < data.size(); i++) begin
      d_in <= data[i];
      $write("%02X ", data[i]);
      @(posedge clk);
    end
    d_valid <= 1'b0;
    $display("");
    @(posedge clk);
  endtask

  task check_output_note_on_off (
    input logic [3:0] channel,
    input logic       noteon,
    input logic       noteoff,
    input logic [6:0] num,
    input logic [6:0] vel
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel  != channel),
      (v_noteoff  != noteoff),
      (v_noteon   != noteon ),
      (v_note_num != num    ),
      (v_note_vel != vel    ),
      v_keypressure, v_control, v_program, v_aftertouch, v_pitchbend
    };
    fail = fail | int_fail;
    $display(
      "  output: note %s, channel=%X, num=%02X, vel=%02X (%s)",
      v_noteon ? "on" : (v_noteoff ? "off" : "--"),
      v_channel, v_note_num, v_note_vel,
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_keypressure (
    input logic [3:0] channel,
    input logic [6:0] num,
    input logic [6:0] val
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel != channel),
      ~v_keypressure,
      (v_keypressure_num != num),
      (v_keypressure_val != val),
      v_noteoff, v_noteon, v_control, v_program, v_aftertouch, v_pitchbend
    };
    fail = fail | int_fail;
    $display(
      "  output: keypressure, channel=%X, num=%02X, val=%02X (%s)",
      v_channel, v_keypressure_num, v_keypressure_val,
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_control (
    input logic [3:0] channel,
    input logic [6:0] num,
    input logic [6:0] val
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel != channel),
      ~v_control,
      (v_control_num != num),
      (v_control_val != val),
      v_noteoff, v_noteon, v_keypressure, v_program, v_aftertouch, v_pitchbend
    };
    fail = fail | int_fail;
    $display(
      "  output: control, channel=%X, num=%02X, val=%02X (%s)",
      v_channel, v_control_num, v_control_val,
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_program (
    input logic [3:0] channel,
    input logic [6:0] num
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel != channel),
      ~v_program,
      (v_program_num != num),
      v_noteoff, v_noteon, v_keypressure, v_control, v_aftertouch, v_pitchbend
    };
    fail = fail | int_fail;
    $display(
      "  output: program, channel=%X, num=%02X (%s)",
      v_channel, v_program_num,
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_aftertouch (
    input logic [3:0] channel,
    input logic [6:0] val
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel != channel),
      ~v_aftertouch,
      (v_aftertouch_val != val),
      v_noteoff, v_noteon, v_keypressure, v_control, v_program, v_pitchbend
    };
    fail = fail | int_fail;
    $display(
      "  output: aftertouch, channel=%X, val=%02X (%s)",
      v_channel, v_aftertouch_val,
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_pitchbend (
    input logic [ 3:0] channel,
    input logic [13:0] val
  );
    logic int_fail;
    wait(v_valid);
    @(posedge clk);
    int_fail = |{
      (v_channel != channel),
      ~v_pitchbend,
      (v_pitchbend_val != val),
      v_noteoff, v_noteon, v_keypressure, v_control, v_program, v_aftertouch
    };
    fail = fail | int_fail;
    $display(
      "  output: pitchbend, channel=%X, val=%02X %02X (%s)",
      v_channel, v_pitchbend_val[13:7], v_pitchbend_val[6:0],
      int_fail ? "FAIL" : "PASS"
    );
  endtask

  task check_output_no_valid ();
    logic timeout;
    timeout = 1'b0;
    fork
      begin
        wait(v_valid);
      end
      begin
        #10;
        timeout = 1'b1;
      end
    join_any
    disable fork;
    fail = fail | ~timeout;
    $display("  output: valid=%d (%s)", ~timeout, ~timeout ? "FAIL" : "PASS");
  endtask

  initial begin
    clk <= 1'b1;
    forever
      #(CLK_CYCLE/2) clk <= ~clk;
  end

  initial begin
    d_in <= 8'h00;
    d_valid <= 1'b0;
    resetn <= 1'b0;
    fail <= 1'b0;

    repeat (10) @(posedge clk);
    resetn <= 1'b1;
    repeat (10) @(posedge clk);

    $display("Check channel number");
    for (i = 0; i < 15; i++) begin
      update_input('{8'h90 | {4'h0, i[3:0]}, i[6:0], i[6:0]});
      check_output_note_on_off(.channel(i[3:0]), .noteon(1'b1), .noteoff(1'b0), .num(i[6:0]), .vel(i[6:0]));
    end

    $display("Check note off");
    update_input('{8'h80, 8'h12, 8'h34});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b0), .noteoff(1'b1), .num(7'h12), .vel(7'h34));

    $display("Check note on");
    update_input('{8'h90, 8'h56, 8'h78});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b1), .noteoff(1'b0), .num(7'h56), .vel(7'h78));

    $display("Check key pressure");
    update_input('{8'hA0, 8'h12, 8'h34});
    check_output_keypressure(.channel(4'h0), .num(7'h12), .val(7'h34));

    $display("Check control change");
    update_input('{8'hB0, 8'h56, 8'h78});
    check_output_control(.channel(4'h0), .num(7'h56), .val(7'h78));

    $display("Check program change");
    update_input('{8'hC0, 8'h12});
    check_output_program(.channel(4'h0), .num(7'h12));

    $display("Check aftertouch");
    update_input('{8'hD0, 8'h34});
    check_output_aftertouch(.channel(4'h0), .val(7'h34));

    $display("Check pitchbend");
    update_input('{8'hE0, 8'h56, 8'h78});
    check_output_pitchbend(.channel(4'h0), .val({7'h78, 7'h56}));

    $display("Check ignore system messages");
    update_input('{8'hF0, 8'h7F, 8'h04, 8'h01, 8'h00, 8'h00, 8'hF7});
    check_output_no_valid();
    update_input('{8'hF1, 8'h00, 8'h00});
    check_output_no_valid();
    update_input('{8'hF8});
    check_output_no_valid();

    $display("Check running status");
    update_input('{8'h80, 8'h12, 8'h34});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b0), .noteoff(1'b1), .num(7'h12), .vel(7'h34));
    update_input('{8'h56, 8'h78});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b0), .noteoff(1'b1), .num(7'h56), .vel(7'h78));
    update_input('{8'h90, 8'h12, 8'h34});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b1), .noteoff(1'b0), .num(7'h12), .vel(7'h34));
    update_input('{8'h56, 8'h78});
    check_output_note_on_off(.channel(4'h0), .noteon(1'b1), .noteoff(1'b0), .num(7'h56), .vel(7'h78));

    repeat (10) @(posedge clk);

    if (fail)
      $fatal(0, "Test FAILED");

    $display("Test PASSED");
    $finish;
  end

endmodule
