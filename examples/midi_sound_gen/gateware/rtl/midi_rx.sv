/* midi_rx.sv - Connection module for receiving MIDI */

module midi_rx #(
  parameter NUM_SYNC_STAGE = 5,
  parameter FREQ_SYSCLK    = 20000000,
  parameter BAUDRATE       = 31250,
  parameter MAX_VOICE      = 4
)(
  input  logic       clk,
  input  logic       resetn,
  input  logic       midi_in,
  input  logic [7:0] bus_A,
  output logic [7:0] bus_D_out,
  output logic [3:0] note_act
);

  int i;
  genvar j;

  logic        rx_valid, rx_f_error;
  logic [ 7:0] rx_data;
  logic        v_valid, v_noteoff, v_noteon, v_control, v_pitchbend;
  logic [ 3:0] v_channel;
  logic [ 6:0] v_note_num, v_note_vel, v_control_num, v_control_val;
  logic [13:0] v_pitchbend_val;

  logic [ 6:0] note_num    [0:3];
  logic [ 6:0] note_vel    [0:3];
  logic [ 6:0] cc_modwheel [0:3];  // CC  1
  logic [ 6:0] cc_volume   [0:3];  // CC  7
  logic [ 6:0] cc_pan      [0:3];  // CC 10
  logic [ 6:0] cc_gp1      [0:3];  // CC 16
  logic [13:0] pitchbend   [0:3];

  logic [ 3:0] all_notes_off;
  logic [ 3:0] ch_valid;
  logic [ 1:0] bus_A_upper;
  logic [ 3:0] bus_A_lower;

  always_comb begin
    for (i = 0; i < 4; i++)
      ch_valid[i] = v_valid & (v_channel == i);
  end

  assign bus_A_upper = bus_A[5:4];
  assign bus_A_lower = bus_A[3:0];

  uart_rx #(
    .NUM_SYNC_STAGE (NUM_SYNC_STAGE),
    .FREQ_SYSCLK    (FREQ_SYSCLK   ),
    .BAUDRATE       (BAUDRATE      )
  ) uart_rx_inst (
    .clk            (clk           ),
    .resetn         (resetn        ),
    .rx_in          (midi_in       ),
    .valid          (rx_valid      ),
    .d_out          (rx_data       ),
    .f_error        (rx_f_error    )
  );

  midi_perser midi_perser_inst (
    .clk             (clk                   ),
    .resetn          (resetn                ),
    .d_in            (rx_data               ),
    .d_valid         (~rx_f_error & rx_valid),
    .v_valid         (v_valid               ),
    .v_channel       (v_channel             ),
    .v_noteoff       (v_noteoff             ),
    .v_noteon        (v_noteon              ),
    .v_note_num      (v_note_num            ),
    .v_note_vel      (v_note_vel            ),
    .v_control       (v_control             ),
    .v_control_num   (v_control_num         ),
    .v_control_val   (v_control_val         ),
    .v_pitchbend     (v_pitchbend           ),
    .v_pitchbend_val (v_pitchbend_val       )
  );

  generate
    for (j = 0; j < 4; j = j + 1) begin: gen_poly2mono
      poly2mono #(
        .MAX_VOICE     (MAX_VOICE                 )
      ) poly2mono_inst (
        .clk           (clk                       ),
        .resetn        (resetn & ~all_notes_off[j]),
        .busy          (                          ),
        .v_valid_in    (v_valid & ch_valid[j]     ),
        .v_noteon_in   (v_noteon                  ),
        .v_noteoff_in  (v_noteoff                 ),
        .v_note_num_in (v_note_num                ),
        .v_note_vel_in (v_note_vel                ),
        .note_act_out  (note_act[j]               ),
        .note_num_out  (note_num[j]               ),
        .note_vel_out  (note_vel[j]               )
      );
    end
  endgenerate

  always_ff @(posedge clk) begin
    for (i = 0; i < 4; i++) begin
      if (~resetn) begin
        cc_modwheel[i] <= 7'd0;
        cc_volume[i]   <= 7'd127;
        cc_pan[i]      <= 7'd64;
        cc_gp1[i]      <= 7'd127;  // fix it
        pitchbend[i]   <= 14'd8192;
      end
      else begin
        cc_modwheel[i] <= (ch_valid[i] & v_control & (v_control_num ==  7'd1)) ? v_control_val : cc_modwheel[i];
        cc_volume[i]   <= (ch_valid[i] & v_control & (v_control_num ==  7'd7)) ? v_control_val : cc_volume[i];
        cc_pan[i]      <= (ch_valid[i] & v_control & (v_control_num == 7'd10)) ? v_control_val : cc_pan[i];
        cc_gp1[i]      <= (ch_valid[i] & v_control & (v_control_num == 7'd16)) ? v_control_val : cc_gp1[i];
        pitchbend[i]   <= (ch_valid[i] & v_pitchbend) ? v_pitchbend_val : pitchbend[i];
      end
      all_notes_off[i] <= v_valid & ch_valid[i] & (v_control_num == 7'd123);
    end
  end

  always_ff @(posedge clk) begin
    case (bus_A_lower)
      4'h0: bus_D_out <= {7'b0, note_act[bus_A_upper]};
      4'h1: bus_D_out <= {1'b0, note_num[bus_A_upper]};
      4'h2: bus_D_out <= {1'b0, note_act[bus_A_upper] ? note_vel[bus_A_upper] : 7'd0};
      4'h3: bus_D_out <= {1'b0, cc_modwheel[bus_A_upper]};
      4'h4: bus_D_out <= {1'b0, cc_volume[bus_A_upper]};
      4'h5: bus_D_out <= {1'b0, cc_pan[bus_A_upper]};
      4'h6: bus_D_out <= {1'b0, cc_gp1[bus_A_upper]};
      4'hE: bus_D_out <= pitchbend[bus_A_upper][7:0];
      4'hF: bus_D_out <= {2'b00, pitchbend[bus_A_upper][13:8]};
      default: bus_D_out <= 8'h00;
    endcase
  end

endmodule
