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

module ips2t_pcie_top_v1_8 #(
parameter                   PF1_ENABLE          = "TRUE"        ,   // FALSE, TRUE
parameter                   FLT_SHORT_TLP       = "TRUE"        ,   // FALSE, TRUE
parameter        integer    APP_DEV_NUM         = 0             ,   // set device_number
parameter        integer    APP_BUS_NUM         = 0             ,   // set bus_number
parameter        integer    DEBUG_INFO_SEL      = 0             ,   // set debug_info_mux, 0-33
parameter                   DYN_DEBUG_SEL_EN    = "TRUE"        ,   // FALSE, TRUE
parameter                   VF_ER_REPORT_EN     = "TRUE"        ,   // FALSE, TRUE
parameter                   ATOMIC_DISABLE      = "FALSE"       ,   // FALSE, TRUE
parameter                   VC_DISABLE          = "FALSE"       ,   // FALSE, TRUE
parameter                   SRIOV_DISABLE       = "TRUE"        ,   // FALSE, TRUE
parameter        integer    BAR_RESIZABLE       = 0             ,   // enable pf0 & pf1 bars resizable, default: pf0 - bar4,bar2,bar0; pf1 - bar4,bar2,bar0
parameter        integer    NUM_OF_RBARS        = 0             ,   // set pf0 & pf1 resizable bars number,  default: pf0 - 3; pf1 - 3
parameter        integer    MSI_PVM_DISABLE     = 0             ,   // 0: all func enable, 1:pf0 disable, 2:pf1 disable, 3:pf0&pf1 disable, 4:vf0 disable ......255:all func disable
parameter        integer    BAR_MASK_WRITABLE   = 12'hfff       ,   // 0~63 -- pf0, 64~128 --pf1; 0: no writable bar, 1:pf0 bar0 writable, 2:pf0 bar1 writable, 3:pf0 bar3 writable, ... 63:pf0 bar0-5 writable
parameter        integer    HSST_LANE_NUM       = 8             ,   //1:X1 2:X2 4:X4 8:X8
parameter                   HPLL_EN         = "TRUE"            ,//TRUE, FALSE; for HPLL enable
//init
parameter                   DEVICE_TYPE                       = 4'b000        ,   // EP-> 4'b0000; RC->4'b0100;
parameter                   MULTI_EN                          = 1'b0          ,
parameter                   PCIE_CAP_RCB                      = 1'b1          ,
parameter                   PCIE_CAP_CRS                      = 1'b0          ,
parameter                   PCIE_CAP_ATOMIC_EN                = 1'b0          ,
parameter                   SCRAMBLE_DISABLE                  = 1'b0          ,
parameter                   AUTO_LANE_FLIP_CTRL_EN            = 1'b1          ,
parameter                   PCIE_CAP_HW_AUTO_SPEED_DISABLE    = 1'b0          ,
parameter                   DO_DESKEW_FOR_SRIS                = 1'b1          ,
parameter                   TPH_REQ_NEXT_PTR                  = 12'h0         ,
parameter                   UPCONFIGURE_SUPPORT               = 1'b1          ,
parameter                   TARGET_LINK_SPEED                 = 4'h1          ,
parameter                   LINK_CAPABLE                      = 6'b00_0111    ,   //0x1:x1 0x3:x2 0x7:x4 0xf:x8
parameter                   NUM_OF_LANES                      = 5'b0_0001     ,   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
parameter                   MAX_LINK_WIDTH                    = 6'b00_0100    ,   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
parameter                   MAX_LINK_SPEED                    = 4'b0010       ,   //0x1:gen1 0x2:gen2 0x3 gen3
parameter                   EXT_TAG_EN                        = 1'b1          ,
parameter                   EXT_TAG_SUPP                      = 1'b1          ,
parameter                   INT_DISABLE                       = 1'b0          ,
parameter                   PF0_DEVICE_ID                     = 16'h0755      ,
parameter                   PF0_SUBSYS_DEV_ID                 = 16'h0000      ,
parameter                   PF0_VENDOR_ID                     = 16'h0755      ,
parameter                   PF0_SUBSYS_VENDOR_ID              = 16'h0000      ,
parameter                   PF0_BASE_CLASS_CODE               = 8'h05         ,
parameter                   PF0_SUBCLASS_CODE                 = 8'h80         ,
parameter                   PF0_PROGRAM_INTERFACE             = 8'h00         ,
parameter                   PF0_REVISION_ID                   = 8'h00         ,
parameter                   PF0_MAX_PAYLOAD_SIZE              = 3'b011        ,  // 1024-bytes
parameter                   PF0_INT_PIN                       = 8'h0          ,
parameter                   PF0_MSI_64_BIT_ADDR_CAP           = 1'b1          ,
parameter                   PF0_MSI_MULTIPLE_MSG_CAP          = 3'b101        ,
parameter                   PF0_MSI_ENABLE                    = 1'b0          ,
parameter                   PF0_MSI_CAP_NEXT_OFFSET           = 8'h70         ,
parameter                   PF0_CAP_POINTER                   = 8'h50         ,
parameter                   PF0_PCIE_CAP_NEXT_PTR             = 8'hB0         ,
parameter                   PF0_BAR0_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR0_TYPE                     = 2'b0          ,
parameter                   PF0_BAR0_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR0_ENABLED                  = 1'b1          ,
parameter                   PF0_BAR0_MASK                     = 31'h0000_0fff ,
parameter                   PF0_BAR1_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR1_TYPE                     = 2'b0          ,
parameter                   PF0_BAR1_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR1_ENABLED                  = 1'b1          ,
parameter                   PF0_BAR1_MASK                     = 31'h0000_07ff ,
parameter                   PF0_BAR2_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR2_TYPE                     = 2'b10         ,
parameter                   PF0_BAR2_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR2_ENABLED                  = 1'b1          ,
parameter                   PF0_BAR2_MASK                     = 31'h0000_0fff ,
parameter                   PF0_BAR3_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR3_TYPE                     = 2'b0          ,
parameter                   PF0_BAR3_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR3_ENABLED                  = 1'b0          ,
parameter                   PF0_BAR3_MASK                     = 31'd0         ,
parameter                   PF0_BAR4_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR4_TYPE                     = 2'b0          ,
parameter                   PF0_BAR4_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR4_ENABLED                  = 1'b0          ,
parameter                   PF0_BAR4_MASK                     = 31'd0         ,
parameter                   PF0_BAR5_PREFETCH                 = 1'b0          ,
parameter                   PF0_BAR5_TYPE                     = 2'b0          ,
parameter                   PF0_BAR5_MEM_IO                   = 1'b0          ,
parameter                   PF0_BAR5_ENABLED                  = 1'b0          ,
parameter                   PF0_BAR5_MASK                     = 31'd0         ,
parameter                   PF0_ROM_BAR_ENABLE                = 1'b0          ,
parameter                   PF0_ROM_BAR_ENABLED               = 1'd0          ,
parameter                   PF0_ROM_MASK                      = 31'd0         ,
parameter                   PF0_ECRC_CHECK_EN                 = 1'b1          ,
parameter                   PF0_ECRC_GEN_EN                   = 1'b1          ,
parameter                   PF0_PCI_MSIX_ENABLE               = 1'b0          ,
parameter                   PF0_PCI_FUNCTION_MASK             = 1'b0          ,
parameter                   PF0_PCI_MSIX_TABLE_SIZE           = 11'h0         ,
parameter                   PF0_PCI_MSIX_CAP_NEXT_OFFSET      = 8'h0          ,
parameter                   PF0_PCI_MSIX_TABLE_OFFSET         = 29'h0         ,
parameter                   PF0_PCI_MSIX_BIR                  = 3'h0          ,
parameter                   PF0_PCI_MSIX_PBA_OFFSET           = 29'h0         ,
parameter                   PF0_PCI_MSIX_PBA_BIR              = 3'h0          ,
parameter                   PF0_AER_CAP_NEXT_OFFSET           = 12'h0         ,
parameter                   PF0_RESBAR_BAR0_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF0_RESBAR_BAR0_INIT_SIZE         = 5'h13         ,
parameter                   PF0_RESBAR_BAR1_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF0_RESBAR_BAR1_INIT_SIZE         = 5'h13         ,
parameter                   PF0_RESBAR_BAR2_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF0_RESBAR_BAR2_INIT_SIZE         = 5'hb          ,
parameter                   PF1_DEVICE_ID                     = 16'h0755      ,
parameter                   PF1_SUBSYS_DEV_ID                 = 16'h0000      ,
parameter                   PF1_VENDOR_ID                     = 16'h0755      ,
parameter                   PF1_SUBSYS_VENDOR_ID              = 16'h0000      ,
parameter                   PF1_BASE_CLASS_CODE               = 8'h05         ,
parameter                   PF1_SUBCLASS_CODE                 = 8'h80         ,
parameter                   PF1_PROGRAM_INTERFACE             = 8'h00         ,
parameter                   PF1_REVISION_ID                   = 8'h00         ,
parameter                   PF1_MAX_PAYLOAD_SIZE              = 3'b011        ,  // 1024-bytes
parameter                   PF1_INT_PIN                       = 8'h0          ,
parameter                   PF1_MSI_64_BIT_ADDR_CAP           = 1'b1          ,
parameter                   PF1_MSI_MULTIPLE_MSG_CAP          = 3'b101        ,
parameter                   PF1_MSI_ENABLE                    = 1'b0          ,
parameter                   PF1_MSI_CAP_NEXT_OFFSET           = 8'h70         ,
parameter                   PF1_CAP_POINTER                   = 8'h50         ,
parameter                   PF1_PCIE_CAP_NEXT_PTR             = 8'hB0         ,
parameter                   PF1_BAR0_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR0_TYPE                     = 2'b0          ,
parameter                   PF1_BAR0_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR0_ENABLED                  = 1'b1          ,
parameter                   PF1_BAR0_MASK                     = 31'h0000_0fff ,
parameter                   PF1_BAR1_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR1_TYPE                     = 2'b0          ,
parameter                   PF1_BAR1_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR1_ENABLED                  = 1'b1          ,
parameter                   PF1_BAR1_MASK                     = 31'h0000_07ff ,
parameter                   PF1_BAR2_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR2_TYPE                     = 2'b10         ,
parameter                   PF1_BAR2_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR2_ENABLED                  = 1'b1          ,
parameter                   PF1_BAR2_MASK                     = 31'h0000_0fff ,
parameter                   PF1_BAR3_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR3_TYPE                     = 2'b0          ,
parameter                   PF1_BAR3_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR3_ENABLED                  = 1'b0          ,
parameter                   PF1_BAR3_MASK                     = 31'd0         ,
parameter                   PF1_BAR4_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR4_TYPE                     = 2'b0          ,
parameter                   PF1_BAR4_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR4_ENABLED                  = 1'b0          ,
parameter                   PF1_BAR4_MASK                     = 31'd0         ,
parameter                   PF1_BAR5_PREFETCH                 = 1'b0          ,
parameter                   PF1_BAR5_TYPE                     = 2'b0          ,
parameter                   PF1_BAR5_MEM_IO                   = 1'b0          ,
parameter                   PF1_BAR5_ENABLED                  = 1'b0          ,
parameter                   PF1_BAR5_MASK                     = 31'd0         ,
parameter                   PF1_ROM_BAR_ENABLE                = 1'b0          ,
parameter                   PF1_ROM_BAR_ENABLED               = 1'd0          ,
parameter                   PF1_ROM_MASK                      = 31'd0         ,
parameter                   PF1_ECRC_CHECK_EN                 = 1'b1          ,
parameter                   PF1_ECRC_GEN_EN                   = 1'b1          ,
parameter                   PF1_PCI_MSIX_ENABLE               = 1'b0          ,
parameter                   PF1_PCI_FUNCTION_MASK             = 1'b0          ,
parameter                   PF1_PCI_MSIX_TABLE_SIZE           = 11'h0         ,
parameter                   PF1_PCI_MSIX_CAP_NEXT_OFFSET      = 8'h0          ,
parameter                   PF1_PCI_MSIX_TABLE_OFFSET         = 29'h0         ,
parameter                   PF1_PCI_MSIX_BIR                  = 3'h0          ,
parameter                   PF1_PCI_MSIX_PBA_OFFSET           = 29'h0         ,
parameter                   PF1_PCI_MSIX_PBA_BIR              = 3'h0          ,
parameter                   PF1_AER_CAP_NEXT_OFFSET           = 12'h0         ,
parameter                   PF1_RESBAR_BAR0_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF1_RESBAR_BAR0_INIT_SIZE         = 5'h13         ,
parameter                   PF1_RESBAR_BAR1_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF1_RESBAR_BAR1_INIT_SIZE         = 5'h13         ,
parameter                   PF1_RESBAR_BAR2_MAX_SUPP_SIZE     = 20'hf_ffff    ,
parameter                   PF1_RESBAR_BAR2_INIT_SIZE         = 5'hb          ,
//SRIOV CAP
parameter                   PF0_SRIOV_EXT_CAP_NXT_OFFSET      = 12'h0         ,
parameter                   PF0_SRIOV_EXT_CAP_VER             = 4'h0          ,
parameter                   PF0_SRIOV_INITIAL_VFS             = 16'h3         ,
parameter                   PF0_SRIOV_VF_OFFSET               = 16'h0         ,
parameter                   PF0_SRIOV_VF_DEVICE_ID            = 16'h0755      ,
parameter                   PF0_SRIOV_VF_BAR0_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR0_TYPE            = 2'b0          ,
parameter                   PF0_SRIOV_VF_BAR0_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR0_ENABLED         = 1'b1          ,
parameter                   PF0_SRIOV_VF_BAR0_MASK            = 31'h0000_0fff ,
parameter                   PF0_SRIOV_VF_BAR1_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR1_TYPE            = 2'b0          ,
parameter                   PF0_SRIOV_VF_BAR1_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR1_ENABLED         = 1'b1          ,
parameter                   PF0_SRIOV_VF_BAR1_MASK            = 31'h0000_07ff ,
parameter                   PF0_SRIOV_VF_BAR2_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR2_TYPE            = 2'b10         ,
parameter                   PF0_SRIOV_VF_BAR2_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR2_ENABLED         = 1'b1          ,
parameter                   PF0_SRIOV_VF_BAR2_MASK            = 31'h0000_0fff ,
parameter                   PF0_SRIOV_VF_BAR3_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR3_TYPE            = 2'b0          ,
parameter                   PF0_SRIOV_VF_BAR3_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR3_ENABLED         = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR3_MASK            = 31'd0         ,
parameter                   PF0_SRIOV_VF_BAR4_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR4_TYPE            = 2'b0          ,
parameter                   PF0_SRIOV_VF_BAR4_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR4_ENABLED         = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR4_MASK            = 31'd0         ,
parameter                   PF0_SRIOV_VF_BAR5_PREFETCH        = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR5_TYPE            = 2'b0          ,
parameter                   PF0_SRIOV_VF_BAR5_MEM_IO          = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR5_ENABLED         = 1'b0          ,
parameter                   PF0_SRIOV_VF_BAR5_MASK            = 31'd0         ,
parameter                   PF0_SRIOV_MSI_64_BIT_ADDR_CAP     = 1'b1          ,
parameter                   PF0_SRIOV_MSI_MULTIPLE_MSG_CAP    = 3'b101        ,
parameter                   PF0_SRIOV_MSI_ENABLE              = 1'b0          ,
parameter                   PF0_SRIOV_MSI_CAP_NEXT_OFFSET     = 8'h70         ,
parameter                   PF1_SRIOV_EXT_CAP_NXT_OFFSET      = 12'h0         ,
parameter                   PF1_SRIOV_EXT_CAP_VER             = 4'h0          ,
parameter                   PF1_SRIOV_INITIAL_VFS             = 16'h3         ,
parameter                   PF1_SRIOV_VF_OFFSET               = 16'h0         ,
parameter                   PF1_SRIOV_VF_DEVICE_ID            = 16'h0755      ,
parameter                   PF1_SRIOV_VF_BAR0_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR0_TYPE            = 2'b0          ,
parameter                   PF1_SRIOV_VF_BAR0_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR0_ENABLED         = 1'b1          ,
parameter                   PF1_SRIOV_VF_BAR0_MASK            = 31'h0000_0fff ,
parameter                   PF1_SRIOV_VF_BAR1_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR1_TYPE            = 2'b0          ,
parameter                   PF1_SRIOV_VF_BAR1_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR1_ENABLED         = 1'b1          ,
parameter                   PF1_SRIOV_VF_BAR1_MASK            = 31'h0000_07ff ,
parameter                   PF1_SRIOV_VF_BAR2_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR2_TYPE            = 2'b10         ,
parameter                   PF1_SRIOV_VF_BAR2_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR2_ENABLED         = 1'b1          ,
parameter                   PF1_SRIOV_VF_BAR2_MASK            = 31'h0000_0fff ,
parameter                   PF1_SRIOV_VF_BAR3_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR3_TYPE            = 2'b0          ,
parameter                   PF1_SRIOV_VF_BAR3_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR3_ENABLED         = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR3_MASK            = 31'd0         ,
parameter                   PF1_SRIOV_VF_BAR4_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR4_TYPE            = 2'b0          ,
parameter                   PF1_SRIOV_VF_BAR4_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR4_ENABLED         = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR4_MASK            = 31'd0         ,
parameter                   PF1_SRIOV_VF_BAR5_PREFETCH        = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR5_TYPE            = 2'b0          ,
parameter                   PF1_SRIOV_VF_BAR5_MEM_IO          = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR5_ENABLED         = 1'b0          ,
parameter                   PF1_SRIOV_VF_BAR5_MASK            = 31'd0         ,
parameter                   PF1_SRIOV_MSI_64_BIT_ADDR_CAP     = 1'b1          ,
parameter                   PF1_SRIOV_MSI_MULTIPLE_MSG_CAP    = 3'b101        ,
parameter                   PF1_SRIOV_MSI_ENABLE              = 1'b0          ,
parameter                   PF1_SRIOV_MSI_CAP_NEXT_OFFSET     = 8'h70
)(
input    [5:0]                  dyn_debug_info_sel,
input                           power_up_rst_n    ,
input                           button_rst_n      ,
input                           perst_n           ,
input                           user_clk          ,
output                          ref_clk           ,
output wire                     pclk_div2         ,
output wire                     pclk              ,
input                           user_pll_lock     ,
output  [1:0]                   p_calib_done      ,

input                           app_clk_pm_en       ,
input                           app_init_rst        ,
input                           app_req_entr_l1     ,
input                           app_ready_entr_l23  ,
input                           app_req_exit_l1     ,
input                           app_xfer_pending    ,
input                           app_req_retry_en    ,
input   [2-1:0]                 app_pf_req_retry_en ,
input   [6-1:0]                 app_vf_req_retry_en ,
input   [2:0]                   app_pf0_vf_num      ,
input   [2:0]                   app_pf1_vf_num      ,

//apb interface
input                           apb_clk             ,
input                           apb_rst_n           ,
input                           apb_sel             ,
input           [ 3:0]          apb_strb            ,
input           [31:0]          apb_addr            ,
input           [31:0]          apb_wdata           ,
input                           apb_ce              ,
input                           apb_we              ,
output  wire                    apb_rdy             ,
output  wire    [31:0]          apb_rdata           ,

output [2-1:0]                  cfg_ido_req_en      ,
output [2-1:0]                  cfg_ido_cpl_en      ,

input                           ven_msi_req         ,
input   [1-1:0]                 ven_msi_func_num    ,
input   [4-2:0]                 ven_msi_vfunc_num   ,
input                           ven_msi_vfunc_active,
input   [2:0]                   ven_msi_tc          ,
input   [4:0]                   ven_msi_vector      ,
output                          ven_msi_grant       ,
output  [2-1:0]                 cfg_msi_en          ,
output  [6-1:0]                 cfg_vf_msi_en       ,
output                          cfg_msi_mask_update ,
input   [(32*2)-1:0]            cfg_msi_pending     ,
input   [(32*6)-1:0]            cfg_vf_msi_pending  ,
output  [(3*2)-1:0]             cfg_multi_msi_en    ,
output  [(3*6)-1:0]             cfg_vf_multi_msi_en ,

input   [63:0]                  msix_addr           ,
input   [31:0]                  msix_data           ,
output  [2-1:0]                 cfg_msix_en         ,
output  [2-1:0]                 cfg_msix_func_mask  ,
output  [6-1:0]                 cfg_vf_msix_en      ,
output  [6-1:0]                 cfg_vf_msix_func_mask,
output  [6-1:0]                 cfg_vf_bme          ,
output  [2-1:0]                 cfg_vf_en           ,
output  [16*2-1:0]              cfg_num_vf          ,
output  [2*3-1:0]               cfg_start_vfi       ,


output  [4:0]                   msg_rcvd_type       ,
output  [7:0]                   msg_rcvd_data       ,
output                          msg_rcvd            ,
// START_IO:VPD Signal Descriptions.
// END_IO:VPD Signal Descriptions.

// START_IO:FLR Signal Descriptions.
output  [2-1:0]                 cfg_flr_pf_active   ,
input   [2-1:0]                 app_flr_pf_done     ,
output  [6-1:0]                 cfg_flr_vf_active   ,
input   [6-1:0]                 app_flr_vf_done     ,
// END_IO:FLR Signal Descriptions.

output [(1*2)-1:0]              cfg_tph_req_en      ,
output [(3*2)-1:0]              cfg_pf_tph_st_mode  ,


output [2-1:0]                  dpa_substate_update ,


output  [(3*6)-1:0]             cfg_vf_tph_st_mode  ,
output  [(1*6)-1:0]             cfg_vf_tph_req_en   ,

output [2-1:0]                  cfg_atomic_req_en   ,
output [2-1:0]                  cfg_atomic_egress_block,

output                          cfg_ltr_m_en,
input                           app_ltr_msg_req,
output                          app_ltr_msg_grant,
input   [31:0]                  app_ltr_msg_latency,
input   [1-1:0]                 app_ltr_msg_func_num,
output                          cfg_disable_ltr_clr_msg,



// START_IO: Power Budgeting Signal Descriptions.
input                           cfg_pwr_budget_valid,
input   [31:0]                  cfg_pwr_budget_data_reg,
input   [1-1:0]                 cfg_pwr_budget_func_num,
output  [7:0]                   cfg_pwr_budget_data_sel_reg,
output  [2-1:0]                 cfg_pwr_budget_sel,
// END_IO: Power Budgeting Signal Descriptions.
output  [2-1:0]                 cfg_ari_fwd_en,

// START_IO:VMI Signal Descriptions.

// END_IO:VMI Signal Descriptions.

// START_IO:SII Signal Descriptions.
input                           rx_lane_flip_en,
input                           tx_lane_flip_en,

input   [2-1:0]                 sys_int,
input   [2-1:0]                 apps_pm_xmt_pme,
input   [6-1:0]                 apps_pm_vf_xmt_pme,


input                           app_unlock_msg,
input                           apps_pm_xmt_turnoff,
output  [2-1:0]                 cfg_sys_err_rc,
output  [2-1:0]                 cfg_aer_rc_err_int,
output  [2-1:0]                 cfg_aer_rc_err_msi,
output  [2-1:0]                 cfg_pme_int,
output  [2-1:0]                 cfg_pme_msi,
output  [2-1:0]                 cfg_crs_sw_vis_en,


output  [1-1:0]                 radm_q_not_empty,
output  [1-1:0]                 radm_qoverflow,

output  [1*8-1:0]               xadm_ph_cdts,
output  [1*12-1:0]              xadm_pd_cdts,
output  [1*8-1:0]               xadm_nph_cdts,
output  [1*12-1:0]              xadm_npd_cdts,
output  [1*8-1:0]               xadm_cplh_cdts,
output  [1*12-1:0]              xadm_cpld_cdts,


output  [2-1:0]                 cfg_bus_master_en,
output                          cfg_2nd_reset,

output  [(3*2)-1:0]             cfg_max_payload_size,
output  [2-1:0]                 cfg_rcb,
output  [7:0]                   cfg_tc_enable,

output  [2-1:0]                 cfg_mem_space_en,
output  [(3*2)-1:0]             cfg_max_rd_req_size,

output  [2-1:0]                 cfg_ext_tag_en,

output                          rdlh_link_up,
output  [5:0]                   smlh_ltssm_state,


output                          smlh_link_up,
output                          smlh_req_rst_not,
output                          link_req_rst_not,

output  [2-1:0]                 cfg_reg_serren,
output  [2-1:0]                 cfg_cor_err_rpt_en,
output  [2-1:0]                 cfg_nf_err_rpt_en,
output  [2-1:0]                 cfg_f_err_rpt_en,

input   [3-1 :0]                diag_ctrl_bus,

input                           app_ras_des_sd_hold_ltssm,
//input   [1:0]                   app_ras_des_tba_ctrl,


output                          training_rst_n,

output [(3*2)-1:0]              pm_dstate,
output [(3*6)-1:0]              pm_vf_dstate,
output [6-1:0]                  pm_vf_pme_en,
output [6-1:0]                  pm_vf_status,
output [2-1:0]                  aux_pm_en,
output [2-1:0]                  pm_pme_en,


output  [2-1:0]                 pm_status,
output  [8-1:0]                 cfg_pbus_num,
output  [5-1:0]                 cfg_pbus_dev_num,


output [1:0]                    cfg_obff_en,
input                           app_obff_idle_msg_req,
input                           app_obff_obff_msg_req,
input                           app_obff_cpu_active_msg_req,
output                          app_obff_msg_grant,

output                          wake,
// END_IO:SII Signal Descriptions.
input                           app_hdr_valid,
input   [127:0]                 app_hdr_log,
input   [13-1:0]                app_err_bus,
input                           app_err_advisory,
input   [1-1:0]                 app_err_func_num,
input [4-2:0]                   app_err_vfunc_num,
input                           app_err_vfunc_active,


// completion timeout interface
output  [1:0]                   radm_cpl_timeout,
output  [1:0]                   radm_timeout_func_num,
output  [5:0]                   radm_timeout_vfunc_num,
output  [1:0]                   radm_timeout_vfunc_active,
output  [5:0]                   radm_timeout_cpl_tc,
output  [3:0]                   radm_timeout_cpl_attr,
output  [21:0]                  radm_timeout_cpl_len,
output  [15:0]                  radm_timeout_cpl_tag,



output  [142:0]                 debug_info_mux,

output  [2-1:0]                 cfg_send_cor_err,
output  [2-1:0]                 cfg_send_nf_err,
output  [2-1:0]                 cfg_send_f_err,
output  [2-1:0]                 cfg_int_disable,
output  [2-1:0]                 cfg_no_snoop_en,
output  [2-1:0]                 cfg_relax_order_en,


output                          cfg_link_auto_bw_int,
output                          cfg_link_auto_bw_msi,
output                          cfg_bw_mgt_int,
output                          cfg_bw_mgt_msi,
output                          cfg_link_eq_req_int,

output                          int_grt,

output [2-1:0]                  rbar_ctrl_update,
output                          user_rst_n,

output [5-1:0]                  pm_master_state,
output  [5-1:0]                 pm_slave_state,


// completion timeout interface
//AXIS master interface : master0 for remote request
output                          axis_master0_tvalid,
input                           axis_master0_tready,
output  [255:0]                 axis_master0_tdata,
output  [7:0]                   axis_master0_tkeep,
output                          axis_master0_tlast,
output  [12:0]                  axis_master0_tuser,//{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                //   function number  , vf number , vf active }
input                           user_rcvd_np_ready,
output [5:0]                    core_avl_np_cnt,
input                           user_rcvd_p_ready,
output [5:0]                    core_avl_p_cnt,

//AXIS master interface : master1 for remote completion
output                          axis_master1_tvalid,
output  [255:0]                 axis_master1_tdata,
output  [7:0]                   axis_master1_tkeep,
output  [33:0]                  axis_master1_tuser,//{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                      //   function number  , vf number , vf active spill_cpl_data }
//**********************************************************************
//axis slave 0 interface
output                          axis_slave0_tready,
input                           axis_slave0_tvalid,
input   [255:0]                 axis_slave0_tdata,
input                           axis_slave0_tlast,
input   [5:0]                   axis_slave0_tuser,//{bad eot , function number  , vf number , vf active}

//axis slave 1 interface
output                          axis_slave1_tready,
input                           axis_slave1_tvalid,
input   [255:0]                 axis_slave1_tdata,
input                           axis_slave1_tlast,
input   [5:0]                   axis_slave1_tuser,

//axis slave 2 interface
output                          axis_slave2_tready,
input                           axis_slave2_tvalid,
input   [255:0]                 axis_slave2_tdata,
input                           axis_slave2_tlast,
input   [5:0]                   axis_slave2_tuser,

output                          pm_xtlh_block_tlp,      //ask about the processing latency

// PHY inside device_top (or inside core), export serial lines, import refclk
input  [HSST_LANE_NUM-1:0]      rxp,
input  [HSST_LANE_NUM-1:0]      rxn,
output [HSST_LANE_NUM-1:0]      txp,
output [HSST_LANE_NUM-1:0]      txn,
input                           refclk_p,
input                           refclk_n,

//prbs
input                           prbs_en,
input                           force_loss_signal,
input                           force_cdr_align,
input                           force_word_align,

//loopback
input  [HSST_LANE_NUM-1:0]      pcs_nearend_loop,
input  [HSST_LANE_NUM-1:0]      pma_nearend_ploop,
input  [HSST_LANE_NUM-1:0]      pma_nearend_sloop,
//iscan
input  [HSST_LANE_NUM-1:0]      rx_eye_rst,
input  [HSST_LANE_NUM-1:0]      rx_eye_en,
input  [HSST_LANE_NUM*8-1:0]    rx_eye_tap,
input  [HSST_LANE_NUM*8-1:0]    rx_pic_eye,
input  [HSST_LANE_NUM-1:0]      em_rd_trigger,
input  [HSST_LANE_NUM*2-1:0]    em_mode_ctrl,
output [HSST_LANE_NUM-1:0]      txlane_done,
output [HSST_LANE_NUM-1:0]      rxlane_done,
output                          pll_done,
output [HSST_LANE_NUM-1:0]      rx_sigdet_sta,
output [HSST_LANE_NUM-1:0]      lx_cdr_align
);

