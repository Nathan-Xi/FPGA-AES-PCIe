//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2024 PANGO MICROSYSTEMS, INC
// ALL RIGHTS RESERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename: bdma_example
//////////////////////////////////////////////////////////////////////////////
module bdma_pcie #(
    parameter PCIE_MAX_LINK_WIDTH  = 4    
)(
    input                             perst_n            ,
    //clk and rst                     
    input                             ref_clk_n          ,      //100 Mhz
    input                             ref_clk_p          ,      //100 Mhz
    //diff signals                    
    input  [PCIE_MAX_LINK_WIDTH-1:0]  rxn                ,
    input  [PCIE_MAX_LINK_WIDTH-1:0]  rxp                ,
    output [PCIE_MAX_LINK_WIDTH-1:0]  txn                ,
    output [PCIE_MAX_LINK_WIDTH-1:0]  txp                ,
    output                            pcie_link_up             

 );

localparam C_FAMILY            = "TITAN2"                ;
localparam C_DEVICE            = "PG2T390H"              ;
localparam AXI_LITE_MASTER     = "TRUE"                  ;
localparam BAR0_SIZE_WIDTH     = 15                      ;
localparam BAR1_SIZE_WIDTH     = 16                      ;
localparam BAR2_SIZE_WIDTH     = 15                      ;
localparam PCIE2AXIBAR_0       = 64'h0000_0000_0000_0000 ;
localparam PCIE2AXIBAR_1       = 64'h0000_0000_0000_0000 ;
localparam PCIE2AXIBAR_2       = 64'h0000_0000_0000_0000 ;
localparam M_AXI_ADDR_WIDTH    = 64                      ;
localparam M_AXI_DATA_WIDTH    = 128                     ;
localparam M_AXI_ID_WIDTH      = 2                       ;
localparam DMA_STS_PORTS       = "TRUE"                  ;
localparam H2C_CHNL_NUM        = 4                       ;
localparam C2H_CHNL_NUM        = 4                       ;
localparam H2C_RID_NUM         = 32                      ;
localparam C2H_RID_NUM         = 16                      ;
localparam DMA_AXIMM           = 0                       ;
localparam DMA_AXIS            = 1                       ;
localparam C2H_DSC_BYPASS      = 0                       ;
localparam H2C_DSC_BYPASS      = 0                       ;
localparam USR_IRQ_NUM         = 1                       ;
localparam MSIX_VECTORS_NUM    = 32                      ;
localparam PCIE_MPL_SIZE       = 1024                    ;
localparam PCIE_MRRS_SIZE      = 1024                    ;
localparam PCIE_TAG_NUM        = 64                      ;
localparam PCIE_MAX_LINK_SPEED = 3                       ;

localparam AXI_USER_MRRS_SIZE  = (DMA_AXIS == 1) ? 28'h800_0000 : ((M_AXI_DATA_WIDTH > 64) ? 28'd4096 : 28'd2048);
localparam AXI_USER_MPL_SIZE   = (M_AXI_DATA_WIDTH > 64) ? 28'd4096 : 28'd2048;

localparam AXI_RAM_DEPTH       = 16384                   ;//16K*16B=256KB
localparam AXI_LITE_DEPTH      = 4096                    ;//4096*4B=16KB
localparam AXI_BYPASS_DEPTH    = 2048                    ;//2K*16B=32KB

localparam ST_LOOP_BACK        = 0                       ;//1 for stream loopback test; 0 for stream performance test

