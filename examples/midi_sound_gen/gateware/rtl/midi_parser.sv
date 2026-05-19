/* midi_parser.sv - Parse MIDI messages from UART RX module */

module midi_perser (
  input  logic        clk,
  input  logic        resetn,

  /* Inputs from UART module */
  input  logic [ 7:0] d_in,               // Data input
  input  logic        d_valid,            // Data valid input

  /* MIDI Perser outputs */
  output logic        v_valid,            // Voice message is valid
  output logic [ 3:0] v_channel,          // Channel number

  output logic        v_noteoff,          // Voice message is note-off
  output logic        v_noteon,           // Voice message is note-on
  output logic [ 6:0] v_note_num,         // Note number
  output logic [ 6:0] v_note_vel,         // Note velocity

  output logic        v_keypressure,      // Voice message is polyphonic key pressure
  output logic [ 6:0] v_keypressure_num,  // Polyphonic key pressure note number
  output logic [ 6:0] v_keypressure_val,  // Polyphonic key pressure value

  output logic        v_control,          // Voice message is control change
  output logic [ 6:0] v_control_num,      // Control change number
  output logic [ 6:0] v_control_val,      // Control change value

  output logic        v_program,          // Voice message is program change
  output logic [ 6:0] v_program_num,      // Program change number

  output logic        v_aftertouch,       // Voice message is aftertouch (channel pressure)
  output logic [ 6:0] v_aftertouch_val,   // Aftertouch value

  output logic        v_pitchbend,        // Voice message is pitch bend
  output logic [13:0] v_pitchbend_val     // Pitch bend value
);

  typedef enum logic [2:0] {
    T_NOTEOFF,      // 8nH
    T_NOTEON,       // 9nH
    T_KEYPRESSURE,  // AnH
    T_CONTROL,      // BnH
    T_PROGRAM,      // CnH
    T_AFTERTOUCH,   // DnH
    T_PITCHBEND,    // EnH
    T_SYSTEM        // FnH, system messages are ignored in this module
  } t_voice;

  logic [1:0] v_count, v_len;
  logic v_system;

  t_voice voice_type;
  assign voice_type = t_voice'(d_in[6:4]);

  logic is_data_byte, is_status_byte;
  assign is_status_byte =  d_in[7];  // 8xh - Fxh
  assign is_data_byte   = ~d_in[7];

  logic [6:0] v_pitchbend_val_l, v_pitchbend_val_h;
  assign v_pitchbend_val = {v_pitchbend_val_h, v_pitchbend_val_l};

  always_ff @(posedge clk) begin
    if (~resetn)
      v_len <= 2'd1;
    else if (d_valid & is_status_byte) begin
      case (voice_type)
        T_NOTEOFF,
        T_NOTEON,
        T_KEYPRESSURE,
        T_CONTROL,
        T_PITCHBEND:
          v_len <= 2'd1;  // 2-Data bytes
        T_PROGRAM,
        T_AFTERTOUCH,
        T_SYSTEM:
          v_len <= 2'd0;  // 1-Data bytes
      endcase
    end
    else
      v_len <= v_len;
  end

  always_ff @(posedge clk) begin
    if (~resetn)
      v_count <= 2'd0;
    else if (d_valid) begin
      if (is_status_byte)
        v_count <= 2'd0;
      else if (is_data_byte)
        v_count <= (v_count == v_len) ? 2'd0 : v_count + 2'd1;  // Running status
      else
        v_count <= v_count;
    end
    else
      v_count <= v_count;
  end

  always_ff @(posedge clk) begin
    if (~resetn) begin
      v_valid       <= 1'b0;
      v_noteoff     <= 1'b0;
      v_noteon      <= 1'b0;
      v_keypressure <= 1'b0;
      v_control     <= 1'b0;
      v_program     <= 1'b0;
      v_aftertouch  <= 1'b0;
      v_pitchbend   <= 1'b0;
      v_system      <= 1'b0;
    end
    else begin
      v_valid       <= d_valid & ~v_system & (v_count == v_len);
      v_noteoff     <= (d_valid & is_status_byte) ? (voice_type == T_NOTEOFF    ) : v_noteoff;
      v_noteon      <= (d_valid & is_status_byte) ? (voice_type == T_NOTEON     ) : v_noteon;
      v_keypressure <= (d_valid & is_status_byte) ? (voice_type == T_KEYPRESSURE) : v_keypressure;
      v_control     <= (d_valid & is_status_byte) ? (voice_type == T_CONTROL    ) : v_control;
      v_program     <= (d_valid & is_status_byte) ? (voice_type == T_PROGRAM    ) : v_program;
      v_aftertouch  <= (d_valid & is_status_byte) ? (voice_type == T_AFTERTOUCH ) : v_aftertouch;
      v_pitchbend   <= (d_valid & is_status_byte) ? (voice_type == T_PITCHBEND  ) : v_pitchbend;
      v_system      <= (d_valid & is_status_byte) ? (voice_type == T_SYSTEM     ) : v_system;
    end
  end

  always_ff @(posedge clk) begin
    v_channel         <= (d_valid & is_status_byte) ? d_in[3:0] : v_channel;
    v_note_num        <= (d_valid & (v_noteoff | v_noteon) & (v_count == 2'd0)) ? d_in[6:0] : v_note_num;
    v_note_vel        <= (d_valid & (v_noteoff | v_noteon) & (v_count == 2'd1)) ? d_in[6:0] : v_note_vel;
    v_keypressure_num <= (d_valid & v_keypressure          & (v_count == 2'd0)) ? d_in[6:0] : v_keypressure_num;
    v_keypressure_val <= (d_valid & v_keypressure          & (v_count == 2'd1)) ? d_in[6:0] : v_keypressure_val;
    v_control_num     <= (d_valid & v_control              & (v_count == 2'd0)) ? d_in[6:0] : v_control_num;
    v_control_val     <= (d_valid & v_control              & (v_count == 2'd1)) ? d_in[6:0] : v_control_val;
    v_program_num     <= (d_valid & v_program              & (v_count == 2'd0)) ? d_in[6:0] : v_program_num;
    v_aftertouch_val  <= (d_valid & v_aftertouch           & (v_count == 2'd0)) ? d_in[6:0] : v_aftertouch_val;
    v_pitchbend_val_l <= (d_valid & v_pitchbend            & (v_count == 2'd0)) ? d_in[6:0] : v_pitchbend_val_l;
    v_pitchbend_val_h <= (d_valid & v_pitchbend            & (v_count == 2'd1)) ? d_in[6:0] : v_pitchbend_val_h;
  end

endmodule