// ======================================================================
//            PHY and clk_rst block instantiation
// ======================================================================
wire [8-1:0]                   phy_mac_rxelecidle;
wire [31:0]                    cfg_phy_control;
wire [8-1:0]                   phy_mac_phystatus;

wire                           phy_rst_n;
// --------------------------------------------------------
// PHY connection (PIPE interface)
// --------------------------------------------------------
wire    [255:0]                         phy_mac_rxdata;
wire    [31:0]                          phy_mac_rxdatak;
wire    [8-1:0]                         phy_mac_rxvalid;
wire    [(8*3)-1:0]                     phy_mac_rxstatus;
wire    [8-1:0]                         phy_mac_rxstandbystatus;
wire                                    mac_phy_elasticbuffermode;
wire    [8-1:0]                         phy_mac_rxdatavalid;
wire    [8-1:0]                         mac_phy_txdatavalid;
wire    [8*1-1:0]                       phy_mac_rxstartblock;
wire    [8*2-1:0]                       phy_mac_rxsyncheader;
wire    [8-1:0]                         mac_phy_txstartblock;
wire    [8*2-1:0]                       mac_phy_txsyncheader;
wire    [8*6-1:0]                       phy_mac_localfs;
wire    [8*6-1:0]                       phy_mac_locallf;
wire    [8*6-1:0]                       phy_mac_dirfeedback;
wire    [8*8-1:0]                       phy_mac_fomfeedback;
wire    [8*18-1:0]                      phy_mac_local_tx_pset_coef;
wire    [8-1:0]                         phy_mac_local_tx_coef_valid;
wire    [8-1:0]                         mac_phy_invalid_req;
wire    [8-1:0]                         mac_phy_rxeqinprogress;
wire    [8-1:0]                         mac_phy_rxeqeval;
wire    [8*4-1:0]                       mac_phy_local_pset_index;
wire    [8-1:0]                         mac_phy_getlocal_pset_coef;
wire    [8*6-1:0]                       mac_phy_fs;
wire    [8*6-1:0]                       mac_phy_lf;
wire                                    mac_phy_blockaligncontrol;
wire                                    mac_phy_encodedecodebypass;
wire    [8*3-1:0]                       mac_phy_rxpresethint;
wire    [8-1:0]                         mac_phy_dirchange;
wire    [255:0]                         mac_phy_txdata;
wire    [31:0]                          mac_phy_txdatak;
wire    [8-1:0]                         mac_phy_txdetectrx_loopback;
wire    [8-1:0]                         mac_phy_txcompliance;
wire    [8-1:0]                         mac_phy_rxpolarity;
wire    [2-1:0]                         mac_phy_width;
wire    [3-1:0]                         mac_phy_pclk_rate;
wire    [1:0]                           mac_phy_powerdown;
wire    [8*1-1:0]                       mac_phy_txelecidle_l;
wire    [8*1-1:0]                       mac_phy_txelecidle_h;
wire    [144-1:0]                       mac_phy_txdeemph;
wire    [2:0]                           mac_phy_txmargin;
wire                                    mac_phy_txswing;
wire    [2-1:0]                         mac_phy_rate;
wire    [1:0]                           mac_phy_pclkreq_n;
wire                                    phy_ref_clk_req_n;

