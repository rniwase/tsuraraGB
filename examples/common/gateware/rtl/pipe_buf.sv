module pipe_buf #(
  parameter WIDTH = 8,
  parameter NUM_STAGE = 6
)(
  input  logic             clk,
  input  logic [WIDTH-1:0] din,
  output logic [WIDTH-1:0] dout
);

  logic [WIDTH-1:0] buffer [NUM_STAGE-1:0];
  int i;

  always_ff @(posedge clk) begin
    buffer[0] <= din;
    for (i = 1; i < NUM_STAGE; i = i + 1)
      buffer[i] <= buffer[i-1];
  end

  assign dout = buffer[NUM_STAGE-1];

endmodule
