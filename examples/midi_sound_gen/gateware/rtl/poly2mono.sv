`include "build_option.sv"

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
  t_mask w_mask, search_mask;

  logic        note_on_str;
  logic [ 6:0] note_num_str, velocity_str;
  logic [ 3:0] w_addr, search_addr_out;
  logic [18:0] w_din, search_din, search_dout;
  logic        w_en, search_en, search_valid, search_notfound;
  logic [ 3:0] search_addr_out_str;
  logic [18:0] search_dout_str;
  logic [ 4:0] voices;
  logic [ 3:0] pcount;

  ptcam ptcam_inst (
    .clk             (clk            ),
    .reset_n         (reset_n        ),
    .w_addr          (w_addr         ),
    .w_din           (w_din          ),
    .w_mask          (w_mask         ),
    .w_en            (w_en           ),
    .r_addr          (4'd0           ),
    .r_dout          (               ),
    .search_din      (search_din     ),
    .search_mask     (search_mask    ),
    .search_en       (search_en      ),
    .search_valid    (search_valid   ),
    .search_dout     (search_dout    ),
    .search_addr_out (search_addr_out),
    .search_notfound (search_notfound)
  );

  assign ready = (state == S_IDLE);

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
          state <= valid_in ? S_STORE_INPUT : state;

        S_STORE_INPUT:
          state <= S_SEARCH_SAME_NOTE;

        S_SEARCH_SAME_NOTE:
          state <= S_SEARCH_SAME_NOTE_WAIT;

        S_SEARCH_SAME_NOTE_WAIT: begin
          if (search_valid) begin
            if (note_on_str & |velocity_str)
              state <= search_notfound ? S_SEARCH_NONACTIVE : S_UPDATE_VELOCITY;
            else
              state <= search_notfound ? S_IDLE : S_CLEAR_ACTIVE;
          end
          else
            state <= state;
        end

        S_SEARCH_NONACTIVE:
          state <= S_SEARCH_NONACTIVE_WAIT;

        S_SEARCH_NONACTIVE_WAIT: begin
          if (search_valid)
            state <= search_notfound ? S_IDLE : S_UPDATE_LIST;
          else
            state <= state;
        end

        S_CLEAR_ACTIVE:
          state <= S_CHECK_VOICES;

        S_CHECK_VOICES: begin
          if (voices[3:0] == pcount)
            state <= S_SEARCH_LAST_VOICED;
          else if (|voices)
            state <= S_SEARCH_PRIORITY;
          else
            state <= S_IDLE;
        end

        S_SEARCH_LAST_VOICED:
          state <= S_SEARCH_LAST_VOICED_WAIT;

        S_SEARCH_LAST_VOICED_WAIT:
          state <= search_valid ? S_UPDATE_TO_LAST_VOICED : state;

        S_SEARCH_PRIORITY:
          state <= S_SEARCH_PRIORITY_WAIT;

        S_SEARCH_PRIORITY_WAIT:
          state <= search_valid ? S_UPDATE_PRIORITY : state;

        S_UPDATE_PRIORITY:
          state <= (pcount == voices[3:0]) ? S_IDLE : S_SEARCH_PRIORITY;

        default:
          state <= state;
      endcase
    end
  end

  always_ff @(posedge clk) begin
    if (state == S_IDLE & valid_in) begin
      note_on_str <= note_on_in;
      note_num_str <= note_num_in;
      velocity_str <= velocity_in;
    end
    else begin
      note_on_str <= note_on_str;
      note_num_str <= note_num_str;
      velocity_str <= velocity_str;
    end
  end

  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE:
        search_din <= {1'b1, 4'b0, note_num_str, 7'b0};

      S_SEARCH_NONACTIVE:
        search_din <= {1'b0, 4'b0, 7'b0, 7'b0};

      S_SEARCH_LAST_VOICED:
        search_din <= {1'b1, pcount - 4'd1, 7'b0, 7'b0};

      S_SEARCH_PRIORITY:
        search_din <= {1'b1, pcount, 7'b0, 7'b0};

      default:
        search_din <= search_din;
    endcase
  end

`ifdef USE_RADIANT
  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE:
        search_mask <= t_mask'(M_ACTIVE | M_NOTENUM);

      S_SEARCH_NONACTIVE:
        search_mask <= M_ACTIVE;

      S_SEARCH_LAST_VOICED,
      S_SEARCH_PRIORITY:
        search_mask <= t_mask'(M_ACTIVE | M_PRIORITY);

      default:
        search_mask <= search_mask;
    endcase
  end
