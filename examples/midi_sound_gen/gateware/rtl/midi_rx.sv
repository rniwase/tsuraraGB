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

  logic [ 6:0] note_num  [0:3];
  logic [ 6:0] note_vel  [0:3];
  logic [ 6:0] cc_volume [0:3];
  logic [13:0] pitchbend [0:3];

  logic [ 3:0] all_notes_off;

  logic [ 3:0] ch_valid;

  always_comb begin
    for (i = 0; i < 4; i++)
      ch_valid[i] = (v_channel == i);
  end

  uart_rx #(
    .NUM_SYNC_STAGE (NUM_SYNC_STAGE),
    .FREQ_SYSCLK    (FREQ_SYSCLK   ),
    .BAUDRATE       (BAUDRATE      )
  ) uart_rx_i (
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
    if (~resetn) begin
      for (i = 0; i < 4; i++)
        cc_volume[i] <= 7'd127;
    end
    else if (v_valid & v_control & (v_control_num == 7'd7)) begin
      for (i = 0; i < 4; i++)
        cc_volume[i] <= ch_valid[i] ? v_control_val : cc_volume[i];
    end
    else begin
      for (i = 0; i < 4; i++)
        cc_volume[i] <= cc_volume[i];
    end
  end

  always_ff @(posedge clk) begin
    if (~resetn) begin
      for (i = 0; i < 4; i++)
        pitchbend[i] <= 14'd8192;
    end
    else if (v_valid & v_pitchbend) begin
      for (i = 0; i < 4; i++)
        pitchbend[i] <= ch_valid[i] ? v_pitchbend_val : pitchbend[i];
    end
    else begin
      for (i = 0; i < 4; i++)
        pitchbend[i] <= pitchbend[i];
    end
  end

  always @(posedge clk) begin
    for (i = 0; i < 4; i++)
      all_notes_off[i] <= v_valid & ch_valid[i] & (v_control_num == 7'd123);
  end

  always_ff @(posedge clk) begin
    case (bus_A[2:0])
      3'h0:
        bus_D_out <= {7'b0, note_act[bus_A[5:4]]};
      3'h1:
        bus_D_out <= {1'b0, note_num[bus_A[5:4]]};
      3'h2:
        bus_D_out <= {1'b0, note_act[bus_A[5:4]] ? note_vel[bus_A[5:4]] : 7'd0};
      3'h3:
        bus_D_out <= {1'b0, cc_volume[bus_A[5:4]]};
      3'h4:
        bus_D_out <= pitchbend[bus_A[5:4]][7:0];
      3'h5:
        bus_D_out <= {2'b00, pitchbend[bus_A[5:4]][13:8]};
      default:
        bus_D_out <= 8'h00;
    endcase
  end

endmodule
