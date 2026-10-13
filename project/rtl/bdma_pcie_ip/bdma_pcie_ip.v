
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2020 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
// Library:
// Filename: bdma_pcie_ip.v
//////////////////////////////////////////////////////////////////////////////
module bdma_pcie_ip
(
    //clk and rst
    output  wire                    pclk                ,
    output  wire                    pclk_div2           ,
    output  wire                    ref_clk             ,
    input                           user_clk            ,
    input                           ref_clk_n           ,
    input                           ref_clk_p           ,
    input                           button_rst_n        ,
    input                           power_up_rst_n      ,
    input                           perst_n             ,
    output  wire                    user_rst_n          ,
    input                           user_pll_lock       ,
    output          [ 1:0]          p_calib_done        ,

    //APB interface to  DBI cfg
    input                           p_clk               ,
    input                           p_rst_n             ,
    input                           p_sel               ,
    input           [ 3:0]          p_strb              ,
    input           [31:0]          p_addr              ,
    input           [31:0]          p_wdata             ,
    input                           p_ce                ,
    input                           p_we                ,
    output  wire                    p_rdy               ,
    output  wire    [31:0]          p_rdata             ,

    //PHY diff signals

    input           [7:0]           rxp,
    input           [7:0]           rxn,
    output          [7:0]           txp,
    output          [7:0]           txn,

    input           [7:0]           pcs_nearend_loop,
    input           [7:0]           pma_nearend_ploop,
    input           [7:0]           pma_nearend_sloop,


    //AXIS master interface : master0 for remote request
    output  wire                    axis_master0_tvalid ,
    input                           axis_master0_tready ,
    output  wire    [255:0]         axis_master0_tdata  ,
    output  wire    [7:0]           axis_master0_tkeep  ,
    output  wire                    axis_master0_tlast  ,
    output  wire    [12:0]          axis_master0_tuser  , //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                        //   function number  , vf number , vf active }
    input                           user_rcvd_np_ready  ,
    output  wire    [5:0]           core_avl_np_cnt     ,
    input                           user_rcvd_p_ready   ,
    output  wire    [5:0]           core_avl_p_cnt      ,

    //AXIS master interface : master1 for remote completion
    output  wire                    axis_master1_tvalid ,
    output  wire    [255:0]         axis_master1_tdata  ,
    output  wire    [7:0]           axis_master1_tkeep  ,
    output  wire    [33:0]          axis_master1_tuser  , //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                        //   function number  , vf number , vf active spill_cpl_data }
    //**********************************************************************
    //axis slave 0 interface
    output  wire                    axis_slave0_tready  ,
    input                           axis_slave0_tvalid  ,
    input           [255:0]         axis_slave0_tdata   ,
    input                           axis_slave0_tlast   ,
    input           [5:0]           axis_slave0_tuser   ,//{bad eot , function number  , vf number , vf active}

    //axis slave 1 interface
    output  wire                    axis_slave1_tready  ,
    input                           axis_slave1_tvalid  ,
    input           [255:0]         axis_slave1_tdata   ,
    input                           axis_slave1_tlast   ,
    input           [5:0]           axis_slave1_tuser   ,
    //axis slave 2 interface
    output  wire                    axis_slave2_tready  ,
    input                           axis_slave2_tvalid  ,
    input           [255:0]         axis_slave2_tdata   ,
    input                           axis_slave2_tlast   ,
    input           [5:0]           axis_slave2_tuser   ,

    //radm timeout
    output  wire    [1:0]           radm_cpl_timeout          ,
    output  wire    [1:0]           radm_timeout_func_num     ,
    output  wire    [5:0]           radm_timeout_vfunc_num    ,
    output  wire    [1:0]           radm_timeout_vfunc_active ,
    output  wire    [5:0]           radm_timeout_cpl_tc       ,
    output  wire    [3:0]           radm_timeout_cpl_attr     ,
    output  wire    [21:0]          radm_timeout_cpl_len      ,
    output  wire    [15:0]          radm_timeout_cpl_tag      ,

    //legacy interrupt
    output  wire    [2-1:0]         cfg_int_disable            ,
    input   wire    [  1:0]         sys_int                    ,//0:INTa 1:INTb
    output  wire                    int_grt                    ,

    output  wire    [1:0]           cfg_msi_en                 ,
    input           [4:0]           ven_msi_vector             ,
    input           [63:0]          cfg_msi_pending            ,
    input                           ven_msi_func_num           ,
    input           [2:0]           ven_msi_vfunc_num          ,
    input                           ven_msi_vfunc_active       ,
    output  wire                    cfg_msi_mask_update        ,
    input           [191:0]         cfg_vf_msi_pending         ,

    input                           ven_msi_req                ,
    input           [2:0]           ven_msi_tc                 ,
    output  wire                    ven_msi_grant              ,

    input           [63:0]          msix_addr                  ,
    input           [31:0]          msix_data                  ,
    output  wire    [1:0]           cfg_msix_func_mask         ,
    output  wire    [5:0]           cfg_vf_msix_func_mask      ,
    output  wire    [17:0]          cfg_vf_multi_msi_en        ,
    output  wire    [5:0]           cfg_vf_msix_en             ,
    output  wire    [5:0]           cfg_vf_msi_en              ,
    output  wire    [5:0]           cfg_multi_msi_en           ,
    output  wire    [1:0]           cfg_msix_en                ,

    //Configuration reg output interface
    output  wire    [6-1:0]         cfg_vf_bme                 ,
    output  wire    [2-1:0]         cfg_vf_en                  ,
    output  wire    [16*2-1:0]      cfg_num_vf                 ,
    output  wire    [6-1:0]         cfg_start_vfi              ,
    output  wire    [(1*2)-1:0]     cfg_tph_req_en             ,
    output  wire    [(3*2)-1:0]     cfg_pf_tph_st_mode         ,
    output  wire    [(3*6)-1:0]     cfg_vf_tph_st_mode         ,
    output  wire    [(1*6)-1:0]     cfg_vf_tph_req_en          ,
    output  wire    [2-1:0]         dpa_substate_update        ,
    output  wire    [2-1:0]         cfg_atomic_req_en          ,
    output  wire    [2-1:0]         cfg_atomic_egress_block    ,
    output  wire    [2-1:0]         cfg_ari_fwd_en             ,
    output  wire    [2-1:0]         cfg_send_cor_err           ,
    output  wire    [2-1:0]         cfg_send_nf_err            ,
    output  wire    [2-1:0]         cfg_send_f_err             ,
    output  wire    [2-1:0]         cfg_no_snoop_en            ,
    output  wire    [2-1:0]         cfg_relax_order_en         ,
    output  wire                    cfg_link_auto_bw_int       ,
    output  wire                    cfg_link_auto_bw_msi       ,
    output  wire                    cfg_bw_mgt_int             ,
    output  wire                    cfg_bw_mgt_msi             ,
    output  wire                    cfg_link_eq_req_int        ,
    output  wire    [2-1:0]         rbar_ctrl_update           ,
    output  wire    [2-1:0]         cfg_ido_req_en             ,
    output  wire    [2-1:0]         cfg_ido_cpl_en             ,
    output  wire    [2-1:0]         cfg_sys_err_rc             ,
    output  wire    [2-1:0]         cfg_aer_rc_err_int         ,
    output  wire    [2-1:0]         cfg_aer_rc_err_msi         ,
    output  wire    [2-1:0]         cfg_pme_int                ,
    output  wire    [2-1:0]         cfg_pme_msi                ,
    output  wire    [2-1:0]         cfg_crs_sw_vis_en          ,
    output  wire    [1-1:0]         radm_q_not_empty           ,
    output  wire    [1-1:0]         radm_qoverflow             ,
    output  wire    [2-1:0]         cfg_bus_master_en          ,
    output  wire                    cfg_2nd_reset              ,
    output  wire    [6-1:0]         cfg_max_payload_size       ,
    output  wire    [2-1:0]         cfg_rcb                    ,
    output  wire    [8-1:0]         cfg_tc_enable              ,
    output  wire    [2-1:0]         cfg_mem_space_en           ,
    output  wire    [6-1:0]         cfg_max_rd_req_size        ,
    output  wire    [2-1:0]         cfg_ext_tag_en             ,
    output  wire    [2-1:0]         cfg_reg_serren             ,
    output  wire    [2-1:0]         cfg_cor_err_rpt_en         ,
    output  wire    [2-1:0]         cfg_nf_err_rpt_en          ,
    output  wire    [2-1:0]         cfg_f_err_rpt_en           ,
    output  wire    [8-1:0]         cfg_pbus_num               ,
    output  wire    [5-1:0]         cfg_pbus_dev_num           ,
    output  wire    [1:0]           cfg_obff_en                ,

    //debug interface
    input           [6-1 :0]        dyn_debug_info_sel         ,
    input                           app_ras_des_sd_hold_ltssm  ,
    //input           [3-1 :0]        diag_ctrl_bus              ,
    output  wire    [142:0]         debug_info_mux             ,

    // START_IO:FLR Signal Descriptions
    output  wire    [2-1:0]         cfg_flr_pf_active          ,
    input           [2-1:0]         app_flr_pf_done            ,

    //Link status interface
    output  wire                    rdlh_link_up               ,
    output  wire    [5:0]           smlh_ltssm_state           ,
    output  wire                    smlh_link_up               ,
    output  wire                    link_req_rst_not           ,
    output  wire                    smlh_req_rst_not
);


    localparam              DEVICE_TYPE = 4'b0000  ;   // EP-> 4'b0000; RC->4'b0100;

    localparam              PF1_ENABLE                      = "FALSE"   ;   // FALSE, TRUE