`else
  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE:
        search_mask <= M_ACTIVE | M_NOTENUM;

      S_SEARCH_NONACTIVE:
        search_mask <= M_ACTIVE;

      S_SEARCH_LAST_VOICED,
      S_SEARCH_PRIORITY:
        search_mask <= M_ACTIVE | M_PRIORITY;

      default:
        search_mask <= search_mask;
    endcase
  end
`endif

  always_ff @(posedge clk) begin
    case (state)
      S_SEARCH_SAME_NOTE,
      S_SEARCH_NONACTIVE,
      S_SEARCH_LAST_VOICED,
      S_SEARCH_PRIORITY:
        search_en <= 1'b1;

      default:
        search_en <= 1'b0;
    endcase
  end

  always_ff @(posedge clk) begin
    search_addr_out_str <= search_valid ? search_addr_out : search_addr_out_str;
    search_dout_str <= search_valid ? search_dout : search_dout_str;
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY,
      S_UPDATE_LIST,
      S_CLEAR_ACTIVE,
      S_UPDATE_PRIORITY:
        w_addr <= search_addr_out_str;

      default:
        w_addr <= w_addr;
    endcase
  end

  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY:
        w_din <= {1'b0, 4'b0, 7'b0, velocity_str};

      S_UPDATE_LIST:
        w_din <= {1'b1, voices[3:0], note_num_str, velocity_str};

      S_CLEAR_ACTIVE:
        w_din <= {1'b0, 4'b0, 7'b0, 7'b0};

      S_UPDATE_PRIORITY:
        w_din <= {1'b0, pcount - 4'd1, 7'b0, 7'b0};

      default:
        w_din <= w_din;
    endcase
  end

`ifdef USE_RADIANT
  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY:
        w_mask <= M_VELOCITY;

      S_UPDATE_LIST:
        w_mask <= t_mask'(M_ACTIVE | M_PRIORITY | M_NOTENUM | M_VELOCITY);

      S_CLEAR_ACTIVE:
        w_mask <= M_ACTIVE;

      S_UPDATE_PRIORITY:
        w_mask <= M_PRIORITY;

      default:
        w_mask <= w_mask;
    endcase
  end
`else
  always_ff @(posedge clk) begin
    case (state)
      S_UPDATE_VELOCITY:
        w_mask <= M_VELOCITY;

      S_UPDATE_LIST:
        w_mask <= M_ACTIVE | M_PRIORITY | M_NOTENUM | M_VELOCITY;

      S_CLEAR_ACTIVE:
        w_mask <= M_ACTIVE;

      S_UPDATE_PRIORITY:
        w_mask <= M_PRIORITY;

      default:
        w_mask <= w_mask;
    endcase
  end
`endif

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
        pcount <= search_dout_str[17:14];

      S_UPDATE_PRIORITY:
        pcount <= (pcount != voices[3:0]) ? pcount + 4'd1 : pcount;

      default:
        pcount <= pcount;
    endcase
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_on_out <= 1'b0;
    else begin
      case (state)
        S_STORE_INPUT:
          note_on_out <= (~voices[4] & note_on_str & |velocity_str) ? 1'b1 : note_on_out;

        S_CHECK_VOICES:
          note_on_out <= (~|voices) ? 1'b0 : note_on_out;

        default:
          note_on_out <= note_on_out;
      endcase
    end
  end

  always @(posedge clk) begin
    if (~reset_n)
      note_num_out <= 7'd0;
    else begin
      case (state)
        S_STORE_INPUT:
          note_num_out <= (~voices[4] & note_on_str & |velocity_str) ? note_num_str : note_num_out;

        S_UPDATE_TO_LAST_VOICED:
          note_num_out <= search_dout_str[13:7];

        default:
          note_num_out <= note_num_out;
      endcase
    end
  end

  always @(posedge clk) begin
    if (~reset_n)
      velocity_out <= 7'd0;
    else begin
      case (state)
        S_STORE_INPUT:
          velocity_out <= (~voices[4] & note_on_str & |velocity_str) ? velocity_str : velocity_out;

        S_UPDATE_TO_LAST_VOICED:
          velocity_out <= search_dout_str[6:0];

        default:
          velocity_out <= velocity_out;
      endcase
    end
  end

endmodule
