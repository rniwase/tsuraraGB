`timescale 1 ns / 1 ns

module midi_rx_testbench;

  initial begin
    $dumpfile("midi_rx_testbench.vcd");
    $dumpvars;
  end

  parameter CLK_CYCLE = 2;
  localparam FREQ_SYSCLK = 16, BAUDRATE = 1;  // for simulation

  integer i;

  logic clk, reset_n;

  logic uart_tx_out, uart_tx_valid, uart_tx_ready;
  logic [7:0] uart_tx_d_in;
  logic [7:0] bus_A;
  logic [7:0] bus_D_out;

  logic fail;

  uart_tx #(
    .FREQ_SYSCLK (FREQ_SYSCLK),
    .BAUDRATE    (BAUDRATE   )
  ) uart_tx_inst (
    .clk     (clk          ),
    .reset_n (reset_n      ),
    .tx_out  (uart_tx_out  ),
    .valid   (uart_tx_valid),
    .ready   (uart_tx_ready),
    .d_in    (uart_tx_d_in )
  );

  midi_rx #(
    .NUM_SYNC_STAGE (5          ),
    .FREQ_SYSCLK    (FREQ_SYSCLK),
    .BAUDRATE       (BAUDRATE   ),
    .MAX_VOICE      (4          )
  ) midi_rx_inst (
    .clk       (clk        ),
    .reset_n   (reset_n    ),
    .midi_in   (uart_tx_out),
    .bus_A     (bus_A      ),
    .bus_D_out (bus_D_out  )
  );

  task update_input (
    input byte data[]
  );
    integer i;
    $write("   input: ");
    for (i = 0; i < data.size(); i = i + 1) begin
      @(posedge clk);
      wait(uart_tx_ready);
      uart_tx_valid <= 1'b1;
      uart_tx_d_in <= data[i];
      $write("%02X ", data[i]);
      @(posedge clk);
      uart_tx_valid <= 1'b0;
    end
    $display("");
    @(posedge clk);
  endtask

  task check_output (
    logic [7:0] addr,
    logic [7:0] dout
  );
    logic int_fail;
    int_fail = 1'b0;
    bus_A <= addr;
    repeat(20) @(posedge clk);
    int_fail = (bus_D_out != dout);
    fail = fail | int_fail;
    $display(
      "  output: bus_A=%02X, bus_D_out=%02x (%s)",
      bus_A, bus_D_out, int_fail ? "FAIL" : "PASS"
    );
  endtask

  initial begin
    clk <= 1'b1;
    forever
      #(CLK_CYCLE/2) clk <= ~clk;
  end

  initial begin
    uart_tx_d_in <= 8'h00;
    uart_tx_valid <= 1'b0;
    bus_A <= 8'h00;
    reset_n <= 1'b0;
    fail <= 1'b0;

    repeat (10) @(posedge clk);
    reset_n <= 1'b1;
    repeat (10) @(posedge clk);

    $display("Check note on");
    for (i = 0; i < 4; i++) begin
      update_input('{{4'h9, 2'b00, i[1:0]}, 8'h40 + i[7:0], 8'h70 + i[7:0]});
      wait(midi_rx_inst.v_valid);
      check_output(.addr({i[1:0], 1'b0, 3'd0}), .dout({7'd0, 1'b1}));
      check_output(.addr({i[1:0], 1'b0, 3'd1}), .dout({1'b0, 7'h40 + i[7:0]}));
      check_output(.addr({i[1:0], 1'b0, 3'd2}), .dout({1'b0, 7'h70 + i[7:0]}));
    end

    $display("Check note off");
    for (i = 0; i < 4; i++) begin
      update_input('{{4'h8, 2'b00, i[1:0]}, 8'h40 + i[7:0], 8'h00});
      wait(midi_rx_inst.v_valid);
      check_output(.addr({i[1:0], 1'b0, 3'd0}), .dout({7'd0, 1'b0}));
    end

    $display("Check volume (CC7)");
    for (i = 0; i < 4; i++) begin
      update_input('{{4'hB, 2'b00, i[1:0]}, 8'h07, 8'h70 + i[7:0]});
      wait(midi_rx_inst.v_valid);
      check_output(.addr({i[1:0], 1'b0, 3'd3}), .dout({1'b0, 7'h70 + i[7:0]}));
    end

    $display("Check pitchbend");
    for (i = 0; i < 4; i++) begin
      update_input('{{4'hE, 2'b00, i[1:0]}, 8'h10 + i[7:0], 8'h20 + i[7:0]});
      wait(midi_rx_inst.v_valid);
      check_output(.addr({i[1:0], 1'b0, 3'd4}), .dout({7'h20 + i[6:0], 7'h10 + i[6:0]}));
      check_output(.addr({i[1:0], 1'b0, 3'd5}), .dout((7'h20 + i[6:0]) >> 1));
    end

    repeat (10) @(posedge clk);

    if (fail)
      $fatal(0, "Test FAILED");

    $display("Test PASSED");
    $finish;
  end

endmodule
