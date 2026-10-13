`timescale 1ns / 1ps
import aes_types_pkg::*;

module aes_core (
    input  logic         clk,
    input  logic         aresetn,
    input  logic         start,
    input  logic [127:0] key,
    input  logic         key_init_start,
    input  aes_types_pkg::state_t plaintext,
    output logic         busy,
    output logic         key_ready,
    output aes_types_pkg::state_t ciphertext,
    output logic         data_valid
);

    import aes_types_pkg::*;

    state_t state_reg, state_next;
    state_e current_state, next_state;
    logic [3:0] round_count, round_count_next;
    logic       data_valid_reg;

    logic [127:0] round_key;
    logic         key_update;
    logic [3:0]   key_update_round;

    // Display-order byte arrays. state_bytes[0] is the most-significant byte
    // of the 128-bit state, matching the AXI TDATA byte order used by the TB.
    logic [7:0] state_bytes [0:15];
    logic [7:0] sub_bytes   [0:15];
    logic [7:0] round_bytes [0:15];
    logic [7:0] shift_bytes [0:15];
    logic [7:0] mix_bytes   [0:15];

    function automatic int word_idx(input int k);
        return (15 - k) / 4;
    endfunction

    function automatic int lane_idx(input int k);
        return (15 - k) % 4;
    endfunction

    function automatic int byte_idx(input int r, input int c);
        return 4 * c + r;
    endfunction

    aes_key_expand key_expander (
        .clk           (clk),
        .aresetn       (aresetn),
        .key_init_start(key_init_start),
        .key_in        (key),
        .round         (round_count),
        .update_round  (key_update_round),
        .update        (key_update),
        .round_key     (round_key),
        .key_ready     (key_ready)
    );

    genvar k;
    generate
        for (k = 0; k < 16; k++) begin : sbox_inst
            aes_sbox sbox_byte (
                .sbox_in (state_bytes[k]),
                .sbox_out(sub_bytes[k])
            );
        end
    endgenerate

    always_ff @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            current_state  <= IDLE;
            round_count    <= 4'd0;
            state_reg      <= '0;
            data_valid_reg <= 1'b0;
        end else begin
            current_state  <= next_state;
            round_count    <= round_count_next;
            state_reg      <= state_next;
            data_valid_reg <= (current_state == DONE);
        end
    end

    always_comb begin
        next_state       = current_state;
        round_count_next = round_count;
        state_next       = state_reg;
        busy             = 1'b1;

        key_update       = 1'b0;
        key_update_round = round_count;

        for (int i = 0; i < 16; i++) begin
            state_bytes[i] = state_reg[word_idx(i)][lane_idx(i)];
            round_bytes[i] = round_key[8 * (15 - i) +: 8];
        end

        case (current_state)
            IDLE: begin
                busy = 1'b0;
                if (start) begin
                    next_state = INIT_ROUND;
                end
            end

            INIT_ROUND: begin
                for (int i = 0; i < 4; i++) begin
                    for (int j = 0; j < 4; j++) begin
                        state_next[i][j] = plaintext[i][j];
                    end
                end
                round_count_next = 4'd0;
                next_state = ADD_KEY;
            end

            ADD_KEY: begin
                for (int i = 0; i < 16; i++) begin
                    state_next[word_idx(i)][lane_idx(i)] = state_bytes[i] ^ round_bytes[i];
                end

                if (round_count == 10) begin
                    next_state = DONE;
                end else begin
                    next_state = SUB_BYTES;
                end
            end

            SUB_BYTES: begin
                for (int i = 0; i < 16; i++) begin
                    state_next[word_idx(i)][lane_idx(i)] = sub_bytes[i];
                end
                next_state = SHIFT_ROWS;
            end

            SHIFT_ROWS: begin
                // Standard FIPS-197 ShiftRows on the display-order state.
                for (int r = 0; r < 4; r++) begin
                    for (int c = 0; c < 4; c++) begin
                        shift_bytes[byte_idx(r, c)] = state_bytes[byte_idx(r, (c + r) % 4)];
                    end
                end

                for (int i = 0; i < 16; i++) begin
                    state_next[word_idx(i)][lane_idx(i)] = shift_bytes[i];
                end

                if (round_count == 9) begin
                    key_update       = 1'b1;
                    key_update_round = 4'd10;
                    next_state       = LAST_ROUND_ADD_KEY;
                end else begin
                    next_state = MIX_COLUMNS;
                end
            end

            MIX_COLUMNS: begin
                for (int c = 0; c < 4; c++) begin
                    logic [7:0] col_in[4];
                    logic [7:0] col_out[4];

                    for (int r = 0; r < 4; r++) begin
                        col_in[r] = state_bytes[byte_idx(r, c)];
                    end

                    col_out[0] = xtime(col_in[0]) ^ (xtime(col_in[1]) ^ col_in[1]) ^ col_in[2] ^ col_in[3];
                    col_out[1] = col_in[0] ^ xtime(col_in[1]) ^ (xtime(col_in[2]) ^ col_in[2]) ^ col_in[3];
                    col_out[2] = col_in[0] ^ col_in[1] ^ xtime(col_in[2]) ^ (xtime(col_in[3]) ^ col_in[3]);
                    col_out[3] = (xtime(col_in[0]) ^ col_in[0]) ^ col_in[1] ^ col_in[2] ^ xtime(col_in[3]);

                    for (int r = 0; r < 4; r++) begin
                        mix_bytes[byte_idx(r, c)] = col_out[r];
                    end
                end

                for (int i = 0; i < 16; i++) begin
                    state_next[word_idx(i)][lane_idx(i)] = mix_bytes[i];
                end

                key_update       = 1'b1;
                key_update_round = round_count + 1;
                round_count_next = round_count + 1;
                next_state       = ADD_KEY;
            end

            LAST_ROUND_ADD_KEY: begin
                for (int i = 0; i < 16; i++) begin
                    state_next[word_idx(i)][lane_idx(i)] = state_bytes[i] ^ round_bytes[i];
                end
                next_state = DONE;
            end

            DONE: begin
                busy = 1'b0;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    function automatic logic [7:0] xtime(logic [7:0] b);
        return (b[7] ? (b << 1) ^ 8'h1B : (b << 1));
    endfunction

    assign ciphertext = state_reg;
    assign data_valid  = data_valid_reg;

endmodule
