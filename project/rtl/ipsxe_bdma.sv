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
// Filename: 
//////////////////////////////////////////////////////////////////////////////
module ipsxe_bdma #(
    parameter IP_ID                   = 12'h803                ,
    parameter IP_VERSION              = 1                      ,
    parameter C_FAMILY                = "TITAN2"               ,
    parameter C_DEVICE                = "PG2T390H"             ,
    parameter PCIE_MAX_LINK_WIDTH     = 1                      ,
    parameter M_AXI_DATA_WIDTH        = 64                     ,
    parameter M_AXI_ADDR_WIDTH        = 64                     ,
    parameter M_AXI_ID_WIDTH          = 4                      ,
    parameter M_AXI_AWUSER_WIDTH      = 32                     ,
    parameter M_AXI_ARUSER_WIDTH      = 32                     ,
    parameter AXI_WRITE_NUM           = 8                      ,
    parameter AXI_READ_NUM            = 8                      ,
    parameter AXI_LITE_MASTER         = "TRUE"                 ,
    parameter PCIE2AXIBAR_0           = 64'h00000000_00000000  ,
    parameter PCIE2AXIBAR_1           = 64'h00000000_00000000  ,
    parameter PCIE2AXIBAR_2           = 64'h00000000_00000000  ,  
    parameter BAR0_SIZE_WIDTH         = 15                     ,
    parameter BAR1_SIZE_WIDTH         = 16                     ,
    parameter BAR2_SIZE_WIDTH         = 15                     ,
    parameter DMA_EN                  = 1                      ,
    parameter DMA_STS_PORTS           = "TRUE"                 ,
    parameter H2C_CHNL_NUM            = 4                      ,
    parameter C2H_CHNL_NUM            = 4                      ,
    parameter H2C_RID_NUM             = 64                     ,
    parameter C2H_RID_NUM             = 32                     ,
    parameter DMA_STS_WIDTH           = 8                      ,
    parameter DMA_AXIMM               = 1                      ,
    parameter DMA_AXIS                = 0                      ,
    parameter C2H_DSC_BYPASS          = 0                      ,
    parameter H2C_DSC_BYPASS          = 0                      ,
    parameter H2C_RAM_DEPTH           = 512                    ,
    parameter C2H_RAM_DEPTH           = 512                    ,
    parameter DSC_RAM_DEPTH           = 512                    ,
    parameter BRDG_RAM_DEPTH          = 512                    ,
    parameter DSC_MGC_EN              = 1                      ,                                  
    parameter USR_IRQ_NUM             = 16                     ,
    parameter MSIX_VECTORS_NUM        = 32                     ,
    parameter AXI_USER_MRRS_SIZE      = 4096                   ,
    parameter AXI_USER_MPL_SIZE       = 4096                   ,
    parameter PCIE_MRRS_SIZE          = 1024                   ,
    parameter PCIE_MPL_SIZE           = 1024                   ,
    parameter PCIE_TAG_NUM            = 64                     ,
    parameter AXIL_AWUSER_WIDTH       = 8                      ,
    parameter AXIL_ARUSER_WIDTH       = 8                      ,
    parameter PCIE_MAX_LINK_SPEED     = 2                      ,
    parameter MSIX_REG_ADDR_ID        = 4'h8                   
)
(
    input                                             perst_n            ,
    //clk and rst                                     
    input                                             ref_clk_n          ,      //100 Mhz
    input                                             ref_clk_p          ,      //100 Mhz
    //diff signals                                    
    input  [PCIE_MAX_LINK_WIDTH-1:0]                  rxn                ,
    input  [PCIE_MAX_LINK_WIDTH-1:0]                  rxp                ,
    output [PCIE_MAX_LINK_WIDTH-1:0]                  txn                ,
    output [PCIE_MAX_LINK_WIDTH-1:0]                  txp                ,
    output                                            axi_clk            ,
    output                                            axi_rst_n          ,
    output                                            ref_clk            ,

    output                                            pcie_link_up       ,
    output                                            cfg_msi_en         ,
    output [2:0]                                      cfg_multi_msi_en   ,
    output                                            cfg_msix_en        ,

    input  [USR_IRQ_NUM-1:0]                          i_user_int_req     ,
    output [USR_IRQ_NUM-1:0]                          o_user_int_grt     ,

    //user dsc_bypass
    output                                            c2h_dsc_byp_ready_0   ,
    input                                             c2h_dsc_byp_valid_0   ,
    input  [64-1:0]                                   c2h_dsc_byp_src_addr_0,
    input  [64-1:0]                                   c2h_dsc_byp_dst_addr_0,
    input  [28-1:0]                                   c2h_dsc_byp_len_0     ,
    input  [8-1:0]                                    c2h_dsc_byp_ctrl_0    ,

    output                                            h2c_dsc_byp_ready_0   ,
    input                                             h2c_dsc_byp_valid_0   ,
    input  [64-1:0]                                   h2c_dsc_byp_src_addr_0,
    input  [64-1:0]                                   h2c_dsc_byp_dst_addr_0,
    input  [28-1:0]                                   h2c_dsc_byp_len_0     ,
    input  [8-1:0]                                    h2c_dsc_byp_ctrl_0    ,

    output                                            c2h_dsc_byp_ready_1   ,
    input                                             c2h_dsc_byp_valid_1   ,
    input  [64-1:0]                                   c2h_dsc_byp_src_addr_1,
    input  [64-1:0]                                   c2h_dsc_byp_dst_addr_1,
    input  [28-1:0]                                   c2h_dsc_byp_len_1     ,
    input  [8-1:0]                                    c2h_dsc_byp_ctrl_1    ,

    output                                            h2c_dsc_byp_ready_1   ,
    input                                             h2c_dsc_byp_valid_1   ,
    input  [64-1:0]                                   h2c_dsc_byp_src_addr_1,
    input  [64-1:0]                                   h2c_dsc_byp_dst_addr_1,
    input  [28-1:0]                                   h2c_dsc_byp_len_1     ,
    input  [8-1:0]                                    h2c_dsc_byp_ctrl_1    ,

    output                                            c2h_dsc_byp_ready_2   ,
    input                                             c2h_dsc_byp_valid_2   ,
    input  [64-1:0]                                   c2h_dsc_byp_src_addr_2,
    input  [64-1:0]                                   c2h_dsc_byp_dst_addr_2,
    input  [28-1:0]                                   c2h_dsc_byp_len_2     ,
    input  [8-1:0]                                    c2h_dsc_byp_ctrl_2    ,

    output                                            h2c_dsc_byp_ready_2   ,
    input                                             h2c_dsc_byp_valid_2   ,
    input  [64-1:0]                                   h2c_dsc_byp_src_addr_2,
    input  [64-1:0]                                   h2c_dsc_byp_dst_addr_2,
    input  [28-1:0]                                   h2c_dsc_byp_len_2     ,
    input  [8-1:0]                                    h2c_dsc_byp_ctrl_2    ,

    output                                            c2h_dsc_byp_ready_3   ,
    input                                             c2h_dsc_byp_valid_3   ,
    input  [64-1:0]                                   c2h_dsc_byp_src_addr_3,
    input  [64-1:0]                                   c2h_dsc_byp_dst_addr_3,
    input  [28-1:0]                                   c2h_dsc_byp_len_3     ,
    input  [8-1:0]                                    c2h_dsc_byp_ctrl_3    ,

    output                                            h2c_dsc_byp_ready_3   ,
    input                                             h2c_dsc_byp_valid_3   ,
    input  [64-1:0]                                   h2c_dsc_byp_src_addr_3,
    input  [64-1:0]                                   h2c_dsc_byp_dst_addr_3,
    input  [28-1:0]                                   h2c_dsc_byp_len_3     ,
    input  [8-1:0]                                    h2c_dsc_byp_ctrl_3    ,

    //user mm_master
    input                                             m_axi_arready       ,
    output                                            m_axi_arvalid       ,
    output [M_AXI_ID_WIDTH-1:0]                       m_axi_arid          ,
    output [M_AXI_ADDR_WIDTH-1:0]                     m_axi_araddr        ,
    output [7:0]                                      m_axi_arlen         ,
    output [2:0]                                      m_axi_arsize        ,
    output [1:0]                                      m_axi_arburst       ,
    output [2:0]                                      m_axi_arprot        ,
    output                                            m_axi_arlock        ,
    output [3:0]                                      m_axi_arcache       ,
                    
    output                                            m_axi_rready        ,
    input                                             m_axi_rvalid        ,
    input  [M_AXI_ID_WIDTH-1:0]                       m_axi_rid           ,
    input  [M_AXI_DATA_WIDTH-1:0]                     m_axi_rdata         ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   m_axi_ruser         ,
    input  [1:0]                                      m_axi_rresp         ,
    input                                             m_axi_rlast         ,
                    
    input                                             m_axi_awready       ,
    output                                            m_axi_awvalid       ,
    output [M_AXI_ID_WIDTH-1:0]                       m_axi_awid          ,
    output [M_AXI_ADDR_WIDTH-1:0]                     m_axi_awaddr        ,
    output [7:0]                                      m_axi_awlen         ,
    output [2:0]                                      m_axi_awsize        ,
    output [1:0]                                      m_axi_awburst       ,
    output [2:0]                                      m_axi_awprot        ,
    output                                            m_axi_awlock        ,
    output [3:0]                                      m_axi_awcache       ,
                                                                                                                     
    input                                             m_axi_wready        ,
    output                                            m_axi_wvalid        ,
    output [M_AXI_DATA_WIDTH-1:0]                     m_axi_wdata         ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axi_wuser         ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axi_wstrb         ,
    output                                            m_axi_wlast         ,
                                                                          
    output                                            m_axi_bready        ,
    input                                             m_axi_bvalid        ,
    input  [M_AXI_ID_WIDTH-1:0]                       m_axi_bid           ,
    input  [1:0]                                      m_axi_bresp         ,

    //user axis
    output                                            s_axis_c2h_tready_0 ,
    input                                             s_axis_c2h_tvalid_0 ,
    input  [M_AXI_DATA_WIDTH-1:0]                     s_axis_c2h_tdata_0  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tuser_0  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tkeep_0  ,
    input                                             s_axis_c2h_tlast_0  ,
                                                                         
    input                                             m_axis_h2c_tready_0 ,
    output                                            m_axis_h2c_tvalid_0 ,
    output [M_AXI_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_0  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tuser_0  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tkeep_0  ,
    output                                            m_axis_h2c_tlast_0  ,
                                                                         
    output                                            s_axis_c2h_tready_1 ,
    input                                             s_axis_c2h_tvalid_1 ,
    input  [M_AXI_DATA_WIDTH-1:0]                     s_axis_c2h_tdata_1  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tuser_1  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tkeep_1  ,
    input                                             s_axis_c2h_tlast_1  ,
                                                                         
    input                                             m_axis_h2c_tready_1 ,
    output                                            m_axis_h2c_tvalid_1 ,
    output [M_AXI_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_1  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tuser_1  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tkeep_1  ,
    output                                            m_axis_h2c_tlast_1  ,

    output                                            s_axis_c2h_tready_2 ,
    input                                             s_axis_c2h_tvalid_2 ,
    input  [M_AXI_DATA_WIDTH-1:0]                     s_axis_c2h_tdata_2  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tuser_2  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tkeep_2  ,
    input                                             s_axis_c2h_tlast_2  ,
                                                                         
    input                                             m_axis_h2c_tready_2 ,
    output                                            m_axis_h2c_tvalid_2 ,
    output [M_AXI_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_2  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tuser_2  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tkeep_2  ,
    output                                            m_axis_h2c_tlast_2  ,

    output                                            s_axis_c2h_tready_3 ,
    input                                             s_axis_c2h_tvalid_3 ,
    input  [M_AXI_DATA_WIDTH-1:0]                     s_axis_c2h_tdata_3  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tuser_3  ,
    input  [M_AXI_DATA_WIDTH/8-1:0]                   s_axis_c2h_tkeep_3  ,
    input                                             s_axis_c2h_tlast_3  ,
                                                                         
    input                                             m_axis_h2c_tready_3 ,
    output                                            m_axis_h2c_tvalid_3 ,
    output [M_AXI_DATA_WIDTH-1:0]                     m_axis_h2c_tdata_3  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tuser_3  ,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axis_h2c_tkeep_3  ,
    output                                            m_axis_h2c_tlast_3  ,

    // user write and read the DMA register 
    // AXI-Lite Slave interface    
    input  [31:0]                                     s_axil_awaddr ,
    input  [AXIL_AWUSER_WIDTH-1:0]                    s_axil_awuser ,
    input  [2:0]                                      s_axil_awprot ,
    input                                             s_axil_awvalid,
    output                                            s_axil_awready,
    input  [31:0]                                     s_axil_wdata  ,
    input  [ 3:0]                                     s_axil_wstrb  ,
    input                                             s_axil_wvalid ,
    output                                            s_axil_wready ,
    output                                            s_axil_bvalid ,
    output [ 1:0]                                     s_axil_bresp  ,
    input                                             s_axil_bready ,                 
    input  [31:0]                                     s_axil_araddr ,
    input  [AXIL_AWUSER_WIDTH-1:0]                    s_axil_aruser ,
    input  [ 2:0]                                     s_axil_arprot ,
    input                                             s_axil_arvalid,
    output                                            s_axil_arready,
    output [31:0]                                     s_axil_rdata  ,
    output [ 1:0]                                     s_axil_rresp  ,
    output                                            s_axil_rvalid ,
    input                                             s_axil_rready ,

    //axi_mm_master write address channel-master side
    output [M_AXI_ADDR_WIDTH-1:0 ]                    m_axib_awaddr,
    output [M_AXI_AWUSER_WIDTH-1:0]                   m_axib_awuser,
    output [7:0  ]                                    m_axib_awlen,
    output [2:0  ]                                    m_axib_awsize,
    output [1:0  ]                                    m_axib_awburst,
    output [2:0  ]                                    m_axib_awprot,
    output                                            m_axib_awlock,
    output [3:0  ]                                    m_axib_awcache,
    output                                            m_axib_awvalid,
    input                                             m_axib_awready,
    
    //axi_mm_master write data channel-master side
    output [M_AXI_DATA_WIDTH-1:0 ]                    m_axib_wdata,
    output [M_AXI_DATA_WIDTH/8-1:0]                   m_axib_wstrb,
    output                                            m_axib_wlast,
    output                                            m_axib_wvalid,
    input                                             m_axib_wready,
    
    //axi_mm_master write response channel-master side
    input  [1:0]                                      m_axib_bresp,
    input                                             m_axib_bvalid,
    output                                            m_axib_bready,
    
    //axi_mm_master read address channel-master side
    output [M_AXI_ADDR_WIDTH-1:0 ]                    m_axib_araddr ,
    output [M_AXI_ARUSER_WIDTH-1:0]                   m_axib_aruser,
    output [M_AXI_ID_WIDTH-1:0]                       m_axib_arid,
    output [7:0]                                      m_axib_arlen ,
    output [2:0]                                      m_axib_arsize,
    output [2:0]                                      m_axib_arprot,
    output                                            m_axib_arlock,
    output [3:0]                                      m_axib_arcache,
    output [1:0]                                      m_axib_arburst,
    output                                            m_axib_arvalid ,
    input                                             m_axib_arready ,
    
    //axi_mm_master read data channel-master side
    input  [M_AXI_DATA_WIDTH-1:0 ]                    m_axib_rdata  ,
    input  [M_AXI_ID_WIDTH-1:0]                       m_axib_rid,
    input  [1:0]                                      m_axib_rresp,
    input                                             m_axib_rlast  ,
    input                                             m_axib_rvalid ,
    output                                            m_axib_rready ,

    //axi_lite_master DMA register write channel
    output [31:0 ]                                    m_axil_awaddr,
    output [AXIL_AWUSER_WIDTH-1:0]                    m_axil_awuser,
    output [2:0  ]                                    m_axil_awprot,
    output                                            m_axil_awvalid,
    input                                             m_axil_awready,
    output                                            m_axil_awlock,
                                       
    output [31:0 ]                                    m_axil_wdata,
    output [32/8-1:0  ]                               m_axil_wstrb,
    output                                            m_axil_wvalid,
    input                                             m_axil_wready,
    
    input  [1:0]                                      m_axil_bresp,
    input                                             m_axil_bvalid,
    output                                            m_axil_bready,
    
    //axi_lite_master DMA register read channel
    output [31:0 ]                                    m_axil_araddr ,
    output [AXIL_ARUSER_WIDTH-1:0]                    m_axil_aruser,
    output [2:0  ]                                    m_axil_arprot,
    output                                            m_axil_arvalid ,
    input                                             m_axil_arready ,
                                       
    input  [31:0 ]                                    m_axil_rdata ,
    input  [1:0  ]                                    m_axil_rresp,
    input                                             m_axil_rvalid ,
    output                                            m_axil_rready ,


    output [DMA_STS_WIDTH-1:0]                        c2h_status_0,
    output [DMA_STS_WIDTH-1:0]                        h2c_status_0,
    output [DMA_STS_WIDTH-1:0]                        c2h_status_1,
    output [DMA_STS_WIDTH-1:0]                        h2c_status_1,
    output [DMA_STS_WIDTH-1:0]                        c2h_status_2,
    output [DMA_STS_WIDTH-1:0]                        h2c_status_2,
    output [DMA_STS_WIDTH-1:0]                        c2h_status_3,
    output [DMA_STS_WIDTH-1:0]                        h2c_status_3
    
);

////////////////////////////////////////////////
//              internal signals define
////////////////////////////////////////////////
localparam PCIE_AXIS_DATA_WIDTH = 256                     ;
localparam PCIE_AXIS_KEEP_WIDTH = PCIE_AXIS_DATA_WIDTH/32 ;
localparam PCIE_AXIS_M1_TUSER_W = (C_DEVICE == "PG2T390H") ? 34 :
                                  (C_DEVICE == "PG2L100H") ? 8  :
                                  (C_DEVICE == "PG3T500P"  || C_DEVICE == "PG3T600P" ||
                                   C_DEVICE == "PG3K1000P" || C_DEVICE == "PG3K120AS") ? 132 : 34;
localparam PCIE_AXIS_M0_TUSER_W = (C_DEVICE == "PG2T390H") ? 13 :
                                  (C_DEVICE == "PG2L100H") ? 8  :
                                  (C_DEVICE == "PG3T500P"  || C_DEVICE == "PG3T600P" ||
                                   C_DEVICE == "PG3K1000P" || C_DEVICE == "PG3K120AS") ? 32 : 13 ;
localparam PCIE_AXIS_S_TUSER_W  = (C_DEVICE == "PG2T390H") ? 6 :
                                  (C_DEVICE == "PG2L100H") ? 1 :
                                  (C_DEVICE == "PG3T500P"  || C_DEVICE == "PG3T600P" ||
                                   C_DEVICE == "PG3K1000P" || C_DEVICE == "PG3K120AS") ? 26 : 6 ;
//localparam BAR0_SIZE_WIDTH      = 20;
//localparam BAR1_SIZE_WIDTH      = 16;
//localparam BAR2_SIZE_WIDTH      = 20;
                               
localparam C_AXI_LITE_MASTER    = (AXI_LITE_MASTER == "TRUE" ) ? 1 : 0;                   

logic                        ref_clk              ;
logic                        user_clk             ;
logic                        pclk_div2            ;
logic                        pclk                 ;
logic                        user_rst_n           ;
                                                 
logic    [5:0]               smlh_ltssm_state     ;
logic                        button_rst_n         ;

logic    [6-1:0]             cfg_max_payload_size ;  
logic    [6-1:0]             cfg_max_rd_req_size  ;  
logic    [8-1:0]             cfg_pbus_num         ;  
logic    [5-1:0]             cfg_pbus_dev_num     ;  
logic                        s_app_flr_pf_done    ;
logic                        s_ven_msi_func_num   ;
logic                        sys_int              ;
logic                        int_grt              ;
logic    [1:0]               cfg_flr_pf_active    ;
logic    [1:0]               app_flr_pf_done      ;


logic                        axis_master0_tvalid  ;
logic                        axis_master0_tready  ;
logic    [255:0]             axis_master0_tdata   ;
logic    [7:0]               axis_master0_tkeep   ;
logic                        axis_master0_tlast   ;
logic    [12:0]              axis_master0_tuser   ;                                          
logic                        user_rcvd_np_ready   ;
logic    [5:0]               core_avl_np_cnt      ;
logic                        user_rcvd_p_ready    ;
logic    [5:0]               core_avl_p_cnt       ;
                                                  
logic                        axis_master1_tvalid  ;
logic    [255:0]             axis_master1_tdata   ;
logic    [7:0]               axis_master1_tkeep   ;
logic    [33:0]              axis_master1_tuser   ;
                                                  
logic                        axis_slave0_tready   ;
logic                        axis_slave0_tvalid   ;
logic    [255:0]             axis_slave0_tdata    ;
logic                        axis_slave0_tlast    ;
logic    [5:0]               axis_slave0_tuser    ;

//axis slave 1 interface
logic                        axis_slave1_tready   ;
logic                        axis_slave1_tvalid   ;
logic    [255:0]             axis_slave1_tdata    ;
logic                        axis_slave1_tlast    ;
logic    [5:0]               axis_slave1_tuser    ;

//axis slave 2 interface
logic                        axis_slave2_tready   ;
logic                        axis_slave2_tvalid   ;
logic    [255:0]             axis_slave2_tdata    ;
logic                        axis_slave2_tlast    ;
logic    [5:0]               axis_slave2_tuser    ;
// led lights up
logic    [  1:0]             p_calib_done         ;
logic                        power_up_rst_n       ;
///////////////////////////
// msi intf
logic    [1:0]              s_cfg_msi_en           ;
logic    [5:0]              s_cfg_multi_msi_en     ;
logic                       ven_msi_req            ;    
logic   [2:0]               ven_msi_tc             ;    
logic   [4:0]               ven_msi_vector         ;    
logic                       ven_msi_grant          ;
logic   [1:0]               ven_msi_func_num       ;
logic   [2:0]               ven_msi_vfunc_num      ;
logic                       ven_msi_vfunc_active   ;
logic   [1:0]               s_cfg_msix_en          ;
logic   [1:0]               s_cfg_msix_func_mask   ;
logic                       cfg_msix_func_mask     ;
logic   [63:0]              msix_addr              ;
logic   [31:0]              msix_data              ;
logic                       user_rst_n_1d          ;
logic                       user_rst_n_2d          ;

assign               button_rst_n       = 1'b1     ;


//--------------------------------------------------------
//              reset debounce and sync processing
//---------------debounce button_rst_n (ref_clk)
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2T_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_buttonrstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (button_rst_n       ),
    .rstn_out           (sync_button_rst_n  )
);

//---------------debounce  perst_n   (ref_clk)
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2T_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_perstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (perst_n            ),
    .rstn_out           (sync_perst_n       )
);

//---------------pclk_div2_button_rst_n (pclk_div2)
ips2t_pcie_sync_v1_0  u_pclk_div2_button_rstn_sync(
    .clk                (pclk_div2              ),
    .rst_n              (sync_button_rst_n      ),
    .sig_async          (1'b1                   ),
    .sig_synced         (pclk_div2_button_rst_n )
);

//---------------user_button_rst_n (user_clk)
ips2t_pcie_sync_v1_0  u_user_button_rstn_sync(
    .clk                (user_clk            ),
    .rst_n              (sync_button_rst_n   ),
    .sig_async          (1'b1                ),
    .sig_synced         (user_button_rst_n   )
);

//---------------pclk_button_rst_n (pclk_div2)
ips2t_pcie_sync_v1_0  u_pclk_button_rstn_sync(
    .clk                (pclk                ),
    .rst_n              (sync_button_rst_n   ),
    .sig_async          (1'b1                ),
    .sig_synced         (pclk_button_rst_n   )
);

//---------------pclk_user_rst_n
ips2t_pcie_sync_v1_0  u_pclk_user_rst_n(
    .clk                (pclk                ),
    .rst_n              (user_rst_n          ),
    .sig_async          (1'b1                ),
    .sig_synced         (pclk_user_rst_n     )
);

//---------------pclk_div2_user_rst_n
ips2t_pcie_sync_v1_0  u_pclk_div2_user_rst_n(
    .clk                (pclk_div2            ),
    .rst_n              (user_rst_n           ),
    .sig_async          (1'b1                 ),
    .sig_synced         (pclk_div2_user_rst_n )
);


//********************************************************************
//              PLL user_clk gen
//*********************************************************************

ips2t_pll_user  u_user_clk_pll(
    .clkout0 (              ), //62.5Mhz gen1
    .clkout1 (              ), //125Mhz  gen2
    .clkout2 (user_clk      ), //250Mhz  gen3
    .clkin1  (ref_clk       ),
    .rst     (~(perst_n &   button_rst_n) ),
    .lock    (user_pll_lock )   //clock stable indicator
);

assign  axi_clk   = user_clk      ;
assign  axi_rst_n = user_rst_n_2d ;
always@(posedge user_clk or negedge user_rst_n)
begin
    if (!user_rst_n)
        begin
            user_rst_n_1d <= 1'b0;
            user_rst_n_2d <= 1'b0;
        end
    else
        begin
            user_rst_n_1d <= 1'b1;
            user_rst_n_2d <= user_rst_n_1d;
        end
end

//********************************************************************
//              pcie_top instance
//********************************************************************

assign power_up_rst_n = sync_perst_n & p_calib_done[1];
bdma_pcie_ip u_bdma_pcie_ip (
    //clk and rst
    .power_up_rst_n             (power_up_rst_n         ),  
    .button_rst_n               (sync_button_rst_n      ),  
    .perst_n                    (sync_perst_n           ),  
    .user_rst_n                 (user_rst_n             ),  
    .user_clk                   (user_clk               ),  
    .ref_clk                    (ref_clk                ),  
    .pclk_div2                  (pclk_div2              ),  
    .pclk                       (pclk                   ),  
    .user_pll_lock              (user_pll_lock          ),
    .p_calib_done               (p_calib_done           ), 

    .p_clk                      (ref_clk                ), 
    .p_rst_n                    (sync_button_rst_n      ), 
    .p_sel                      ('h0                    ), 
    .p_strb                     ('h0                    ), 
    .p_addr                     ('h0                    ), 
    .p_wdata                    ('h0                    ), 
    .p_ce                       ('h0                    ), 
    .p_we                       ('h0                    ), 
    .p_rdy                      (                       ), 
    .p_rdata                    (                       ), 

    //the input ref_clk pair
    .ref_clk_n                  (ref_clk_n              ),  
    .ref_clk_p                  (ref_clk_p              ),  

    //AXIS master interface : master0 for remote request
    .axis_master0_tvalid        (axis_master0_tvalid    ),  
    .axis_master0_tready        (axis_master0_tready    ),  
    .axis_master0_tdata         (axis_master0_tdata     ),  
    .axis_master0_tkeep         (axis_master0_tkeep     ),  
    .axis_master0_tlast         (axis_master0_tlast     ),  
    .axis_master0_tuser         (axis_master0_tuser     ),  
                                                            
    .user_rcvd_np_ready         (user_rcvd_np_ready     ),  
    .core_avl_np_cnt            (core_avl_np_cnt        ),  
    .user_rcvd_p_ready          (user_rcvd_p_ready      ),  
    .core_avl_p_cnt             (core_avl_p_cnt         ),  
    //AXIS master interface : master1 for remote completion
    .axis_master1_tvalid        (axis_master1_tvalid    ),  
    .axis_master1_tdata         (axis_master1_tdata     ),  
    .axis_master1_tkeep         (axis_master1_tkeep     ),  
    .axis_master1_tuser         (axis_master1_tuser     ),  
                                                            
    //axis slave 0 interface
    .axis_slave0_tready         (axis_slave0_tready     ),  
    .axis_slave0_tvalid         (axis_slave0_tvalid     ),  
    .axis_slave0_tdata          (axis_slave0_tdata      ),  
    .axis_slave0_tlast          (axis_slave0_tlast      ),  
    .axis_slave0_tuser          (axis_slave0_tuser      ),  


    //axis slave 1 interface
    .axis_slave1_tready         (axis_slave1_tready     ),  
    .axis_slave1_tvalid         (axis_slave1_tvalid     ),  
    .axis_slave1_tdata          (axis_slave1_tdata      ),  
    .axis_slave1_tlast          (axis_slave1_tlast      ),  
    .axis_slave1_tuser          (axis_slave1_tuser      ),  
    //axis slave 2 interface
    .axis_slave2_tready         (axis_slave2_tready     ),  
    .axis_slave2_tvalid         (axis_slave2_tvalid     ),  
    .axis_slave2_tdata          (axis_slave2_tdata      ),  
    .axis_slave2_tlast          (axis_slave2_tlast      ),  
    .axis_slave2_tuser          (axis_slave2_tuser      ),  

    .cfg_int_disable            (                       ),
    .sys_int                    ({1'b0,sys_int}         ),
    .int_grt                    (int_grt                ),

    .ven_msi_vector             (ven_msi_vector         ),  
    .cfg_msi_pending            (64'b0                  ),  
    .cfg_msi_en                 (s_cfg_msi_en           ),  
    .cfg_multi_msi_en           (s_cfg_multi_msi_en     ),
    .ven_msi_func_num           (s_ven_msi_func_num     ),  
    .ven_msi_vfunc_num          (ven_msi_vfunc_num      ),  
    .ven_msi_vfunc_active       (ven_msi_vfunc_active   ),  
    .cfg_msi_mask_update        (                       ),  
    .cfg_vf_msi_pending         (192'b0                 ),  

    .ven_msi_req                (ven_msi_req            ),  
    .ven_msi_tc                 (ven_msi_tc             ),  
    .ven_msi_grant              (ven_msi_grant          ),  
    .cfg_msix_en                (s_cfg_msix_en          ),
    .cfg_msix_func_mask         (s_cfg_msix_func_mask   ),
    .msix_addr                  (msix_addr              ),
    .msix_data                  (msix_data              ),

    .radm_cpl_timeout           (                       ),  
    .radm_timeout_func_num      (                       ),  
    .radm_timeout_vfunc_num     (                       ),  
    .radm_timeout_vfunc_active  (                       ),  
    .radm_timeout_cpl_tc        (                       ),  
    .radm_timeout_cpl_attr      (                       ),  
    .radm_timeout_cpl_len       (                       ),  
    .radm_timeout_cpl_tag       (                       ),  

    .rdlh_link_up               (rdlh_link_up           ),  
    .smlh_ltssm_state           (smlh_ltssm_state       ),  
    .smlh_link_up               (smlh_link_up           ),  
    .smlh_req_rst_not           (                       ),  

    //Configuration reg output interface
    .cfg_vf_bme                 (                       ),  
    .cfg_vf_en                  (                       ),  
    .cfg_num_vf                 (                       ),  
    .cfg_start_vfi              (                       ),  
    .cfg_tph_req_en             (                       ),  
    .cfg_pf_tph_st_mode         (                       ),  
    .cfg_vf_tph_st_mode         (                       ),  
    .cfg_vf_tph_req_en          (                       ),  
    .dpa_substate_update        (                       ),  
    .cfg_atomic_req_en          (                       ),  
    .cfg_atomic_egress_block    (                       ),  
    .cfg_ari_fwd_en             (                       ),  
    .cfg_send_cor_err           (                       ),  
    .cfg_send_nf_err            (                       ),  
    .cfg_send_f_err             (                       ),  
    .cfg_no_snoop_en            (                       ),  
    .cfg_relax_order_en         (                       ),  
    .cfg_link_auto_bw_int       (                       ),  
    .cfg_link_auto_bw_msi       (                       ),  
    .cfg_bw_mgt_int             (                       ),  
    .cfg_bw_mgt_msi             (                       ),  
    .cfg_link_eq_req_int        (                       ),  
    .rbar_ctrl_update           (                       ),  
    .cfg_ido_req_en             (                       ),  
    .cfg_ido_cpl_en             (                       ),  
    .cfg_sys_err_rc             (                       ),  
    .cfg_aer_rc_err_int         (                       ),  
    .cfg_aer_rc_err_msi         (                       ),  
    .cfg_pme_int                (                       ),  
    .cfg_pme_msi                (                       ),  
    .cfg_crs_sw_vis_en          (                       ),  
    .radm_q_not_empty           (                       ),  
    .radm_qoverflow             (                       ),  
    .cfg_bus_master_en          (                       ),
    .cfg_2nd_reset              (                       ), 
    .cfg_max_payload_size       (cfg_max_payload_size   ), 
    .cfg_rcb                    (                       ), 
    .cfg_tc_enable              (                       ), 
    .cfg_mem_space_en           (                       ), 
    .cfg_max_rd_req_size        (cfg_max_rd_req_size    ), 
    .cfg_ext_tag_en             (                       ), 
    .cfg_reg_serren             (                       ), 
    .cfg_cor_err_rpt_en         (                       ), 
    .cfg_nf_err_rpt_en          (                       ), 
    .cfg_f_err_rpt_en           (                       ), 
    .cfg_pbus_num               (cfg_pbus_num           ), 
    .cfg_pbus_dev_num           (cfg_pbus_dev_num       ), 
    .cfg_obff_en                (                       ), 

    //debug interface
    .dyn_debug_info_sel         (6'b0                   ),  
    .app_ras_des_sd_hold_ltssm  (1'b0                   ),  
    .debug_info_mux             (                       ),  

    // START_IO:FLR Signal Descriptions
    .cfg_flr_pf_active          (cfg_flr_pf_active      ), 
    .app_flr_pf_done            (app_flr_pf_done        ), 

    // END_IO:FLR Signal Descriptions.

    // PHY inside device_top (or inside core)           export serial lines, import refclk
    .rxp                        (rxp                    ),  
    .rxn                        (rxn                    ),  
    .txp                        (txp                    ),  
    .txn                        (txn                    ),  

    .pcs_nearend_loop           ({8{1'b0}}              ),  
    .pma_nearend_ploop          ({8{1'b0}}              ),  
    .pma_nearend_sloop          ({8{1'b0}}              )   
);


assign app_flr_pf_done       = {1'b0,s_app_flr_pf_done};
assign s_ven_msi_func_num    = ven_msi_func_num[0]   ;
assign cfg_msi_en            = s_cfg_msi_en[0]         ;
assign cfg_multi_msi_en      = s_cfg_multi_msi_en[2:0] ;
assign cfg_msix_en           = s_cfg_msix_en[0]        ;
assign cfg_msix_func_mask[0] = s_cfg_msix_func_mask[0] ;

bdma_top_v1_0 #( 
    .IP_ID                   ( IP_ID                ),
    .IP_VERSION              ( IP_VERSION           ),
    .C_FAMILY                ( C_FAMILY             ),
    .C_DEVICE                ( C_DEVICE             ),
    .PCIE_AXIS_DATA_WIDTH    ( PCIE_AXIS_DATA_WIDTH ),
    .PCIE_AXIS_KEEP_WIDTH    ( PCIE_AXIS_KEEP_WIDTH ),
    .PCIE_AXIS_M1_TUSER_W    ( PCIE_AXIS_M1_TUSER_W ),
    .PCIE_AXIS_M0_TUSER_W    ( PCIE_AXIS_M0_TUSER_W ),
    .PCIE_AXIS_S_TUSER_W     ( PCIE_AXIS_S_TUSER_W  ),
    .M_AXI_DATA_WIDTH        ( M_AXI_DATA_WIDTH     ),
    .M_AXI_ADDR_WIDTH        ( M_AXI_ADDR_WIDTH     ),
    .M_AXI_ID_WIDTH          ( M_AXI_ID_WIDTH       ),
    .M_AXI_AWUSER_WIDTH      ( M_AXI_AWUSER_WIDTH   ),
    .M_AXI_ARUSER_WIDTH      ( M_AXI_ARUSER_WIDTH   ),
    .AXI_WRITE_NUM           ( AXI_WRITE_NUM        ),
    .AXI_READ_NUM            ( AXI_READ_NUM         ),
    .AXI_LITE_MASTER         ( C_AXI_LITE_MASTER    ),
    .PCIE2AXIBAR_0           ( PCIE2AXIBAR_0        ),
    .PCIE2AXIBAR_1           ( PCIE2AXIBAR_1        ),
    .PCIE2AXIBAR_2           ( PCIE2AXIBAR_2        ),
    .BAR0_SIZE_WIDTH         ( BAR0_SIZE_WIDTH      ),
    .BAR1_SIZE_WIDTH         ( BAR1_SIZE_WIDTH      ),
    .BAR2_SIZE_WIDTH         ( BAR2_SIZE_WIDTH      ),
    .DMA_EN                  ( DMA_EN               ),
    .DMA_STS_PORTS           ( DMA_STS_PORTS        ),
    .H2C_CHNL_NUM            ( H2C_CHNL_NUM         ),
    .C2H_CHNL_NUM            ( C2H_CHNL_NUM         ),
    .H2C_RID_NUM             ( H2C_RID_NUM          ),
    .C2H_RID_NUM             ( C2H_RID_NUM          ),
    .DMA_STS_WIDTH           ( DMA_STS_WIDTH        ),
    .DMA_AXIMM               ( DMA_AXIMM            ),
    .DMA_AXIS                ( DMA_AXIS             ),
    .C2H_DSC_BYPASS          ( C2H_DSC_BYPASS       ),
    .H2C_DSC_BYPASS          ( H2C_DSC_BYPASS       ),
    .H2C_RAM_DEPTH           ( 512                  ),
    .C2H_RAM_DEPTH           ( 512                  ),
    .DSC_RAM_DEPTH           ( 512                  ),
    .BRDG_RAM_DEPTH          ( 512                  ),
    .DSC_MGC_EN              ( 1                    ),
    .USR_IRQ_NUM             ( USR_IRQ_NUM          ),
    .MSIX_VECTORS_NUM        ( MSIX_VECTORS_NUM     ),
    .AXI_USER_MRRS_SIZE      ( AXI_USER_MRRS_SIZE   ),
    .AXI_USER_MPL_SIZE       ( AXI_USER_MPL_SIZE    ),
    .PCIE_MRRS_SIZE          ( PCIE_MRRS_SIZE       ),
    .PCIE_MPL_SIZE           ( PCIE_MPL_SIZE        ),
    .PCIE_TAG_NUM            ( PCIE_TAG_NUM         ),
    .AXIL_AWUSER_WIDTH       ( AXIL_AWUSER_WIDTH    ),
    .AXIL_ARUSER_WIDTH       ( AXIL_ARUSER_WIDTH    ),
    .PCIE_MAX_LINK_SPEED     ( PCIE_MAX_LINK_SPEED  ),
    .MSIX_REG_ADDR_ID        ( MSIX_REG_ADDR_ID     )
    )
u_bdma_top
(
    .i_clk                 (user_clk             ),
    .i_rst_n               (user_rst_n           ),

    //pcie ip
    .i_pclk_div2           (pclk_div2            ),
    .i_smlh_ltssm_state    (smlh_ltssm_state     ),
    .i_smlh_link_up        (smlh_link_up         ),
    .i_rdlh_link_up        (rdlh_link_up         ),
    .o_pcie_link_up        (pcie_link_up         ),
    .i_pcie_cfg_mrrs       (cfg_max_rd_req_size[2:0]  ),
    .i_pcie_cfg_mpl        (cfg_max_payload_size[2:0] ),
    .i_cfg_pbus_num        (cfg_pbus_num         ),
    .i_cfg_pbus_dev_num    (cfg_pbus_dev_num     ),
    .i_cfg_flr_pf_active   (cfg_flr_pf_active[0] ),
    .o_app_flr_pf_done     (s_app_flr_pf_done    ),
    .o_sys_int             (sys_int              ),
    .i_int_grt             (int_grt              ),
    .i_cfg_msi_en          (cfg_msi_en           ),
    .i_cfg_multi_msi_en    (cfg_multi_msi_en     ),
    .o_ven_msi_func_num    (ven_msi_func_num     ),
    .o_ven_msi_vfunc_num   (ven_msi_vfunc_num    ),
    .o_ven_msi_vfunc_active(ven_msi_vfunc_active ),
    .o_ven_msi_tc          (ven_msi_tc           ),
    .o_ven_msi_vector      (ven_msi_vector       ),
    .o_ven_msi_req         (ven_msi_req          ),
    .i_ven_msi_grant       (ven_msi_grant        ),
    .i_cfg_msix_en         (cfg_msix_en          ),
    .i_cfg_msix_func_mask  (cfg_msix_func_mask[0]),
    .o_msix_addr           (msix_addr            ),
    .o_msix_data           (msix_data            ),
    .o_user_rcvd_p_ready   (user_rcvd_p_ready    ),
    .o_user_rcvd_np_ready  (user_rcvd_np_ready   ),
    .i_core_avl_np_cnt     (core_avl_np_cnt      ),
    .i_core_avl_p_cnt      (core_avl_p_cnt       ),


    .i_user_int_req        (i_user_int_req       ),
    .o_user_int_grt        (o_user_int_grt       ),
                                                 
    //from pcie axis_master                      
    .axis_master1_tvalid   (axis_master1_tvalid  ),
    .axis_master1_tdata    (axis_master1_tdata   ),
    .axis_master1_tkeep    (axis_master1_tkeep   ),
    .axis_master1_tuser    (axis_master1_tuser   ),
    .axis_master1_tlast    (axis_master1_tlast   ),
    .axis_master1_tready   (axis_master1_tready  ),

    //from pcie axis_master                                                                  
    .axis_master0_tvalid   (axis_master0_tvalid  ),
    .axis_master0_tdata    (axis_master0_tdata   ),
    .axis_master0_tkeep    (axis_master0_tkeep   ),
    .axis_master0_tuser    (axis_master0_tuser   ),
    .axis_master0_tlast    (axis_master0_tlast   ),
    .axis_master0_tready   (axis_master0_tready  ),
                                                 
    //to pcie axis_slave                         
    .m_axis_tvalid_0       (axis_slave0_tvalid   ),    
    .m_axis_tready_0       (axis_slave0_tready   ),    
    .m_axis_tdata_0        (axis_slave0_tdata    ),
    .m_axis_tuser_0        (axis_slave0_tuser    ),
    .m_axis_tlast_0        (axis_slave0_tlast    ),
    //to pcie axis_slave                                
    .m_axis_tvalid_1       (axis_slave1_tvalid   ), 
    .m_axis_tready_1       (axis_slave1_tready   ), 
    .m_axis_tdata_1        (axis_slave1_tdata    ), 
    .m_axis_tuser_1        (axis_slave1_tuser    ), 
    .m_axis_tlast_1        (axis_slave1_tlast    ), 
    //to pcie axis_slave                                
    .m_axis_tvalid_2       (axis_slave2_tvalid   ), 
    .m_axis_tready_2       (axis_slave2_tready   ), 
    .m_axis_tdata_2        (axis_slave2_tdata    ), 
    .m_axis_tuser_2        (axis_slave2_tuser    ), 
    .m_axis_tlast_2        (axis_slave2_tlast    ), 
                                                                                                                  
    //user dsc_bypass
    .c2h_dsc_byp_ready     ({c2h_dsc_byp_ready_3   , c2h_dsc_byp_ready_2   ,c2h_dsc_byp_ready_1   , c2h_dsc_byp_ready_0   }),
    .c2h_dsc_byp_valid     ({c2h_dsc_byp_valid_3   , c2h_dsc_byp_valid_2   ,c2h_dsc_byp_valid_1   , c2h_dsc_byp_valid_0   }),
    .c2h_dsc_byp_src_addr  ({c2h_dsc_byp_src_addr_3, c2h_dsc_byp_src_addr_2,c2h_dsc_byp_src_addr_1, c2h_dsc_byp_src_addr_0}),
    .c2h_dsc_byp_dst_addr  ({c2h_dsc_byp_dst_addr_3, c2h_dsc_byp_dst_addr_2,c2h_dsc_byp_dst_addr_1, c2h_dsc_byp_dst_addr_0}),
    .c2h_dsc_byp_len       ({c2h_dsc_byp_len_3     , c2h_dsc_byp_len_2     ,c2h_dsc_byp_len_1     , c2h_dsc_byp_len_0     }),
    .c2h_dsc_byp_ctrl      ({c2h_dsc_byp_ctrl_3    , c2h_dsc_byp_ctrl_2    ,c2h_dsc_byp_ctrl_1    , c2h_dsc_byp_ctrl_0    }),
    
    
    .h2c_dsc_byp_ready     ({h2c_dsc_byp_ready_3    ,h2c_dsc_byp_ready_2   ,h2c_dsc_byp_ready_1    ,h2c_dsc_byp_ready_0   }),
    .h2c_dsc_byp_valid     ({h2c_dsc_byp_valid_3    ,h2c_dsc_byp_valid_2   ,h2c_dsc_byp_valid_1    ,h2c_dsc_byp_valid_0   }),
    .h2c_dsc_byp_src_addr  ({h2c_dsc_byp_src_addr_3 ,h2c_dsc_byp_src_addr_2,h2c_dsc_byp_src_addr_1 ,h2c_dsc_byp_src_addr_0}),
    .h2c_dsc_byp_dst_addr  ({h2c_dsc_byp_dst_addr_3 ,h2c_dsc_byp_dst_addr_2,h2c_dsc_byp_dst_addr_1 ,h2c_dsc_byp_dst_addr_0}),
    .h2c_dsc_byp_len       ({h2c_dsc_byp_len_3      ,h2c_dsc_byp_len_2     ,h2c_dsc_byp_len_1      ,h2c_dsc_byp_len_0     }),
    .h2c_dsc_byp_ctrl      ({h2c_dsc_byp_ctrl_3     ,h2c_dsc_byp_ctrl_2    ,h2c_dsc_byp_ctrl_1     ,h2c_dsc_byp_ctrl_0    }),

    //user mm_master
    .m_axi_arready         (m_axi_arready        ),
    .m_axi_arvalid         (m_axi_arvalid        ),
    .m_axi_arid            (m_axi_arid           ),
    .m_axi_araddr          (m_axi_araddr         ),
    .m_axi_arlen           (m_axi_arlen          ),
    .m_axi_arsize          (m_axi_arsize         ),
    .m_axi_arburst         (m_axi_arburst        ),
    .m_axi_arprot          (m_axi_arprot         ),
    .m_axi_arlock          (m_axi_arlock         ),
    .m_axi_arcache         (m_axi_arcache        ),
                                                 
    .m_axi_rready          (m_axi_rready         ),
    .m_axi_rvalid          (m_axi_rvalid         ),
    .m_axi_rid             (m_axi_rid            ),
    .m_axi_rdata           (m_axi_rdata          ),
    .m_axi_ruser           (m_axi_ruser          ),
    .m_axi_rresp           (m_axi_rresp          ),
    .m_axi_rlast           (m_axi_rlast          ),
                                                 
    .m_axi_awready         (m_axi_awready        ),
    .m_axi_awvalid         (m_axi_awvalid        ),
    .m_axi_awid            (m_axi_awid           ),
    .m_axi_awaddr          (m_axi_awaddr         ),
    .m_axi_awlen           (m_axi_awlen          ),
    .m_axi_awsize          (m_axi_awsize         ),
    .m_axi_awburst         (m_axi_awburst        ),
    .m_axi_awprot          (m_axi_awprot         ),
    .m_axi_awlock          (m_axi_awlock         ),
    .m_axi_awcache         (m_axi_awcache        ),
                                                 
    .m_axi_wready          (m_axi_wready         ),
    .m_axi_wvalid          (m_axi_wvalid         ),
    .m_axi_wdata           (m_axi_wdata          ),
    .m_axi_wuser           (m_axi_wuser          ),
    .m_axi_wstrb           (m_axi_wstrb          ),
    .m_axi_wlast           (m_axi_wlast          ),
                                                 
    .m_axi_bready          (m_axi_bready         ),
    .m_axi_bvalid          (m_axi_bvalid         ),
    .m_axi_bid             (m_axi_bid            ),
    .m_axi_bresp           (m_axi_bresp          ),
                                      
    //user axis
    .s_axis_c2h_tready     ({s_axis_c2h_tready_3, s_axis_c2h_tready_2,s_axis_c2h_tready_1, s_axis_c2h_tready_0}),
    .s_axis_c2h_tvalid     ({s_axis_c2h_tvalid_3, s_axis_c2h_tvalid_2,s_axis_c2h_tvalid_1, s_axis_c2h_tvalid_0}),
    .s_axis_c2h_tdata      ({s_axis_c2h_tdata_3 , s_axis_c2h_tdata_2 ,s_axis_c2h_tdata_1 , s_axis_c2h_tdata_0 }),
    .s_axis_c2h_tuser      ({s_axis_c2h_tuser_3 , s_axis_c2h_tuser_2 ,s_axis_c2h_tuser_1 , s_axis_c2h_tuser_0 }),
    .s_axis_c2h_tkeep      ({s_axis_c2h_tkeep_3 , s_axis_c2h_tkeep_2 ,s_axis_c2h_tkeep_1 , s_axis_c2h_tkeep_0 }),
    .s_axis_c2h_tlast      ({s_axis_c2h_tlast_3 , s_axis_c2h_tlast_2 ,s_axis_c2h_tlast_1 , s_axis_c2h_tlast_0 }),
                                                 
    .m_axis_h2c_tready     ({m_axis_h2c_tready_3, m_axis_h2c_tready_2,m_axis_h2c_tready_1, m_axis_h2c_tready_0}),
    .m_axis_h2c_tvalid     ({m_axis_h2c_tvalid_3, m_axis_h2c_tvalid_2,m_axis_h2c_tvalid_1, m_axis_h2c_tvalid_0}),
    .m_axis_h2c_tdata      ({m_axis_h2c_tdata_3 , m_axis_h2c_tdata_2 ,m_axis_h2c_tdata_1 , m_axis_h2c_tdata_0 }),
    .m_axis_h2c_tuser      ({m_axis_h2c_tuser_3 , m_axis_h2c_tuser_2 ,m_axis_h2c_tuser_1 , m_axis_h2c_tuser_0 }),
    .m_axis_h2c_tkeep      ({m_axis_h2c_tkeep_3 , m_axis_h2c_tkeep_2 ,m_axis_h2c_tkeep_1 , m_axis_h2c_tkeep_0 }),
    .m_axis_h2c_tlast      ({m_axis_h2c_tlast_3 , m_axis_h2c_tlast_2 ,m_axis_h2c_tlast_1 , m_axis_h2c_tlast_0 }),

    // user write and read the DMA register 
    // AXI-Lite Slave interface    
    .s_axil_awaddr         (s_axil_awaddr        ),
    .s_axil_awuser         (s_axil_awuser        ),
    .s_axil_awprot         (s_axil_awprot        ),
    .s_axil_awvalid        (s_axil_awvalid       ),
    .s_axil_awready        (s_axil_awready       ),
    .s_axil_wdata          (s_axil_wdata         ),
    .s_axil_wstrb          (s_axil_wstrb         ),
    .s_axil_wvalid         (s_axil_wvalid        ),
    .s_axil_wready         (s_axil_wready        ),
    .s_axil_bvalid         (s_axil_bvalid        ),
    .s_axil_bresp          (s_axil_bresp         ),
    .s_axil_bready         (s_axil_bready        ),
    .s_axil_araddr         (s_axil_araddr        ),
    .s_axil_aruser         (s_axil_aruser        ),
    .s_axil_arprot         (s_axil_arprot        ),
    .s_axil_arvalid        (s_axil_arvalid       ),
    .s_axil_arready        (s_axil_arready       ),
    .s_axil_rdata          (s_axil_rdata         ),
    .s_axil_rresp          (s_axil_rresp         ),
    .s_axil_rvalid         (s_axil_rvalid        ),
    .s_axil_rready         (s_axil_rready        ),

    //axi_mm_master write address channel-master side
    .m_axib_awaddr         (m_axib_awaddr        ),
    .m_axib_awuser         (                     ),
    .m_axib_awlen          (m_axib_awlen         ),
    .m_axib_awsize         (m_axib_awsize        ),
    .m_axib_awburst        (m_axib_awburst       ),
    .m_axib_awprot         (m_axib_awprot        ),
    .m_axib_awlock         (m_axib_awlock        ),
    .m_axib_awcache        (m_axib_awcache       ),
    .m_axib_awvalid        (m_axib_awvalid       ),
    .m_axib_awready        (m_axib_awready       ),
    
    //axi_mm_master write data channel-master side
    .m_axib_wdata          (m_axib_wdata         ),
    .m_axib_wstrb          (m_axib_wstrb         ),
    .m_axib_wlast          (m_axib_wlast         ),
    .m_axib_wvalid         (m_axib_wvalid        ),
    .m_axib_wready         (m_axib_wready        ),

    //axi_mm_master write response channel-master side
    .m_axib_bresp          (m_axib_bresp         ),
    .m_axib_bvalid         (m_axib_bvalid        ),
    .m_axib_bready         (m_axib_bready        ),
    
    //axi_mm_master read address channel-master side
    .m_axib_araddr         (m_axib_araddr        ),
    .m_axib_aruser         (                     ),
    .m_axib_arid           (m_axib_arid          ),
    .m_axib_arlen          (m_axib_arlen         ),
    .m_axib_arsize         (m_axib_arsize        ),
    .m_axib_arprot         (m_axib_arprot        ),
    .m_axib_arlock         (m_axib_arlock        ),
    .m_axib_arcache        (m_axib_arcache       ),
    .m_axib_arburst        (m_axib_arburst       ),
    .m_axib_arvalid        (m_axib_arvalid       ),
    .m_axib_arready        (m_axib_arready       ),
    
    //axi_mm_master read data channel-master side
    .m_axib_rdata          (m_axib_rdata         ),
    .m_axib_rid            (m_axib_rid           ),
    .m_axib_rresp          (m_axib_rresp         ),
    .m_axib_rlast          (m_axib_rlast         ),
    .m_axib_rvalid         (m_axib_rvalid        ),
    .m_axib_rready         (m_axib_rready        ),

    //axi_lite_master DMA register write channel
    .m_axil_awaddr         (m_axil_awaddr        ),
    .m_axil_awuser         (                     ),
    .m_axil_awprot         (m_axil_awprot        ),
    .m_axil_awvalid        (m_axil_awvalid       ),
    .m_axil_awready        (m_axil_awready       ),
    .m_axil_awlock         (                     ),
                                                 
    .m_axil_wdata          (m_axil_wdata         ),
    .m_axil_wstrb          (m_axil_wstrb         ),
    .m_axil_wvalid         (m_axil_wvalid        ),
    .m_axil_wready         (m_axil_wready        ),
                                                 
    .m_axil_bresp          (m_axil_bresp         ),
    .m_axil_bvalid         (m_axil_bvalid        ),
    .m_axil_bready         (m_axil_bready        ),
                                                 
    .m_axil_araddr         (m_axil_araddr        ),
    .m_axil_aruser         (                     ),
    .m_axil_arprot         (m_axil_arprot        ),
    .m_axil_arvalid        (m_axil_arvalid       ),
    .m_axil_arready        (m_axil_arready       ),
                                                 
    .m_axil_rdata          (m_axil_rdata         ),
    .m_axil_rresp          (m_axil_rresp         ),
    .m_axil_rvalid         (m_axil_rvalid        ),
    .m_axil_rready         (m_axil_rready        ),
    .o_c2h_status          ({c2h_status_3,c2h_status_2,c2h_status_1,c2h_status_0}),
    .o_h2c_status          ({h2c_status_3,h2c_status_2,h2c_status_1,h2c_status_0})
);

endmodule
