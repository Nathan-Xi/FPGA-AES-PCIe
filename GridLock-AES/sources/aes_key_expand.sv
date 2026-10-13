`timescale 1ns / 1ps

module aes_key_expand (
    input  logic         clk,
    input  logic         aresetn,
    input  logic         key_init_start,
    input  logic [127:0] key_in,
    input  logic [3:0]   round,
    input  logic [3:0]   update_round,
    input  logic         update,
    output logic [127:0] round_key,
    output logic         key_ready
);

    logic [127:0] key_reg;
    logic [127:0] next_key;
    logic [127:0] effective_key;
    logic         key_ready_reg;

    localparam [0:9][7:0] Rcon = {
        8'h01, 8'h02, 8'h04, 8'h08, 8'h10, 8'h20, 8'h40, 8'h80, 8'h1b, 8'h36
    };

    logic [7:0]  rot0, rot1, rot2, rot3;
    logic [7:0]  sub0, sub1, sub2, sub3;
    logic [31:0] w_new;

    // For the first round-key update after each plaintext block, always derive
    // from the original key. key_reg retains the final round key from the
    // previous block and must not be used as the base for round one.
    assign effective_key = (update && (update_round == 1)) ? key_in : key_reg;

    // RotWord(w3) in the big-endian word order used by effective_key.
    assign rot0 = effective_key[23:16];
    assign rot1 = effective_key[15:8];
    assign rot2 = effective_key[7:0];
    assign rot3 = effective_key[31:24];

    aes_sbox sbox0 (.sbox_in(rot0), .sbox_out(sub0));
    aes_sbox sbox1 (.sbox_in(rot1), .sbox_out(sub1));
    aes_sbox sbox2 (.sbox_in(rot2), .sbox_out(sub2));
    aes_sbox sbox3 (.sbox_in(rot3), .sbox_out(sub3));

    always_comb begin
        next_key = key_reg;

        if ((update_round > 0) && (update_round < 11)) begin
            w_new[31:24] = sub0 ^ Rcon[update_round - 1] ^ effective_key[127:120];
            w_new[23:16] = sub1 ^ effective_key[119:112];
            w_new[15:8]  = sub2 ^ effective_key[111:104];
            w_new[7:0]   = sub3 ^ effective_key[103:96];

            next_key[127:96] = w_new;
            next_key[95:64]  = effective_key[95:64] ^ w_new;
            next_key[63:32]  = effective_key[63:32] ^ next_key[95:64];
            next_key[31:0]   = effective_key[31:0] ^ next_key[63:32];
        end
    end

    always_ff @(posedge clk or negedge aresetn) begin
        if (!aresetn) begin
            key_reg <= 128'b0;
            key_ready_reg <= 1'b0;
        end else if (key_init_start) begin
            key_reg <= key_in;
            key_ready_reg <= 1'b1;
        end else if (update) begin
            key_reg <= next_key;
        end
    end

    assign round_key = (round == 0) ? key_in : key_reg;
    assign key_ready = key_ready_reg;

endmodule
