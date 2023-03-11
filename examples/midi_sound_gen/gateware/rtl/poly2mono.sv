/* poly2mono.sv - Converting note messages from polyphony to monophony */

module poly2mono #(
  parameter MAX_VOICE = 16  // Max. of poly voices to store
)(
  input  logic       clk,
  input  logic       reset_n,
  output logic       busy,

  /* Input from MIDI perser */
  input  logic       v_valid_in,    // Voice message valid
  input  logic       v_noteon_in,   // Note-on message
  input  logic       v_noteoff_in,  // Note-off message
  input  logic [6:0] v_note_num_in, // Note number
  input  logic [6:0] v_note_vel_in, // Note velocity

  /* Note output converted to monophony */
  output logic       note_act_out,  // Note is active
  output logic [6:0] note_num_out,  // Last note number
  output logic [6:0] note_vel_out   // Last note velocity
);

  localparam BW_VOICES = $clog2(MAX_VOICE);

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

  t_state state;

  logic                  note_on_str;
  logic [           6:0] note_num_str, note_vel_str;
  logic                  note_msg_vld;

  logic [BW_VOICES   :0] voices;
  logic [BW_VOICES-1 :0] pcount;

  logic [BW_VOICES-1 :0] w_addr;
  logic [BW_VOICES+14:0] w_din, w_mask;
  logic                  w_din_active;
  logic [BW_VOICES-1 :0] w_din_priority;
  logic                  w_mask_active, w_mask_priority, w_mask_note_num, w_mask_note_vel;
  logic                  w_en;

  logic [BW_VOICES+14:0] s_din, s_mask, s_dout;
  logic                  s_din_active;
  logic [BW_VOICES-1 :0] s_din_priority, s_dout_priority_str;
  logic                  s_mask_priority, s_mask_note_num;
  logic                  s_en, s_valid, s_notfound;
  logic [           6:0] s_dout_note_num_str, s_dout_note_vel_str;
  logic [BW_VOICES-1 :0] s_addr_out, s_addr_out_str;

  assign note_msg_vld = v_valid_in & (v_noteon_in | v_noteoff_in);
  assign w_din  = {w_din_active , w_din_priority                , note_num_str          , note_vel_str          };
  assign w_mask = {w_mask_active, {(BW_VOICES){w_mask_priority}}, {(7){w_mask_note_num}}, {(7){w_mask_note_vel}}};
  assign s_din  = {s_din_active , s_din_priority                , note_num_str          , 7'b0                  };
  assign s_mask = {1'b1         , {(BW_VOICES){s_mask_priority}}, {(7){s_mask_note_num}}, 7'd0                  };

  ptcam #(
    .DWIDTH          (BW_VOICES+15),
    .MEMSIZE         (MAX_VOICE   )
  ) ptcam_inst (
    .clk             (clk         ),
    .reset_n         (reset_n     ),
    .w_addr          (w_addr      ),
    .w_din           (w_din       ),
    .w_mask          (w_mask      ),
    .w_en            (w_en        ),
    .r_addr          ('d0         ),
    .r_dout          (            ),
    .search_din      (s_din       ),
    .search_mask     (s_mask      ),
    .search_en       (s_en        ),
    .search_valid    (s_valid     ),
    .search_dout     (s_dout      ),
    .search_addr_out (s_addr_out  ),
    .search_notfound (s_notfound  )
  );

  assign busy = (state != S_IDLE);

  always_ff @(posedge clk) begin
    if (~reset_n)
      state <= S_IDLE;
    else begin
      case (state)
        S_UPDATE_VELOCITY,
        S_UPDATE_LIST,
        S_UPDATE_TO_LAST_VOICED:
          state <= S_IDLE;

        S_IDLE:
          state <= note_msg_vld ? S_STORE_INPUT : state;

        S_STORE_INPUT:
          state <= S_SEARCH_SAME_NOTE;

        S_SEARCH_SAME_NOTE:
          state <= S_SEARCH_SAME_NOTE_WAIT;

        S_SEARCH_SAME_NOTE_WAIT: begin
          if (s_valid) begin
            if (note_on_str & |note_vel_str)
              state <= s_notfound ? S_SEARCH_NONACTIVE : S_UPDATE_VELOCITY;
            else
              state <= s_notfound ? S_IDLE : S_CLEAR_ACTIVE;
          end
          else
            state <= state;
        end

        S_SEARCH_NONACTIVE:
          state <= S_SEARCH_NONACTIVE_WAIT;

        S_SEARCH_NONACTIVE_WAIT: begin
          if (s_valid)
            state <= s_notfound ? S_IDLE : S_UPDATE_LIST;
          else
            state <= state;
        end

        S_CLEAR_ACTIVE:
          state <= S_CHECK_VOICES;

        S_CHECK_VOICES: begin
          if (voices[BW_VOICES-1:0] == pcount)
            state <= S_SEARCH_LAST_VOICED;
          else if (|voices)
            state <= S_SEARCH_PRIORITY;
          else
            state <= S_IDLE;
        end

        S_SEARCH_LAST_VOICED:
          state <= S_SEARCH_LAST_VOICED_WAIT;

        S_SEARCH_LAST_VOICED_WAIT:
          state <= s_valid ? S_UPDATE_TO_LAST_VOICED : state;

        S_SEARCH_PRIORITY:
          state <= S_SEARCH_PRIORITY_WAIT;

        S_SEARCH_PRIORITY_WAIT:
          state <= s_valid ? S_UPDATE_PRIORITY : state;

        S_UPDATE_PRIORITY:
          state <= (voices[BW_VOICES-1:0] == pcount) ? S_IDLE : S_SEARCH_PRIORITY;

        default:
          state <= state;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE & note_msg_vld) begin
      note_on_str <= v_noteon_in;
      note_num_str <= v_note_num_in;
      note_vel_str <= v_note_vel_in;
    end
    else begin
      note_on_str <= note_on_str;
      note_num_str <= note_num_str;
      note_vel_str <= note_vel_str;
    end
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY,
      S_UPDATE_LIST,
      S_CLEAR_ACTIVE,
      S_UPDATE_PRIORITY:
        w_addr <= s_addr_out_str;
      default:
        w_addr <= w_addr;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_LIST: begin
        w_din_active <= 1'b1;
        w_mask_active <= 1'b1;
      end
      S_CLEAR_ACTIVE: begin
        w_din_active <= 1'b0;
        w_mask_active <= 1'b1;
      end
      default: begin
        w_din_active <= 1'b0;
        w_mask_active <= 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_LIST: begin
        w_din_priority <= voices[BW_VOICES-1:0];
        w_mask_priority <= 1'b1;
      end
      S_UPDATE_PRIORITY: begin
        w_din_priority <= pcount - BW_VOICES'(1);
        w_mask_priority <= 1'b1;
      end
      default: begin
        w_din_priority <= w_din_priority;
        w_mask_priority <= 1'b0;
      end
    endcase
  end
  
  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_LIST:
        w_mask_note_num <= 1'b1;
      default:
        w_mask_note_num <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY,
      S_UPDATE_LIST:
        w_mask_note_vel <= 1'b1;
      default:
        w_mask_note_vel <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY,
      S_UPDATE_LIST,
      S_CLEAR_ACTIVE,
      S_UPDATE_PRIORITY:
        w_en <= 1'b1;
      default:
        w_en <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE,
      S_SEARCH_LAST_VOICED,
      S_SEARCH_PRIORITY:
        s_din_active <= 1'b1;
      default:
        s_din_active <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_LAST_VOICED: begin
        s_din_priority <= pcount - BW_VOICES'(1);
        s_mask_priority <= 1'b1;
      end
      S_SEARCH_PRIORITY: begin
        s_din_priority <= pcount;
        s_mask_priority <= 1'b1;
      end
      default: begin
        s_din_priority <= s_din_priority;
        s_mask_priority <= 1'b0;
      end
    endcase
  end

  always_ff @(posedge clk)
    s_mask_note_num <= state == S_SEARCH_SAME_NOTE;

  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE,
      S_SEARCH_NONACTIVE,
      S_SEARCH_LAST_VOICED,
      S_SEARCH_PRIORITY:
        s_en <= 1'b1;
      default:
        s_en <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    if (s_valid) begin
      s_addr_out_str <= s_addr_out;
      s_dout_priority_str <= s_dout[14 +: BW_VOICES];
      s_dout_note_num_str <= s_dout[ 7 +:         7];
      s_dout_note_vel_str <= s_dout[ 0 +:         7];
    end
    else begin
      s_addr_out_str <= s_addr_out_str;
      s_dout_priority_str <= s_dout_priority_str;
      s_dout_note_num_str <= s_dout_note_num_str;
      s_dout_note_vel_str <= s_dout_note_vel_str;
    end
  end

  always @(posedge clk) begin
    if (~reset_n)
      voices <= 5'd0;
    else begin
      case (state)
        S_UPDATE_LIST:
          voices <= voices + 5'd1;
        S_CLEAR_ACTIVE:
          voices <= voices - 5'd1;
        default:
          voices <= voices;
      endcase
    end
  end

  always @(posedge clk) begin
    case (state)
      S_CLEAR_ACTIVE:
        pcount <= s_dout_priority_str;
      S_UPDATE_PRIORITY:
        pcount <= (pcount != voices[BW_VOICES-1:0]) ? pcount + 4'd1 : pcount;
      default:
        pcount <= pcount;
    endcase
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_act_out <= 1'b0;
    else begin
      case (state)
        S_STORE_INPUT:
          note_act_out <= ((voices != MAX_VOICE) & note_on_str & |note_vel_str) ? 1'b1 : note_act_out;
        S_CHECK_VOICES:
          note_act_out <= (~|voices) ? 1'b0 : note_act_out;
        default:
          note_act_out <= note_act_out;
      endcase
    end
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_num_out <= 7'd0;
    else begin
      case (state)
        S_STORE_INPUT:
          note_num_out <= ((voices != MAX_VOICE) & note_on_str & |note_vel_str) ? note_num_str : note_num_out;
        S_UPDATE_TO_LAST_VOICED:
          note_num_out <= s_dout_note_num_str;
        default:
          note_num_out <= note_num_out;
      endcase
    end
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_vel_out <= 7'd0;
    else begin
      case (state)
        S_STORE_INPUT:
          note_vel_out <= ((voices != MAX_VOICE) & note_on_str & |note_vel_str) ? note_vel_str : note_vel_out;
        S_UPDATE_TO_LAST_VOICED:
          note_vel_out <= s_dout_note_vel_str;
        default:
          note_vel_out <= note_vel_out;
      endcase
    end
  end

endmodule