logic                              axi_clk               ;
logic                              axi_rst_n             ;
logic                              ref_clk               ;
logic                              cfg_msi_en            ;
logic  [2:0]                       cfg_multi_msi_en      ;
logic                              cfg_msix_en           ;
logic  [USR_IRQ_NUM-1 : 0]         user_int_req          ;
logic  [USR_IRQ_NUM-1 : 0]         user_int_grt          ;
logic                              c2h_dsc_byp_ready_0   ;
logic                              c2h_dsc_byp_valid_0   ;
logic  [64-1:0]                    c2h_dsc_byp_src_addr_0;
logic  [64-1:0]                    c2h_dsc_byp_dst_addr_0;
logic  [28-1:0]                    c2h_dsc_byp_len_0     ;
logic  [8-1:0]                     c2h_dsc_byp_ctrl_0    ;
logic                              h2c_dsc_byp_ready_0   ;
logic                              h2c_dsc_byp_valid_0   ;
logic  [64-1:0]                    h2c_dsc_byp_src_addr_0;
logic  [64-1:0]                    h2c_dsc_byp_dst_addr_0;
logic  [28-1:0]                    h2c_dsc_byp_len_0     ;
logic  [8-1:0]                     h2c_dsc_byp_ctrl_0    ;
logic                              c2h_dsc_byp_ready_1   ;
logic                              c2h_dsc_byp_valid_1   ;
logic  [64-1:0]                    c2h_dsc_byp_src_addr_1;
logic  [64-1:0]                    c2h_dsc_byp_dst_addr_1;
logic  [28-1:0]                    c2h_dsc_byp_len_1     ;
logic  [8-1:0]                     c2h_dsc_byp_ctrl_1    ;
logic                              h2c_dsc_byp_ready_1   ;
logic                              h2c_dsc_byp_valid_1   ;
logic  [64-1:0]                    h2c_dsc_byp_src_addr_1;
logic  [64-1:0]                    h2c_dsc_byp_dst_addr_1;
logic  [28-1:0]                    h2c_dsc_byp_len_1     ;
logic  [8-1:0]                     h2c_dsc_byp_ctrl_1    ;
logic                              c2h_dsc_byp_ready_2   ;
logic                              c2h_dsc_byp_valid_2   ;
logic  [64-1:0]                    c2h_dsc_byp_src_addr_2;
logic  [64-1:0]                    c2h_dsc_byp_dst_addr_2;
logic  [28-1:0]                    c2h_dsc_byp_len_2     ;
logic  [8-1:0]                     c2h_dsc_byp_ctrl_2    ;
logic                              h2c_dsc_byp_ready_2   ;
logic                              h2c_dsc_byp_valid_2   ;
logic  [64-1:0]                    h2c_dsc_byp_src_addr_2;
logic  [64-1:0]                    h2c_dsc_byp_dst_addr_2;
logic  [28-1:0]                    h2c_dsc_byp_len_2     ;
logic  [8-1:0]                     h2c_dsc_byp_ctrl_2    ;
logic                              c2h_dsc_byp_ready_3   ;
logic                              c2h_dsc_byp_valid_3   ;
logic  [64-1:0]                    c2h_dsc_byp_src_addr_3;
logic  [64-1:0]                    c2h_dsc_byp_dst_addr_3;
logic  [28-1:0]                    c2h_dsc_byp_len_3     ;
logic  [8-1:0]                     c2h_dsc_byp_ctrl_3    ;
logic                              h2c_dsc_byp_ready_3   ;
logic                              h2c_dsc_byp_valid_3   ;
logic  [64-1:0]                    h2c_dsc_byp_src_addr_3;
logic  [64-1:0]                    h2c_dsc_byp_dst_addr_3;
logic  [28-1:0]                    h2c_dsc_byp_len_3     ;
logic  [8-1:0]                     h2c_dsc_byp_ctrl_3    ;
logic                              m_axi_arready         ;
logic                              m_axi_arvalid         ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axi_arid            ;
logic  [M_AXI_ADDR_WIDTH-1:0]      m_axi_araddr          ;
logic  [7:0]                       m_axi_arlen           ;
logic  [2:0]                       m_axi_arsize          ;
logic  [1:0]                       m_axi_arburst         ;
logic  [2:0]                       m_axi_arprot          ;
logic                              m_axi_arlock          ;
logic  [3:0]                       m_axi_arcache         ;
logic                              m_axi_rready          ;
logic                              m_axi_rvalid          ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axi_rid             ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axi_rdata           ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axi_ruser           ;
logic  [1:0]                       m_axi_rresp           ;
logic                              m_axi_rlast           ;
logic                              m_axi_awready         ;
logic                              m_axi_awvalid         ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axi_awid            ;                 
logic  [M_AXI_ADDR_WIDTH-1:0]      m_axi_awaddr          ;                 
logic  [7:0]                       m_axi_awlen           ;                 
logic  [2:0]                       m_axi_awsize          ;                 
logic  [1:0]                       m_axi_awburst         ;                 
logic  [2:0]                       m_axi_awprot          ;                 
logic                              m_axi_awlock          ;                 
logic  [3:0]                       m_axi_awcache         ;                 
logic                              m_axi_wready          ;                 
logic                              m_axi_wvalid          ;                 
logic  [M_AXI_DATA_WIDTH-1:0]      m_axi_wdata           ;                 
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axi_wuser           ;                 
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axi_wstrb           ;                 
logic                              m_axi_wlast           ;                 
logic                              m_axi_bready          ;                 
logic                              m_axi_bvalid          ;                 
logic  [M_AXI_ID_WIDTH-1:0]        m_axi_bid             ;                 
logic  [1:0]                       m_axi_bresp           ;                 
logic                              m_axib_arready        ;
logic                              m_axib_arvalid        ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axib_arid           ;
logic  [M_AXI_ADDR_WIDTH-1:0]      m_axib_araddr         ;
logic  [7:0]                       m_axib_arlen          ;
logic  [2:0]                       m_axib_arsize         ;
logic  [1:0]                       m_axib_arburst        ;
logic  [2:0]                       m_axib_arprot         ;
logic                              m_axib_arlock         ;
logic  [3:0]                       m_axib_arcache        ;
logic                              m_axib_rready         ;
logic                              m_axib_rvalid         ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axib_rid            ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axib_rdata          ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axib_ruser          ;
logic  [1:0]                       m_axib_rresp          ;
logic                              m_axib_rlast          ;
logic                              m_axib_awready        ;
logic                              m_axib_awvalid        ;
logic  [M_AXI_ID_WIDTH-1:0]        m_axib_awid           ;                  
logic  [M_AXI_ADDR_WIDTH-1:0]      m_axib_awaddr         ;                  
logic  [7:0]                       m_axib_awlen          ;                  
logic  [2:0]                       m_axib_awsize         ;                  
logic  [1:0]                       m_axib_awburst        ;                  
logic  [2:0]                       m_axib_awprot         ;                  
logic                              m_axib_awlock         ;                  
logic  [3:0]                       m_axib_awcache        ;                  
logic                              m_axib_wready         ;                  
logic                              m_axib_wvalid         ;                  
logic  [M_AXI_DATA_WIDTH-1:0]      m_axib_wdata          ;                  
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axib_wuser          ;                  
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axib_wstrb          ;                  
logic                              m_axib_wlast          ;                  
logic                              m_axib_bready         ;                  
logic                              m_axib_bvalid         ;                  
logic  [M_AXI_ID_WIDTH-1:0]        m_axib_bid            ;                  
logic  [1:0]                       m_axib_bresp          ;
logic  [31:0]                      s_axil_awaddr         ;
logic  [2:0]                       s_axil_awprot         ;
logic                              s_axil_awvalid        ;
logic                              s_axil_awready        ;
logic  [31:0]                      s_axil_wdata          ;
logic  [ 3:0]                      s_axil_wstrb          ;
logic                              s_axil_wvalid         ;
logic                              s_axil_wready         ;
logic                              s_axil_bvalid         ;
logic  [ 1:0]                      s_axil_bresp          ;
logic                              s_axil_bready         ;
logic  [31:0]                      s_axil_araddr         ;
logic  [ 2:0]                      s_axil_arprot         ;
logic                              s_axil_arvalid        ;
logic                              s_axil_arready        ;
logic  [31:0]                      s_axil_rdata          ;
logic  [ 1:0]                      s_axil_rresp          ;
logic                              s_axil_rvalid         ;           
logic                              s_axil_rready         ;
logic  [31:0]                      m_axil_awaddr         ;
logic  [2:0]                       m_axil_awprot         ;
logic                              m_axil_awvalid        ;
logic                              m_axil_awready        ;
logic  [31:0]                      m_axil_wdata          ;
logic  [ 3:0]                      m_axil_wstrb          ;
logic                              m_axil_wvalid         ;
logic                              m_axil_wready         ;
logic                              m_axil_bvalid         ;
logic  [ 1:0]                      m_axil_bresp          ;
logic                              m_axil_bready         ;
logic  [31:0]                      m_axil_araddr         ;
logic  [ 2:0]                      m_axil_arprot         ;
logic                              m_axil_arvalid        ;
logic                              m_axil_arready        ;
logic  [31:0]                      m_axil_rdata          ;
logic  [ 1:0]                      m_axil_rresp          ;
logic                              m_axil_rvalid         ;           
logic                              m_axil_rready         ;
logic  [8-1:0]                     c2h_status_0          ;
logic  [8-1:0]                     h2c_status_0          ;
logic  [8-1:0]                     c2h_status_1          ;
logic  [8-1:0]                     h2c_status_1          ;
logic  [8-1:0]                     c2h_status_2          ;
logic  [8-1:0]                     h2c_status_2          ;
logic  [8-1:0]                     c2h_status_3          ;
logic  [8-1:0]                     h2c_status_3          ;

logic                              s_axis_c2h_tready_0 ;
logic                              s_axis_c2h_tvalid_0 ;
logic  [M_AXI_DATA_WIDTH-1:0]      s_axis_c2h_tdata_0  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tuser_0  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tkeep_0  ;
logic                              s_axis_c2h_tlast_0  ;

logic                              m_axis_h2c_tready_0 ;
logic                              m_axis_h2c_tvalid_0 ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axis_h2c_tdata_0  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tuser_0  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tkeep_0  ;
logic                              m_axis_h2c_tlast_0  ;

logic                              s_axis_c2h_tready_1 ;
logic                              s_axis_c2h_tvalid_1 ;
logic  [M_AXI_DATA_WIDTH-1:0]      s_axis_c2h_tdata_1  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tuser_1  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tkeep_1  ;
logic                              s_axis_c2h_tlast_1  ;

logic                              m_axis_h2c_tready_1 ;
logic                              m_axis_h2c_tvalid_1 ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axis_h2c_tdata_1  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tuser_1  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tkeep_1  ;
logic                              m_axis_h2c_tlast_1  ;

logic                              s_axis_c2h_tready_2 ;
logic                              s_axis_c2h_tvalid_2 ;
logic  [M_AXI_DATA_WIDTH-1:0]      s_axis_c2h_tdata_2  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tuser_2  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tkeep_2  ;
logic                              s_axis_c2h_tlast_2  ;

logic                              m_axis_h2c_tready_2 ;
logic                              m_axis_h2c_tvalid_2 ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axis_h2c_tdata_2  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tuser_2  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tkeep_2  ;
logic                              m_axis_h2c_tlast_2  ;

logic                              s_axis_c2h_tready_3 ;
logic                              s_axis_c2h_tvalid_3 ;
logic  [M_AXI_DATA_WIDTH-1:0]      s_axis_c2h_tdata_3  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tuser_3  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    s_axis_c2h_tkeep_3  ;
logic                              s_axis_c2h_tlast_3  ;

logic                              m_axis_h2c_tready_3 ;
logic                              m_axis_h2c_tvalid_3 ;
logic  [M_AXI_DATA_WIDTH-1:0]      m_axis_h2c_tdata_3  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tuser_3  ;
logic  [M_AXI_DATA_WIDTH/8-1:0]    m_axis_h2c_tkeep_3  ;
logic                              m_axis_h2c_tlast_3  ;

