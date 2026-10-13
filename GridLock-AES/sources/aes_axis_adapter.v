module aes_axis_adapter (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [127:0] s_axis_tdata,
    input  wire [15:0]  s_axis_tkeep,
    input  wire         s_axis_tlast,
    input  wire         s_axis_tvalid,
    output wire         s_axis_tready,

    output wire [127:0] m_axis_tdata,
    output wire [15:0]  m_axis_tkeep,
    output wire         m_axis_tlast,
    output wire         m_axis_tvalid,
    input  wire         m_axis_tready,

    output wire [127:0] aes_in_tdata,
    output wire         aes_in_tvalid,
    input  wire         aes_in_tready,

    input  wire [127:0] aes_out_tdata,
    input  wire         aes_out_tvalid,
    output wire         aes_out_tready
);

    reg [127:0] in_data;
    reg [15:0]  in_keep;
    reg         in_last;
    reg         in_valid;

    reg         aes_busy;
    reg [15:0]  pending_keep;
    reg         pending_last;

    reg [127:0] out_data;
    reg [15:0]  out_keep;
    reg         out_last;
    reg         out_valid;

    wire in_fire      = s_axis_tvalid  && s_axis_tready;
    wire aes_fire     = aes_in_tvalid  && aes_in_tready;
    wire aes_out_fire = aes_out_tvalid && aes_out_tready;
    wire out_fire     = m_axis_tvalid  && m_axis_tready;

    assign s_axis_tready = !in_valid;

    assign aes_in_tdata   = in_data;
    assign aes_in_tvalid  = in_valid && !aes_busy;
    assign aes_out_tready = !out_valid;

    assign m_axis_tdata  = out_data;
    assign m_axis_tkeep  = out_keep;
    assign m_axis_tlast  = out_last;
    assign m_axis_tvalid = out_valid;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data      <= 128'b0;
            in_keep      <= 16'b0;
            in_last      <= 1'b0;
            in_valid     <= 1'b0;
            aes_busy     <= 1'b0;
            pending_keep <= 16'b0;
            pending_last <= 1'b0;
            out_data     <= 128'b0;
            out_keep     <= 16'b0;
            out_last     <= 1'b0;
            out_valid    <= 1'b0;
        end else begin
            if (in_fire) begin
                in_data  <= s_axis_tdata;
                in_keep  <= s_axis_tkeep;
                in_last  <= s_axis_tlast;
                in_valid <= 1'b1;
            end

            if (aes_fire) begin
                in_valid     <= 1'b0;
                aes_busy     <= 1'b1;
                pending_keep <= in_keep;
                pending_last <= in_last;
            end

            if (aes_out_fire) begin
                out_data  <= aes_out_tdata;
                out_keep  <= pending_keep;
                out_last  <= pending_last;
                out_valid <= 1'b1;
                aes_busy  <= 1'b0;
            end

            if (out_fire) begin
                out_valid <= 1'b0;
            end
        end
    end

endmodule
