module midi_rx (
  input  logic       clk,
  input  logic       reset_n,
  input  logic       midi_in,
  output logic       note_on_out,
  output logic [6:0] note_num_out,
  output logic [6:0] velocity_out,
  output logic [6:0] cc_volume_out
);

  logic rx_valid, rx_f_error;
  logic [7:0] rx_data;

  uart_rx #(
    .NUM_SYNC_STAGE(5),
    .BAUDGEN_PERIOD(640)
  ) uart_rx_i (
    .clk     (clk       ),
    .reset_n (reset_n   ),
    .rx_in   (midi_in   ),
    .valid   (rx_valid  ),
    .d_out   (rx_data   ),
    .f_error (rx_f_error)
  );

  logic v_valid, v_note_off, v_note_on;
  logic [3:0] v_channel;
  logic [6:0] v_note_num;
  logic [6:0] v_note_velocity;
  logic v_parameter;
  logic [6:0] v_parameter_num;
  logic [6:0] v_parameter_value;

  midi_perser midi_perser_i (
    .clk              (clk              ),
    .reset_n          (reset_n          ),
    .d_in             (rx_data          ),
    .d_valid          (rx_valid         ),
    .f_error          (rx_f_error       ),
    .v_valid          (v_valid          ),
    .v_channel        (v_channel        ),
    .v_note_off       (v_note_off       ),
    .v_note_on        (v_note_on        ),
    .v_note_num       (v_note_num       ),
    .v_note_velocity  (v_note_velocity  ),
    .v_parameter      (v_parameter      ),
    .v_parameter_num  (v_parameter_num  ),
    .v_parameter_value(v_parameter_value)
  );

  poly2mono poly2mono_i (
    .clk          (clk                               ),
    .reset_n      (reset_n                           ),
    .ready        (                                  ),
    .valid_in     (v_valid & (v_note_off | v_note_on)),
    .note_on_in   (v_note_on                         ),
    .note_num_in  (v_note_num                        ),
    .velocity_in  (v_note_velocity                   ),
    .note_on_out  (note_on_out                       ),
    .note_num_out (note_num_out                      ),
    .velocity_out (velocity_out                      )
  );

  always @(posedge clk) begin
    if (~reset_n)
      cc_volume_out <= 6'd127;
    else if (v_valid & v_parameter & (v_parameter_num == 6'd7))
      cc_volume_out <= v_parameter_value;
    else
      cc_volume_out <= cc_volume_out;
  end

endmodule
