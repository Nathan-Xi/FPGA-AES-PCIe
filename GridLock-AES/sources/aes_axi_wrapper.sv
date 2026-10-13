`timescale 1ns / 1ps
import aes_types_pkg::*;

module aes_axi_wrapper #(
    parameter int C_S_AXI_ADDR_WIDTH = 5,
    parameter int C_S_AXI_DATA_WIDTH = 32,
    parameter int TDATA_WIDTH        = 128
)(
    axi4_lite_if.slave    axi_lite,
    axi4_stream_if.slave  s_axis,
    axi4_stream_if.master m_axis
);

    import aes_types_pkg::*;

    logic [127:0] key_reg;
    logic         key_init_start_reg;
    logic         key_ready_status;
    logic         start_encryption;
    logic         core_busy;
    logic         core_data_valid;
    state_t       plaintext_state;
    state_t       ciphertext_state;

    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    logic                          axi_awready;
    logic                          axi_wready;
    logic [1:0]                    axi_bresp;
    logic                          axi_bvalid;

    // Independent AW/W storage for AXI-Lite writes. AW and W are accepted
    // separately and committed once both channels have arrived.
    logic                              aw_pending;
    logic                              w_pending;
    logic [C_S_AXI_DATA_WIDTH-1:0]     axi_wdata_q;
    logic [C_S_AXI_ADDR_WIDTH-1:0]     write_addr;
    logic [C_S_AXI_DATA_WIDTH-1:0]     write_data;
    logic                              write_commit;
    logic [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    logic                          axi_arready;
    logic [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    logic [1:0]                    axi_rresp;
    logic                          axi_rvalid;

    aes_core aes_engine (
        .clk           (axi_lite.aclk),
        .aresetn       (axi_lite.aresetn),
        .start         (start_encryption),
        .key           (key_reg),
        .key_init_start(key_init_start_reg),
        .plaintext     (plaintext_state),
        .busy          (core_busy),
        .key_ready     (key_ready_status),
        .ciphertext    (ciphertext_state),
        .data_valid    (core_data_valid)
    );

    // Accept one write transaction at a time. Ready is suppressed while a
    // write response is still pending.
    assign axi_awready = !aw_pending && !axi_bvalid;
    assign axi_wready  = !w_pending  && !axi_bvalid;

    // Select the address/data for the committed write. If the corresponding
    // channel handshakes this cycle, use the bus value; otherwise use the
    // value stored by the earlier handshake.
    always_comb begin
        write_addr = (axi_awready && axi_lite.awvalid) ? axi_lite.awaddr : axi_awaddr;
        write_data = (axi_wready && axi_lite.wvalid) ? axi_lite.wdata : axi_wdata_q;
        write_commit = (aw_pending || (axi_awready && axi_lite.awvalid)) &&
                       (w_pending  || (axi_wready  && axi_lite.wvalid));
    end

    always_ff @(posedge axi_lite.aclk) begin
        if (!axi_lite.aresetn) begin
            aw_pending         <= 1'b0;
            w_pending          <= 1'b0;
            axi_awaddr         <= '0;
            axi_wdata_q        <= '0;
            axi_bvalid         <= 1'b0;
            axi_bresp          <= 2'b0;
            key_reg            <= 128'b0;
            key_init_start_reg <= 1'b0;
        end else begin
            // key_init_start is a one-cycle pulse by default.
            key_init_start_reg <= 1'b0;

            if (write_commit) begin
                aw_pending <= 1'b0;
                w_pending  <= 1'b0;
            end else begin
                if (axi_awready && axi_lite.awvalid) begin
                    axi_awaddr <= axi_lite.awaddr;
                    aw_pending <= 1'b1;
                end

                if (axi_wready && axi_lite.wvalid) begin
                    axi_wdata_q <= axi_lite.wdata;
                    w_pending   <= 1'b1;
                end
            end

            if (write_commit) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b0;

                // Host writes key words in display order: address 0x00 is the
                // most significant 32-bit word of the 128-bit key register.
                case (write_addr)
                    'h00: key_reg[127:96]    <= write_data;
                    'h04: key_reg[95:64]     <= write_data;
                    'h08: key_reg[63:32]     <= write_data;
                    'h0C: key_reg[31:0]      <= write_data;
                    'h14: key_init_start_reg <= write_data[0];
                    default: ;
                endcase
            end else if (axi_bvalid && axi_lite.bready) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    always_ff @(posedge axi_lite.aclk) begin
        if (!axi_lite.aresetn) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_rresp   <= 2'b0;
            axi_rdata   <= 32'b0;
        end else begin
            if (!axi_arready && axi_lite.arvalid) begin
                axi_araddr  <= axi_lite.araddr;
                axi_arready <= 1'b1;
            end else begin
                axi_arready <= 1'b0;
            end

            if (axi_arready && axi_lite.arvalid && !axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;
                case (axi_araddr)
                    'h18:    axi_rdata <= {29'b0, key_ready_status, core_busy};
                    default: axi_rdata <= 32'b0;
                endcase
            end else if (axi_rvalid && axi_lite.rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    assign s_axis.tready   = m_axis.tready;
    assign start_encryption = s_axis.tvalid && s_axis.tready;

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                plaintext_state[i][j] = s_axis.tdata[i * 32 + j * 8 +: 8];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < 4; i++) begin
            for (int j = 0; j < 4; j++) begin
                m_axis.tdata[i * 32 + j * 8 +: 8] = ciphertext_state[i][j];
            end
        end
    end

    assign m_axis.tvalid = core_data_valid;
    assign m_axis.tlast  = 1'b1;
    assign m_axis.tstrb  = '1;

    assign axi_lite.awready = axi_awready;
    assign axi_lite.wready  = axi_wready;
    assign axi_lite.bresp   = axi_bresp;
    assign axi_lite.bvalid  = axi_bvalid;
    assign axi_lite.arready = axi_arready;
    assign axi_lite.rdata   = axi_rdata;
    assign axi_lite.rresp   = axi_rresp;
    assign axi_lite.rvalid  = axi_rvalid;

endmodule