//SC Param
    localparam              VC_DISABLE                      = "FALSE"   ;   // FALSE, TRUE

    localparam            SRIOV_DISABLE                     = "TRUE"    ;   // FALSE, TRUE

    localparam            MULTI_EN                          = 1'b0     ;

    localparam               MSI_PVM_DISABLE                = 255    ;

    localparam              ATOMIC_DISABLE                  = "TRUE";

// cfg space reg

    localparam               MAX_LINK_WIDTH                 = 6'h8   ;  //0x1:x1 0x2:x2 0x4:x4 0x8:x8

    localparam               MAX_LINK_SPEED                 = 4'h3   ;  //0x1:gen1 0x2:gen2 0x3 gen3

    localparam               LINK_CAPABLE                   = 6'hf   ;  //0x1:x1 0x3:x2 0x7:x4 0xf:x8

    localparam               NUM_OF_LANES                   = 5'b1   ;   //0x1:x1 0x2:x2 0x4:x4 0x8:x8

    localparam              PCIE_CAP_RCB                    = 1'b1        ;

    localparam              PCIE_CAP_CRS                    = 1'b0     ;

    localparam              PCIE_CAP_ATOMIC_EN              = 1'b0     ;

    localparam              SCRAMBLE_DISABLE               = 1'b1;

    localparam              AUTO_LANE_FLIP_CTRL_EN         = 1'b0;

    localparam              PCIE_CAP_HW_AUTO_SPEED_DISABLE  = 1'b0     ;

    localparam              DO_DESKEW_FOR_SRIS              = 1'b1      ;
    //localparam             TPH_REQ_NEXT_PTR               = 12'h2E4           ;

    //localparam             UPCONFIGURE_SUPPORT            = 1'b0     ;  //@IPC bool

    localparam               TARGET_LINK_SPEED              = 4'h3      ;

    localparam               EXT_TAG_EN                     = 1'b1     ;

    localparam               EXT_TAG_SUPP                   = 1'b1     ;

    localparam               INT_DISABLE                    = 1'b0;

    //localparam  integer     BAR_MASK_WRITABLE                   = 12'hfff           ;// 0~63 -- pf0 64~128 --pf1; 0: no writable bar, 1:pf0 bar0 writable, 2:pf0 bar1 writable, 3:pf0 bar3 writable, ... 63:pf0 bar0-5 writable
    //localparam  integer     BAR_RESIZABLE                       = 12'h0             ; // enable pf0 and pf1 bars resizable, default: pf0 - bar4,bar2,bar0; pf1 - bar4,bar2,bar0
    //localparam  integer     NUM_OF_RBARS                        = 6'h0              ; // set pf0 and pf1 resizable bars number,  default: pf0 - 3; pf1 - 3

//============================PF0 and PF1 Config different value
//PF0

    localparam               PF0_DEVICE_ID                      = 16'h0755   ;

    localparam               PF0_SUBSYS_DEV_ID                  = 16'h0000   ;

    localparam               PF0_VENDOR_ID                      = 16'h0755   ;

    localparam               PF0_SUBSYS_VENDOR_ID               = 16'h0000   ;

    localparam               PF0_BASE_CLASS_CODE                = 8'h05    ;

    localparam               PF0_SUBCLASS_CODE                  = 8'h80    ;

    localparam               PF0_PROGRAM_INTERFACE              = 8'h00    ;

    localparam               PF0_REVISION_ID                    = 8'h00    ;

    localparam               PF0_MAX_PAYLOAD_SIZE               = 3'd3   ;   // 1024-bytes

    localparam               PF0_INT_PIN                        = 8'h1   ;

    localparam               PF0_MSI_64_BIT_ADDR_CAP            = 1'b1;

    localparam               PF0_MSI_MULTIPLE_MSG_CAP           = 3'd5   ;

    localparam               PF0_MSI_ENABLE                     = 1'b1;

    localparam               PF0_CAP_POINTER                    = 8'h50    ;

    localparam               PF0_PCIE_CAP_NEXT_PTR              = 8'hB0    ;

    localparam               PF0_BAR0_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR0_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_BAR0_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR0_ENABLED                   = 1'b1    ;   //@IPC bool

    localparam               PF0_BAR0_MASK                      = 31'h3fff   ; //@IPC string

    localparam               PF0_BAR1_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR1_ENABLED                   = 1'b1    ;   //@IPC bool

    localparam               PF0_BAR1_MASK                      = 31'h7fff   ; //@IPC string

    localparam               PF0_BAR2_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR2_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_BAR2_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR2_ENABLED                   = 1'b1    ;   //@IPC bool

    localparam               PF0_BAR2_MASK                      = 31'h3fff   ; //@IPC string

    localparam               PF0_BAR3_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR3_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_BAR3_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_BAR4_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR4_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_BAR4_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR4_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_BAR4_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_BAR5_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_BAR5_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_BAR5_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_ROM_BAR_ENABLE                 = 1'b0    ;   //@IPC bool

    localparam               PF0_ROM_BAR_ENABLED                = 1'b0    ;   //@IPC bool

    localparam               PF0_ROM_MASK                       = 31'h0   ; //@IPC string

    localparam               PF0_ECRC_CHECK_EN                  = 1'b1     ;  //@IPC bool

    localparam               PF0_ECRC_GEN_EN                    = 1'b0     ;  //@IPC bool

    localparam               PF0_PCI_MSIX_ENABLE                = 1'b1     ;  //@IPC bool

    localparam               PF0_PCI_FUNCTION_MASK              = 1'b0      ;

    localparam               PF0_PCI_MSIX_TABLE_SIZE            = 11'h1f   ; //@IPC string

    localparam               PF0_PCI_MSIX_CAP_NEXT_OFFSET       = 8'h0      ;

    localparam               PF0_PCI_MSIX_TABLE_OFFSET          = 29'h1000   ; //@IPC string

    localparam               PF0_PCI_MSIX_BIR                   = 3'd1   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_PCI_MSIX_PBA_OFFSET            = 29'h11FC   ; //@IPC string

    localparam               PF0_PCI_MSIX_PBA_BIR               = 3'd1   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_AER_CAP_NEXT_OFFSET            = 12'h0    ;

    //localparam              PF0_RESBAR_BAR0_MAX_SUPP_SIZE     = 20'hf_ffff    ;
    //localparam              PF0_RESBAR_BAR0_INIT_SIZE         = 5'h0          ;
    //localparam              PF0_RESBAR_BAR1_MAX_SUPP_SIZE     = 20'hf_ffff    ;
    //localparam              PF0_RESBAR_BAR1_INIT_SIZE         = 5'h0          ;
    //localparam              PF0_RESBAR_BAR2_MAX_SUPP_SIZE     = 20'hf_ffff    ;
    //localparam              PF0_RESBAR_BAR2_INIT_SIZE         = 5'h0          ;
