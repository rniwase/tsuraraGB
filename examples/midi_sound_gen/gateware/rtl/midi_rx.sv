/* midi_rx.sv - Connection module for receiving MIDI */

module midi_rx #(
  parameter P2M_MAX_VOICE = 8
)(
  input  logic       clk,
  input  logic       reset_n,
  input  logic       midi_in,
  input  logic [7:0] bus_A,
  output logic [7:0] bus_D_out,
  output logic [3:0] note_act
);

  integer i;
  genvar j;

  logic       rx_valid, rx_f_error;
  logic [7:0] rx_data;
  logic       v_valid, v_noteoff, v_noteon, v_control;
  logic [3:0] v_channel;
  logic [6:0] v_note_num, v_note_vel, v_control_num, v_control_val;

  logic [6:0] note_num [0:3];
  logic [6:0] note_vel [0:3];
  logic [6:0] cc_volume [0:3];

  logic [3:0] ch_valid;

  always_comb begin
    for (i = 0; i < 4; i = i + 1)
      ch_valid[i] = (v_channel == i);
  end

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

  generate
    for (j = 0; j < 4; j = j + 1) begin: gen_poly2mono
      poly2mono #(
        .MAX_VOICE     (P2M_MAX_VOICE)
      ) poly2mono_inst (
        .clk           (clk                  ),
        .reset_n       (reset_n              ),
        .busy          (                     ),
        .v_valid_in    (v_valid & ch_valid[j]),
        .v_noteon_in   (v_noteon             ),
        .v_noteoff_in  (v_noteoff            ),
        .v_note_num_in (v_note_num           ),
        .v_note_vel_in (v_note_vel           ),
        .note_act_out  (note_act[j]          ),
        .note_num_out  (note_num[j]          ),
        .note_vel_out  (note_vel[j]          )
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    if (~reset_n) begin
      for (i = 0; i < 4; i = i + 1)
        cc_volume[i] <= 7'd127;
    end
    else if (v_valid & v_control & (v_control_num == 7'd7)) begin
      for (i = 0; i < 4; i = i + 1)
        cc_volume[i] <= ch_valid[i] ? v_control_val : cc_volume[i];
    end
    else begin
      for (i = 0; i < 4; i = i + 1)
        cc_volume[i] <= cc_volume[i];
    end
  end

  always_ff @(posedge clk) begin
    case (bus_A[1:0])
      2'h0:
        bus_D_out <= {7'b0, note_act[bus_A[5:4]]};
      2'h1:
        bus_D_out <= {1'b0, note_num[bus_A[5:4]]};
      2'h2:
        bus_D_out <= {1'b0, note_vel[bus_A[5:4]]};
      2'h3:
        bus_D_out <= {1'b0, cc_volume[bus_A[5:4]]};
      default:
        bus_D_out <= 8'h00;
    endcase
  end

endmodule
