module poly2mono #(
  parameter MAX_VOICE = 16
)(
  input  logic       clk,
  input  logic       reset_n,
  output logic       ready,

  input  logic       valid_in,
  input  logic       note_on_in,
  input  logic [6:0] note_num_in,
  input  logic [6:0] velocity_in,

  output logic       note_on_out,
  output logic [6:0] note_num_out,
  output logic [6:0] velocity_out
);

  typedef enum logic [3:0] {
    S_IDLE,
    S_STORE_INPUT,
    S_SEARCH_SAME_NOTE,
    S_SEARCH_SAME_NOTE_WAIT,
    S_UPDATE_VELOCITY,
    S_SEARCH_NONACTIVE,
    S_SEARCH_NONACTIVE_WAIT,
    S_UPDATE_LIST,
    S_CLEAR_ACTIVE,
    S_CHECK_VOICES,
    S_SEARCH_LAST_VOICED,
    S_SEARCH_LAST_VOICED_WAIT,
    S_UPDATE_TO_LAST_VOICED,
    S_SEARCH_PRIORITY,
    S_SEARCH_PRIORITY_WAIT,
    S_UPDATE_PRIORITY
  } t_state;

  typedef enum logic [18:0] {
    M_ACTIVE = {1'b1, 18'b0},
    M_PRIORITY = {1'b0, ~4'b0, 14'b0},
    M_NOTENUM = {5'b0, ~7'b0, 7'b0},
    M_VELOCITY = {12'b0, ~7'b0}
  } t_mask;

  t_state state;

  logic note_on_str;
  logic [6:0] note_num_str, velocity_str;

  logic [3:0] w_addr, search_addr_out;
  logic [18:0] w_din, search_din, search_dout;
  t_mask w_mask, search_mask;
  logic w_en, search_en, search_valid, search_notfound;
  logic [3:0] search_addr_out_str;
  logic [18:0] search_dout_str;

  logic [4:0] voices;
  logic [3:0] pcount;

  ptcam ptcam_i (
    .r_addr (4'd0),
    .r_dout (),
    .*
  );

  always_ff @(posedge clk) begin
    if (~reset_n)
      state <= S_IDLE;
    else if (state == S_UPDATE_VELOCITY)
      state <= S_IDLE;
    else if (state == S_UPDATE_LIST)
      state <= S_IDLE;
    else if (state == S_UPDATE_TO_LAST_VOICED)
      state <= S_IDLE;
    else if (state == S_IDLE & valid_in)
      state <= S_STORE_INPUT;
    else if (state == S_STORE_INPUT)
      state <= S_SEARCH_SAME_NOTE;
    else if (state == S_SEARCH_SAME_NOTE)
      state <= S_SEARCH_SAME_NOTE_WAIT;
    else if (state == S_SEARCH_SAME_NOTE_WAIT & search_valid) begin
      if (note_on_str & |velocity_str)
        state <= search_notfound ? S_SEARCH_NONACTIVE : S_UPDATE_VELOCITY;
      else
        state <= search_notfound ? S_IDLE : S_CLEAR_ACTIVE;
    end
    else if (state == S_SEARCH_NONACTIVE)
      state <= S_SEARCH_NONACTIVE_WAIT;
    else if (state == S_SEARCH_NONACTIVE_WAIT & search_valid)
      state <= search_notfound ? S_IDLE : S_UPDATE_LIST;
    else if (state == S_CLEAR_ACTIVE)
      state <= S_CHECK_VOICES;
    else if (state == S_CHECK_VOICES) begin
      if (voices[3:0] == pcount)
        state <= S_SEARCH_LAST_VOICED;
      else if (|voices)
        state <= S_SEARCH_PRIORITY;
      else
        state <= S_IDLE;
    end
    else if (state == S_SEARCH_LAST_VOICED)
      state <= S_SEARCH_LAST_VOICED_WAIT;
    else if (state == S_SEARCH_LAST_VOICED_WAIT & search_valid)
      state <= S_UPDATE_TO_LAST_VOICED;
    else if (state == S_SEARCH_PRIORITY)
      state <= S_SEARCH_PRIORITY_WAIT;
    else if (state == S_SEARCH_PRIORITY_WAIT & search_valid)
      state <= S_UPDATE_PRIORITY;
    else if (state == S_UPDATE_PRIORITY)
      state <= (pcount == voices[3:0]) ? S_IDLE : S_SEARCH_PRIORITY;
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE & valid_in) begin
      note_on_str <= note_on_in;
      note_num_str <= note_num_in;
      velocity_str <= velocity_in;
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_SEARCH_SAME_NOTE)
      search_din <= {1'b1, 4'b0, note_num_str, 7'b0};
    else if (state == S_SEARCH_NONACTIVE)
      search_din <= {1'b0, 4'b0, 7'b0, 7'b0};
    else if (state == S_SEARCH_LAST_VOICED)
      search_din <= {1'b1, pcount - 4'd1, 7'b0, 7'b0};
    else if (state == S_SEARCH_PRIORITY)
      search_din <= {1'b1, pcount, 7'b0, 7'b0};
  end

  always_ff @(posedge clk) begin
    if (state == S_SEARCH_SAME_NOTE)
      search_mask <= t_mask'(M_ACTIVE | M_NOTENUM);
    else if (state == S_SEARCH_NONACTIVE)
      search_mask <= M_ACTIVE;
    else if (state == S_SEARCH_LAST_VOICED)
      search_mask <= t_mask'(M_ACTIVE | M_PRIORITY);
    else if (state == S_SEARCH_PRIORITY)
      search_mask <= t_mask'(M_ACTIVE | M_PRIORITY);
  end

  always_ff @(posedge clk) begin
    if (state == S_SEARCH_SAME_NOTE)
      search_en <= 1'b1;
    else if (state == S_SEARCH_NONACTIVE)
      search_en <= 1'b1;
    else if (state == S_SEARCH_LAST_VOICED)
      search_en <= 1'b1;
    else if (state == S_SEARCH_PRIORITY)
      search_en <= 1'b1;
    else
      search_en <= 1'b0;
  end

  always_ff @(posedge clk) begin
    if (search_valid)
      search_addr_out_str <= search_addr_out;
  end

  always_ff @(posedge clk) begin
    if (search_valid)
      search_dout_str <= search_dout;
  end

  always_ff @(posedge clk) begin
    if (state == S_UPDATE_VELOCITY)
      w_addr <= search_addr_out_str;
    else if (state == S_UPDATE_LIST)
      w_addr <= search_addr_out_str;
    else if (state == S_CLEAR_ACTIVE)
      w_addr <= search_addr_out_str;
    else if (state == S_UPDATE_PRIORITY)
      w_addr <= search_addr_out_str;
  end

  always_ff @(posedge clk) begin
    if (state == S_UPDATE_VELOCITY)
      w_din <= {1'b0, 4'b0, 7'b0, velocity_str};
    else if (state == S_UPDATE_LIST)
      w_din <= {1'b1, voices[3:0], note_num_str, velocity_str};
    else if (state == S_CLEAR_ACTIVE)
      w_din <= {1'b0, 4'b0, 7'b0, 7'b0};
    else if (state == S_UPDATE_PRIORITY)
      w_din <= {1'b0, pcount - 4'd1, 7'b0, 7'b0};
  end

  always_ff @(posedge clk) begin
    if (state == S_UPDATE_VELOCITY)
      w_mask <= M_VELOCITY;
    else if (state == S_UPDATE_LIST)
      w_mask <= t_mask'(M_ACTIVE | M_PRIORITY | M_NOTENUM | M_VELOCITY);
    else if (state == S_CLEAR_ACTIVE)
      w_mask <= M_ACTIVE;
    else if (state == S_UPDATE_PRIORITY)
      w_mask <= M_PRIORITY;
  end

  always_ff @(posedge clk) begin
    if (state == S_UPDATE_VELOCITY)
      w_en <= 1'b1;
    else if (state == S_UPDATE_LIST)
      w_en <= 1'b1;
    else if (state == S_CLEAR_ACTIVE)
      w_en <= 1'b1;
    else if (state == S_UPDATE_PRIORITY)
      w_en <= 1'b1;
    else
      w_en <= 1'b0;
  end

  always @(posedge clk) begin
    if (~reset_n)
      voices <= 5'd0;
    else if (state == S_UPDATE_LIST)
      voices <= voices + 5'd1;
    else if (state == S_CLEAR_ACTIVE)
      voices <= voices - 5'd1;
  end

  always @(posedge clk) begin
    if (state == S_CLEAR_ACTIVE)
      pcount <= search_dout_str[17:14];
    else if (state == S_UPDATE_PRIORITY & pcount != voices[3:0])
      pcount <= pcount + 4'd1;
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_on_out <= 1'b0;
    else if (state == S_STORE_INPUT & ~voices[4] & note_on_str & |velocity_str)
      note_on_out <= 1'b1;
    else if (state == S_CHECK_VOICES & ~|voices)
      note_on_out <= 1'b0;
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_num_out <= 7'd0;
    else if (state == S_STORE_INPUT & ~voices[4] & note_on_str & |velocity_str)
      note_num_out <= note_num_str;
    else if (state == S_UPDATE_TO_LAST_VOICED)
      note_num_out <= search_dout_str[13:7];
  end

  always @(posedge clk) begin
    if (~reset_n)
      velocity_out <= 7'd0;
    else if (state == S_STORE_INPUT & ~voices[4] & note_on_str & |velocity_str)
      velocity_out <= velocity_str;
    else if (state == S_UPDATE_TO_LAST_VOICED)
      velocity_out <= search_dout_str[6:0];
  end

  assign ready = state == S_IDLE;

endmodule