logic axib_rst_n;
//logic dma_status ;
logic msi_status ;

dma_sync_v1_0 axib_rst_sync (
    .clk        (axi_clk    ),
    .rst_n      (axi_rst_n  ),
    .sig_async  (1'b1       ),
    .sig_synced (axib_rst_n )
);



ipsxe_bdma #(
    .IP_ID                   (12'h803                ),
    .IP_VERSION              (1                      ),
    .C_FAMILY                (C_FAMILY               ),
    .C_DEVICE                (C_DEVICE               ),
    .PCIE_MAX_LINK_WIDTH     (PCIE_MAX_LINK_WIDTH    ),
    .M_AXI_DATA_WIDTH        (M_AXI_DATA_WIDTH       ),
    .M_AXI_ADDR_WIDTH        (M_AXI_ADDR_WIDTH       ),
    .M_AXI_ID_WIDTH          (M_AXI_ID_WIDTH         ),
    .M_AXI_AWUSER_WIDTH      (32                     ),
    .M_AXI_ARUSER_WIDTH      (32                     ),
    .AXI_WRITE_NUM           (8                      ),
    .AXI_READ_NUM            (8                      ),
    .AXI_LITE_MASTER         (AXI_LITE_MASTER        ),
    .PCIE2AXIBAR_0           (PCIE2AXIBAR_0          ),
    .PCIE2AXIBAR_1           (PCIE2AXIBAR_1          ),
    .PCIE2AXIBAR_2           (PCIE2AXIBAR_2          ),  
    .BAR0_SIZE_WIDTH         (BAR0_SIZE_WIDTH        ),
    .BAR1_SIZE_WIDTH         (BAR1_SIZE_WIDTH        ),
    .BAR2_SIZE_WIDTH         (BAR2_SIZE_WIDTH        ),  
    .DMA_EN                  (1                      ),
    .DMA_STS_PORTS           (DMA_STS_PORTS          ),
    .H2C_CHNL_NUM            (H2C_CHNL_NUM           ),
    .C2H_CHNL_NUM            (C2H_CHNL_NUM           ),
    .H2C_RID_NUM             (H2C_RID_NUM            ),
    .C2H_RID_NUM             (C2H_RID_NUM            ),
    .DMA_STS_WIDTH           (8                      ),
    .DMA_AXIMM               (DMA_AXIMM              ),
    .DMA_AXIS                (DMA_AXIS               ),
    .C2H_DSC_BYPASS          (C2H_DSC_BYPASS         ),
    .H2C_DSC_BYPASS          (H2C_DSC_BYPASS         ),
    .H2C_RAM_DEPTH           (512                    ),
    .C2H_RAM_DEPTH           (512                    ),
    .DSC_RAM_DEPTH           (512                    ),
    .BRDG_RAM_DEPTH          (512                    ),
    .DSC_MGC_EN              (1                      ),                                  
    .USR_IRQ_NUM             (USR_IRQ_NUM            ),
    .MSIX_VECTORS_NUM        (MSIX_VECTORS_NUM       ),
    .AXI_USER_MRRS_SIZE      (AXI_USER_MRRS_SIZE     ),
    .AXI_USER_MPL_SIZE       (AXI_USER_MPL_SIZE      ),
    .PCIE_MRRS_SIZE          (PCIE_MRRS_SIZE         ),
    .PCIE_MPL_SIZE           (PCIE_MPL_SIZE          ),
    .PCIE_TAG_NUM            (PCIE_TAG_NUM           ),
    .AXIL_AWUSER_WIDTH       (8                      ),
    .AXIL_ARUSER_WIDTH       (8                      ),
    .PCIE_MAX_LINK_SPEED     (PCIE_MAX_LINK_SPEED    ),
    .MSIX_REG_ADDR_ID        (4'h8                   )
)
u_bdma_core_top
(
    .perst_n             (perst_n             ),
    .ref_clk_n           (ref_clk_n           ),
    .ref_clk_p           (ref_clk_p           ),
    .rxn                 (rxn                 ),
    .rxp                 (rxp                 ),
    .txn                 (txn                 ),
    .txp                 (txp                 ),
    .axi_clk             (axi_clk             ),
    .axi_rst_n           (axi_rst_n           ),
    .ref_clk             (ref_clk             ),
    .pcie_link_up        (pcie_link_up        ),
    .cfg_msi_en          (cfg_msi_en          ),
    .cfg_multi_msi_en    (cfg_multi_msi_en    ),
    .cfg_msix_en         (cfg_msix_en         ),
    .i_user_int_req      (user_int_req        ),
    .o_user_int_grt      (user_int_grt        ),
    //user dsc_bypass
    .c2h_dsc_byp_ready_0   (c2h_dsc_byp_ready_0   ),
    .c2h_dsc_byp_valid_0   (c2h_dsc_byp_valid_0   ),
    .c2h_dsc_byp_src_addr_0(c2h_dsc_byp_src_addr_0),
    .c2h_dsc_byp_dst_addr_0(c2h_dsc_byp_dst_addr_0),
    .c2h_dsc_byp_len_0     (c2h_dsc_byp_len_0     ),
    .c2h_dsc_byp_ctrl_0    (c2h_dsc_byp_ctrl_0    ),
    .h2c_dsc_byp_ready_0   (h2c_dsc_byp_ready_0   ),
    .h2c_dsc_byp_valid_0   (h2c_dsc_byp_valid_0   ),
    .h2c_dsc_byp_src_addr_0(h2c_dsc_byp_src_addr_0),
    .h2c_dsc_byp_dst_addr_0(h2c_dsc_byp_dst_addr_0),
    .h2c_dsc_byp_len_0     (h2c_dsc_byp_len_0     ),
    .h2c_dsc_byp_ctrl_0    (h2c_dsc_byp_ctrl_0    ),

    .c2h_dsc_byp_ready_1   (c2h_dsc_byp_ready_1   ),
    .c2h_dsc_byp_valid_1   (c2h_dsc_byp_valid_1   ),
    .c2h_dsc_byp_src_addr_1(c2h_dsc_byp_src_addr_1),
    .c2h_dsc_byp_dst_addr_1(c2h_dsc_byp_dst_addr_1),
    .c2h_dsc_byp_len_1     (c2h_dsc_byp_len_1     ),
    .c2h_dsc_byp_ctrl_1    (c2h_dsc_byp_ctrl_1    ),
    .h2c_dsc_byp_ready_1   (h2c_dsc_byp_ready_1   ),
    .h2c_dsc_byp_valid_1   (h2c_dsc_byp_valid_1   ),
    .h2c_dsc_byp_src_addr_1(h2c_dsc_byp_src_addr_1),
    .h2c_dsc_byp_dst_addr_1(h2c_dsc_byp_dst_addr_1),
    .h2c_dsc_byp_len_1     (h2c_dsc_byp_len_1     ),
    .h2c_dsc_byp_ctrl_1    (h2c_dsc_byp_ctrl_1    ),

    .c2h_dsc_byp_ready_2   (c2h_dsc_byp_ready_2   ),
    .c2h_dsc_byp_valid_2   (c2h_dsc_byp_valid_2   ),
    .c2h_dsc_byp_src_addr_2(c2h_dsc_byp_src_addr_2),
    .c2h_dsc_byp_dst_addr_2(c2h_dsc_byp_dst_addr_2),
    .c2h_dsc_byp_len_2     (c2h_dsc_byp_len_2     ),
    .c2h_dsc_byp_ctrl_2    (c2h_dsc_byp_ctrl_2    ),
    .h2c_dsc_byp_ready_2   (h2c_dsc_byp_ready_2   ),
    .h2c_dsc_byp_valid_2   (h2c_dsc_byp_valid_2   ),
    .h2c_dsc_byp_src_addr_2(h2c_dsc_byp_src_addr_2),
    .h2c_dsc_byp_dst_addr_2(h2c_dsc_byp_dst_addr_2),
    .h2c_dsc_byp_len_2     (h2c_dsc_byp_len_2     ),
    .h2c_dsc_byp_ctrl_2    (h2c_dsc_byp_ctrl_2    ),

    .c2h_dsc_byp_ready_3   (c2h_dsc_byp_ready_3   ),
    .c2h_dsc_byp_valid_3   (c2h_dsc_byp_valid_3   ),
    .c2h_dsc_byp_src_addr_3(c2h_dsc_byp_src_addr_3),
    .c2h_dsc_byp_dst_addr_3(c2h_dsc_byp_dst_addr_3),
    .c2h_dsc_byp_len_3     (c2h_dsc_byp_len_3     ),
    .c2h_dsc_byp_ctrl_3    (c2h_dsc_byp_ctrl_3    ),
    .h2c_dsc_byp_ready_3   (h2c_dsc_byp_ready_3   ),
    .h2c_dsc_byp_valid_3   (h2c_dsc_byp_valid_3   ),
    .h2c_dsc_byp_src_addr_3(h2c_dsc_byp_src_addr_3),
    .h2c_dsc_byp_dst_addr_3(h2c_dsc_byp_dst_addr_3),
    .h2c_dsc_byp_len_3     (h2c_dsc_byp_len_3     ),
    .h2c_dsc_byp_ctrl_3    (h2c_dsc_byp_ctrl_3    ),

    //user mm_master
    .m_axi_arready       (m_axi_arready       ),
    .m_axi_arvalid       (m_axi_arvalid       ),
    .m_axi_arid          (m_axi_arid          ),
    .m_axi_araddr        (m_axi_araddr        ),
    .m_axi_arlen         (m_axi_arlen         ),
    .m_axi_arsize        (m_axi_arsize        ),
    .m_axi_arburst       (m_axi_arburst       ),
    .m_axi_arprot        (m_axi_arprot        ),
    .m_axi_arlock        (m_axi_arlock        ),
    .m_axi_arcache       (m_axi_arcache       ),
    .m_axi_rready        (m_axi_rready        ),
    .m_axi_rvalid        (m_axi_rvalid        ),
    .m_axi_rid           (m_axi_rid           ),
    .m_axi_rdata         (m_axi_rdata         ),
    .m_axi_ruser         (m_axi_ruser         ),
    .m_axi_rresp         (m_axi_rresp         ),
    .m_axi_rlast         (m_axi_rlast         ),
    .m_axi_awready       (m_axi_awready       ),
    .m_axi_awvalid       (m_axi_awvalid       ),
    .m_axi_awid          (m_axi_awid          ),
    .m_axi_awaddr        (m_axi_awaddr        ),
    .m_axi_awlen         (m_axi_awlen         ),
    .m_axi_awsize        (m_axi_awsize        ),
    .m_axi_awburst       (m_axi_awburst       ),
    .m_axi_awprot        (m_axi_awprot        ),
    .m_axi_awlock        (m_axi_awlock        ),
    .m_axi_awcache       (m_axi_awcache       ),
    .m_axi_wready        (m_axi_wready        ),
    .m_axi_wvalid        (m_axi_wvalid        ),
    .m_axi_wdata         (m_axi_wdata         ),
    .m_axi_wuser         (m_axi_wuser         ),
    .m_axi_wstrb         (m_axi_wstrb         ),
    .m_axi_wlast         (m_axi_wlast         ),
    .m_axi_bready        (m_axi_bready        ),
    .m_axi_bvalid        (m_axi_bvalid        ),
    .m_axi_bid           (m_axi_bid           ),
    .m_axi_bresp         (m_axi_bresp         ),

    //user axis
    .s_axis_c2h_tready_0 (s_axis_c2h_tready_0 ),
    .s_axis_c2h_tvalid_0 (s_axis_c2h_tvalid_0 ),
    .s_axis_c2h_tdata_0  (s_axis_c2h_tdata_0  ),
    .s_axis_c2h_tuser_0  (s_axis_c2h_tuser_0  ),
    .s_axis_c2h_tkeep_0  (s_axis_c2h_tkeep_0  ),
    .s_axis_c2h_tlast_0  (s_axis_c2h_tlast_0  ),

    .m_axis_h2c_tready_0 (m_axis_h2c_tready_0 ),
    .m_axis_h2c_tvalid_0 (m_axis_h2c_tvalid_0 ),
    .m_axis_h2c_tdata_0  (m_axis_h2c_tdata_0  ),
    .m_axis_h2c_tuser_0  (m_axis_h2c_tuser_0  ),
    .m_axis_h2c_tkeep_0  (m_axis_h2c_tkeep_0  ),
    .m_axis_h2c_tlast_0  (m_axis_h2c_tlast_0  ),

    .s_axis_c2h_tready_1 (s_axis_c2h_tready_1 ),
    .s_axis_c2h_tvalid_1 (s_axis_c2h_tvalid_1 ),
    .s_axis_c2h_tdata_1  (s_axis_c2h_tdata_1  ),
    .s_axis_c2h_tuser_1  (s_axis_c2h_tuser_1  ),
    .s_axis_c2h_tkeep_1  (s_axis_c2h_tkeep_1  ),
    .s_axis_c2h_tlast_1  (s_axis_c2h_tlast_1  ),
                                              
    .m_axis_h2c_tready_1 (m_axis_h2c_tready_1 ),
    .m_axis_h2c_tvalid_1 (m_axis_h2c_tvalid_1 ),
    .m_axis_h2c_tdata_1  (m_axis_h2c_tdata_1  ),
    .m_axis_h2c_tuser_1  (m_axis_h2c_tuser_1  ),
    .m_axis_h2c_tkeep_1  (m_axis_h2c_tkeep_1  ),
    .m_axis_h2c_tlast_1  (m_axis_h2c_tlast_1  ),
                                           
    .s_axis_c2h_tready_2 (s_axis_c2h_tready_2 ),
    .s_axis_c2h_tvalid_2 (s_axis_c2h_tvalid_2 ),
    .s_axis_c2h_tdata_2  (s_axis_c2h_tdata_2  ),
    .s_axis_c2h_tuser_2  (s_axis_c2h_tuser_2  ),
    .s_axis_c2h_tkeep_2  (s_axis_c2h_tkeep_2  ),
    .s_axis_c2h_tlast_2  (s_axis_c2h_tlast_2  ),
                                              
    .m_axis_h2c_tready_2 (m_axis_h2c_tready_2 ),
    .m_axis_h2c_tvalid_2 (m_axis_h2c_tvalid_2 ),
    .m_axis_h2c_tdata_2  (m_axis_h2c_tdata_2  ),
    .m_axis_h2c_tuser_2  (m_axis_h2c_tuser_2  ),
    .m_axis_h2c_tkeep_2  (m_axis_h2c_tkeep_2  ),
    .m_axis_h2c_tlast_2  (m_axis_h2c_tlast_2  ),

    .s_axis_c2h_tready_3 (s_axis_c2h_tready_3 ),
    .s_axis_c2h_tvalid_3 (s_axis_c2h_tvalid_3 ),
    .s_axis_c2h_tdata_3  (s_axis_c2h_tdata_3  ),
    .s_axis_c2h_tuser_3  (s_axis_c2h_tuser_3  ),
    .s_axis_c2h_tkeep_3  (s_axis_c2h_tkeep_3  ),
    .s_axis_c2h_tlast_3  (s_axis_c2h_tlast_3  ),
                                              
    .m_axis_h2c_tready_3 (m_axis_h2c_tready_3 ),
    .m_axis_h2c_tvalid_3 (m_axis_h2c_tvalid_3 ),
    .m_axis_h2c_tdata_3  (m_axis_h2c_tdata_3  ),
    .m_axis_h2c_tuser_3  (m_axis_h2c_tuser_3  ),
    .m_axis_h2c_tkeep_3  (m_axis_h2c_tkeep_3  ),
    .m_axis_h2c_tlast_3  (m_axis_h2c_tlast_3  ),

    // user write and read the DMA register 
    // AXI-Lite Slave interface    
    .s_axil_awaddr       (s_axil_awaddr       ),
    .s_axil_awuser       ( 'd0                ),
    .s_axil_awprot       (s_axil_awprot       ),
    .s_axil_awvalid      (s_axil_awvalid      ),
    .s_axil_awready      (s_axil_awready      ),
    .s_axil_wdata        (s_axil_wdata        ),
    .s_axil_wstrb        (s_axil_wstrb        ),
    .s_axil_wvalid       (s_axil_wvalid       ),
    .s_axil_wready       (s_axil_wready       ),
    .s_axil_bvalid       (s_axil_bvalid       ),
    .s_axil_bresp        (s_axil_bresp        ),
    .s_axil_bready       (s_axil_bready       ),
    .s_axil_araddr       (s_axil_araddr       ),
    .s_axil_aruser       ( 'd0                ),
    .s_axil_arprot       (s_axil_arprot       ),
    .s_axil_arvalid      (s_axil_arvalid      ),
    .s_axil_arready      (s_axil_arready      ),
    .s_axil_rdata        (s_axil_rdata        ),
    .s_axil_rresp        (s_axil_rresp        ),
    .s_axil_rvalid       (s_axil_rvalid       ),
    .s_axil_rready       (s_axil_rready       ),

    //axi_mm_master write address channel-master side
    .m_axib_awaddr       (m_axib_awaddr       ),
    .m_axib_awuser       (                    ),
    .m_axib_awlen        (m_axib_awlen        ),
    .m_axib_awsize       (m_axib_awsize       ),
    .m_axib_awburst      (m_axib_awburst      ),
    .m_axib_awprot       (m_axib_awprot       ),
    .m_axib_awlock       (m_axib_awlock       ),
    .m_axib_awcache      (m_axib_awcache      ),
    .m_axib_awvalid      (m_axib_awvalid      ),
    .m_axib_awready      (m_axib_awready      ),
    .m_axib_wdata        (m_axib_wdata        ),
    .m_axib_wstrb        (m_axib_wstrb        ),
    .m_axib_wlast        (m_axib_wlast        ),
    .m_axib_wvalid       (m_axib_wvalid       ),
    .m_axib_wready       (m_axib_wready       ),
    .m_axib_bresp        (m_axib_bresp        ),
    .m_axib_bvalid       (m_axib_bvalid       ),
    .m_axib_bready       (m_axib_bready       ),

    .m_axib_araddr       (m_axib_araddr       ),
    .m_axib_aruser       (                    ),
    .m_axib_arid         (m_axib_arid         ),
    .m_axib_arlen        (m_axib_arlen        ),
    .m_axib_arsize       (m_axib_arsize       ),
    .m_axib_arprot       (m_axib_arprot       ),
    .m_axib_arlock       (m_axib_arlock       ),
    .m_axib_arcache      (m_axib_arcache      ),
    .m_axib_arburst      (m_axib_arburst      ),
    .m_axib_arvalid      (m_axib_arvalid      ),
    .m_axib_arready      (m_axib_arready      ),
    .m_axib_rdata        (m_axib_rdata        ),
    .m_axib_rid          (m_axib_rid          ),
    .m_axib_rresp        (m_axib_rresp        ),
    .m_axib_rlast        (m_axib_rlast        ),
    .m_axib_rvalid       (m_axib_rvalid       ),
    .m_axib_rready       (m_axib_rready       ),

    //axi_lite_master DMA register write channel
    .m_axil_awaddr       (m_axil_awaddr       ),
    .m_axil_awuser       (                    ),
    .m_axil_awprot       (m_axil_awprot       ),
    .m_axil_awvalid      (m_axil_awvalid      ),
    .m_axil_awready      (m_axil_awready      ),
    .m_axil_awlock       (m_axil_awlock       ),
    .m_axil_wdata        (m_axil_wdata        ),
    .m_axil_wstrb        (m_axil_wstrb        ),
    .m_axil_wvalid       (m_axil_wvalid       ),
    .m_axil_wready       (m_axil_wready       ),
    .m_axil_bresp        (m_axil_bresp        ),
    .m_axil_bvalid       (m_axil_bvalid       ),
    .m_axil_bready       (m_axil_bready       ),
    .m_axil_araddr       (m_axil_araddr       ),
    .m_axil_aruser       (                    ),
    .m_axil_arprot       (m_axil_arprot       ),
    .m_axil_arvalid      (m_axil_arvalid      ),
    .m_axil_arready      (m_axil_arready      ),
    .m_axil_rdata        (m_axil_rdata        ),
    .m_axil_rresp        (m_axil_rresp        ),
    .m_axil_rvalid       (m_axil_rvalid       ),
    .m_axil_rready       (m_axil_rready       ),

    .c2h_status_0        (c2h_status_0        ),
    .h2c_status_0        (h2c_status_0        ),
    .c2h_status_1        (c2h_status_1        ),
    .h2c_status_1        (h2c_status_1        ),
    .c2h_status_2        (c2h_status_2        ),
    .h2c_status_2        (h2c_status_2        ),
    .c2h_status_3        (c2h_status_3        ),
    .h2c_status_3        (h2c_status_3        )
);



/*axi_ram #(
    .MEMORY_DEPTH                (AXI_RAM_DEPTH),
    .AXI_DATA_WIDTH              (M_AXI_DATA_WIDTH),
    .AXI_ID_WIDTH                (M_AXI_ID_WIDTH  )
)
u_axi_ram (
    .s_axi_aclk                  (axi_clk  ),
    .s_axi_aresetn               (axi_rst_n),
                                
    .s_axi_awid                  (m_axi_awid                      ),                         
    .s_axi_awaddr                (m_axi_awaddr[$clog2(AXI_RAM_DEPTH*M_AXI_DATA_WIDTH/8)-1:0]),
    .s_axi_awlen                 (m_axi_awlen                     ),
    .s_axi_awsize                (m_axi_awsize                    ),
    .s_axi_awburst               (m_axi_awburst                   ),
    .s_axi_awlock                (m_axi_awlock                    ),
    .s_axi_awcache               (m_axi_awcache                   ),
    .s_axi_awprot                (m_axi_awprot                    ),
    .s_axi_awvalid               (m_axi_awvalid                   ),
    .s_axi_awready               (m_axi_awready                   ),
                             
    .s_axi_wdata                 (m_axi_wdata                     ),
    .s_axi_wstrb                 (m_axi_wstrb                     ),
    .s_axi_wlast                 (m_axi_wlast                     ),
    .s_axi_wvalid                (m_axi_wvalid                    ),
    .s_axi_wready                (m_axi_wready                    ),
                              
    .s_axi_bid                   (m_axi_bid                       ),                             
    .s_axi_bresp                 (m_axi_bresp                     ),
    .s_axi_bvalid                (m_axi_bvalid                    ),
    .s_axi_bready                (m_axi_bready                    ),
                               
    .s_axi_arid                  (m_axi_arid                      ),                               
    .s_axi_araddr                (m_axi_araddr[$clog2(AXI_RAM_DEPTH*M_AXI_DATA_WIDTH/8)-1:0]),
    .s_axi_arlen                 (m_axi_arlen                     ),
    .s_axi_arsize                (m_axi_arsize                    ),
    .s_axi_arburst               (m_axi_arburst                   ),
    .s_axi_arlock                (m_axi_arlock                    ),
    .s_axi_arcache               (m_axi_arcache                   ),
    .s_axi_arprot                (m_axi_arprot                    ),
    .s_axi_arvalid               (m_axi_arvalid                   ),
    .s_axi_arready               (m_axi_arready                   ),
                                
    .s_axi_rid                   (m_axi_rid                       ),                               
    .s_axi_rdata                 (m_axi_rdata                     ),
    .s_axi_rresp                 (m_axi_rresp                     ),
    .s_axi_rlast                 (m_axi_rlast                     ),
    .s_axi_rvalid                (m_axi_rvalid                    ),
    .s_axi_rready                (m_axi_rready                    )
);

  
axi_ram #(
    .MEMORY_DEPTH                (AXI_BYPASS_DEPTH),
    .AXI_DATA_WIDTH              (M_AXI_DATA_WIDTH)
)
u_axi_ram_bypass (
    .s_axi_aclk                  (axi_clk),
    .s_axi_aresetn               (axib_rst_n),
                                
    .s_axi_awid                  (m_axib_awid),
                                
    .s_axi_awaddr                (m_axib_awaddr),
    .s_axi_awlen                 (m_axib_awlen  ),
    .s_axi_awsize                (m_axib_awsize ),
    .s_axi_awburst               (m_axib_awburst),
    .s_axi_awlock                (m_axib_awlock ),
    .s_axi_awcache               (m_axib_awcache),
    .s_axi_awprot                (m_axib_awprot ),
    .s_axi_awvalid               (m_axib_awvalid),
    .s_axi_awready               (m_axib_awready),
                             
    .s_axi_wdata                 (m_axib_wdata ),
    .s_axi_wstrb                 (m_axib_wstrb ),
    .s_axi_wlast                 (m_axib_wlast ),
    .s_axi_wvalid                (m_axib_wvalid),
    .s_axi_wready                (m_axib_wready),
                              
    .s_axi_bid                   (m_axib_bid),
                             
    .s_axi_bresp                 (m_axib_bresp ),
    .s_axi_bvalid                (m_axib_bvalid),
    .s_axi_bready                (m_axib_bready),
                               
    .s_axi_arid                  (m_axib_arid),
                               
    .s_axi_araddr                (m_axib_araddr ),
    .s_axi_arlen                 (m_axib_arlen  ),
    .s_axi_arsize                (m_axib_arsize ),
    .s_axi_arburst               (m_axib_arburst),
    .s_axi_arlock                (m_axib_arlock ),
    .s_axi_arcache               (m_axib_arcache),
    .s_axi_arprot                (m_axib_arprot ),
    .s_axi_arvalid               (m_axib_arvalid),
    .s_axi_arready               (m_axib_arready),
                                
    .s_axi_rid                   (m_axib_rid),
                               
    .s_axi_rdata                 (m_axib_rdata ),
    .s_axi_rresp                 (m_axib_rresp ),
    .s_axi_rlast                 (m_axib_rlast ),
    .s_axi_rvalid                (m_axib_rvalid),
    .s_axi_rready                (m_axib_rready)
);
               


axi_lite_ram #(
    .MEMORY_DEPTH                (AXI_LITE_DEPTH)
)
u_axi_lite_ram(
    .s_axi_aclk                  (axi_clk),
    .s_axi_aresetn               (axi_rst_n),
                                
    .s_axi_awaddr                (m_axil_awaddr),
    .s_axi_awvalid               (m_axil_awvalid),
    .s_axi_awready               (m_axil_awready),
                              
    .s_axi_wdata                 (m_axil_wdata),
    .s_axi_wstrb                 (m_axil_wstrb ),
    .s_axi_wvalid                (m_axil_wvalid),
    .s_axi_wready                (m_axil_wready),
                              
    .s_axi_bresp                 (m_axil_bresp ),
    .s_axi_bvalid                (m_axil_bvalid),
    .s_axi_bready                (m_axil_bready),
                               
    .s_axi_araddr                (m_axil_araddr),
    .s_axi_arvalid               (m_axil_arvalid),
    .s_axi_arready               (m_axil_arready),
                              
    .s_axi_rdata                 (m_axil_rdata ),
    .s_axi_rresp                 (m_axil_rresp ),
    .s_axi_rvalid                (m_axil_rvalid),
    .s_axi_rready                (m_axil_rready)
);*/

// ====================================================================
// 1. Tie off unused channels to prevent floating DMA channels from hanging PCIe.
// ====================================================================
assign m_axis_h2c_tready_1 = 1'b0;
assign m_axis_h2c_tready_2 = 1'b0;
assign m_axis_h2c_tready_3 = 1'b0;

assign s_axis_c2h_tvalid_1 = 1'b0;
assign s_axis_c2h_tvalid_2 = 1'b0;
assign s_axis_c2h_tvalid_3 = 1'b0;
assign s_axis_c2h_tdata_1  = '0;
assign s_axis_c2h_tdata_2  = '0;
assign s_axis_c2h_tdata_3  = '0;
assign s_axis_c2h_tkeep_1  = '0;
assign s_axis_c2h_tkeep_2  = '0;
assign s_axis_c2h_tkeep_3  = '0;
assign s_axis_c2h_tlast_1  = 1'b0;
assign s_axis_c2h_tlast_2  = 1'b0;
assign s_axis_c2h_tlast_3  = 1'b0;

// Tie off user sideband signals (TUSER).
assign s_axis_c2h_tuser_0  = '0; 
// Tie off the AXI-MM response/ready inputs left undriven by the commented RAMs.
assign m_axi_arready  = 1'b0;
assign m_axi_rvalid   = 1'b0;
assign m_axi_rresp    = 2'b0;
assign m_axi_rdata    = '0;
assign m_axi_rid      = '0;
assign m_axi_rlast    = 1'b0;
assign m_axi_ruser    = '0;
assign m_axi_awready  = 1'b0;
assign m_axi_wready   = 1'b0;
assign m_axi_bvalid   = 1'b0;
assign m_axi_bresp    = 2'b0;
assign m_axi_bid      = '0;

assign m_axib_arready = 1'b0;
assign m_axib_rvalid  = 1'b0;
assign m_axib_rresp   = 2'b0;
assign m_axib_rdata   = '0;
assign m_axib_rid     = '0;
assign m_axib_rlast   = 1'b0;
assign m_axib_ruser   = '0;
assign m_axib_awready = 1'b0;
assign m_axib_wready  = 1'b0;
assign m_axib_bvalid  = 1'b0;
assign m_axib_bresp   = 2'b0;
assign m_axib_bid     = '0;


// ====================================================================
// 2. Instantiate SystemVerilog interfaces.
// Keep interface parameters aligned with the BDMA configuration (128-bit data, 32-bit address).
// ====================================================================
axi4_stream_if #(.TDATA_WIDTH(M_AXI_DATA_WIDTH)) aes_s_axis ();
axi4_stream_if #(.TDATA_WIDTH(M_AXI_DATA_WIDTH)) aes_m_axis ();
axi4_lite_if   #(.C_S_AXI_ADDR_WIDTH(32), .C_S_AXI_DATA_WIDTH(32)) aes_axil ();

logic [31:0]                     m_axil_s_awaddr;
logic [2:0]                      m_axil_s_awprot;
logic                            m_axil_s_awvalid;
logic                            m_axil_s_awready;
logic [31:0]                     m_axil_s_wdata;
logic [3:0]                      m_axil_s_wstrb;
logic                            m_axil_s_wvalid;
logic                            m_axil_s_wready;
logic [1:0]                      m_axil_s_bresp;
logic                            m_axil_s_bvalid;
logic                            m_axil_s_bready;
logic [31:0]                     m_axil_s_araddr;
logic [2:0]                      m_axil_s_arprot;
logic                            m_axil_s_arvalid;
logic                            m_axil_s_arready;
logic [31:0]                     m_axil_s_rdata;
logic [1:0]                      m_axil_s_rresp;
logic                            m_axil_s_rvalid;
logic                            m_axil_s_rready;

logic                            ram_awvalid;
logic                            ram_awready;
logic [31:0]                     ram_awaddr;
logic [31:0]                     ram_wdata;
logic [3:0]                      ram_wstrb;
logic                            ram_wvalid;
logic                            ram_wready;
logic [1:0]                      ram_bresp;
logic                            ram_bvalid;
logic                            ram_bready;
logic [31:0]                     ram_araddr;
logic                            ram_arvalid;
logic                            ram_arready;
logic [31:0]                     ram_rdata;
logic [1:0]                      ram_rresp;
logic                            ram_rvalid;
logic                            ram_rready;
logic                            aw_sel;
logic                            ar_sel;
logic                            aw_sel_r;
logic                            ar_sel_r;

localparam [31:0] AES_AXIL_BASE = 32'h0000_4000;

axil_reg_slice u_axil_reg_slice (
    .clk            (axi_clk),
    .rst_n          (axi_rst_n),

    .s_axil_awaddr  (m_axil_awaddr),
    .s_axil_awprot  (m_axil_awprot),
    .s_axil_awvalid (m_axil_awvalid),
    .s_axil_awready (m_axil_awready),
    .m_axil_awaddr  (m_axil_s_awaddr),
    .m_axil_awprot  (m_axil_s_awprot),
    .m_axil_awvalid (m_axil_s_awvalid),
    .m_axil_awready (m_axil_s_awready),

    .s_axil_wdata   (m_axil_wdata),
    .s_axil_wstrb   (m_axil_wstrb),
    .s_axil_wvalid  (m_axil_wvalid),
    .s_axil_wready  (m_axil_wready),
    .m_axil_wdata   (m_axil_s_wdata),
    .m_axil_wstrb   (m_axil_s_wstrb),
    .m_axil_wvalid  (m_axil_s_wvalid),
    .m_axil_wready  (m_axil_s_wready),

    .s_axil_bresp   (m_axil_s_bresp),
    .s_axil_bvalid  (m_axil_s_bvalid),
    .s_axil_bready  (m_axil_s_bready),
    .m_axil_bresp   (m_axil_bresp),
    .m_axil_bvalid  (m_axil_bvalid),
    .m_axil_bready  (m_axil_bready),

    .s_axil_araddr  (m_axil_araddr),
    .s_axil_arprot  (m_axil_arprot),
    .s_axil_arvalid (m_axil_arvalid),
    .s_axil_arready (m_axil_arready),
    .m_axil_araddr  (m_axil_s_araddr),
    .m_axil_arprot  (m_axil_s_arprot),
    .m_axil_arvalid (m_axil_s_arvalid),
    .m_axil_arready (m_axil_s_arready),

    .s_axil_rdata   (m_axil_s_rdata),
    .s_axil_rresp   (m_axil_s_rresp),
    .s_axil_rvalid  (m_axil_s_rvalid),
    .s_axil_rready  (m_axil_s_rready),
    .m_axil_rdata   (m_axil_rdata),
    .m_axil_rresp   (m_axil_rresp),
    .m_axil_rvalid  (m_axil_rvalid),
    .m_axil_rready  (m_axil_rready)
);

// Provide the AXI clock and reset to all interfaces.
assign aes_s_axis.aclk    = axi_clk;
assign aes_s_axis.aresetn = axi_rst_n;
assign aes_m_axis.aclk    = axi_clk;
assign aes_m_axis.aresetn = axi_rst_n;
assign aes_axil.aclk      = axi_clk;
assign aes_axil.aresetn   = axi_rst_n;


// ====================================================================
// 3. Route the AXI-Lite control channel (m_axil_*) to the AES control interface.
// Decode addresses and pass only the low 8 bits to the wrapper register map.
// ====================================================================
assign aw_sel = (m_axil_s_awaddr >= AES_AXIL_BASE);
assign ar_sel = (m_axil_s_araddr >= AES_AXIL_BASE);

always @(posedge axi_clk or negedge axi_rst_n) begin
    if (!axi_rst_n) begin
        aw_sel_r <= 1'b0;
        ar_sel_r <= 1'b0;
    end else begin
        if (m_axil_s_awvalid && m_axil_s_awready)
            aw_sel_r <= aw_sel;
        if (m_axil_s_arvalid && m_axil_s_arready)
            ar_sel_r <= ar_sel;
    end
end

assign aes_axil.awaddr  = {24'd0, m_axil_s_awaddr[7:0]};
assign aes_axil.awprot  = 3'b0;
assign aes_axil.awvalid = m_axil_s_awvalid && aw_sel;
assign ram_awaddr       = m_axil_s_awaddr;
assign ram_awvalid      = m_axil_s_awvalid && !aw_sel;
assign m_axil_s_awready = aw_sel ? aes_axil.awready : ram_awready;

assign aes_axil.wdata   = m_axil_s_wdata;
assign aes_axil.wstrb   = m_axil_s_wstrb;
assign aes_axil.wvalid  = m_axil_s_wvalid && aw_sel;
assign ram_wdata        = m_axil_s_wdata;
assign ram_wstrb        = m_axil_s_wstrb;
assign ram_wvalid       = m_axil_s_wvalid && !aw_sel;
assign m_axil_s_wready  = aw_sel ? aes_axil.wready : ram_wready;

assign m_axil_s_bresp   = aw_sel_r ? aes_axil.bresp : ram_bresp;
assign m_axil_s_bvalid  = aw_sel_r ? aes_axil.bvalid : ram_bvalid;
assign aes_axil.bready  = m_axil_s_bready && aw_sel_r;
assign ram_bready       = m_axil_s_bready && !aw_sel_r;

assign aes_axil.araddr  = {24'd0, m_axil_s_araddr[7:0]};
assign aes_axil.arprot  = 3'b0;
assign aes_axil.arvalid = m_axil_s_arvalid && ar_sel;
assign ram_araddr       = m_axil_s_araddr;
assign ram_arvalid      = m_axil_s_arvalid && !ar_sel;
assign m_axil_s_arready = ar_sel ? aes_axil.arready : ram_arready;

assign m_axil_s_rdata   = ar_sel_r ? aes_axil.rdata : ram_rdata;
assign m_axil_s_rresp   = ar_sel_r ? aes_axil.rresp : ram_rresp;
assign m_axil_s_rvalid  = ar_sel_r ? aes_axil.rvalid : ram_rvalid;
assign aes_axil.rready  = m_axil_s_rready && ar_sel_r;
assign ram_rready       = m_axil_s_rready && !ar_sel_r;


// ====================================================================
// 4. Instantiate the AES core wrapper.
// Connect interface instances directly; do not append a modport here.
// ====================================================================
aes_axi_wrapper #(
    .C_S_AXI_ADDR_WIDTH(32), // Must override the default 5-bit address width.
    .C_S_AXI_DATA_WIDTH(32),
    .TDATA_WIDTH(M_AXI_DATA_WIDTH)
) u_aes_axi (
    .axi_lite (aes_axil),    // Interface instance, not aes_axil.slave.
    .s_axis   (aes_s_axis),  // Interface instance, not aes_s_axis.slave.
    .m_axis   (aes_m_axis)   // Interface instance, not aes_m_axis.master.
);


// ====================================================================
// 5. Instantiate the stream adapter between the DMA streams and AES core.
// ====================================================================
aes_axis_adapter u_aes_adapter (
    .clk            (axi_clk),
    .rst_n          (axi_rst_n),
    
    // --> Receive side: connect DMA H2C channel 0 data from the host.
    .s_axis_tdata   (m_axis_h2c_tdata_0),
    .s_axis_tkeep   (m_axis_h2c_tkeep_0),
    .s_axis_tlast   (m_axis_h2c_tlast_0),
    .s_axis_tvalid  (m_axis_h2c_tvalid_0),
    .s_axis_tready  (m_axis_h2c_tready_0),

    // <-- Transmit side: return AES ciphertext to DMA C2H channel 0.
    .m_axis_tdata   (s_axis_c2h_tdata_0),
    .m_axis_tkeep   (s_axis_c2h_tkeep_0),
    .m_axis_tlast   (s_axis_c2h_tlast_0),
    .m_axis_tvalid  (s_axis_c2h_tvalid_0),
    .m_axis_tready  (s_axis_c2h_tready_0),

    // AES wrapper stream handshake.
    .aes_in_tdata   (aes_s_axis.tdata),
    .aes_in_tvalid  (aes_s_axis.tvalid),
    .aes_in_tready  (aes_s_axis.tready),
    
    .aes_out_tdata  (aes_m_axis.tdata),
    .aes_out_tvalid (aes_m_axis.tvalid),
    .aes_out_tready (aes_m_axis.tready)
);

// Tie AES slave sideband high; the adapter preserves the real TLAST.
assign aes_s_axis.tstrb = 16'hFFFF;
assign aes_s_axis.tlast = 1'b1;

// Re-instantiate axi_lite_ram
axi_lite_ram #(
    .MEMORY_DEPTH(AXI_LITE_DEPTH)
) u_axi_lite_ram (
    .s_axi_aclk   (axi_clk),
    .s_axi_aresetn(axi_rst_n),

    .s_axi_awaddr (ram_awaddr),
    .s_axi_awvalid(ram_awvalid),
    .s_axi_awready(ram_awready),

    .s_axi_wdata  (ram_wdata),
    .s_axi_wstrb  (ram_wstrb),
    .s_axi_wvalid (ram_wvalid),
    .s_axi_wready (ram_wready),

    .s_axi_bresp  (ram_bresp),
    .s_axi_bvalid (ram_bvalid),
    .s_axi_bready (ram_bready),

    .s_axi_araddr (ram_araddr),
    .s_axi_arvalid(ram_arvalid),
    .s_axi_arready(ram_arready),

    .s_axi_rdata  (ram_rdata),
    .s_axi_rresp  (ram_rresp),
    .s_axi_rvalid (ram_rvalid),
    .s_axi_rready (ram_rready)
);
  

always @(posedge axi_clk or negedge axi_rst_n) 
begin
    if (!axi_rst_n)
        msi_status <= 1'b0;
    else 
        msi_status <= (|cfg_msi_en) && (|cfg_multi_msi_en) && (|cfg_msix_en);
end  


always @(posedge axi_clk or negedge axi_rst_n) 
begin
    if (!axi_rst_n)
        user_int_req <= 'd0;
    else if(user_int_grt)
        user_int_req <= 1'b0;
    //else if()
    //    user_int_req <= 1'b1;
end  
    

endmodule

module axil_skid_buffer #(
    parameter DATA_WIDTH = 32
)(
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire [DATA_WIDTH-1:0] s_data,
    input  wire                  s_valid,
    output wire                  s_ready,
    output wire [DATA_WIDTH-1:0] m_data,
    output wire                  m_valid,
    input  wire                  m_ready
);

    reg [DATA_WIDTH-1:0] data_q;
    reg                  valid_q;
    reg [DATA_WIDTH-1:0] data_skid;
    reg                  valid_skid;

    assign s_ready = !valid_skid;
    assign m_data  = data_q;
    assign m_valid = valid_q;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_q     <= '0;
            valid_q    <= 1'b0;
            data_skid  <= '0;
            valid_skid <= 1'b0;
        end else begin
            if (m_ready) begin
                if (valid_skid) begin
                    data_q     <= data_skid;
                    valid_q    <= 1'b1;
                    valid_skid <= 1'b0;
                end else begin
                    data_q  <= s_data;
                    valid_q <= s_valid;
                end
            end else if (!valid_q) begin
                data_q  <= s_data;
                valid_q <= s_valid;
            end

            if (s_valid && s_ready && valid_q && !m_ready) begin
                data_skid  <= s_data;
                valid_skid <= 1'b1;
            end
        end
    end

endmodule

module axil_reg_slice (
    input  wire         clk,
    input  wire         rst_n,

    input  wire [31:0]  s_axil_awaddr,
    input  wire [2:0]   s_axil_awprot,
    input  wire         s_axil_awvalid,
    output wire         s_axil_awready,
    output wire [31:0]  m_axil_awaddr,
    output wire [2:0]   m_axil_awprot,
    output wire         m_axil_awvalid,
    input  wire         m_axil_awready,

    input  wire [31:0]  s_axil_wdata,
    input  wire [3:0]   s_axil_wstrb,
    input  wire         s_axil_wvalid,
    output wire         s_axil_wready,
    output wire [31:0]  m_axil_wdata,
    output wire [3:0]   m_axil_wstrb,
    output wire         m_axil_wvalid,
    input  wire         m_axil_wready,

    input  wire [1:0]   s_axil_bresp,
    input  wire         s_axil_bvalid,
    output wire         s_axil_bready,
    output wire [1:0]   m_axil_bresp,
    output wire         m_axil_bvalid,
    input  wire         m_axil_bready,

    input  wire [31:0]  s_axil_araddr,
    input  wire [2:0]   s_axil_arprot,
    input  wire         s_axil_arvalid,
    output wire         s_axil_arready,
    output wire [31:0]  m_axil_araddr,
    output wire [2:0]   m_axil_arprot,
    output wire         m_axil_arvalid,
    input  wire         m_axil_arready,

    input  wire [31:0]  s_axil_rdata,
    input  wire [1:0]   s_axil_rresp,
    input  wire         s_axil_rvalid,
    output wire         s_axil_rready,
    output wire [31:0]  m_axil_rdata,
    output wire [1:0]   m_axil_rresp,
    output wire         m_axil_rvalid,
    input  wire         m_axil_rready
);

    axil_skid_buffer #(.DATA_WIDTH(35)) u_aw_slice (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  ({s_axil_awaddr, s_axil_awprot}),
        .s_valid (s_axil_awvalid),
        .s_ready (s_axil_awready),
        .m_data  ({m_axil_awaddr, m_axil_awprot}),
        .m_valid (m_axil_awvalid),
        .m_ready (m_axil_awready)
    );

    axil_skid_buffer #(.DATA_WIDTH(36)) u_w_slice (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  ({s_axil_wdata, s_axil_wstrb}),
        .s_valid (s_axil_wvalid),
        .s_ready (s_axil_wready),
        .m_data  ({m_axil_wdata, m_axil_wstrb}),
        .m_valid (m_axil_wvalid),
        .m_ready (m_axil_wready)
    );

    axil_skid_buffer #(.DATA_WIDTH(2)) u_b_slice (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  (s_axil_bresp),
        .s_valid (s_axil_bvalid),
        .s_ready (s_axil_bready),
        .m_data  (m_axil_bresp),
        .m_valid (m_axil_bvalid),
        .m_ready (m_axil_bready)
    );

    axil_skid_buffer #(.DATA_WIDTH(35)) u_ar_slice (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  ({s_axil_araddr, s_axil_arprot}),
        .s_valid (s_axil_arvalid),
        .s_ready (s_axil_arready),
        .m_data  ({m_axil_araddr, m_axil_arprot}),
        .m_valid (m_axil_arvalid),
        .m_ready (m_axil_arready)
    );

    axil_skid_buffer #(.DATA_WIDTH(34)) u_r_slice (
        .clk     (clk),
        .rst_n   (rst_n),
        .s_data  ({s_axil_rdata, s_axil_rresp}),
        .s_valid (s_axil_rvalid),
        .s_ready (s_axil_rready),
        .m_data  ({m_axil_rdata, m_axil_rresp}),
        .m_valid (m_axil_rvalid),
        .m_ready (m_axil_rready)
    );

endmodule
