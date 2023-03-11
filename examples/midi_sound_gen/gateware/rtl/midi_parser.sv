/* midi_parser.sv - Parse MIDI messages from UART signals */

module midi_perser (
  input  logic        clk,
  input  logic        reset_n,

  /* Inputs from UART */
  input  logic [ 7:0] d_in,          // Data input
  input  logic        d_valid,       // Data valid input

  /* MIDI Perser outputs */
  output logic        v_valid,       // Voice message is valid
  output logic [ 3:0] v_channel,     // Channel number

  output logic        v_noteoff,     // Voice message is note-off
  output logic        v_noteon,      // Voice message is note-on
  output logic [ 6:0] v_note_num,    // Note number
  output logic [ 6:0] v_note_vel,    // Note velocity

  output logic        v_control,     // Voice message is control change
  output logic [ 6:0] v_control_num, // Control change number
  output logic [ 6:0] v_control_val  // Control change value
);

  localparam [2:0]
    V_NOTEOFF     = 3'd0,  // 8nH
    V_NOTEON      = 3'd1,  // 9nH
    V_KEYPRESSURE = 3'd2,  // AnH
    V_CONTROL     = 3'd3,  // BnH
    V_PROGRAM     = 3'd4,  // CnH
    V_AFTERTOUCH  = 3'd5,  // DnH
    V_PITCHBEND   = 3'd6;  // EnH

  logic [2:0] voice_state;
  logic [1:0] voice_len, voice_len_max;
  logic [7:0] d_in_str;
  logic is_data_byte, is_status_byte;
  
  assign is_data_byte = ~d_in_str[7];
  assign is_status_byte = d_in_str[7] & ~&d_in_str[6:4];  // 8Xh - EXh

  // logic is_system_msg, is_eox;
  // logic is_realtime_msg, is_timing_clock, is_start, is_continue, is_stop;
  // assign is_system_msg = &d_in_str[7:4] & ~d_in_str[3];
  // assign is_eox = d_in_str == 8'hF7;
  // assign is_realtime_msg = &d_in_str[7:4] & d_in_str[3];
  // assign is_timing_clock = d_in_str == 8'hF8;
  // assign is_start = d_in_str == 8'hFA;
  // assign is_continue = d_in_str == 8'hFB;
  // assign is_stop = d_in_str == 8'hFC;

  always_ff @(posedge clk) begin
    if (~reset_n)
      d_in_str <= 8'b0;
    else if (d_valid)
      d_in_str <= d_in;
    else
      d_in_str <= d_in_str;
  end

  logic [2:0] d_valid_pipe;
  always_ff @(posedge clk) begin
    if (~reset_n)
      d_valid_pipe <= 3'b0;
    else
      d_valid_pipe <= {d_valid_pipe[1:0], d_valid};
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      voice_state <= V_NOTEOFF;
    else if (d_valid_pipe[0] & is_status_byte)
      voice_state <= d_in_str[6:4];
    else
      voice_state <= voice_state;
  end

  always_ff @(posedge clk) begin
    case (voice_state)
      V_NOTEOFF,
      V_NOTEON,
      V_KEYPRESSURE,
      V_CONTROL,
      V_PITCHBEND:
        voice_len_max <= 2'd2;
      default:
        voice_len_max <= 2'd1;
    endcase
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      voice_len <= 2'd0;
    else if (d_valid_pipe[0]) begin
      if (is_status_byte)
        voice_len <= 2'd0;
      else if (is_data_byte)
        voice_len <= (voice_len == voice_len_max) ? 2'd1 : voice_len + 2'd1;
      else
        voice_len <= voice_len;
    end
    else
      voice_len <= voice_len;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_valid <= 1'b0;
    else if (d_valid_pipe[2])
      v_valid <= voice_len == voice_len_max;
    else
      v_valid <= 1'b0;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_channel <= 4'd0;
    else if (d_valid_pipe[2] & is_status_byte)
      v_channel <= d_in_str[3:0];
    else
      v_channel <= v_channel;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_noteoff <= 1'b0;
    else if (d_valid_pipe[2] & is_status_byte)
      v_noteoff <= voice_state == V_NOTEOFF;
    else
      v_noteoff <= v_noteoff;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_noteon <= 1'b0;
    else if (d_valid_pipe[2] & is_status_byte)
      v_noteon <= voice_state == V_NOTEON;
    else
      v_noteon <= v_noteon;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_num <= 7'd0;
    else if (d_valid_pipe[2] & (voice_len == 2'd1) & ((voice_state == V_NOTEOFF) | (voice_state == V_NOTEON)))
      v_note_num <= d_in_str[6:0];
    else
      v_note_num <= v_note_num;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_vel <= 7'd0;
    else if (d_valid_pipe[2] & (voice_len == 2'd2) & ((voice_state == V_NOTEOFF) | (voice_state == V_NOTEON)))
      v_note_vel <= d_in_str[6:0];
    else
      v_note_vel <= v_note_vel;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_control <= 1'b0;
    else if (d_valid_pipe[2] & is_status_byte)
      v_control <= voice_state == V_CONTROL;
    else
      v_control <= v_control;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_control_num <= 7'd0;
    else if (d_valid_pipe[2] & (voice_len == 2'd1) & (voice_state == V_CONTROL))
      v_control_num <= d_in_str[6:0];
    else
      v_control_num <= v_control_num;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_control_val <= 7'd0;
    else if (d_valid_pipe[2] & (voice_len == 2'd2) & (voice_state == V_CONTROL))
      v_control_val <= d_in_str[6:0];
    else
      v_control_val <= v_control_val;
  end

endmodule
