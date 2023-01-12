`include "build_option.sv"

module midi_perser (
  input  logic        clk,
  input  logic        reset_n,
  input  logic [ 7:0] d_in,
  input  logic        d_valid,
  input  logic        f_error,

  output logic        v_valid,
  output logic [ 3:0] v_channel,

  output logic        v_note_off,
  output logic        v_note_on,
  output logic [ 6:0] v_note_num,
  output logic [ 6:0] v_note_velocity,

  output logic        v_parameter,
  output logic [ 6:0] v_parameter_num,
  output logic [ 6:0] v_parameter_value//,

  // output logic        v_pitch_wheel,
  // output logic [13:0] v_pitch_wheel_value
);

  typedef enum logic [2:0] {
    V_NOTE_OFF,
    V_NOTE_ON,
    V_KEY_PRESSURE,
    V_PARAMETER,
    V_PROGRAM,
    V_AFTER_TOUCH,
    V_PITCH_WHEEL
  } t_voice;

  t_voice voice_state;
  logic [1:0] voice_len, voice_len_max;

  logic [7:0] d_in_str;

  logic data_valid, is_data_byte, is_status_byte;
  assign data_valid = ~f_error & d_valid;
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
    else if (data_valid)
      d_in_str <= d_in;
  end

  logic [2:0] data_valid_p;
  always_ff @(posedge clk) begin
    if (~reset_n)
      data_valid_p <= 3'b0;
    else
      data_valid_p <= {data_valid_p[1:0], data_valid};
  end

`ifdef USE_RADIANT
  always_ff @(posedge clk) begin
    if (~reset_n)
      voice_state <= V_NOTE_OFF;
    else if (data_valid_p[0] & is_status_byte) begin
      voice_state <= t_voice'(d_in_str[6:4]);
    end
  end
`else
  always_ff @(posedge clk) begin
    if (~reset_n)
      voice_state <= V_NOTE_OFF;
    else if (data_valid_p[0] & is_status_byte) begin
      voice_state <= d_in_str[6:4];
    end
  end
`endif

  always_ff @(posedge clk) begin
    case (voice_state)
      V_NOTE_OFF     : voice_len_max <= 2'd2;
      V_NOTE_ON      : voice_len_max <= 2'd2;
      V_KEY_PRESSURE : voice_len_max <= 2'd2;
      V_PARAMETER    : voice_len_max <= 2'd2;
      V_PROGRAM      : voice_len_max <= 2'd1;
      V_AFTER_TOUCH  : voice_len_max <= 2'd1;
      V_PITCH_WHEEL  : voice_len_max <= 2'd2;
      default : voice_len_max <= 2'd1;
    endcase
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      voice_len <= 2'd0;
    else if (data_valid_p[0]) begin
      if (is_status_byte)
        voice_len <= 2'd0;
      else if (is_data_byte)
        voice_len <= (voice_len == voice_len_max) ? 2'd1 : voice_len + 2'd1;
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_valid <= 1'b0;
    else if (data_valid_p[2]) begin
      if (voice_len == voice_len_max)
        v_valid <= 1'b1;
    end
    else
      v_valid <= 1'b0;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_channel <= 4'd0;
    else if (data_valid_p[2] & is_status_byte)
      v_channel <= d_in_str[3:0];
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_off <= 1'b0;
    else if (data_valid_p[2] & is_status_byte)
      v_note_off <= voice_state == V_NOTE_OFF;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_on <= 1'b0;
    else if (data_valid_p[2] & is_status_byte)
      v_note_on <= voice_state == V_NOTE_ON;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_num <= 7'd0;
    else if (data_valid_p[2] & voice_len == 2'd1) begin
      if (voice_state == V_NOTE_OFF | voice_state == V_NOTE_ON)
        v_note_num <= d_in_str[6:0];
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_note_velocity <= 7'd0;
    else if (data_valid_p[2] & voice_len == 2'd2) begin
      if (voice_state == V_NOTE_OFF | voice_state == V_NOTE_ON)
        v_note_velocity <= d_in_str[6:0];
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_parameter <= 1'b0;
    else if (data_valid_p[2] & is_status_byte)
      v_parameter <= voice_state == V_PARAMETER;
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_parameter_num <= 7'd0;
    else if (data_valid_p[2] & voice_len == 2'd1) begin
      if (voice_state == V_PARAMETER)
        v_parameter_num <= d_in_str[6:0];
    end
  end

  always_ff @(posedge clk) begin
    if (~reset_n)
      v_parameter_value <= 7'd0;
    else if (data_valid_p[2] & voice_len == 2'd2) begin
      if (voice_state == V_PARAMETER)
        v_parameter_value <= d_in_str[6:0];
    end
  end

endmodule
