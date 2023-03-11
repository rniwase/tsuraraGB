/* midi_rx.sv - Connection module for receiving MIDI */

module midi_rx #(
  parameter P2M_MAX_VOICE = 16
)(
  input  logic       clk,
  input  logic       reset_n,
  input  logic       midi_in,
  output logic       note_act_out,
  output logic [6:0] note_num_out,
  output logic [6:0] note_vel_out,
  output logic [6:0] cc_volume_out
);

  logic       rx_valid, rx_f_error;
  logic [7:0] rx_data;
  logic       v_valid, v_noteoff, v_noteon, v_control;
  logic [3:0] v_channel;
  logic [6:0] v_note_num, v_note_vel, v_control_num, v_control_val;

  uart_rx #(
    .NUM_SYNC_STAGE (  5),
    .BAUDGEN_PERIOD (640)  // 31.25 kbaud
  ) uart_rx_i (
    .clk     (clk       ),
    .reset_n (reset_n   ),
    .rx_in   (midi_in   ),
    .valid   (rx_valid  ),
    .d_out   (rx_data   ),
    .f_error (rx_f_error)
  );

  midi_perser midi_perser_inst (
    .clk           (clk                   ),
    .reset_n       (reset_n               ),
    .d_in          (rx_data               ),
    .d_valid       (~rx_f_error & rx_valid),
    .v_valid       (v_valid               ),
    .v_channel     (v_channel             ),
    .v_noteoff     (v_noteoff             ),
    .v_noteon      (v_noteon              ),
    .v_note_num    (v_note_num            ),
    .v_note_vel    (v_note_vel            ),
    .v_control     (v_control             ),
    .v_control_num (v_control_num         ),
    .v_control_val (v_control_val         )
  );

  poly2mono #(
    .MAX_VOICE     (P2M_MAX_VOICE)
  ) poly2mono_inst (
    .clk           (clk          ),
    .reset_n       (reset_n      ),
    .busy          (             ),
    .v_valid_in    (v_valid      ),
    .v_noteon_in   (v_noteon     ),
    .v_noteoff_in  (v_noteoff    ),
    .v_note_num_in (v_note_num   ),
    .v_note_vel_in (v_note_vel   ),
    .note_act_out  (note_act_out ),
    .note_num_out  (note_num_out ),
    .note_vel_out  (note_vel_out )
  );

  always @(posedge clk) begin
    if (~reset_n)
      cc_volume_out <= 7'd127;
    else if (v_valid & v_control & (v_control_num == 7'd7))
      cc_volume_out <= v_control_val;
    else
      cc_volume_out <= cc_volume_out;
  end

endmodule
