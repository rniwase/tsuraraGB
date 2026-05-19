`timescale 1 ns / 1 ns

module ptcam_testbench;

  initial begin
    $dumpfile("ptcam_testbench.vcd");
    $dumpvars;
  end

  parameter  CLK_CYCLE = 50;
  parameter  DWIDTH = 16;
  parameter  DEPTH = 16;
  localparam AWIDTH = $clog2(DEPTH);

  logic              clk;
  logic              reset_n;
  logic [AWIDTH-1:0] w_addr;
  logic [DWIDTH-1:0] w_din;
  logic [DWIDTH-1:0] w_mask;
  logic              w_en;
  logic [AWIDTH-1:0] r_addr;
  logic [DWIDTH-1:0] r_dout;
  logic [DWIDTH-1:0] s_din;
  logic [DWIDTH-1:0] s_mask;
  logic              s_en;
  logic              s_valid;
  logic [DWIDTH-1:0] s_dout;
  logic [AWIDTH-1:0] s_addr_out;
  logic              s_notfound;

  logic              r_fail;
  logic [DWIDTH-1:0] r_dout_check;
  logic              s_fail;

  integer i;

  ptcam #(.DWIDTH(DWIDTH), .DEPTH(DEPTH)) ptcam_inst (.*);

  initial begin
    clk <= 1'b1;
    forever
      #(CLK_CYCLE/2) clk <= ~clk;
  end

  always_ff @(posedge clk)
    r_dout_check <= {4{r_addr[3:0]}};

  initial begin
    w_addr  <= '0;
    r_addr  <= '0;
    w_mask  <= ~'0;
    w_en    <= 1'b0;
    w_din   <= '0;
    s_din   <= '0;
    s_mask  <= ~'0;
    s_en    <= 1'b0;
    reset_n <= 1'b0;
    r_fail  <= 1'b0;
    s_fail  <= 1'b0;

    repeat (10) @(posedge clk);
    reset_n <= 1'b1;
    repeat (10) @(posedge clk);

    // Write test data
    w_en <= 1'b1;
    w_mask <= ~'0;
    for (i=0; i<DEPTH; i=i+1) begin
      w_addr <= i[AWIDTH-1:0];
      w_din <= {4{i[3:0]}};
      @(posedge clk);
      $display("Write data: w_addr=%x, w_din=%x", w_addr, w_din);
    end
    w_en <= 1'b0;

    // Test read data
    for (i=0; i<DEPTH; i=i+1) begin
      r_addr <= i[AWIDTH-1:0];
      @(posedge clk);
      #1;
      $display("Read data: r_addr=%x, r_dout=%x", r_addr, r_dout);
      r_fail <= r_fail | (r_dout != r_dout_check);
    end

    // Test valid search
    s_mask <= ~'0;
    for (i=0; i<DEPTH; i=i+1) begin
      s_din <= {4{i[3:0]}};
      s_en <= 1'b1;
      @(posedge clk);
      s_en <= 1'b0;
      wait(s_valid);
      @(posedge clk);
      $display("Search data: s_din=%x, s_dout=%x", s_din, s_dout);
      s_fail <= s_fail | (s_din != s_dout) | s_notfound;
    end

    // Test invalid search
    s_din <= 'h1234;
    s_en <= 1'b1;
    @(posedge clk);
    s_en <= 1'b0;
    wait(s_valid);
    @(posedge clk);
    $display("Search data: s_din=%x, s_notfound=%x", s_din, s_notfound);
    s_fail <= s_fail | ~s_notfound;

    repeat (10) @(posedge clk);

    if (r_fail | s_fail)
      $fatal(0, "Test FAILED (r_fail=%d, s_fail=%d)", r_fail, s_fail);

    $display("Test PASSED");
    $finish;
  end

endmodule