//PF1

    localparam               PF1_DEVICE_ID                      = 16'h0755   ;

    localparam               PF1_SUBSYS_DEV_ID                  = 16'h0000   ;

    localparam               PF1_VENDOR_ID                      = 16'h0755   ;

    localparam               PF1_SUBSYS_VENDOR_ID               = 16'h0000   ;

    localparam               PF1_BASE_CLASS_CODE                = 8'h05    ;

    localparam               PF1_SUBCLASS_CODE                  = 8'h80    ;

    localparam               PF1_PROGRAM_INTERFACE              = 8'h00    ;

    localparam               PF1_REVISION_ID                    = 8'h00    ;

    localparam               PF1_MAX_PAYLOAD_SIZE               = 3'd0   ;   // 1024-bytes

    localparam               PF1_INT_PIN                        = 8'h2   ;

    localparam               PF1_MSI_64_BIT_ADDR_CAP            = 1'b0;

    localparam               PF1_MSI_MULTIPLE_MSG_CAP           = 3'd0   ;

    localparam               PF1_MSI_ENABLE                     = 1'b0;

    localparam               PF1_CAP_POINTER                    = 8'h70    ;

    localparam               PF1_PCIE_CAP_NEXT_PTR              = 8'h00    ;

    localparam               PF1_BAR0_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR0_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_BAR0_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR0_ENABLED                   = 1'b1    ;   //@IPC bool

    localparam               PF1_BAR0_MASK                      = 31'hfff   ; //@IPC string

    localparam               PF1_BAR1_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR1_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_BAR1_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_BAR2_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR2_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_BAR2_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR2_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_BAR2_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_BAR3_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR3_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_BAR3_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_BAR4_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR4_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_BAR4_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR4_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_BAR4_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_BAR5_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_BAR5_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_BAR5_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_ROM_BAR_ENABLE                 = 1'b0    ;   //@IPC bool

    localparam               PF1_ROM_BAR_ENABLED                = 1'b0    ;   //@IPC bool

    localparam               PF1_ROM_MASK                       = 31'h0   ; //@IPC string

    localparam               PF1_ECRC_CHECK_EN                  = 1'b1     ;  //@IPC bool

    localparam               PF1_ECRC_GEN_EN                    = 1'b0     ;  //@IPC bool

    localparam               PF1_PCI_MSIX_ENABLE                = 1'b0     ;  //@IPC bool

    localparam               PF1_PCI_FUNCTION_MASK              = 1'b0      ;

    localparam               PF1_PCI_MSIX_TABLE_SIZE            = 11'h1   ; //@IPC string

    localparam               PF1_PCI_MSIX_CAP_NEXT_OFFSET       = 8'h0      ;

    localparam               PF1_PCI_MSIX_TABLE_OFFSET          = 29'h0   ; //@IPC string

    localparam               PF1_PCI_MSIX_BIR                   = 3'd0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_PCI_MSIX_PBA_OFFSET            = 29'h0   ; //@IPC string

    localparam               PF1_PCI_MSIX_PBA_BIR               = 3'd0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_AER_CAP_NEXT_OFFSET            = 12'h0    ;

    //SRIOV CAP
    localparam              PF0_SRIOV_EXT_CAP_NXT_OFFSET          = 12'h0         ;

    localparam              PF0_SRIOV_EXT_CAP_VER                 = 4'h0         ;

    localparam              PF0_SRIOV_INITIAL_VFS                 = 16'h1        ;

    localparam              PF0_SRIOV_VF_OFFSET                   = 16'h2         ; //@IPC int 2,64

    localparam              PF0_SRIOV_VF_DEVICE_ID                = 16'h0000     ;

    localparam               PF0_SRIOV_VF_BAR0_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR0_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_SRIOV_VF_BAR0_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR0_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR0_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_SRIOV_VF_BAR1_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR1_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR1_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_SRIOV_VF_BAR2_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR2_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_SRIOV_VF_BAR2_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR2_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR2_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_SRIOV_VF_BAR3_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR3_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR3_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_SRIOV_VF_BAR4_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR4_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF0_SRIOV_VF_BAR4_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR4_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR4_MASK                      = 31'h0   ; //@IPC string

    localparam               PF0_SRIOV_VF_BAR5_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF0_SRIOV_VF_BAR5_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF0_SRIOV_VF_BAR5_MASK                      = 31'h0   ; //@IPC string

    localparam              PF0_SRIOV_MSI_64_BIT_ADDR_CAP         =  1'b1;

    localparam              PF0_SRIOV_MSI_MULTIPLE_MSG_CAP            = 3'd0   ;

    localparam              PF0_SRIOV_MSI_ENABLE                      = 1'b1;

    localparam              PF0_SRIOV_MSI_CAP_NEXT_OFFSET             = 8'h70;

    localparam              PF1_SRIOV_EXT_CAP_NXT_OFFSET          = 12'h0         ;

    localparam              PF1_SRIOV_EXT_CAP_VER                 = 4'h0         ;

    localparam              PF1_SRIOV_INITIAL_VFS                 = 16'h0        ;

    localparam              PF1_SRIOV_VF_OFFSET                   = 16'h2         ; //@IPC int 2,64

    localparam              PF1_SRIOV_VF_DEVICE_ID                = 16'h0000     ;

    localparam               PF1_SRIOV_VF_BAR0_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR0_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_SRIOV_VF_BAR0_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR0_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR0_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_SRIOV_VF_BAR1_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR1_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR1_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_SRIOV_VF_BAR2_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR2_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_SRIOV_VF_BAR2_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR2_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR2_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_SRIOV_VF_BAR3_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR3_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR3_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_SRIOV_VF_BAR4_PREFETCH                  = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR4_TYPE                      = 2'd0   ;   //@IPC enum 2'd0,2'd2

    localparam               PF1_SRIOV_VF_BAR4_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR4_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR4_MASK                      = 31'h0   ; //@IPC string

    localparam               PF1_SRIOV_VF_BAR5_MEM_IO                    = 1'b0   ;   //@IPC enum 1'b0,1'b1

    localparam               PF1_SRIOV_VF_BAR5_ENABLED                   = 1'b0    ;   //@IPC bool

    localparam               PF1_SRIOV_VF_BAR5_MASK                      = 31'h0   ; //@IPC string

    localparam              PF1_SRIOV_MSI_64_BIT_ADDR_CAP         =  1'b0;

    localparam              PF1_SRIOV_MSI_MULTIPLE_MSG_CAP            = 3'd0   ;

    localparam              PF1_SRIOV_MSI_ENABLE                      = 1'b0;

    localparam              PF1_SRIOV_MSI_CAP_NEXT_OFFSET             = 8'h70;

    //localparam              PF1_RESBAR_BAR0_MAX_SUPP_SIZE       = 20'hf_ffff  ;
    //localparam              PF1_RESBAR_BAR0_INIT_SIZE           = 5'h0        ;
    //localparam              PF1_RESBAR_BAR1_MAX_SUPP_SIZE       = 20'hf_ffff  ;
    //localparam              PF1_RESBAR_BAR1_INIT_SIZE           = 5'h0        ;
    //localparam              PF1_RESBAR_BAR2_MAX_SUPP_SIZE       = 20'hf_ffff  ;
    //localparam              PF1_RESBAR_BAR2_INIT_SIZE           = 5'h0        ;


    localparam              HPLL_EN       = "TRUE"                            ;//TRUE, FALSE; for HPLL enable

    localparam integer  HSST_LANE_NUM = (LINK_CAPABLE == 6'hf) ? 8 :
                                        (LINK_CAPABLE == 6'h7) ? 4 :
                                        (LINK_CAPABLE == 6'h3) ? 2 : 1;
    //SPEEDUP_SIM
    wire    [3-1 :0]  diag_ctrl_bus;
    `ifdef IPS2T_PCIE_SPEEDUP_SIM
    assign diag_ctrl_bus = 3'b100;
    `else
    assign diag_ctrl_bus = 3'b000;
    `endif


//hot rst
wire    app_init_rst;
wire    training_rst_n;
wire    apb_rst_n;
wire    sync_apb_rst_n;

assign  app_init_rst = 1'b0;

//prbs
wire            prbs_en         ;
wire            force_loss_signal;
wire            force_cdr_align  ;
wire            force_word_align ;

assign  prbs_en             = 1'b0;
assign  force_loss_signal    = 1'b0;
assign  force_cdr_align      = 1'b0;
assign  force_word_align     = 1'b0;


//iscan
wire                       iscan_p_rst;
wire [HSST_LANE_NUM-1:0]   rx_eye_rst;
wire [HSST_LANE_NUM-1:0]   rx_eye_en;
wire [HSST_LANE_NUM*8-1:0] rx_eye_tap;
wire [HSST_LANE_NUM*8-1:0] rx_pic_eye;
wire [HSST_LANE_NUM-1:0]   em_rd_trigger;
wire [HSST_LANE_NUM*2-1:0] em_mode_ctrl;
wire                       pll_done;
wire [HSST_LANE_NUM-1:0]   rx_sigdet_sta;
wire [HSST_LANE_NUM-1:0]   lx_cdr_align;
assign iscan_p_rst   = 1'b0;
assign rx_eye_rst    = {HSST_LANE_NUM{1'b0}};
assign rx_eye_en     = {HSST_LANE_NUM{1'b0}};
assign rx_eye_tap    = {(HSST_LANE_NUM*8){1'b0}};
assign rx_pic_eye    = {(HSST_LANE_NUM*8){1'b0}};
assign em_rd_trigger = {HSST_LANE_NUM{1'b0}};
assign em_mode_ctrl  = {(HSST_LANE_NUM*2){1'b0}};

assign apb_rst_n = p_rst_n & ~iscan_p_rst;

ips2t_pcie_sync_v1_0  apb_rstn_sync (.clk(ref_clk), .rst_n(apb_rst_n), .sig_async(1'b1),  .sig_synced(sync_apb_rst_n));

//message
wire   [4:0]           msg_rcvd_type               ;
wire   [7:0]           msg_rcvd_data               ;
wire                   msg_rcvd                    ;
wire                   app_unlock_msg              ;
wire                   app_obff_idle_msg_req       ;
wire                   app_obff_obff_msg_req       ;
wire                   app_obff_cpu_active_msg_req ;
wire                   app_obff_msg_grant          ;
wire                   cfg_ltr_m_en                ;
wire                   app_ltr_msg_req             ;
wire                   app_ltr_msg_grant           ;
wire   [31:0]          app_ltr_msg_latency         ;
wire   [1-1:0]         app_ltr_msg_func_num        ;
wire                   cfg_disable_ltr_clr_msg     ;

assign app_unlock_msg              = 1'd0;
assign app_obff_idle_msg_req       = 1'd0;
assign app_obff_obff_msg_req       = 1'd0;
assign app_obff_cpu_active_msg_req = 1'd0;
assign app_ltr_msg_req             = 1'd0;
assign app_ltr_msg_latency         = 32'd0;
assign app_ltr_msg_func_num        = 1'd0;

wire                    apps_pm_xmt_turnoff        ;
wire                    pm_xtlh_block_tlp          ;
wire    [(3*2)-1:0]     pm_dstate                  ;
wire    [(3*6)-1:0]     pm_vf_dstate               ;
wire    [6-1:0]         pm_vf_pme_en               ;
wire    [6-1:0]         pm_vf_status               ;
wire    [2-1:0]         aux_pm_en                  ;
wire    [2-1:0]         pm_pme_en                  ;
wire    [2-1:0]         pm_status                  ;
wire                    wake                       ;
wire    [5-1:0]         pm_master_state            ;
wire    [5-1:0]         pm_slave_state             ;

assign apps_pm_xmt_turnoff  = 1'd0;

//Error handling
wire                    app_hdr_valid              ;
wire    [127:0]         app_hdr_log                ;
wire    [13-1:0]        app_err_bus                ;
wire                    app_err_advisory           ;
wire    [1-1:0]         app_err_func_num           ;
wire    [4-2:0]         app_err_vfunc_num          ;
wire                    app_err_vfunc_active       ;

assign app_hdr_valid         = 1'd0;
assign app_hdr_log           = 128'd0;
assign app_err_bus           = 13'd0;
assign app_err_advisory      = 1'd0;
assign app_err_func_num      = 1'd0;
assign app_err_vfunc_num     = 3'd0;
assign app_err_vfunc_active  = 1'd0;

// START_IO: Power Budgeting Signal Descriptions.
wire                   cfg_pwr_budget_valid       ;
wire   [2-1:0]         cfg_pwr_budget_sel         ;
wire   [1-1:0]         cfg_pwr_budget_func_num    ;
wire   [7:0]           cfg_pwr_budget_data_sel_reg;
wire   [31:0]          cfg_pwr_budget_data_reg    ;

assign cfg_pwr_budget_valid     = 1'd0;
assign cfg_pwr_budget_func_num  = 1'd0;
assign cfg_pwr_budget_data_reg  = 32'd0;

//App cfg interface
wire                   rx_lane_flip_en            ;
wire                   tx_lane_flip_en            ;
wire                   app_xfer_pending           ;
wire   [6-1:0]         app_vf_req_retry_en        ;
wire                   app_req_retry_en           ;
wire                   app_req_exit_l1            ;
wire                   app_req_entr_l1            ;
wire                   app_ready_entr_l23         ;
wire   [2-1:0]         app_pf_req_retry_en        ;
wire   [2-1:0]         apps_pm_xmt_pme            ;
wire   [6-1:0]         apps_pm_vf_xmt_pme         ;

assign rx_lane_flip_en     = 1'd0;
assign tx_lane_flip_en     = 1'd0;
assign app_xfer_pending    = 1'd0;
assign app_vf_req_retry_en = 6'd0;
assign app_req_retry_en    = 1'd0;
assign app_req_exit_l1     = 1'd0;
assign app_req_entr_l1     = 1'd0;
assign app_ready_entr_l23  = 1'd0;
assign app_pf_req_retry_en = 2'd0;
assign apps_pm_xmt_pme     = 2'd0;
assign apps_pm_vf_xmt_pme  = 6'd0;

//Flow control Interface
wire    [1*8-1:0]       xadm_ph_cdts               ;
wire    [1*12-1:0]      xadm_pd_cdts               ;
wire    [1*8-1:0]       xadm_nph_cdts              ;
wire    [1*12-1:0]      xadm_npd_cdts              ;
wire    [1*8-1:0]       xadm_cplh_cdts             ;
wire    [1*12-1:0]      xadm_cpld_cdts             ;

//vf_num
wire   [2:0]           app_pf0_vf_num             ;
wire   [2:0]           app_pf1_vf_num             ;

assign app_pf0_vf_num = 3'd0;
assign app_pf1_vf_num = 3'd0;

wire    [6-1:0]         cfg_flr_vf_active          ;
wire    [6-1:0]         app_flr_vf_done            ;

assign app_flr_vf_done = 6'd0;

//********************************************************************
//              pcie_top instance
//********************************************************************
ips2t_pcie_top_v1_8 #(

    .PF1_ENABLE                     (PF1_ENABLE                     ), // FALSE, TRUE
    //.FLT_SHORT_TLP                  ("TRUE"                         ), // FALSE, TRUE
    //.VF_ER_REPORT_EN                ("TRUE"                         ), // FALSE, TRUE
    .VC_DISABLE                     (VC_DISABLE                      ), // FALSE, TRUE
    .SRIOV_DISABLE                  (SRIOV_DISABLE                  ), // FALSE, TRUE
    .MSI_PVM_DISABLE                (MSI_PVM_DISABLE                ), // 0: all func enable, 1:pf0 disable, 2:pf1 disable, 3:pf0 and pf1 disable, 4:vf0 disable ......255:all func disable
    .ATOMIC_DISABLE                 (ATOMIC_DISABLE                 ), // FALSE, TRUE
    //.BAR_RESIZABLE                  (BAR_RESIZABLE                    ), // enable pf0 and pf1 bars resizable, default: pf0 - bar4,bar2,bar0; pf1 - bar4,bar2,bar0
    //.NUM_OF_RBARS                   (NUM_OF_RBARS                     ), // set pf0 and pf1 resizable bars number,  default: pf0 - 3; pf1 - 3
    //.BAR_MASK_WRITABLE              (BAR_MASK_WRITABLE                       ), // 0~63 -- pf0 64~128 --pf1; 0: no writable bar, 1:pf0 bar0 writable, 2:pf0 bar1 writable, 3:pf0 bar3 writable, ... 63:pf0 bar0-5 writable
    .HSST_LANE_NUM                  (HSST_LANE_NUM                  ),
    .HPLL_EN                        (HPLL_EN                       ),
    //init
    .DEVICE_TYPE                    (DEVICE_TYPE                    ),
    .MULTI_EN                       (MULTI_EN                       ), // 0,1
    .PCIE_CAP_RCB                   (PCIE_CAP_RCB                   ),
    .PCIE_CAP_CRS                   (PCIE_CAP_CRS                   ),
    .PCIE_CAP_ATOMIC_EN             (PCIE_CAP_ATOMIC_EN             ),
    .SCRAMBLE_DISABLE               (SCRAMBLE_DISABLE               ),
    .AUTO_LANE_FLIP_CTRL_EN         (AUTO_LANE_FLIP_CTRL_EN         ),
    .PCIE_CAP_HW_AUTO_SPEED_DISABLE (PCIE_CAP_HW_AUTO_SPEED_DISABLE ),
    .DO_DESKEW_FOR_SRIS             (DO_DESKEW_FOR_SRIS             ),
    //.TPH_REQ_NEXT_PTR               (TPH_REQ_NEXT_PTR               ),
    //.UPCONFIGURE_SUPPORT            (UPCONFIGURE_SUPPORT            ),
    .TARGET_LINK_SPEED              (TARGET_LINK_SPEED              ),
    .LINK_CAPABLE                   (LINK_CAPABLE                   ),   //0x1:x1 0x3:x2 0x7:x4 0xf:x8
    .NUM_OF_LANES                   (NUM_OF_LANES                   ),   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
    .MAX_LINK_WIDTH                 (MAX_LINK_WIDTH                 ),   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
    .MAX_LINK_SPEED                 (MAX_LINK_SPEED                 ),   //0x1:gen1 0x2:gen2 0x3 gen3
    .EXT_TAG_EN                     (EXT_TAG_EN                     ),
    .EXT_TAG_SUPP                   (EXT_TAG_SUPP                   ),
    .INT_DISABLE                    (INT_DISABLE                    ),
    .PF0_DEVICE_ID                  (PF0_DEVICE_ID                  ),
    .PF0_SUBSYS_DEV_ID              (PF0_SUBSYS_DEV_ID              ),
    .PF0_VENDOR_ID                  (PF0_VENDOR_ID                  ),
    .PF0_SUBSYS_VENDOR_ID           (PF0_SUBSYS_VENDOR_ID           ),
    .PF0_BASE_CLASS_CODE            (PF0_BASE_CLASS_CODE            ),
    .PF0_SUBCLASS_CODE              (PF0_SUBCLASS_CODE              ),
    .PF0_PROGRAM_INTERFACE          (PF0_PROGRAM_INTERFACE          ),
    .PF0_REVISION_ID                (PF0_REVISION_ID                ),
    .PF0_MAX_PAYLOAD_SIZE           (PF0_MAX_PAYLOAD_SIZE           ),  // 1024-bytes
    .PF0_INT_PIN                    (PF0_INT_PIN                    ),
    .PF0_MSI_64_BIT_ADDR_CAP        (PF0_MSI_64_BIT_ADDR_CAP        ),
    .PF0_MSI_MULTIPLE_MSG_CAP       (PF0_MSI_MULTIPLE_MSG_CAP       ),
    .PF0_MSI_ENABLE                 (PF0_MSI_ENABLE                 ),
    .PF0_CAP_POINTER                (PF0_CAP_POINTER                ),
    .PF0_PCIE_CAP_NEXT_PTR          (PF0_PCIE_CAP_NEXT_PTR          ),
    .PF0_BAR0_PREFETCH              (PF0_BAR0_PREFETCH              ),
    .PF0_BAR0_TYPE                  (PF0_BAR0_TYPE                  ),
    .PF0_BAR0_MEM_IO                (PF0_BAR0_MEM_IO                ),
    .PF0_BAR0_ENABLED               (PF0_BAR0_ENABLED               ),
    .PF0_BAR0_MASK                  (PF0_BAR0_MASK                  ),
    .PF0_BAR1_MEM_IO                (PF0_BAR1_MEM_IO                ),
    .PF0_BAR1_ENABLED               (PF0_BAR1_ENABLED               ),
    .PF0_BAR1_MASK                  (PF0_BAR1_MASK                  ),
    .PF0_BAR2_PREFETCH              (PF0_BAR2_PREFETCH              ),
    .PF0_BAR2_TYPE                  (PF0_BAR2_TYPE                  ),
    .PF0_BAR2_MEM_IO                (PF0_BAR2_MEM_IO                ),
    .PF0_BAR2_ENABLED               (PF0_BAR2_ENABLED               ),
    .PF0_BAR2_MASK                  (PF0_BAR2_MASK                  ),
    .PF0_BAR3_MEM_IO                (PF0_BAR3_MEM_IO                ),
    .PF0_BAR3_ENABLED               (PF0_BAR3_ENABLED               ),
    .PF0_BAR3_MASK                  (PF0_BAR3_MASK                  ),
    .PF0_BAR4_PREFETCH              (PF0_BAR4_PREFETCH              ),
    .PF0_BAR4_TYPE                  (PF0_BAR4_TYPE                  ),
    .PF0_BAR4_MEM_IO                (PF0_BAR4_MEM_IO                ),
    .PF0_BAR4_ENABLED               (PF0_BAR4_ENABLED               ),
    .PF0_BAR4_MASK                  (PF0_BAR4_MASK                  ),
    .PF0_BAR5_MEM_IO                (PF0_BAR5_MEM_IO                ),
    .PF0_BAR5_ENABLED               (PF0_BAR5_ENABLED               ),
    .PF0_BAR5_MASK                  (PF0_BAR5_MASK                  ),
    .PF0_ROM_BAR_ENABLE             (PF0_ROM_BAR_ENABLE             ),
    .PF0_ROM_BAR_ENABLED            (PF0_ROM_BAR_ENABLED            ),
    .PF0_ROM_MASK                   (PF0_ROM_MASK                   ),
    .PF0_ECRC_CHECK_EN              (PF0_ECRC_CHECK_EN              ),
    .PF0_ECRC_GEN_EN                (PF0_ECRC_GEN_EN                ),
    .PF0_PCI_MSIX_ENABLE            (PF0_PCI_MSIX_ENABLE            ),
    .PF0_PCI_FUNCTION_MASK          (PF0_PCI_FUNCTION_MASK          ),
    .PF0_PCI_MSIX_TABLE_SIZE        (PF0_PCI_MSIX_TABLE_SIZE        ),
    .PF0_PCI_MSIX_CAP_NEXT_OFFSET   (PF0_PCI_MSIX_CAP_NEXT_OFFSET   ),
    .PF0_PCI_MSIX_TABLE_OFFSET      (PF0_PCI_MSIX_TABLE_OFFSET      ),
    .PF0_PCI_MSIX_BIR               (PF0_PCI_MSIX_BIR               ),
    .PF0_PCI_MSIX_PBA_OFFSET        (PF0_PCI_MSIX_PBA_OFFSET        ),
    .PF0_PCI_MSIX_PBA_BIR           (PF0_PCI_MSIX_PBA_BIR           ),
    .PF0_AER_CAP_NEXT_OFFSET        (PF0_AER_CAP_NEXT_OFFSET        ),
    //.PF0_RESBAR_BAR0_MAX_SUPP_SIZE  (PF0_RESBAR_BAR0_MAX_SUPP_SIZE  ),
    //.PF0_RESBAR_BAR0_INIT_SIZE      (PF0_RESBAR_BAR0_INIT_SIZE      ),
    //.PF0_RESBAR_BAR1_MAX_SUPP_SIZE  (PF0_RESBAR_BAR1_MAX_SUPP_SIZE  ),
    //.PF0_RESBAR_BAR1_INIT_SIZE      (PF0_RESBAR_BAR1_INIT_SIZE      ),
    //.PF0_RESBAR_BAR2_MAX_SUPP_SIZE  (PF0_RESBAR_BAR2_MAX_SUPP_SIZE  ),
    //.PF0_RESBAR_BAR2_INIT_SIZE      (PF0_RESBAR_BAR2_INIT_SIZE      ),

    .PF1_DEVICE_ID                  (PF1_DEVICE_ID                  ),
    .PF1_SUBSYS_DEV_ID              (PF1_SUBSYS_DEV_ID              ),
    .PF1_VENDOR_ID                  (PF1_VENDOR_ID                  ),
    .PF1_SUBSYS_VENDOR_ID           (PF1_SUBSYS_VENDOR_ID           ),
    .PF1_BASE_CLASS_CODE            (PF1_BASE_CLASS_CODE            ),
    .PF1_SUBCLASS_CODE              (PF1_SUBCLASS_CODE              ),
    .PF1_PROGRAM_INTERFACE          (PF1_PROGRAM_INTERFACE          ),
    .PF1_REVISION_ID                (PF1_REVISION_ID                ),
    .PF1_MAX_PAYLOAD_SIZE           (PF1_MAX_PAYLOAD_SIZE           ),  // 1024-bytes
    .PF1_INT_PIN                    (PF1_INT_PIN                    ),
    .PF1_MSI_64_BIT_ADDR_CAP        (PF1_MSI_64_BIT_ADDR_CAP        ),
    .PF1_MSI_MULTIPLE_MSG_CAP       (PF1_MSI_MULTIPLE_MSG_CAP       ),
    .PF1_MSI_ENABLE                 (PF1_MSI_ENABLE                 ),
    .PF1_CAP_POINTER                (PF1_CAP_POINTER                ),
    .PF1_PCIE_CAP_NEXT_PTR          (PF1_PCIE_CAP_NEXT_PTR          ),
    .PF1_BAR0_PREFETCH              (PF1_BAR0_PREFETCH              ),
    .PF1_BAR0_TYPE                  (PF1_BAR0_TYPE                  ),
    .PF1_BAR0_MEM_IO                (PF1_BAR0_MEM_IO                ),
    .PF1_BAR0_ENABLED               (PF1_BAR0_ENABLED               ),
    .PF1_BAR0_MASK                  (PF1_BAR0_MASK                  ),
    .PF1_BAR1_MEM_IO                (PF1_BAR1_MEM_IO                ),
    .PF1_BAR1_ENABLED               (PF1_BAR1_ENABLED               ),
    .PF1_BAR1_MASK                  (PF1_BAR1_MASK                  ),
    .PF1_BAR2_PREFETCH              (PF1_BAR2_PREFETCH              ),
    .PF1_BAR2_TYPE                  (PF1_BAR2_TYPE                  ),
    .PF1_BAR2_MEM_IO                (PF1_BAR2_MEM_IO                ),
    .PF1_BAR2_ENABLED               (PF1_BAR2_ENABLED               ),
    .PF1_BAR2_MASK                  (PF1_BAR2_MASK                  ),
    .PF1_BAR3_MEM_IO                (PF1_BAR3_MEM_IO                ),
    .PF1_BAR3_ENABLED               (PF1_BAR3_ENABLED               ),
    .PF1_BAR3_MASK                  (PF1_BAR3_MASK                  ),
    .PF1_BAR4_PREFETCH              (PF1_BAR4_PREFETCH              ),
    .PF1_BAR4_TYPE                  (PF1_BAR4_TYPE                  ),
    .PF1_BAR4_MEM_IO                (PF1_BAR4_MEM_IO                ),
    .PF1_BAR4_ENABLED               (PF1_BAR4_ENABLED               ),
    .PF1_BAR4_MASK                  (PF1_BAR4_MASK                  ),
    .PF1_BAR5_MEM_IO                (PF1_BAR5_MEM_IO                ),
    .PF1_BAR5_ENABLED               (PF1_BAR5_ENABLED               ),
    .PF1_BAR5_MASK                  (PF1_BAR5_MASK                  ),
    .PF1_ROM_BAR_ENABLE             (PF1_ROM_BAR_ENABLE             ),
    .PF1_ROM_BAR_ENABLED            (PF1_ROM_BAR_ENABLED            ),
    .PF1_ROM_MASK                   (PF1_ROM_MASK                   ),
    .PF1_ECRC_CHECK_EN              (PF1_ECRC_CHECK_EN              ),
    .PF1_ECRC_GEN_EN                (PF1_ECRC_GEN_EN                ),
    .PF1_PCI_MSIX_ENABLE            (PF1_PCI_MSIX_ENABLE            ),
    .PF1_PCI_FUNCTION_MASK          (PF1_PCI_FUNCTION_MASK          ),
    .PF1_PCI_MSIX_TABLE_SIZE        (PF1_PCI_MSIX_TABLE_SIZE        ),
    .PF1_PCI_MSIX_CAP_NEXT_OFFSET   (PF1_PCI_MSIX_CAP_NEXT_OFFSET   ),
    .PF1_PCI_MSIX_TABLE_OFFSET      (PF1_PCI_MSIX_TABLE_OFFSET      ),
    .PF1_PCI_MSIX_BIR               (PF1_PCI_MSIX_BIR               ),
    .PF1_PCI_MSIX_PBA_OFFSET        (PF1_PCI_MSIX_PBA_OFFSET        ),
    .PF1_PCI_MSIX_PBA_BIR           (PF1_PCI_MSIX_PBA_BIR           ),
    .PF1_AER_CAP_NEXT_OFFSET        (PF1_AER_CAP_NEXT_OFFSET        ),
    //.PF1_RESBAR_BAR0_MAX_SUPP_SIZE  (PF1_RESBAR_BAR0_MAX_SUPP_SIZE  ),
    //.PF1_RESBAR_BAR0_INIT_SIZE      (PF1_RESBAR_BAR0_INIT_SIZE      ),
    //.PF1_RESBAR_BAR1_MAX_SUPP_SIZE  (PF1_RESBAR_BAR1_MAX_SUPP_SIZE  ),
    //.PF1_RESBAR_BAR1_INIT_SIZE      (PF1_RESBAR_BAR1_INIT_SIZE      ),
    //.PF1_RESBAR_BAR2_MAX_SUPP_SIZE  (PF1_RESBAR_BAR2_MAX_SUPP_SIZE  ),
    //.PF1_RESBAR_BAR2_INIT_SIZE      (PF1_RESBAR_BAR2_INIT_SIZE      )
    .PF0_SRIOV_EXT_CAP_NXT_OFFSET     (PF0_SRIOV_EXT_CAP_NXT_OFFSET     ),
    .PF0_SRIOV_EXT_CAP_VER          (PF0_SRIOV_EXT_CAP_VER          ),
    .PF0_SRIOV_INITIAL_VFS          (PF0_SRIOV_INITIAL_VFS          ),
    .PF0_SRIOV_VF_OFFSET            (PF0_SRIOV_VF_OFFSET            ),
    .PF0_SRIOV_VF_DEVICE_ID         (PF0_SRIOV_VF_DEVICE_ID         ),
    .PF0_SRIOV_VF_BAR0_PREFETCH     (PF0_SRIOV_VF_BAR0_PREFETCH     ),
    .PF0_SRIOV_VF_BAR0_TYPE         (PF0_SRIOV_VF_BAR0_TYPE         ),
    .PF0_SRIOV_VF_BAR0_MEM_IO       (PF0_SRIOV_VF_BAR0_MEM_IO       ),
    .PF0_SRIOV_VF_BAR0_ENABLED      (PF0_SRIOV_VF_BAR0_ENABLED      ),
    .PF0_SRIOV_VF_BAR0_MASK         (PF0_SRIOV_VF_BAR0_MASK         ),
    .PF0_SRIOV_VF_BAR1_MEM_IO       (PF0_SRIOV_VF_BAR1_MEM_IO       ),
    .PF0_SRIOV_VF_BAR1_ENABLED      (PF0_SRIOV_VF_BAR1_ENABLED      ),
    .PF0_SRIOV_VF_BAR1_MASK         (PF0_SRIOV_VF_BAR1_MASK         ),
    .PF0_SRIOV_VF_BAR2_PREFETCH     (PF0_SRIOV_VF_BAR2_PREFETCH     ),
    .PF0_SRIOV_VF_BAR2_TYPE         (PF0_SRIOV_VF_BAR2_TYPE         ),
    .PF0_SRIOV_VF_BAR2_MEM_IO       (PF0_SRIOV_VF_BAR2_MEM_IO       ),
    .PF0_SRIOV_VF_BAR2_ENABLED      (PF0_SRIOV_VF_BAR2_ENABLED      ),
    .PF0_SRIOV_VF_BAR2_MASK         (PF0_SRIOV_VF_BAR2_MASK         ),
    .PF0_SRIOV_VF_BAR3_MEM_IO       (PF0_SRIOV_VF_BAR3_MEM_IO       ),
    .PF0_SRIOV_VF_BAR3_ENABLED      (PF0_SRIOV_VF_BAR3_ENABLED      ),
    .PF0_SRIOV_VF_BAR3_MASK         (PF0_SRIOV_VF_BAR3_MASK         ),
    .PF0_SRIOV_VF_BAR4_PREFETCH     (PF0_SRIOV_VF_BAR4_PREFETCH     ),
    .PF0_SRIOV_VF_BAR4_TYPE         (PF0_SRIOV_VF_BAR4_TYPE         ),
    .PF0_SRIOV_VF_BAR4_MEM_IO       (PF0_SRIOV_VF_BAR4_MEM_IO       ),
    .PF0_SRIOV_VF_BAR4_ENABLED      (PF0_SRIOV_VF_BAR4_ENABLED      ),
    .PF0_SRIOV_VF_BAR4_MASK         (PF0_SRIOV_VF_BAR4_MASK         ),
    .PF0_SRIOV_VF_BAR5_MEM_IO       (PF0_SRIOV_VF_BAR5_MEM_IO       ),
    .PF0_SRIOV_VF_BAR5_ENABLED      (PF0_SRIOV_VF_BAR5_ENABLED      ),
    .PF0_SRIOV_VF_BAR5_MASK         (PF0_SRIOV_VF_BAR5_MASK         ),
    .PF0_SRIOV_MSI_64_BIT_ADDR_CAP  (PF0_SRIOV_MSI_64_BIT_ADDR_CAP  ),
    .PF0_SRIOV_MSI_MULTIPLE_MSG_CAP (PF0_SRIOV_MSI_MULTIPLE_MSG_CAP ),
    .PF0_SRIOV_MSI_ENABLE           (PF0_SRIOV_MSI_ENABLE           ),
    .PF0_SRIOV_MSI_CAP_NEXT_OFFSET  (PF0_SRIOV_MSI_CAP_NEXT_OFFSET  ),
    .PF1_SRIOV_EXT_CAP_NXT_OFFSET   (PF1_SRIOV_EXT_CAP_NXT_OFFSET   ),
    .PF1_SRIOV_EXT_CAP_VER          (PF1_SRIOV_EXT_CAP_VER          ),
    .PF1_SRIOV_INITIAL_VFS          (PF1_SRIOV_INITIAL_VFS          ),
    .PF1_SRIOV_VF_OFFSET            (PF1_SRIOV_VF_OFFSET            ),
    .PF1_SRIOV_VF_DEVICE_ID         (PF1_SRIOV_VF_DEVICE_ID         ),
    .PF1_SRIOV_VF_BAR0_PREFETCH     (PF1_SRIOV_VF_BAR0_PREFETCH     ),
    .PF1_SRIOV_VF_BAR0_TYPE         (PF1_SRIOV_VF_BAR0_TYPE         ),
    .PF1_SRIOV_VF_BAR0_MEM_IO       (PF1_SRIOV_VF_BAR0_MEM_IO       ),
    .PF1_SRIOV_VF_BAR0_ENABLED      (PF1_SRIOV_VF_BAR0_ENABLED      ),
    .PF1_SRIOV_VF_BAR0_MASK         (PF1_SRIOV_VF_BAR0_MASK         ),
    .PF1_SRIOV_VF_BAR1_MEM_IO       (PF1_SRIOV_VF_BAR1_MEM_IO       ),
    .PF1_SRIOV_VF_BAR1_ENABLED      (PF1_SRIOV_VF_BAR1_ENABLED      ),
    .PF1_SRIOV_VF_BAR1_MASK         (PF1_SRIOV_VF_BAR1_MASK         ),
    .PF1_SRIOV_VF_BAR2_PREFETCH     (PF1_SRIOV_VF_BAR2_PREFETCH     ),
    .PF1_SRIOV_VF_BAR2_TYPE         (PF1_SRIOV_VF_BAR2_TYPE         ),
    .PF1_SRIOV_VF_BAR2_MEM_IO       (PF1_SRIOV_VF_BAR2_MEM_IO       ),
    .PF1_SRIOV_VF_BAR2_ENABLED      (PF1_SRIOV_VF_BAR2_ENABLED      ),
    .PF1_SRIOV_VF_BAR2_MASK         (PF1_SRIOV_VF_BAR2_MASK         ),
    .PF1_SRIOV_VF_BAR3_MEM_IO       (PF1_SRIOV_VF_BAR3_MEM_IO       ),
    .PF1_SRIOV_VF_BAR3_ENABLED      (PF1_SRIOV_VF_BAR3_ENABLED      ),
    .PF1_SRIOV_VF_BAR3_MASK         (PF1_SRIOV_VF_BAR3_MASK         ),
    .PF1_SRIOV_VF_BAR4_PREFETCH     (PF1_SRIOV_VF_BAR4_PREFETCH     ),
    .PF1_SRIOV_VF_BAR4_TYPE         (PF1_SRIOV_VF_BAR4_TYPE         ),
    .PF1_SRIOV_VF_BAR4_MEM_IO       (PF1_SRIOV_VF_BAR4_MEM_IO       ),
    .PF1_SRIOV_VF_BAR4_ENABLED      (PF1_SRIOV_VF_BAR4_ENABLED      ),
    .PF1_SRIOV_VF_BAR4_MASK         (PF1_SRIOV_VF_BAR4_MASK         ),
    .PF1_SRIOV_VF_BAR5_MEM_IO       (PF1_SRIOV_VF_BAR5_MEM_IO       ),
    .PF1_SRIOV_VF_BAR5_ENABLED      (PF1_SRIOV_VF_BAR5_ENABLED      ),
    .PF1_SRIOV_VF_BAR5_MASK         (PF1_SRIOV_VF_BAR5_MASK         ),
    .PF1_SRIOV_MSI_64_BIT_ADDR_CAP  (PF1_SRIOV_MSI_64_BIT_ADDR_CAP  ),
    .PF1_SRIOV_MSI_MULTIPLE_MSG_CAP (PF1_SRIOV_MSI_MULTIPLE_MSG_CAP ),
    .PF1_SRIOV_MSI_ENABLE           (PF1_SRIOV_MSI_ENABLE           ),
    .PF1_SRIOV_MSI_CAP_NEXT_OFFSET  (PF1_SRIOV_MSI_CAP_NEXT_OFFSET  )
)u_pcie_top(
    //clk and rst
    .power_up_rst_n             (power_up_rst_n         ),  //input
    .button_rst_n               (button_rst_n           ),  //input
    .perst_n                    (perst_n                ),  //input
    .user_rst_n                 (user_rst_n             ),  //output
    .user_clk                   (user_clk               ),  //input
    .ref_clk                    (ref_clk                ),  //output
    .pclk_div2                  (pclk_div2              ),  //output
    .pclk                       (pclk                   ),  //output
    .user_pll_lock              (user_pll_lock          ),
    .p_calib_done               (p_calib_done           ),  //output [1:0]
    //the input ref_clk pair
    .refclk_n                   (ref_clk_n              ),  //input
    .refclk_p                   (ref_clk_p              ),  //input
    //apb
    .apb_clk                    (p_clk                  ),  //input
    .apb_rst_n                  (sync_apb_rst_n         ),  //input
    .apb_sel                    (p_sel                  ),  //input
    .apb_strb                   (p_strb                 ),  //input [3:0]
    .apb_addr                   (p_addr                 ),  //input [31:0]
    .apb_wdata                  (p_wdata                ),  //input [31:0]
    .apb_ce                     (p_ce                   ),  //input
    .apb_we                     (p_we                   ),  //input
    .apb_rdy                    (p_rdy                  ),  //output
    .apb_rdata                  (p_rdata                ),  //output [31:0]
    //AXIS master interface : master0 for remote request
    .axis_master0_tvalid        (axis_master0_tvalid    ),  //output
    .axis_master0_tready        (axis_master0_tready    ),  //input
    .axis_master0_tdata         (axis_master0_tdata     ),  //output  [255:0]
    .axis_master0_tkeep         (axis_master0_tkeep     ),  //output  [7:0]
    .axis_master0_tlast         (axis_master0_tlast     ),  //output
    .axis_master0_tuser         (axis_master0_tuser     ),  //output  [12:0]                   //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                            //   function number                vf number , vf active }
    .user_rcvd_np_ready         (user_rcvd_np_ready     ),  //input
    .core_avl_np_cnt            (core_avl_np_cnt        ),  //output [5:0]
    .user_rcvd_p_ready          (user_rcvd_p_ready      ),  //input
    .core_avl_p_cnt             (core_avl_p_cnt         ),  //output [5:0]
    //AXIS master interface : master1 for remote completion
    .axis_master1_tvalid        (axis_master1_tvalid    ),  //output
    .axis_master1_tdata         (axis_master1_tdata     ),  //output  [255:0]
    .axis_master1_tkeep         (axis_master1_tkeep     ),  //output  [7:0]
    .axis_master1_tuser         (axis_master1_tuser     ),  //output  [33:0]                   //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                            //   function number                vf number , vf active}
    //**********************************************************************
    //axis slave 0 interface
    .axis_slave0_tready         (axis_slave0_tready     ),  //output
    .axis_slave0_tvalid         (axis_slave0_tvalid     ),  //input
    .axis_slave0_tdata          (axis_slave0_tdata      ),  //input   [255:0]
    .axis_slave0_tlast          (axis_slave0_tlast      ),  //input
    .axis_slave0_tuser          (axis_slave0_tuser      ),  //input   [5:0]                   //{bad eot , function number  , vf number , vf active}
    //axis slave 1 interface
    .axis_slave1_tready         (axis_slave1_tready     ),  //output
    .axis_slave1_tvalid         (axis_slave1_tvalid     ),  //input
    .axis_slave1_tdata          (axis_slave1_tdata      ),  //input   [255:0]
    .axis_slave1_tlast          (axis_slave1_tlast      ),  //input
    .axis_slave1_tuser          (axis_slave1_tuser      ),  //input   [5:0]
    //axis slave 2 interface
    .axis_slave2_tready         (axis_slave2_tready     ),  //output
    .axis_slave2_tvalid         (axis_slave2_tvalid     ),  //input
    .axis_slave2_tdata          (axis_slave2_tdata      ),  //input   [255:0]
    .axis_slave2_tlast          (axis_slave2_tlast      ),  //input
    .axis_slave2_tuser          (axis_slave2_tuser      ),  //input   [5:0]
    //completion timeout interface
    .radm_cpl_timeout           (radm_cpl_timeout           ),  //output  [1:0]
    .radm_timeout_func_num      (radm_timeout_func_num      ),  //output  [1:0]
    .radm_timeout_vfunc_num     (radm_timeout_vfunc_num     ),  //output  [5:0]
    .radm_timeout_vfunc_active  (radm_timeout_vfunc_active  ),  //output  [1:0]
    .radm_timeout_cpl_tc        (radm_timeout_cpl_tc        ),  //output  [5:0]
    .radm_timeout_cpl_attr      (radm_timeout_cpl_attr      ),  //output  [3:0]
    .radm_timeout_cpl_len       (radm_timeout_cpl_len       ),  //output  [21:0]
    .radm_timeout_cpl_tag       (radm_timeout_cpl_tag       ),  //output  [15:0]
    //message
    .msg_rcvd_type                  (msg_rcvd_type                  ),  //output  [4:0]
    .msg_rcvd_data                  (msg_rcvd_data                  ),  //output  [7:0]
    .msg_rcvd                       (msg_rcvd                       ),  //output
    .app_unlock_msg                 (app_unlock_msg                 ),  //input
    .apps_pm_xmt_turnoff            (apps_pm_xmt_turnoff            ),  //input
    .app_obff_idle_msg_req          (app_obff_idle_msg_req          ),  //input
    .app_obff_obff_msg_req          (app_obff_obff_msg_req          ),  //input
    .app_obff_cpu_active_msg_req    (app_obff_cpu_active_msg_req    ),  //input
    .app_obff_msg_grant             (app_obff_msg_grant             ),  //output
    .cfg_ltr_m_en                   (cfg_ltr_m_en                   ),  //output
    .app_ltr_msg_req                (app_ltr_msg_req                ),  //input
    .app_ltr_msg_grant              (app_ltr_msg_grant              ),  //output
    .app_ltr_msg_latency            (app_ltr_msg_latency            ),  //input   [31:0]
    .app_ltr_msg_func_num           (app_ltr_msg_func_num           ),  //input   [1-1:0]
    .cfg_disable_ltr_clr_msg        (cfg_disable_ltr_clr_msg        ),  //output
    //interrupt
    .ven_msi_req                (ven_msi_req            ),  //input
    .ven_msi_func_num           (ven_msi_func_num       ),  //input
    .ven_msi_vfunc_num          (ven_msi_vfunc_num      ),  //input [2:0]
    .ven_msi_vfunc_active       (ven_msi_vfunc_active   ),  //input
    .ven_msi_tc                 (ven_msi_tc             ),  //input [2:0]
    .ven_msi_vector             (ven_msi_vector         ),  //input [4:0]
    .ven_msi_grant              (ven_msi_grant          ),  //output
    .cfg_msi_mask_update        (cfg_msi_mask_update    ),  //output
    .cfg_msi_pending            (cfg_msi_pending        ),  //input [63:0]
    .cfg_vf_msi_pending         (cfg_vf_msi_pending     ),  //input [191:0]
    .msix_addr                  (msix_addr              ),  //input [63:0]
    .msix_data                  (msix_data              ),  //input [31:0]
    .cfg_msix_func_mask         (cfg_msix_func_mask     ),  //output [1:0]
    .cfg_vf_msix_func_mask      (cfg_vf_msix_func_mask  ),  //output [5:0]
    .cfg_vf_multi_msi_en        (cfg_vf_multi_msi_en    ),  //output [17:0]
    .cfg_vf_msix_en             (cfg_vf_msix_en         ),  //output [5:0]
    .cfg_vf_msi_en              (cfg_vf_msi_en          ),  //output [5:0]
    .cfg_multi_msi_en           (cfg_multi_msi_en       ),  //output [5:0]
    .cfg_msix_en                (cfg_msix_en            ),  //output [1:0]
    .cfg_msi_en                 (cfg_msi_en             ),  //output [1:0]
    .sys_int                    (sys_int                ),  //input [1:0]
    .int_grt                    (int_grt                ),  //output
    //Link status interface
    .link_req_rst_not           (link_req_rst_not       ),  //output
    .pm_xtlh_block_tlp          (pm_xtlh_block_tlp      ),  //output
    .training_rst_n             (training_rst_n         ),  //output
    .pm_dstate                  (pm_dstate              ),  //output [(3*2)-1:0]
    .pm_vf_dstate               (pm_vf_dstate           ),  //output [(3*6)-1:0]
    .pm_vf_pme_en               (pm_vf_pme_en           ),  //output [6-1:0]
    .pm_vf_status               (pm_vf_status           ),  //output [6-1:0]
    .aux_pm_en                  (aux_pm_en              ),  //output [2-1:0]
    .pm_pme_en                  (pm_pme_en              ),  //output [2-1:0]
    .pm_status                  (pm_status              ),  //output [2-1:0]
    .wake                       (wake                   ),  //output
    .pm_master_state            (pm_master_state        ),  //output [5-1:0]
    .pm_slave_state             (pm_slave_state         ),  //output  [5-1:0]
    .rdlh_link_up               (rdlh_link_up           ),  //output
    .smlh_ltssm_state           (smlh_ltssm_state       ),  //output  [5:0]
    .smlh_link_up               (smlh_link_up           ),  //output
    .smlh_req_rst_not           (smlh_req_rst_not       ),  //output
    //Configuration reg output interface
    .cfg_vf_bme                 (cfg_vf_bme             ),  //output [6-1:0]
    .cfg_vf_en                  (cfg_vf_en              ),  //output [2-1:0]
    .cfg_num_vf                 (cfg_num_vf             ),  //output [16*2-1:0]
    .cfg_start_vfi              (cfg_start_vfi          ),  //output [6-1:0]
    .cfg_tph_req_en             (cfg_tph_req_en         ),  //output [(1*8)-1:0]
    .cfg_pf_tph_st_mode         (cfg_pf_tph_st_mode     ),  //output [(3*8)-1:0]
    .cfg_vf_tph_st_mode         (cfg_vf_tph_st_mode     ),  //output  [(3*6)-1:0]
    .cfg_vf_tph_req_en          (cfg_vf_tph_req_en      ),  //output  [(1*6)-1:0]
    .dpa_substate_update        (dpa_substate_update    ),  //output [2-1:0]
    .cfg_atomic_req_en          (cfg_atomic_req_en      ),  //output [2-1:0]
    .cfg_atomic_egress_block    (cfg_atomic_egress_block),  //output [2-1:0]
    .cfg_ari_fwd_en             (cfg_ari_fwd_en         ),  //output  [2-1:0]
    .cfg_send_cor_err           (cfg_send_cor_err       ),  //output  [2-1:0]
    .cfg_send_nf_err            (cfg_send_nf_err        ),  //output  [2-1:0]
    .cfg_send_f_err             (cfg_send_f_err         ),  //output  [2-1:0]
    .cfg_int_disable            (cfg_int_disable        ),  //output  [2-1:0]
    .cfg_no_snoop_en            (cfg_no_snoop_en        ),  //output  [2-1:0]
    .cfg_relax_order_en         (cfg_relax_order_en     ),  //output  [2-1:0]
    .cfg_link_auto_bw_int       (cfg_link_auto_bw_int   ),  //output
    .cfg_link_auto_bw_msi       (cfg_link_auto_bw_msi   ),  //output
    .cfg_bw_mgt_int             (cfg_bw_mgt_int         ),  //output
    .cfg_bw_mgt_msi             (cfg_bw_mgt_msi         ),  //output
    .cfg_link_eq_req_int        (cfg_link_eq_req_int    ),  //output
    .rbar_ctrl_update           (rbar_ctrl_update       ),  //output  [2-1:0]
    .cfg_ido_req_en             (cfg_ido_req_en         ),  //output  [2-1:0]
    .cfg_ido_cpl_en             (cfg_ido_cpl_en         ),  //output  [2-1:0]
    .cfg_sys_err_rc             (cfg_sys_err_rc         ),  //output  [2-1:0]
    .cfg_aer_rc_err_int         (cfg_aer_rc_err_int     ),  //output  [2-1:0]
    .cfg_aer_rc_err_msi         (cfg_aer_rc_err_msi     ),  //output  [2-1:0]
    .cfg_pme_int                (cfg_pme_int            ),  //output  [2-1:0]
    .cfg_pme_msi                (cfg_pme_msi            ),  //output  [2-1:0]
    .cfg_crs_sw_vis_en          (cfg_crs_sw_vis_en      ),  //output  [2-1:0]
    .radm_q_not_empty           (radm_q_not_empty       ),  //output  [1-1:0]
    .radm_qoverflow             (radm_qoverflow         ),  //output  [1-1:0]
    .cfg_bus_master_en          (cfg_bus_master_en      ),  //output  [2-1:0]
    .cfg_2nd_reset              (cfg_2nd_reset          ),  //output
    .cfg_max_payload_size       (cfg_max_payload_size   ),  //output  [6-1:0]
    .cfg_rcb                    (cfg_rcb                ),  //output  [2-1:0]
    .cfg_tc_enable              (cfg_tc_enable          ),  //output  [8-1:0]
    .cfg_mem_space_en           (cfg_mem_space_en       ),  //output  [2-1:0]
    .cfg_max_rd_req_size        (cfg_max_rd_req_size    ),  //output  [6-1:0]
    .cfg_ext_tag_en             (cfg_ext_tag_en         ),  //output  [2-1:0]
    .cfg_reg_serren             (cfg_reg_serren         ),  //output  [2-1:0]
    .cfg_cor_err_rpt_en         (cfg_cor_err_rpt_en     ),  //output  [2-1:0]
    .cfg_nf_err_rpt_en          (cfg_nf_err_rpt_en      ),  //output  [2-1:0]
    .cfg_f_err_rpt_en           (cfg_f_err_rpt_en       ),  //output  [2-1:0]
    .cfg_pbus_num               (cfg_pbus_num           ),  //output  [8-1:0]
    .cfg_pbus_dev_num           (cfg_pbus_dev_num       ),  //output  [5-1:0]
    .cfg_obff_en                (cfg_obff_en            ),  //output  [1:0]
    // START_IO: Power Budgeting Signal Descriptions.
    .cfg_pwr_budget_valid           (cfg_pwr_budget_valid           ), //input
    .cfg_pwr_budget_sel             (cfg_pwr_budget_sel             ), //output  [2-1:0]
    .cfg_pwr_budget_func_num        (cfg_pwr_budget_func_num        ), //input   [1-1:0]
    .cfg_pwr_budget_data_sel_reg    (cfg_pwr_budget_data_sel_reg    ), //output  [7:0]
    .cfg_pwr_budget_data_reg        (cfg_pwr_budget_data_reg        ), //input   [31:0]
    // END_IO: Power Budgeting Signal Descriptions.
    //App cfg interface
    .rx_lane_flip_en            (rx_lane_flip_en        ),  //input
    .tx_lane_flip_en            (tx_lane_flip_en        ),  //input
    .app_xfer_pending           (app_xfer_pending       ),  //PM signals
    .app_vf_req_retry_en        (app_vf_req_retry_en    ),  //input
    .app_req_retry_en           (app_req_retry_en       ),  //input
    .app_req_exit_l1            (app_req_exit_l1        ),  //PM signals
    .app_req_entr_l1            (app_req_entr_l1        ),  //PM signals
    .app_ready_entr_l23         (app_ready_entr_l23     ),  //PM signals
    .app_pf_req_retry_en        (app_pf_req_retry_en    ),  //input [2-1:0]
    .app_clk_pm_en              (1'b1                   ),  //tie 1 when IP
    .app_init_rst               (app_init_rst           ),  //hot reset request signal
    .apps_pm_xmt_pme            (apps_pm_xmt_pme        ),  //input [8-1:0]
    .apps_pm_vf_xmt_pme         (apps_pm_vf_xmt_pme     ),  //input [6-1:0]
    //Error handling
    .app_hdr_valid              (app_hdr_valid          ),  //input
    .app_hdr_log                (app_hdr_log            ),  //input [127:0]
    .app_err_bus                (app_err_bus            ),  //input [13-1:0]
    .app_err_advisory           (app_err_advisory       ),  //input
    .app_err_func_num           (app_err_func_num       ),  //input [1-1:0]
    .app_err_vfunc_num          (app_err_vfunc_num      ),  //input [4-2:0]
    .app_err_vfunc_active       (app_err_vfunc_active   ),  //input
    //debug interface
    .dyn_debug_info_sel         (dyn_debug_info_sel     ),  //input   [6-1 :0]
    .app_ras_des_sd_hold_ltssm  (app_ras_des_sd_hold_ltssm),//input
    .diag_ctrl_bus              (diag_ctrl_bus          ),  //input   [3-1 :0]
    .debug_info_mux             (debug_info_mux         ),  //output  [142:0]
    //Flow control Interface
    .xadm_ph_cdts               (xadm_ph_cdts           ),  //output  [1*8-1:0]
    .xadm_pd_cdts               (xadm_pd_cdts           ),  //output  [1*12-1:0]
    .xadm_nph_cdts              (xadm_nph_cdts          ),  //output  [1*8-1:0]
    .xadm_npd_cdts              (xadm_npd_cdts          ),  //output  [1*12-1:0]
    .xadm_cplh_cdts             (xadm_cplh_cdts         ),  //output  [1*8-1:0]
    .xadm_cpld_cdts             (xadm_cpld_cdts         ),  //output  [1*12-1:0]
    //vf_num
    .app_pf0_vf_num             (app_pf0_vf_num         ),  //input   [2:0]
    .app_pf1_vf_num             (app_pf1_vf_num         ),  //input   [2:0]
    // START_IO:FLR Signal Descriptions
    .cfg_flr_pf_active          (cfg_flr_pf_active      ),  //output  [2-1:0]
    .app_flr_pf_done            (app_flr_pf_done        ),  //input   [2-1:0]
    .cfg_flr_vf_active          (cfg_flr_vf_active      ),  //output  [6-1:0]
    .app_flr_vf_done            (app_flr_vf_done        ),  //input   [6-1:0]
    // END_IO:FLR Signal Descriptions.
    // PHY inside device_top (or inside core)           export serial lines, import refclk
    .rxp                        (rxp                    ),  //input  [HSST_LANE_NUM-1:0]
    .rxn                        (rxn                    ),  //input  [HSST_LANE_NUM-1:0]
    .txp                        (txp                    ),  //output [HSST_LANE_NUM-1:0]
    .txn                        (txn                    ),  //output [HSST_LANE_NUM-1:0]
    .prbs_en                    (prbs_en                ),
    .force_loss_signal          (force_loss_signal      ),
    .force_cdr_align            (force_cdr_align        ),
    .force_word_align           (force_word_align       ),
    .pcs_nearend_loop           (pcs_nearend_loop       ),  //input  [HSST_LANE_NUM-1:0]
    .pma_nearend_ploop          (pma_nearend_ploop      ),  //input  [HSST_LANE_NUM-1:0]
    .pma_nearend_sloop          (pma_nearend_sloop      ),  //input  [HSST_LANE_NUM-1:0]
    //iscan
    .rx_eye_rst                 (rx_eye_rst             ),  //input  [HSST_LANE_NUM-1:0]
    .rx_eye_en                  (rx_eye_en              ),  //input  [HSST_LANE_NUM-1:0]
    .rx_eye_tap                 (rx_eye_tap             ),  //input  [HSST_LANE_NUM*8-1:0]
    .rx_pic_eye                 (rx_pic_eye             ),  //input  [HSST_LANE_NUM*8-1:0]
    .em_rd_trigger              (em_rd_trigger          ),  //input  [HSST_LANE_NUM-1:0]
    .em_mode_ctrl               (em_mode_ctrl           ),  //input  [HSST_LANE_NUM*2-1:0]
    .txlane_done                (                       ),  //output [HSST_LANE_NUM-1:0]
    .rxlane_done                (                       ),  //output [HSST_LANE_NUM-1:0]
    .pll_done                   (pll_done               ),  //output
    .rx_sigdet_sta              (rx_sigdet_sta          ),  //output [HSST_LANE_NUM-1:0]
    .lx_cdr_align               (lx_cdr_align           )   //output [HSST_LANE_NUM-1:0]
);

endmodule