wire    tx_rst_done;
wire    apb_user_rst_n;
//apb
wire            pcie_p_sel     ;
wire  [3:0]     pcie_p_strb    ;
wire  [31:0]    pcie_p_addr    ;
wire  [31:0]    pcie_p_wdata   ;
wire            pcie_p_ce      ;
wire            pcie_p_we      ;
wire            pcie_p_rdy     ;
wire  [31:0]    pcie_p_rdata   ;

wire                hsst_p_sel                  ;
wire                hsst_p_ce                   ;
wire                hsst_p_we                   ;
wire  [31:0]        hsst_p_addr                 ;
wire  [31:0]        hsst_p_wdata                ;
wire  [7:0]         hsst_p_rdata                ;
wire                hsst_p_rdy                  ;

assign mac_phy_width = 2'b10;//32 bit mode
assign mac_phy_pclk_rate = (mac_phy_rate=='d0) ? 3'd0 :
                           (mac_phy_rate=='d1) ? 3'd1 :
                           (mac_phy_rate=='d2) ? 3'd2 : 3'd0;

   //@@assign   phy_mac_rxdatavalid = 8'hff;
   //@@assign   mac_phy_txdatavalid = 8'hff;

//----------below reset is high active, compared to v0.6-----
wire    perst;
wire    button_rst;
wire    power_up_rst;

assign  perst = ~perst_n;
assign  button_rst = ~button_rst_n;
assign  power_up_rst = ~power_up_rst_n;

ips2t_pcie_sync_v1_0  user_rst_sync (.clk(apb_clk),.rst_n(user_rst_n),.sig_async(1'b1),.sig_synced(apb_user_rst_n));

//=============================================================================
//  APB MUX
//=============================================================================
ips2t_pcie_apb_mux_v1_1 u_pcie_apb_mux (
    //from uart domain
    //.i_uart_clk                     (i_apb_clk                  ),
    .i_uart_clk                     (apb_clk                    ),
    .i_uart_rst_n                   (apb_user_rst_n             ),
    .i_uart_p_sel                   (apb_sel                    ),
    .i_uart_p_strb                  (apb_strb                   ),
    .i_uart_p_addr                  (apb_addr                   ),
    .i_uart_p_wdata                 (apb_wdata                  ),
    .i_uart_p_ce                    (apb_ce                     ),
    .i_uart_p_we                    (apb_we                     ),
    .o_uart_p_rdy                   (apb_rdy                    ),
    .o_uart_p_rdata                 (apb_rdata                  ),
    //to pcie domain
    .i_pcie_clk                     (user_clk                   ),
    .i_pcie_rst_n                   (user_rst_n                 ),
    .o_pcie_p_sel                   (pcie_p_sel                 ),
    .o_pcie_p_strb                  (pcie_p_strb                ),
    .o_pcie_p_addr                  (pcie_p_addr                ),
    .o_pcie_p_wdata                 (pcie_p_wdata               ),
    .o_pcie_p_ce                    (pcie_p_ce                  ),
    .o_pcie_p_we                    (pcie_p_we                  ),
    .i_pcie_p_rdy                   (pcie_p_rdy                 ),
    .i_pcie_p_rdata                 (pcie_p_rdata               ),
    //to hsstlp domain
    .i_hsst_clk                     (apb_clk                    ),  //no use
    .i_hsst_rst_n                   (apb_rst_n                  ),  //no use
    .o_hsst_p_sel                   (hsst_p_sel                 ),
    .o_hsst_p_strb                  (                           ),
    .o_hsst_p_addr                  (hsst_p_addr                ),
    .o_hsst_p_wdata                 (hsst_p_wdata               ),
    .o_hsst_p_ce                    (hsst_p_ce                  ),
    .o_hsst_p_we                    (hsst_p_we                  ),
    .i_hsst_p_rdy                   (hsst_p_rdy                 ),
    .i_hsst_p_rdata                 ({24'b0,hsst_p_rdata}       )
);

// ======================================================================
//            PCIe IP instantiation
// ======================================================================
ips2t_pcie_hard_ctrl_v1_8 #(
    .PF1_ENABLE             (PF1_ENABLE             ),    // FALSE, TRUE
    .FLT_SHORT_TLP          (FLT_SHORT_TLP          ),    // FALSE, TRUE
    .APP_DEV_NUM            (APP_DEV_NUM            ),    // set device_number
    .APP_BUS_NUM            (APP_BUS_NUM            ),    // set bus_number
    .DEBUG_INFO_SEL         (DEBUG_INFO_SEL         ),    // set debug_info_mux, 0-33
    .DYN_DEBUG_SEL_EN       (DYN_DEBUG_SEL_EN       ),    // FALSE, TRUE
    .VF_ER_REPORT_EN        (VF_ER_REPORT_EN        ),    // FALSE, TRUE
    .ATOMIC_DISABLE         (ATOMIC_DISABLE         ),    // FALSE, TRUE
    .VC_DISABLE             (VC_DISABLE             ),    // FALSE, TRUE
    .SRIOV_DISABLE          (SRIOV_DISABLE          ),    // FALSE, TRUE
    .BAR_RESIZABLE          (BAR_RESIZABLE          ),    // enable pf0 & pf1 bars resizable, default: pf0 - bar4,bar2,bar0; pf1 - bar4,bar2,bar0
    .NUM_OF_RBARS           (NUM_OF_RBARS           ),    // set pf0 & pf1 resizable bars number,  default: pf0 - 3; pf1 - 3
    .MSI_PVM_DISABLE        (MSI_PVM_DISABLE        ),    // 0: all func enable, 1:pf0 disable, 2:pf1 disable, 3:pf0&pf1 disable, 4:vf0 disable ......255:all func disable
    .BAR_MASK_WRITABLE      (BAR_MASK_WRITABLE      ),    // 0~63 -- pf0, 64~128 --pf1; 0: no writable bar, 1:pf0 bar0 writable, 2:pf0 bar1 writable, 3:pf0 bar3 writable, ... 63:pf0 bar0-5 writable

    .DEVICE_TYPE                    (DEVICE_TYPE                    ),
    .MULTI_EN                       (MULTI_EN                       ),
    .PCIE_CAP_RCB                   (PCIE_CAP_RCB                   ),
    .PCIE_CAP_CRS                   (PCIE_CAP_CRS                   ),
    .PCIE_CAP_ATOMIC_EN             (PCIE_CAP_ATOMIC_EN             ),
    .SCRAMBLE_DISABLE               (SCRAMBLE_DISABLE               ),
    .AUTO_LANE_FLIP_CTRL_EN         (AUTO_LANE_FLIP_CTRL_EN         ),
    .PCIE_CAP_HW_AUTO_SPEED_DISABLE (PCIE_CAP_HW_AUTO_SPEED_DISABLE ),
    .DO_DESKEW_FOR_SRIS             (DO_DESKEW_FOR_SRIS             ),
    .TPH_REQ_NEXT_PTR               (TPH_REQ_NEXT_PTR               ),
    .UPCONFIGURE_SUPPORT            (UPCONFIGURE_SUPPORT            ),
    .TARGET_LINK_SPEED              (TARGET_LINK_SPEED              ),
    .LINK_CAPABLE                   (LINK_CAPABLE                   ),
    .NUM_OF_LANES                   (NUM_OF_LANES                   ),
    .MAX_LINK_WIDTH                 (MAX_LINK_WIDTH                 ),
    .MAX_LINK_SPEED                 (MAX_LINK_SPEED                 ),
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
    .PF0_MSI_CAP_NEXT_OFFSET        (PF0_MSI_CAP_NEXT_OFFSET        ),
    .PF0_CAP_POINTER                (PF0_CAP_POINTER                ),
    .PF0_PCIE_CAP_NEXT_PTR          (PF0_PCIE_CAP_NEXT_PTR          ),
    .PF0_BAR0_PREFETCH              (PF0_BAR0_PREFETCH              ),
    .PF0_BAR0_TYPE                  (PF0_BAR0_TYPE                  ),
    .PF0_BAR0_MEM_IO                (PF0_BAR0_MEM_IO                ),
    .PF0_BAR0_ENABLED               (PF0_BAR0_ENABLED               ),
    .PF0_BAR0_MASK                  (PF0_BAR0_MASK                  ),
    .PF0_BAR1_PREFETCH              (PF0_BAR1_PREFETCH              ),
    .PF0_BAR1_TYPE                  (PF0_BAR1_TYPE                  ),
    .PF0_BAR1_MEM_IO                (PF0_BAR1_MEM_IO                ),
    .PF0_BAR1_ENABLED               (PF0_BAR1_ENABLED               ),
    .PF0_BAR1_MASK                  (PF0_BAR1_MASK                  ),
    .PF0_BAR2_PREFETCH              (PF0_BAR2_PREFETCH              ),
    .PF0_BAR2_TYPE                  (PF0_BAR2_TYPE                  ),
    .PF0_BAR2_MEM_IO                (PF0_BAR2_MEM_IO                ),
    .PF0_BAR2_ENABLED               (PF0_BAR2_ENABLED               ),
    .PF0_BAR2_MASK                  (PF0_BAR2_MASK                  ),
    .PF0_BAR3_PREFETCH              (PF0_BAR3_PREFETCH              ),
    .PF0_BAR3_TYPE                  (PF0_BAR3_TYPE                  ),
    .PF0_BAR3_MEM_IO                (PF0_BAR3_MEM_IO                ),
    .PF0_BAR3_ENABLED               (PF0_BAR3_ENABLED               ),
    .PF0_BAR3_MASK                  (PF0_BAR3_MASK                  ),
    .PF0_BAR4_PREFETCH              (PF0_BAR4_PREFETCH              ),
    .PF0_BAR4_TYPE                  (PF0_BAR4_TYPE                  ),
    .PF0_BAR4_MEM_IO                (PF0_BAR4_MEM_IO                ),
    .PF0_BAR4_ENABLED               (PF0_BAR4_ENABLED               ),
    .PF0_BAR4_MASK                  (PF0_BAR4_MASK                  ),
    .PF0_BAR5_PREFETCH              (PF0_BAR5_PREFETCH              ),
    .PF0_BAR5_TYPE                  (PF0_BAR5_TYPE                  ),
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
    .PF0_RESBAR_BAR0_MAX_SUPP_SIZE  (PF0_RESBAR_BAR0_MAX_SUPP_SIZE  ),
    .PF0_RESBAR_BAR0_INIT_SIZE      (PF0_RESBAR_BAR0_INIT_SIZE      ),
    .PF0_RESBAR_BAR1_MAX_SUPP_SIZE  (PF0_RESBAR_BAR1_MAX_SUPP_SIZE  ),
    .PF0_RESBAR_BAR1_INIT_SIZE      (PF0_RESBAR_BAR1_INIT_SIZE      ),
    .PF0_RESBAR_BAR2_MAX_SUPP_SIZE  (PF0_RESBAR_BAR2_MAX_SUPP_SIZE  ),
    .PF0_RESBAR_BAR2_INIT_SIZE      (PF0_RESBAR_BAR2_INIT_SIZE      ),
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
    .PF1_MSI_CAP_NEXT_OFFSET        (PF1_MSI_CAP_NEXT_OFFSET        ),
    .PF1_CAP_POINTER                (PF1_CAP_POINTER                ),
    .PF1_PCIE_CAP_NEXT_PTR          (PF1_PCIE_CAP_NEXT_PTR          ),
    .PF1_BAR0_PREFETCH              (PF1_BAR0_PREFETCH              ),
    .PF1_BAR0_TYPE                  (PF1_BAR0_TYPE                  ),
    .PF1_BAR0_MEM_IO                (PF1_BAR0_MEM_IO                ),
    .PF1_BAR0_ENABLED               (PF1_BAR0_ENABLED               ),
    .PF1_BAR0_MASK                  (PF1_BAR0_MASK                  ),
    .PF1_BAR1_PREFETCH              (PF1_BAR1_PREFETCH              ),
    .PF1_BAR1_TYPE                  (PF1_BAR1_TYPE                  ),
    .PF1_BAR1_MEM_IO                (PF1_BAR1_MEM_IO                ),
    .PF1_BAR1_ENABLED               (PF1_BAR1_ENABLED               ),
    .PF1_BAR1_MASK                  (PF1_BAR1_MASK                  ),
    .PF1_BAR2_PREFETCH              (PF1_BAR2_PREFETCH              ),
    .PF1_BAR2_TYPE                  (PF1_BAR2_TYPE                  ),
    .PF1_BAR2_MEM_IO                (PF1_BAR2_MEM_IO                ),
    .PF1_BAR2_ENABLED               (PF1_BAR2_ENABLED               ),
    .PF1_BAR2_MASK                  (PF1_BAR2_MASK                  ),
    .PF1_BAR3_PREFETCH              (PF1_BAR3_PREFETCH              ),
    .PF1_BAR3_TYPE                  (PF1_BAR3_TYPE                  ),
    .PF1_BAR3_MEM_IO                (PF1_BAR3_MEM_IO                ),
    .PF1_BAR3_ENABLED               (PF1_BAR3_ENABLED               ),
    .PF1_BAR3_MASK                  (PF1_BAR3_MASK                  ),
    .PF1_BAR4_PREFETCH              (PF1_BAR4_PREFETCH              ),
    .PF1_BAR4_TYPE                  (PF1_BAR4_TYPE                  ),
    .PF1_BAR4_MEM_IO                (PF1_BAR4_MEM_IO                ),
    .PF1_BAR4_ENABLED               (PF1_BAR4_ENABLED               ),
    .PF1_BAR4_MASK                  (PF1_BAR4_MASK                  ),
    .PF1_BAR5_PREFETCH              (PF1_BAR5_PREFETCH              ),
    .PF1_BAR5_TYPE                  (PF1_BAR5_TYPE                  ),
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
    .PF1_RESBAR_BAR0_MAX_SUPP_SIZE  (PF1_RESBAR_BAR0_MAX_SUPP_SIZE  ),
    .PF1_RESBAR_BAR0_INIT_SIZE      (PF1_RESBAR_BAR0_INIT_SIZE      ),
    .PF1_RESBAR_BAR1_MAX_SUPP_SIZE  (PF1_RESBAR_BAR1_MAX_SUPP_SIZE  ),
    .PF1_RESBAR_BAR1_INIT_SIZE      (PF1_RESBAR_BAR1_INIT_SIZE      ),
    .PF1_RESBAR_BAR2_MAX_SUPP_SIZE  (PF1_RESBAR_BAR2_MAX_SUPP_SIZE  ),
    .PF1_RESBAR_BAR2_INIT_SIZE      (PF1_RESBAR_BAR2_INIT_SIZE      ),
    .PF0_SRIOV_EXT_CAP_NXT_OFFSET   (PF0_SRIOV_EXT_CAP_NXT_OFFSET   ),
    .PF0_SRIOV_EXT_CAP_VER          (PF0_SRIOV_EXT_CAP_VER          ),
    .PF0_SRIOV_INITIAL_VFS          (PF0_SRIOV_INITIAL_VFS          ),
    .PF0_SRIOV_VF_OFFSET            (PF0_SRIOV_VF_OFFSET            ),
    .PF0_SRIOV_VF_DEVICE_ID         (PF0_SRIOV_VF_DEVICE_ID         ),
    .PF0_SRIOV_VF_BAR0_PREFETCH     (PF0_SRIOV_VF_BAR0_PREFETCH     ),
    .PF0_SRIOV_VF_BAR0_TYPE         (PF0_SRIOV_VF_BAR0_TYPE         ),
    .PF0_SRIOV_VF_BAR0_MEM_IO       (PF0_SRIOV_VF_BAR0_MEM_IO       ),
    .PF0_SRIOV_VF_BAR0_ENABLED      (PF0_SRIOV_VF_BAR0_ENABLED      ),
    .PF0_SRIOV_VF_BAR0_MASK         (PF0_SRIOV_VF_BAR0_MASK         ),
    .PF0_SRIOV_VF_BAR1_PREFETCH     (PF0_SRIOV_VF_BAR1_PREFETCH     ),
    .PF0_SRIOV_VF_BAR1_TYPE         (PF0_SRIOV_VF_BAR1_TYPE         ),
    .PF0_SRIOV_VF_BAR1_MEM_IO       (PF0_SRIOV_VF_BAR1_MEM_IO       ),
    .PF0_SRIOV_VF_BAR1_ENABLED      (PF0_SRIOV_VF_BAR1_ENABLED      ),
    .PF0_SRIOV_VF_BAR1_MASK         (PF0_SRIOV_VF_BAR1_MASK         ),
    .PF0_SRIOV_VF_BAR2_PREFETCH     (PF0_SRIOV_VF_BAR2_PREFETCH     ),
    .PF0_SRIOV_VF_BAR2_TYPE         (PF0_SRIOV_VF_BAR2_TYPE         ),
    .PF0_SRIOV_VF_BAR2_MEM_IO       (PF0_SRIOV_VF_BAR2_MEM_IO       ),
    .PF0_SRIOV_VF_BAR2_ENABLED      (PF0_SRIOV_VF_BAR2_ENABLED      ),
    .PF0_SRIOV_VF_BAR2_MASK         (PF0_SRIOV_VF_BAR2_MASK         ),
    .PF0_SRIOV_VF_BAR3_PREFETCH     (PF0_SRIOV_VF_BAR3_PREFETCH     ),
    .PF0_SRIOV_VF_BAR3_TYPE         (PF0_SRIOV_VF_BAR3_TYPE         ),
    .PF0_SRIOV_VF_BAR3_MEM_IO       (PF0_SRIOV_VF_BAR3_MEM_IO       ),
    .PF0_SRIOV_VF_BAR3_ENABLED      (PF0_SRIOV_VF_BAR3_ENABLED      ),
    .PF0_SRIOV_VF_BAR3_MASK         (PF0_SRIOV_VF_BAR3_MASK         ),
    .PF0_SRIOV_VF_BAR4_PREFETCH     (PF0_SRIOV_VF_BAR4_PREFETCH     ),
    .PF0_SRIOV_VF_BAR4_TYPE         (PF0_SRIOV_VF_BAR4_TYPE         ),
    .PF0_SRIOV_VF_BAR4_MEM_IO       (PF0_SRIOV_VF_BAR4_MEM_IO       ),
    .PF0_SRIOV_VF_BAR4_ENABLED      (PF0_SRIOV_VF_BAR4_ENABLED      ),
    .PF0_SRIOV_VF_BAR4_MASK         (PF0_SRIOV_VF_BAR4_MASK         ),
    .PF0_SRIOV_VF_BAR5_PREFETCH     (PF0_SRIOV_VF_BAR5_PREFETCH     ),
    .PF0_SRIOV_VF_BAR5_TYPE         (PF0_SRIOV_VF_BAR5_TYPE         ),
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
    .PF1_SRIOV_VF_BAR1_PREFETCH     (PF1_SRIOV_VF_BAR1_PREFETCH     ),
    .PF1_SRIOV_VF_BAR1_TYPE         (PF1_SRIOV_VF_BAR1_TYPE         ),
    .PF1_SRIOV_VF_BAR1_MEM_IO       (PF1_SRIOV_VF_BAR1_MEM_IO       ),
    .PF1_SRIOV_VF_BAR1_ENABLED      (PF1_SRIOV_VF_BAR1_ENABLED      ),
    .PF1_SRIOV_VF_BAR1_MASK         (PF1_SRIOV_VF_BAR1_MASK         ),
    .PF1_SRIOV_VF_BAR2_PREFETCH     (PF1_SRIOV_VF_BAR2_PREFETCH     ),
    .PF1_SRIOV_VF_BAR2_TYPE         (PF1_SRIOV_VF_BAR2_TYPE         ),
    .PF1_SRIOV_VF_BAR2_MEM_IO       (PF1_SRIOV_VF_BAR2_MEM_IO       ),
    .PF1_SRIOV_VF_BAR2_ENABLED      (PF1_SRIOV_VF_BAR2_ENABLED      ),
    .PF1_SRIOV_VF_BAR2_MASK         (PF1_SRIOV_VF_BAR2_MASK         ),
    .PF1_SRIOV_VF_BAR3_PREFETCH     (PF1_SRIOV_VF_BAR3_PREFETCH     ),
    .PF1_SRIOV_VF_BAR3_TYPE         (PF1_SRIOV_VF_BAR3_TYPE         ),
    .PF1_SRIOV_VF_BAR3_MEM_IO       (PF1_SRIOV_VF_BAR3_MEM_IO       ),
    .PF1_SRIOV_VF_BAR3_ENABLED      (PF1_SRIOV_VF_BAR3_ENABLED      ),
    .PF1_SRIOV_VF_BAR3_MASK         (PF1_SRIOV_VF_BAR3_MASK         ),
    .PF1_SRIOV_VF_BAR4_PREFETCH     (PF1_SRIOV_VF_BAR4_PREFETCH     ),
    .PF1_SRIOV_VF_BAR4_TYPE         (PF1_SRIOV_VF_BAR4_TYPE         ),
    .PF1_SRIOV_VF_BAR4_MEM_IO       (PF1_SRIOV_VF_BAR4_MEM_IO       ),
    .PF1_SRIOV_VF_BAR4_ENABLED      (PF1_SRIOV_VF_BAR4_ENABLED      ),
    .PF1_SRIOV_VF_BAR4_MASK         (PF1_SRIOV_VF_BAR4_MASK         ),
    .PF1_SRIOV_VF_BAR5_PREFETCH     (PF1_SRIOV_VF_BAR5_PREFETCH     ),
    .PF1_SRIOV_VF_BAR5_TYPE         (PF1_SRIOV_VF_BAR5_TYPE         ),
    .PF1_SRIOV_VF_BAR5_MEM_IO       (PF1_SRIOV_VF_BAR5_MEM_IO       ),
    .PF1_SRIOV_VF_BAR5_ENABLED      (PF1_SRIOV_VF_BAR5_ENABLED      ),
    .PF1_SRIOV_VF_BAR5_MASK         (PF1_SRIOV_VF_BAR5_MASK         ),
    .PF1_SRIOV_MSI_64_BIT_ADDR_CAP  (PF1_SRIOV_MSI_64_BIT_ADDR_CAP  ),
    .PF1_SRIOV_MSI_MULTIPLE_MSG_CAP (PF1_SRIOV_MSI_MULTIPLE_MSG_CAP ),
    .PF1_SRIOV_MSI_ENABLE           (PF1_SRIOV_MSI_ENABLE           ),
    .PF1_SRIOV_MSI_CAP_NEXT_OFFSET  (PF1_SRIOV_MSI_CAP_NEXT_OFFSET  )
)u_pcie_hard_ctrl (
    .dyn_debug_info_sel             (dyn_debug_info_sel         ),
    .mem_clk                        (pclk                       ),
    .power_up_rst                   (power_up_rst               ),
    .button_rst                     (button_rst                 ),
    .perst                          (perst                      ),
    .pclk                           (pclk                       ),
    .pclk_div2                      (pclk_div2                  ),
    .user_clk                       (user_clk                   ),
    .phy_rst_n                      (phy_rst_n                  ),
    .app_clk_pm_en                  (app_clk_pm_en              ),
    .app_init_rst                   (app_init_rst               ),
    .app_req_entr_l1                (app_req_entr_l1            ),
    .app_ready_entr_l23             (app_ready_entr_l23         ),
    .app_req_exit_l1                (app_req_exit_l1            ),
    .app_xfer_pending               (app_xfer_pending           ),
    .app_req_retry_en               (app_req_retry_en           ),
    .app_pf_req_retry_en            (app_pf_req_retry_en        ),
    .app_vf_req_retry_en            (app_vf_req_retry_en        ),
    .app_pf0_vf_num                 (app_pf0_vf_num             ),
    .app_pf1_vf_num                 (app_pf1_vf_num             ),
    .tx_rst_done                    (tx_rst_done                ),
    //apb
    .apb_clk                        (user_clk                   ),
    .apb_rst_n                      (user_rst_n                 ),
    .apb_sel                        (pcie_p_sel                 ),
    .apb_strb                       (pcie_p_strb                ),
    .apb_addr                       (pcie_p_addr                ),
    .apb_wdata                      (pcie_p_wdata               ),
    .apb_ce                         (pcie_p_ce                  ),
    .apb_we                         (pcie_p_we                  ),
    .apb_rdy                        (pcie_p_rdy                 ),
    .apb_rdata                      (pcie_p_rdata               ),
    .cfg_ido_req_en                 (cfg_ido_req_en             ),
    .cfg_ido_cpl_en                 (cfg_ido_cpl_en             ),
    .ven_msi_req                    (ven_msi_req                ),
    .ven_msi_func_num               (ven_msi_func_num           ),
    .ven_msi_vfunc_num              (ven_msi_vfunc_num          ),
    .ven_msi_vfunc_active           (ven_msi_vfunc_active       ),
    .ven_msi_tc                     (ven_msi_tc                 ),
    .ven_msi_vector                 (ven_msi_vector             ),
    .ven_msi_grant                  (ven_msi_grant              ),
    .cfg_msi_en                     (cfg_msi_en                 ),
    .cfg_vf_msi_en                  (cfg_vf_msi_en              ),
    .cfg_msi_mask_update            (cfg_msi_mask_update        ),
    .cfg_msi_pending                (cfg_msi_pending            ),
    .cfg_vf_msi_pending             (cfg_vf_msi_pending         ),
    .cfg_multi_msi_en               (cfg_multi_msi_en           ),
    .cfg_vf_multi_msi_en            (cfg_vf_multi_msi_en        ),
    .msix_addr                      (msix_addr                  ),
    .msix_data                      (msix_data                  ),
    .cfg_msix_en                    (cfg_msix_en                ),
    .cfg_msix_func_mask             (cfg_msix_func_mask         ),
    .cfg_vf_msix_en                 (cfg_vf_msix_en             ),
    .cfg_vf_msix_func_mask          (cfg_vf_msix_func_mask      ),
    .cfg_vf_bme                     (cfg_vf_bme                 ),
    .cfg_vf_en                      (cfg_vf_en                  ),
    .cfg_num_vf                     (cfg_num_vf                 ),
    .cfg_start_vfi                  (cfg_start_vfi              ),
    .msg_rcvd_type                  (msg_rcvd_type              ),
    .msg_rcvd_data                  (msg_rcvd_data              ),
    .msg_rcvd                       (msg_rcvd                   ),
    .cfg_flr_pf_active              (cfg_flr_pf_active          ),
    .app_flr_pf_done                (app_flr_pf_done            ),
    .cfg_flr_vf_active              (cfg_flr_vf_active          ),
    .app_flr_vf_done                (app_flr_vf_done            ),
    .cfg_tph_req_en                 (cfg_tph_req_en             ),
    .cfg_pf_tph_st_mode             (cfg_pf_tph_st_mode         ),
    .dpa_substate_update            (dpa_substate_update        ),
    .cfg_vf_tph_st_mode             (cfg_vf_tph_st_mode         ),
    .cfg_vf_tph_req_en              (cfg_vf_tph_req_en          ),
    .cfg_atomic_req_en              (cfg_atomic_req_en          ),
    .cfg_atomic_egress_block        (cfg_atomic_egress_block    ),
    .cfg_ltr_m_en                   (cfg_ltr_m_en               ),
    .app_ltr_msg_req                (app_ltr_msg_req            ),
    .app_ltr_msg_grant              (app_ltr_msg_grant          ),
    .app_ltr_msg_latency            (app_ltr_msg_latency        ),
    .app_ltr_msg_func_num           (app_ltr_msg_func_num       ),
    .cfg_disable_ltr_clr_msg        (cfg_disable_ltr_clr_msg    ),
    .cfg_pwr_budget_valid           (cfg_pwr_budget_valid       ),
    .cfg_pwr_budget_data_reg        (cfg_pwr_budget_data_reg    ),
    .cfg_pwr_budget_func_num        (cfg_pwr_budget_func_num    ),
    .cfg_pwr_budget_data_sel_reg    (cfg_pwr_budget_data_sel_reg),
    .cfg_pwr_budget_sel             (cfg_pwr_budget_sel         ),
    .cfg_ari_fwd_en                 (cfg_ari_fwd_en             ),
    .rx_lane_flip_en                (rx_lane_flip_en            ),
    .tx_lane_flip_en                (tx_lane_flip_en            ),
    .sys_int                        (sys_int                    ),
    .apps_pm_xmt_pme                (apps_pm_xmt_pme            ),
    .apps_pm_vf_xmt_pme             (apps_pm_vf_xmt_pme         ),
    .app_unlock_msg                 (app_unlock_msg             ),
    .apps_pm_xmt_turnoff            (apps_pm_xmt_turnoff        ),
    .cfg_sys_err_rc                 (cfg_sys_err_rc             ),
    .cfg_aer_rc_err_int             (cfg_aer_rc_err_int         ),
    .cfg_aer_rc_err_msi             (cfg_aer_rc_err_msi         ),
    .cfg_pme_int                    (cfg_pme_int                ),
    .cfg_pme_msi                    (cfg_pme_msi                ),
    .cfg_crs_sw_vis_en              (cfg_crs_sw_vis_en          ),
    .radm_q_not_empty               (radm_q_not_empty           ),
    .radm_qoverflow                 (radm_qoverflow             ),
    .xadm_ph_cdts                   (xadm_ph_cdts               ),
    .xadm_pd_cdts                   (xadm_pd_cdts               ),
    .xadm_nph_cdts                  (xadm_nph_cdts              ),
    .xadm_npd_cdts                  (xadm_npd_cdts              ),
    .xadm_cplh_cdts                 (xadm_cplh_cdts             ),
    .xadm_cpld_cdts                 (xadm_cpld_cdts             ),
    .cfg_bus_master_en              (cfg_bus_master_en          ),
    .cfg_2nd_reset                  (cfg_2nd_reset              ),
    .cfg_max_payload_size           (cfg_max_payload_size       ),
    .cfg_rcb                        (cfg_rcb                    ),
    .cfg_tc_enable                  (cfg_tc_enable              ),
    .cfg_mem_space_en               (cfg_mem_space_en           ),
    .cfg_max_rd_req_size            (cfg_max_rd_req_size        ),
    .cfg_ext_tag_en                 (cfg_ext_tag_en             ),
    .rdlh_link_up                   (rdlh_link_up               ),
    .smlh_ltssm_state               (smlh_ltssm_state           ),
    .smlh_link_up                   (smlh_link_up               ),
    .smlh_req_rst_not               (smlh_req_rst_not           ),
    .link_req_rst_not               (link_req_rst_not           ),
    .cfg_reg_serren                 (cfg_reg_serren             ),
    .cfg_cor_err_rpt_en             (cfg_cor_err_rpt_en         ),
    .cfg_nf_err_rpt_en              (cfg_nf_err_rpt_en          ),
    .cfg_f_err_rpt_en               (cfg_f_err_rpt_en           ),
    .diag_ctrl_bus                  (diag_ctrl_bus              ),
    .app_ras_des_sd_hold_ltssm      (app_ras_des_sd_hold_ltssm  ),
    .training_rst_n                 (training_rst_n             ),
    .pm_dstate                      (pm_dstate                  ),
    .pm_vf_dstate                   (pm_vf_dstate               ),
    .pm_vf_pme_en                   (pm_vf_pme_en               ),
    .pm_vf_status                   (pm_vf_status               ),
    .aux_pm_en                      (aux_pm_en                  ),
    .pm_pme_en                      (pm_pme_en                  ),
    .pm_status                      (pm_status                  ),
    .cfg_pbus_num                   (cfg_pbus_num               ),
    .cfg_pbus_dev_num               (cfg_pbus_dev_num           ),
    .cfg_obff_en                    (cfg_obff_en                ),
    .app_obff_idle_msg_req          (app_obff_idle_msg_req      ),
    .app_obff_obff_msg_req          (app_obff_obff_msg_req      ),
    .app_obff_cpu_active_msg_req    (app_obff_cpu_active_msg_req),
    .app_obff_msg_grant             (app_obff_msg_grant         ),
    .wake                           (wake                       ),
    .app_hdr_valid                  (app_hdr_valid              ),
    .app_hdr_log                    (app_hdr_log                ),
    .app_err_bus                    (app_err_bus                ),
    .app_err_advisory               (app_err_advisory           ),
    .app_err_func_num               (app_err_func_num           ),
    .app_err_vfunc_num              (app_err_vfunc_num          ),
    .app_err_vfunc_active           (app_err_vfunc_active       ),
    .radm_cpl_timeout               (radm_cpl_timeout           ),
    .radm_timeout_func_num          (radm_timeout_func_num      ),
    .radm_timeout_vfunc_num         (radm_timeout_vfunc_num     ),
    .radm_timeout_vfunc_active      (radm_timeout_vfunc_active  ),
    .radm_timeout_cpl_tc            (radm_timeout_cpl_tc        ),
    .radm_timeout_cpl_attr          (radm_timeout_cpl_attr      ),
    .radm_timeout_cpl_len           (radm_timeout_cpl_len       ),
    .radm_timeout_cpl_tag           (radm_timeout_cpl_tag       ),
    .debug_info_mux                 (debug_info_mux             ),
    .cfg_send_cor_err               (cfg_send_cor_err           ),
    .cfg_send_nf_err                (cfg_send_nf_err            ),
    .cfg_send_f_err                 (cfg_send_f_err             ),
    .cfg_int_disable                (cfg_int_disable            ),
    .cfg_no_snoop_en                (cfg_no_snoop_en            ),
    .cfg_relax_order_en             (cfg_relax_order_en         ),
    .cfg_link_auto_bw_int           (cfg_link_auto_bw_int       ),
    .cfg_link_auto_bw_msi           (cfg_link_auto_bw_msi       ),
    .cfg_bw_mgt_int                 (cfg_bw_mgt_int             ),
    .cfg_bw_mgt_msi                 (cfg_bw_mgt_msi             ),
    .cfg_link_eq_req_int            (cfg_link_eq_req_int        ),
    .int_grt                        (int_grt                    ),
    .rbar_ctrl_update               (rbar_ctrl_update           ),
    .user_rst_n                     (user_rst_n                 ),
    .pm_master_state                (pm_master_state            ),
    .pm_slave_state                 (pm_slave_state             ),
    .mac_phy_powerdown              (mac_phy_powerdown          ),
    .phy_mac_rxelecidle             (phy_mac_rxelecidle         ),
    .phy_mac_phystatus              (phy_mac_phystatus          ),
    .phy_mac_rxdata                 (phy_mac_rxdata             ),
    .phy_mac_rxdatak                (phy_mac_rxdatak            ),
    .phy_mac_rxvalid                (phy_mac_rxvalid            ),
    .phy_mac_rxstatus               (phy_mac_rxstatus           ),
    .mac_phy_txdata                 (mac_phy_txdata             ),
    .mac_phy_txdatak                (mac_phy_txdatak            ),
    .mac_phy_txdatavalid            (mac_phy_txdatavalid        ),
    .mac_phy_txsyncheader           (mac_phy_txsyncheader       ),
    .mac_phy_txstartblock           (mac_phy_txstartblock       ),
    .mac_phy_blockaligncontrol      (mac_phy_blockaligncontrol  ),
    .mac_phy_txdetectrx_loopback    (mac_phy_txdetectrx_loopback),
    .mac_phy_txelecidle_h           (mac_phy_txelecidle_h       ),
    .mac_phy_txelecidle_l           (mac_phy_txelecidle_l       ),
    .mac_phy_txcompliance           (mac_phy_txcompliance       ),
    .mac_phy_rxpolarity             (mac_phy_rxpolarity         ),
    .mac_phy_rate                   (mac_phy_rate               ),
    .mac_phy_txdeemph               (mac_phy_txdeemph           ),
    .mac_phy_txmargin               (mac_phy_txmargin           ),
    .mac_phy_txswing                (mac_phy_txswing            ),
    .phy_mac_rxdatavalid            (phy_mac_rxdatavalid        ),
    .phy_mac_rxstartblock           (phy_mac_rxstartblock       ),
    .phy_mac_rxsyncheader           (phy_mac_rxsyncheader       ),
    .phy_mac_localfs                (phy_mac_localfs            ),
    .phy_mac_locallf                (phy_mac_locallf            ),
    .mac_phy_rxpresethint           (mac_phy_rxpresethint       ),
    .mac_phy_fs                     (mac_phy_fs                 ),
    .mac_phy_lf                     (mac_phy_lf                 ),
    .phy_mac_dirfeedback            (phy_mac_dirfeedback        ),
    .phy_mac_fomfeedback            (phy_mac_fomfeedback        ),
    .phy_mac_local_tx_pset_coef     (phy_mac_local_tx_pset_coef ),
    .phy_mac_local_tx_coef_valid    (phy_mac_local_tx_coef_valid),
    .mac_phy_local_pset_index       (mac_phy_local_pset_index   ),
    .mac_phy_getlocal_pset_coef     (mac_phy_getlocal_pset_coef ),
    .mac_phy_rxeqinprogress         (mac_phy_rxeqinprogress     ),
    .mac_phy_invalid_req            (mac_phy_invalid_req        ),
    .mac_phy_rxeqeval               (mac_phy_rxeqeval           ),
    .mac_phy_dirchange              (mac_phy_dirchange          ),
    .axis_master0_tvalid            (axis_master0_tvalid        ),
    .axis_master0_tready            (axis_master0_tready        ),
    .axis_master0_tdata             (axis_master0_tdata         ),
    .axis_master0_tkeep             (axis_master0_tkeep         ),
    .axis_master0_tlast             (axis_master0_tlast         ),
    .axis_master0_tuser             (axis_master0_tuser         ),
    .axis_master1_tvalid            (axis_master1_tvalid        ),
    .axis_master1_tdata             (axis_master1_tdata         ),
    .axis_master1_tkeep             (axis_master1_tkeep         ),
    .axis_master1_tuser             (axis_master1_tuser         ),
    .user_rcvd_np_ready             (user_rcvd_np_ready         ),
    .core_avl_np_cnt                (core_avl_np_cnt            ),
    .axis_slave0_tready             (axis_slave0_tready         ),
    .axis_slave0_tvalid             (axis_slave0_tvalid         ),
    .axis_slave0_tdata              (axis_slave0_tdata          ),
    .axis_slave0_tlast              (axis_slave0_tlast          ),
    .axis_slave0_tuser              (axis_slave0_tuser          ),
    .axis_slave1_tready             (axis_slave1_tready         ),
    .axis_slave1_tvalid             (axis_slave1_tvalid         ),
    .axis_slave1_tdata              (axis_slave1_tdata          ),
    .axis_slave1_tlast              (axis_slave1_tlast          ),
    .axis_slave1_tuser              (axis_slave1_tuser          ),
    .axis_slave2_tready             (axis_slave2_tready         ),
    .axis_slave2_tvalid             (axis_slave2_tvalid         ),
    .axis_slave2_tdata              (axis_slave2_tdata          ),
    .axis_slave2_tlast              (axis_slave2_tlast          ),
    .axis_slave2_tuser              (axis_slave2_tuser          ),
    .pm_xtlh_block_tlp              (pm_xtlh_block_tlp          ),
    .user_rcvd_p_ready              (user_rcvd_p_ready          ),
    .core_avl_p_cnt                 (core_avl_p_cnt             )
); // u_pcie3_hard_ctrl_wrap

// ======================================================================
//            PHY block instantiation
// ======================================================================
ips2t_pcie_soft_phy_v1_8 #(
    .HSST_LANE_NUM                      (HSST_LANE_NUM                      ),
    .HPLL_EN                            (HPLL_EN                            )
)u_phy(
    .refclk_p                           (refclk_p                           ),
    .refclk_n                           (refclk_n                           ),
    .pclk                               (pclk                               ),
    .pclk_div2                          (pclk_div2                          ),
    .phy_rst_n                          (phy_rst_n                          ),
    .power_up_rst_n                     (power_up_rst_n                     ),
    .button_rst_n                       (button_rst_n                       ),
    .refclk2core                        (ref_clk                            ),
    .user_pll_lock                      (user_pll_lock                      ),
    .prbs_en                            (prbs_en                            ),
    .force_loss_signal                  (force_loss_signal                  ),
    .force_cdr_align                    (force_cdr_align                    ),
    .force_word_align                   (force_word_align                   ),
    .pcs_nearend_loop                   (pcs_nearend_loop                   ),
    .pma_nearend_ploop                  (pma_nearend_ploop                  ),
    .pma_nearend_sloop                  (pma_nearend_sloop                  ),
    .smlh_ltssm_state                   (smlh_ltssm_state                   ),
    .p_calib_done                       (p_calib_done                       ),
    .tx_rst_done                        (tx_rst_done                        ),
    //APB
    .p_cfg_clk                          (apb_clk                            ), // input
    .p_cfg_rst_n                        (apb_rst_n                          ), // input
    .p_cfg_psel                         (hsst_p_sel                         ), // input
    .p_cfg_enable                       (hsst_p_ce                          ), // input
    .p_cfg_write                        (hsst_p_we                          ), // input
    .p_cfg_addr                         (hsst_p_addr[15:0]                  ), // input  [15:0]
    .p_cfg_wdata                        (hsst_p_wdata[7:0]                  ), // input  [7:0]
    .p_cfg_rdata                        (hsst_p_rdata                       ), // output [7:0]
    .p_cfg_int                          (                                   ), // output
    .p_cfg_ready                        (hsst_p_rdy                         ), // output
    // Phy PIPE interface
    .phy_mac_rxdata                     (phy_mac_rxdata                     ),
    .phy_mac_rxdatak                    (phy_mac_rxdatak                    ),
    .phy_mac_rxvalid                    (phy_mac_rxvalid                    ),
    .phy_mac_rxdatavalid                (phy_mac_rxdatavalid                ),
    .phy_mac_rxstatus                   (phy_mac_rxstatus                   ),
    .phy_mac_rxelecidle                 (phy_mac_rxelecidle                 ),
    .phy_mac_phystatus                  (phy_mac_phystatus                  ),
    .phy_mac_rxstartblock               (phy_mac_rxstartblock               ),
    .phy_mac_rxsyncheader               (phy_mac_rxsyncheader               ),
    .phy_mac_localfs                    (phy_mac_localfs                    ),
    .phy_mac_locallf                    (phy_mac_locallf                    ),
    .phy_mac_dirfeedback                (phy_mac_dirfeedback                ),
    .phy_mac_fomfeedback                (phy_mac_fomfeedback                ),
    .phy_mac_local_tx_pset_coef         (phy_mac_local_tx_pset_coef         ),
    .phy_mac_local_tx_coef_valid        (phy_mac_local_tx_coef_valid        ),
    .mac_phy_rxpresethint               (mac_phy_rxpresethint               ),
    .mac_phy_invalid_req                (mac_phy_invalid_req                ),
    .mac_phy_rxeqinprogress             (mac_phy_rxeqinprogress             ),
    .mac_phy_rxeqeval                   (mac_phy_rxeqeval                   ),
    .mac_phy_local_pset_index           (mac_phy_local_pset_index           ),
    .mac_phy_getlocal_pset_coef         (mac_phy_getlocal_pset_coef         ),
    .mac_phy_fs                         (mac_phy_fs                         ),
    .mac_phy_lf                         (mac_phy_lf                         ),
    .mac_phy_blockaligncontrol          (mac_phy_blockaligncontrol          ),
    .mac_phy_txdata                     (mac_phy_txdata                     ),
    .mac_phy_txdatak                    (mac_phy_txdatak                    ),
    .mac_phy_txdatavalid                (mac_phy_txdatavalid                ),
    .mac_phy_txdetectrx_loopback        (mac_phy_txdetectrx_loopback        ),
    .mac_phy_txelecidle_h               (mac_phy_txelecidle_h               ),
    .mac_phy_txelecidle_l               (mac_phy_txelecidle_l               ),
    .mac_phy_txcompliance               (mac_phy_txcompliance               ),
    .mac_phy_rxpolarity                 (mac_phy_rxpolarity                 ),
    .mac_phy_powerdown                  (mac_phy_powerdown                  ),
    .mac_phy_rate                       (mac_phy_rate                       ),
    .mac_phy_txdeemph                   (mac_phy_txdeemph                   ),
    .mac_phy_txmargin                   (mac_phy_txmargin                   ),
    .mac_phy_txswing                    (mac_phy_txswing                    ),
    .mac_phy_txstartblock               (mac_phy_txstartblock               ),
    .mac_phy_txsyncheader               (mac_phy_txsyncheader               ),
    //difference signals
    .txp                                (txp                                ),
    .txn                                (txn                                ),
    .rxp                                (rxp                                ),
    .rxn                                (rxn                                ),
    .rx_eye_rst                         (rx_eye_rst                         ), 
    .rx_eye_en                          (rx_eye_en                          ), 
    .rx_eye_tap                         (rx_eye_tap                         ), 
    .rx_pic_eye                         (rx_pic_eye                         ), 
    .em_rd_trigger                      (em_rd_trigger                      ), 
    .em_mode_ctrl                       (em_mode_ctrl                       ), 
    .txlane_done                        (txlane_done                        ), 
    .rxlane_done                        (rxlane_done                        ), 
    .pll_done                           (pll_done                           ), 
    .rx_sigdet_sta                      (rx_sigdet_sta                      ), 
    .lx_cdr_align                       (lx_cdr_align                       )  
 );

endmodule
