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

module ips2t_pcie_hard_ctrl_v1_8#(
// PCIe SC
parameter                       PF1_ENABLE          = "TRUE"        ,   // FALSE, TRUE
parameter                       FLT_SHORT_TLP       = "TRUE"        ,   // FALSE, TRUE
parameter        integer        APP_DEV_NUM         = 0             ,   // set device_number
parameter        integer        APP_BUS_NUM         = 0             ,   // set bus_number
parameter        integer        DEBUG_INFO_SEL      = 0             ,   // set debug_info_mux, 0-33
parameter                       DYN_DEBUG_SEL_EN    = "TRUE"        ,   // FALSE, TRUE
parameter                       VF_ER_REPORT_EN     = "TRUE"        ,   // FALSE, TRUE
parameter                       ATOMIC_DISABLE      = "FALSE"       ,   // FALSE, TRUE
parameter                       VC_DISABLE          = "FALSE"       ,   // FALSE, TRUE
parameter                       SRIOV_DISABLE       = "FALSE"       ,   // FALSE, TRUE
parameter        integer        BAR_RESIZABLE       = 1365          ,   // enable pf0 & pf1 bars resizable, default: pf0 - bar4,bar2,bar0; pf1 - bar4,bar2,bar0
parameter        integer        NUM_OF_RBARS        = 27            ,   // set pf0 & pf1 resizable bars number,  default: pf0 - 3; pf1 - 3
parameter        integer        MSI_PVM_DISABLE     = 0             ,   // 0: all func enable, 1:pf0 disable, 2:pf1 disable, 3:pf0&pf1 disable, 4:vf0 disable ......255:all func disable
parameter        integer        BAR_MASK_WRITABLE   = 12'hfff       ,   // 0~63 -- pf0, 64~128 --pf1; 0: no writable bar, 1:pf0 bar0 writable, 2:pf0 bar1 writable, 3:pf0 bar3 writable, ... 63:pf0 bar0-5 writable
//
//==========================PF0 Config Only
parameter                       DEVICE_TYPE                           = 4'b000        ,   // EP-> 4'b0000; RC->4'b0100;
parameter                       MULTI_EN                              = 1'b0          ,
parameter                       PCIE_CAP_RCB                          = 1'b1          ,
parameter                       PCIE_CAP_CRS                          = 1'b0          ,
parameter                       PCIE_CAP_ATOMIC_EN                    = 1'b0          ,
parameter                       SCRAMBLE_DISABLE                      = 1'b0          ,
parameter                       AUTO_LANE_FLIP_CTRL_EN                = 1'b1          ,
parameter                       PCIE_CAP_HW_AUTO_SPEED_DISABLE        = 1'b0          ,
parameter                       DO_DESKEW_FOR_SRIS                    = 1'b1          ,
parameter                       TPH_REQ_NEXT_PTR                      = 12'h0         ,
parameter                       UPCONFIGURE_SUPPORT                   = 1'b1          ,
parameter                       TARGET_LINK_SPEED                     = 4'h1          ,
parameter                       LINK_CAPABLE                          = 6'b00_0111    ,   //0x1:x1 0x3:x2 0x7:x4 0xf:x8
parameter                       NUM_OF_LANES                          = 5'b0_0001     ,   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
//==========================PF0 an PF1 Config Same value
parameter                       MAX_LINK_WIDTH                        = 6'b00_0100    ,   //0x1:x1 0x2:x2 0x4:x4 0x8:x8
parameter                       MAX_LINK_SPEED                        = 4'b0010       ,   //0x1:gen1 0x2:gen2 0x3 gen3
parameter                       EXT_TAG_EN                            = 1'b1          ,
parameter                       EXT_TAG_SUPP                          = 1'b1          ,
parameter                       INT_DISABLE                           = 1'b0          ,
//==========================PF0 an PF1 Config Different value
parameter                       PF0_DEVICE_ID                         = 16'h0755      ,
parameter                       PF0_SUBSYS_DEV_ID                     = 16'h0000      ,
parameter                       PF0_VENDOR_ID                         = 16'h0755      ,
parameter                       PF0_SUBSYS_VENDOR_ID                  = 16'h0000      ,
parameter                       PF0_BASE_CLASS_CODE                   = 8'h05         ,
parameter                       PF0_SUBCLASS_CODE                     = 8'h80         ,
parameter                       PF0_PROGRAM_INTERFACE                 = 8'h00         ,
parameter                       PF0_REVISION_ID                       = 8'h00         ,
parameter                       PF0_MAX_PAYLOAD_SIZE                  = 3'b011        ,  // 1024-bytes
parameter                       PF0_INT_PIN                           = 8'h0          ,
parameter                       PF0_MSI_64_BIT_ADDR_CAP               = 1'b1          ,
parameter                       PF0_MSI_MULTIPLE_MSG_CAP              = 3'b101        ,
parameter                       PF0_MSI_ENABLE                        = 1'b0          ,
parameter                       PF0_MSI_CAP_NEXT_OFFSET               = 8'h70         ,
parameter                       PF0_CAP_POINTER                       = 8'h50         ,
parameter                       PF0_PCIE_CAP_NEXT_PTR                 = 8'hB0         ,
parameter                       PF0_BAR0_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR0_TYPE                         = 2'b0          ,
parameter                       PF0_BAR0_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR0_ENABLED                      = 1'b1          ,
parameter                       PF0_BAR0_MASK                         = 31'h0000_0fff ,
parameter                       PF0_BAR1_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR1_TYPE                         = 2'b0          ,
parameter                       PF0_BAR1_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR1_ENABLED                      = 1'b1          ,
parameter                       PF0_BAR1_MASK                         = 31'h0000_07ff ,
parameter                       PF0_BAR2_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR2_TYPE                         = 2'b10         ,
parameter                       PF0_BAR2_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR2_ENABLED                      = 1'b1          ,
parameter                       PF0_BAR2_MASK                         = 31'h0000_0fff ,
parameter                       PF0_BAR3_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR3_TYPE                         = 2'b0          ,
parameter                       PF0_BAR3_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR3_ENABLED                      = 1'b0          ,
parameter                       PF0_BAR3_MASK                         = 31'd0         ,
parameter                       PF0_BAR4_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR4_TYPE                         = 2'b0          ,
parameter                       PF0_BAR4_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR4_ENABLED                      = 1'b0          ,
parameter                       PF0_BAR4_MASK                         = 31'd0         ,
parameter                       PF0_BAR5_PREFETCH                     = 1'b0          ,
parameter                       PF0_BAR5_TYPE                         = 2'b0          ,
parameter                       PF0_BAR5_MEM_IO                       = 1'b0          ,
parameter                       PF0_BAR5_ENABLED                      = 1'b0          ,
parameter                       PF0_BAR5_MASK                         = 31'd0         ,
parameter                       PF0_ROM_BAR_ENABLE                    = 1'b0          ,
parameter                       PF0_ROM_BAR_ENABLED                   = 1'd0          ,
parameter                       PF0_ROM_MASK                          = 31'd0         ,
parameter                       PF0_ECRC_CHECK_EN                     = 1'b1          ,
parameter                       PF0_ECRC_GEN_EN                       = 1'b1          ,
parameter                       PF0_PCI_MSIX_ENABLE                   = 1'b0          ,
parameter                       PF0_PCI_FUNCTION_MASK                 = 1'b0          ,
parameter                       PF0_PCI_MSIX_TABLE_SIZE               = 11'h0         ,
parameter                       PF0_PCI_MSIX_CAP_NEXT_OFFSET          = 8'h0          ,
parameter                       PF0_PCI_MSIX_TABLE_OFFSET             = 29'h0         ,
parameter                       PF0_PCI_MSIX_BIR                      = 3'h0          ,
parameter                       PF0_PCI_MSIX_PBA_OFFSET               = 29'h0         ,
parameter                       PF0_PCI_MSIX_PBA_BIR                  = 3'h0          ,
parameter                       PF0_AER_CAP_NEXT_OFFSET               = 12'h0         ,
parameter                       PF0_RESBAR_BAR0_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF0_RESBAR_BAR0_INIT_SIZE             = 5'h13         ,
parameter                       PF0_RESBAR_BAR1_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF0_RESBAR_BAR1_INIT_SIZE             = 5'h13         ,
parameter                       PF0_RESBAR_BAR2_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF0_RESBAR_BAR2_INIT_SIZE             = 5'hb          ,
parameter                       PF1_DEVICE_ID                         = 16'h0755      ,
parameter                       PF1_SUBSYS_DEV_ID                     = 16'h0000      ,
parameter                       PF1_VENDOR_ID                         = 16'h0755      ,
parameter                       PF1_SUBSYS_VENDOR_ID                  = 16'h0000      ,
parameter                       PF1_BASE_CLASS_CODE                   = 8'h05         ,
parameter                       PF1_SUBCLASS_CODE                     = 8'h80         ,
parameter                       PF1_PROGRAM_INTERFACE                 = 8'h00         ,
parameter                       PF1_REVISION_ID                       = 8'h00         ,
parameter                       PF1_MAX_PAYLOAD_SIZE                  = 3'b011        ,  // 1024-bytes
parameter                       PF1_INT_PIN                           = 8'h0          ,
parameter                       PF1_MSI_64_BIT_ADDR_CAP               = 1'b1          ,
parameter                       PF1_MSI_MULTIPLE_MSG_CAP              = 3'b101        ,
parameter                       PF1_MSI_ENABLE                        = 1'b0          ,
parameter                       PF1_MSI_CAP_NEXT_OFFSET               = 8'h70         ,
parameter                       PF1_CAP_POINTER                       = 8'h50         ,
parameter                       PF1_PCIE_CAP_NEXT_PTR                 = 8'hB0         ,
parameter                       PF1_BAR0_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR0_TYPE                         = 2'b0          ,
parameter                       PF1_BAR0_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR0_ENABLED                      = 1'b1          ,
parameter                       PF1_BAR0_MASK                         = 31'h0000_0fff ,
parameter                       PF1_BAR1_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR1_TYPE                         = 2'b0          ,
parameter                       PF1_BAR1_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR1_ENABLED                      = 1'b1          ,
parameter                       PF1_BAR1_MASK                         = 31'h0000_07ff ,
parameter                       PF1_BAR2_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR2_TYPE                         = 2'b10         ,
parameter                       PF1_BAR2_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR2_ENABLED                      = 1'b1          ,
parameter                       PF1_BAR2_MASK                         = 31'h0000_0fff ,
parameter                       PF1_BAR3_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR3_TYPE                         = 2'b0          ,
parameter                       PF1_BAR3_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR3_ENABLED                      = 1'b0          ,
parameter                       PF1_BAR3_MASK                         = 31'd0         ,
parameter                       PF1_BAR4_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR4_TYPE                         = 2'b0          ,
parameter                       PF1_BAR4_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR4_ENABLED                      = 1'b0          ,
parameter                       PF1_BAR4_MASK                         = 31'd0         ,
parameter                       PF1_BAR5_PREFETCH                     = 1'b0          ,
parameter                       PF1_BAR5_TYPE                         = 2'b0          ,
parameter                       PF1_BAR5_MEM_IO                       = 1'b0          ,
parameter                       PF1_BAR5_ENABLED                      = 1'b0          ,
parameter                       PF1_BAR5_MASK                         = 31'd0         ,
parameter                       PF1_ROM_BAR_ENABLE                    = 1'b0          ,
parameter                       PF1_ROM_BAR_ENABLED                   = 1'd0          ,
parameter                       PF1_ROM_MASK                          = 31'd0         ,
parameter                       PF1_ECRC_CHECK_EN                     = 1'b1          ,
parameter                       PF1_ECRC_GEN_EN                       = 1'b1          ,
parameter                       PF1_PCI_MSIX_ENABLE                   = 1'b0          ,
parameter                       PF1_PCI_FUNCTION_MASK                 = 1'b0          ,
parameter                       PF1_PCI_MSIX_TABLE_SIZE               = 11'h0         ,
parameter                       PF1_PCI_MSIX_CAP_NEXT_OFFSET          = 8'h0          ,
parameter                       PF1_PCI_MSIX_TABLE_OFFSET             = 29'h0         ,
parameter                       PF1_PCI_MSIX_BIR                      = 3'h0          ,
parameter                       PF1_PCI_MSIX_PBA_OFFSET               = 29'h0         ,
parameter                       PF1_PCI_MSIX_PBA_BIR                  = 3'h0          ,
parameter                       PF1_AER_CAP_NEXT_OFFSET               = 12'h0         ,
parameter                       PF1_RESBAR_BAR0_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF1_RESBAR_BAR0_INIT_SIZE             = 5'h13         ,
parameter                       PF1_RESBAR_BAR1_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF1_RESBAR_BAR1_INIT_SIZE             = 5'h13         ,
parameter                       PF1_RESBAR_BAR2_MAX_SUPP_SIZE         = 20'hf_ffff    ,
parameter                       PF1_RESBAR_BAR2_INIT_SIZE             = 5'hb          ,
//SRIOV CAP
parameter                       PF0_SRIOV_EXT_CAP_NXT_OFFSET          = 12'h0         ,
parameter                       PF0_SRIOV_EXT_CAP_VER                 = 4'h0          ,
parameter                       PF0_SRIOV_INITIAL_VFS                 = 16'h3         ,
parameter                       PF0_SRIOV_VF_OFFSET                   = 16'h0         ,
parameter                       PF0_SRIOV_VF_DEVICE_ID                = 16'h0755      ,
parameter                       PF0_SRIOV_VF_BAR0_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR0_TYPE                = 2'b0          ,
parameter                       PF0_SRIOV_VF_BAR0_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR0_ENABLED             = 1'b1          ,
parameter                       PF0_SRIOV_VF_BAR0_MASK                = 31'h0000_0fff ,
parameter                       PF0_SRIOV_VF_BAR1_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR1_TYPE                = 2'b0          ,
parameter                       PF0_SRIOV_VF_BAR1_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR1_ENABLED             = 1'b1          ,
parameter                       PF0_SRIOV_VF_BAR1_MASK                = 31'h0000_07ff ,
parameter                       PF0_SRIOV_VF_BAR2_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR2_TYPE                = 2'b10         ,
parameter                       PF0_SRIOV_VF_BAR2_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR2_ENABLED             = 1'b1          ,
parameter                       PF0_SRIOV_VF_BAR2_MASK                = 31'h0000_0fff ,
parameter                       PF0_SRIOV_VF_BAR3_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR3_TYPE                = 2'b0          ,
parameter                       PF0_SRIOV_VF_BAR3_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR3_ENABLED             = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR3_MASK                = 31'd0         ,
parameter                       PF0_SRIOV_VF_BAR4_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR4_TYPE                = 2'b0          ,
parameter                       PF0_SRIOV_VF_BAR4_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR4_ENABLED             = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR4_MASK                = 31'd0         ,
parameter                       PF0_SRIOV_VF_BAR5_PREFETCH            = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR5_TYPE                = 2'b0          ,
parameter                       PF0_SRIOV_VF_BAR5_MEM_IO              = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR5_ENABLED             = 1'b0          ,
parameter                       PF0_SRIOV_VF_BAR5_MASK                = 31'd0         ,
parameter                       PF0_SRIOV_MSI_64_BIT_ADDR_CAP         = 1'b1          ,
parameter                       PF0_SRIOV_MSI_MULTIPLE_MSG_CAP        = 3'b101        ,
parameter                       PF0_SRIOV_MSI_ENABLE                  = 1'b0          ,
parameter                       PF0_SRIOV_MSI_CAP_NEXT_OFFSET         = 8'h70         ,
parameter                       PF1_SRIOV_EXT_CAP_NXT_OFFSET          = 12'h0         ,
parameter                       PF1_SRIOV_EXT_CAP_VER                 = 4'h0          ,
parameter                       PF1_SRIOV_INITIAL_VFS                 = 16'h3         ,
parameter                       PF1_SRIOV_VF_OFFSET                   = 16'h0         ,
parameter                       PF1_SRIOV_VF_DEVICE_ID                = 16'h0755      ,
parameter                       PF1_SRIOV_VF_BAR0_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR0_TYPE                = 2'b0          ,
parameter                       PF1_SRIOV_VF_BAR0_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR0_ENABLED             = 1'b1          ,
parameter                       PF1_SRIOV_VF_BAR0_MASK                = 31'h0000_0fff ,
parameter                       PF1_SRIOV_VF_BAR1_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR1_TYPE                = 2'b0          ,
parameter                       PF1_SRIOV_VF_BAR1_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR1_ENABLED             = 1'b1          ,
parameter                       PF1_SRIOV_VF_BAR1_MASK                = 31'h0000_07ff ,
parameter                       PF1_SRIOV_VF_BAR2_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR2_TYPE                = 2'b10         ,
parameter                       PF1_SRIOV_VF_BAR2_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR2_ENABLED             = 1'b1          ,
parameter                       PF1_SRIOV_VF_BAR2_MASK                = 31'h0000_0fff ,
parameter                       PF1_SRIOV_VF_BAR3_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR3_TYPE                = 2'b0          ,
parameter                       PF1_SRIOV_VF_BAR3_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR3_ENABLED             = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR3_MASK                = 31'd0         ,
parameter                       PF1_SRIOV_VF_BAR4_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR4_TYPE                = 2'b0          ,
parameter                       PF1_SRIOV_VF_BAR4_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR4_ENABLED             = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR4_MASK                = 31'd0         ,
parameter                       PF1_SRIOV_VF_BAR5_PREFETCH            = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR5_TYPE                = 2'b0          ,
parameter                       PF1_SRIOV_VF_BAR5_MEM_IO              = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR5_ENABLED             = 1'b0          ,
parameter                       PF1_SRIOV_VF_BAR5_MASK                = 31'd0         ,
parameter                       PF1_SRIOV_MSI_64_BIT_ADDR_CAP         = 1'b1          ,
parameter                       PF1_SRIOV_MSI_MULTIPLE_MSG_CAP        = 3'b101        ,
parameter                       PF1_SRIOV_MSI_ENABLE                  = 1'b0          ,
parameter                       PF1_SRIOV_MSI_CAP_NEXT_OFFSET         = 8'h70
)(
input    [5:0]                  dyn_debug_info_sel,

input                           mem_clk,
input                           power_up_rst,
input                           button_rst,
input                           perst,
input                           pclk,
input                           pclk_div2,
input                           user_clk,
output                          phy_rst_n,
input                           app_clk_pm_en,
input                           app_init_rst,
input                           app_req_entr_l1,
input                           app_ready_entr_l23,
input                           app_req_exit_l1,
input                           app_xfer_pending,
input                           app_req_retry_en,
input   [2-1:0]                 app_pf_req_retry_en,
input   [6-1:0]                 app_vf_req_retry_en,

output [2-1:0]                  cfg_ido_req_en,
output [2-1:0]                  cfg_ido_cpl_en,

//app cfg vf num
input   [2:0]                   app_pf0_vf_num,
input   [2:0]                   app_pf1_vf_num,
//radm timeout
input                           ven_msi_req,
input   [1-1:0]                 ven_msi_func_num,
input   [4-2:0]                 ven_msi_vfunc_num,
input                           ven_msi_vfunc_active,
input   [2:0]                   ven_msi_tc,
input   [4:0]                   ven_msi_vector,
output                          ven_msi_grant,
output  [2-1:0]                 cfg_msi_en,
output  [6-1:0]                 cfg_vf_msi_en,
output                          cfg_msi_mask_update,
input   [(32*2)-1:0]            cfg_msi_pending,
//output  [(32*6)-1:0]          cfg_vf_msi_mask_update,
input   [(32*6)-1:0]            cfg_vf_msi_pending,
output  [(3*2)-1:0]             cfg_multi_msi_en,
output  [(3*6)-1:0]             cfg_vf_multi_msi_en,

input   [63:0]                  msix_addr,
input   [31:0]                  msix_data,
output  [2-1:0]                 cfg_msix_en,
output  [2-1:0]                 cfg_msix_func_mask,
output  [6-1:0]                 cfg_vf_msix_en,
output  [6-1:0]                 cfg_vf_msix_func_mask,
output  [6-1:0]                 cfg_vf_bme,
output  [2-1:0]                 cfg_vf_en,
output  [16*2-1:0]              cfg_num_vf,
output  [2*3-1:0]               cfg_start_vfi,

output  [4:0]                   msg_rcvd_type,
output  [7:0]                   msg_rcvd_data,
output                          msg_rcvd,
// START_IO:VPD Signal Descriptions.
// END_IO:VPD Signal Descriptions.

// START_IO:FLR Signal Descriptions.
output  [2-1:0]                 cfg_flr_pf_active,
input   [2-1:0]                 app_flr_pf_done,
output  [6-1:0]                 cfg_flr_vf_active,
input   [6-1:0]                 app_flr_vf_done,
// END_IO:FLR Signal Descriptions.
output [(1*2)-1:0]              cfg_tph_req_en,
output [(3*2)-1:0]              cfg_pf_tph_st_mode,

output [2-1:0]                  dpa_substate_update,

output  [(3*6)-1:0]             cfg_vf_tph_st_mode,
output  [(1*6)-1:0]             cfg_vf_tph_req_en,

output [2-1:0]                  cfg_atomic_req_en,
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

input   [3 -1 :0]               diag_ctrl_bus,

input                           app_ras_des_sd_hold_ltssm,
//input   [1:0]                 app_ras_des_tba_ctrl,

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

output [2-1:0]              rbar_ctrl_update,
//
//output [2-1:0]                     vf_rbar_ctrl_update,

//output                              core_clk,
output                      user_rst_n,

output  [5-1:0]             pm_master_state,
output  [5-1:0]             pm_slave_state,

//pipe interface
output  [1 : 0]         mac_phy_powerdown,
input   [8-1:0]         phy_mac_rxelecidle,
input   [8-1:0]         phy_mac_phystatus,
input   [255:0]         phy_mac_rxdata,
input   [31:0]          phy_mac_rxdatak,
input   [8-1:0]         phy_mac_rxvalid,
input   [(8*3)-1:0]     phy_mac_rxstatus,
output  [255:0]         mac_phy_txdata,
output  [31:0]          mac_phy_txdatak,
output  [8-1:0]         mac_phy_txdatavalid,
output  [(8*2)-1:0]     mac_phy_txsyncheader,
output  [8-1:0]         mac_phy_txstartblock,
output                  mac_phy_blockaligncontrol,

output  [8-1:0]         mac_phy_txdetectrx_loopback,
output  [8*1-1:0]       mac_phy_txelecidle_h,
output  [8*1-1:0]       mac_phy_txelecidle_l,
output  [8-1:0]         mac_phy_txcompliance,
output  [8-1:0]         mac_phy_rxpolarity,

output  [2-1:0]         mac_phy_rate,
output  reg [144-1:0]   mac_phy_txdeemph,
output  [2:0]           mac_phy_txmargin,
output                  mac_phy_txswing,

input   [8-1:0]         phy_mac_rxdatavalid,
input   [8*1-1:0]       phy_mac_rxstartblock,
input   [8*2-1:0]       phy_mac_rxsyncheader,
//  output  [31:0]                      cfg_phy_control,

input          [8*6-1:0]        phy_mac_localfs,
input          [8*6-1:0]        phy_mac_locallf,
output         [8*3-1:0]        mac_phy_rxpresethint,
output         [8*6-1:0]        mac_phy_fs,
output         [8*6-1:0]        mac_phy_lf,
input          [8*6-1:0]        phy_mac_dirfeedback,
input          [8*8-1:0]        phy_mac_fomfeedback,
input          [8*18-1:0]       phy_mac_local_tx_pset_coef,
input          [8-1:0]          phy_mac_local_tx_coef_valid,
output         [8*4-1:0]        mac_phy_local_pset_index,
output         [8-1:0]          mac_phy_getlocal_pset_coef,
output         [8-1:0]          mac_phy_rxeqinprogress,
output         [8-1:0]          mac_phy_invalid_req,
output         [8-1:0]          mac_phy_rxeqeval,
output         [8-1:0]          mac_phy_dirchange,
// completion timeout interface
//AXIS master interface : master0 for remote request
output              axis_master0_tvalid,
input               axis_master0_tready,
output  [255:0]     axis_master0_tdata,
output  [7:0]       axis_master0_tkeep,
output              axis_master0_tlast,
output  [12:0]      axis_master0_tuser,//{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                      //   function number  , vf number , vf active }
//AXIS master interface : master1 for remote completion
output              axis_master1_tvalid,
//input               axis_master1_tready,
output  [255:0]     axis_master1_tdata,
output  [7:0]       axis_master1_tkeep,
//output              axis_master1_tlast,
output  [33:0]      axis_master1_tuser,//{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                      //   function number  , vf number , vf active spill_cpl_data }

input               user_rcvd_np_ready,
output [5:0]        core_avl_np_cnt,
input               user_rcvd_p_ready,
output [5:0]        core_avl_p_cnt,

//**********************************************************************
//axis slave 0 interface
output              axis_slave0_tready,
input               axis_slave0_tvalid,
input   [255:0]     axis_slave0_tdata,
input               axis_slave0_tlast,
input   [5:0]       axis_slave0_tuser,//{bad eot , function number  , vf number , vf active}

//axis slave 1 interface
output              axis_slave1_tready,
input               axis_slave1_tvalid,
input   [255:0]     axis_slave1_tdata,
input               axis_slave1_tlast,
input   [5:0]       axis_slave1_tuser,

//axis slave 2 interface
output              axis_slave2_tready,
input               axis_slave2_tvalid,
input   [255:0]     axis_slave2_tdata,
input               axis_slave2_tlast,
input   [5:0]       axis_slave2_tuser,

//apb interface
input                   apb_clk     ,
input                   apb_rst_n   ,
input                   apb_sel     ,
input           [ 3:0]  apb_strb    ,
input           [31:0]  apb_addr    ,
input           [31:0]  apb_wdata   ,
input                   apb_ce      ,
input                   apb_we      ,
output  wire            apb_rdy     ,
output  wire    [31:0]  apb_rdata   ,

input                   tx_rst_done ,

output              pm_xtlh_block_tlp      //ask about the processing latency
);

parameter GPHY_TP = 0;
parameter MEM_TP  =0;

// Retry buffer external RAM interface
wire      [135-1:0] xdlh_retryram_data;

// Retry SOT buffer
// ---------------------------------------------------------------------
// RADM Queues
// ---------------------------------------------------------------------

//**********************************************************************
//add for RAM TEST
wire  [10 -1:0]     xdlh_retryram_addr;
wire                xdlh_retryram_we;
wire                xdlh_retryram_en;
wire  [135-1:0]     retryram_xdlh_data;

wire                pnp_ram_rd_en;
wire  [9:0]         pnp_ram_rd_addr;
wire  [134:0]       pnp_ram_rd_data;

wire [9:0]          pnp_ram_wr_addr;
wire [134:0]        pnp_ram_wr_data;
wire                pnp_ram_wr_en;

reg                 tph_ram_wr_en;
reg [7:0]           tph_ram_wr_addr;
reg [1:0]           tph_ram_wr_byte_en;
reg [15:0]          tph_ram_wr_data;

wire                tph_ram_wr_en_core;
wire [1:0]          tph_ram_wr_byte_en_core;
wire [15:0]         tph_ram_wr_data_core;
//tph st table
wire                tph_rd_data_valid;
wire [15:0]         tph_ram_rd_data;
wire                tph_ram_func_active;
wire  [2:0]         tph_ram_func_number;

wire  [33:0]        axis_master1_tuser_i;

wire  [4:0]         tph_ram_addr;
wire  [48:0]        mac_phy_txdeemph_i;
reg   [47:0]        phy_mac_local_tx_pset_coef_i;
reg   [7:0]         phy_mac_local_tx_coef_valid_i;
reg   [48:0]        mac_phy_txdeemph_i_d1;
reg   [48:0]        mac_phy_txdeemph_i_d2;
reg   [7:0]         phy_mac_local_tx_coef_valid_d1;
reg   [7:0]         phy_mac_local_tx_coef_valid_d2;

//wire  [1:0]         mac_phy_rate_i;
//reg   [1:0]         ram_test_mode_n_sync;

//
wire                        app_ltssm_enable      ;
wire                        s_tx_rst_done         ;
reg                         cfg_init_start        ;

wire                        init_dbi_cs           ;
wire                        init_dbi_cs2          ;
wire    [31:0]              init_dbi_addr         ;
wire    [31:0]              init_dbi_din          ;
wire    [3:0]               init_dbi_wr           ;
wire                        init_dbi_ro_wr_disable;
wire    [4-2:0]             init_dbi_vfunc_num    ;
wire                        init_dbi_vfunc_active ;
wire    [1-1:0]             init_dbi_func_num     ;
wire                        init_finish           ;

wire                        apb_dbi_cs           ;
wire                        apb_dbi_cs2          ;
wire    [31:0]              apb_dbi_addr         ;
wire    [31:0]              apb_dbi_din          ;
wire    [3:0]               apb_dbi_wr           ;
wire    [4-2:0]             apb_dbi_vfunc_num    ;
wire                        apb_dbi_vfunc_active ;
wire    [1-1:0]             apb_dbi_func_num     ;
wire                        apb_dbi_ro_wr_disable;

reg                         app_dbi_ro_wr_disable;      // Set dbi_ro_wr_en to 0, disable write to DBI_RO_WR_EN bit

reg    [31:0]               dbi_addr            ;
reg    [31:0]               dbi_din             ;
reg                         dbi_cs              ;
reg                         dbi_cs2             ;
reg    [3:0]                dbi_wr              ;
reg    [4-2:0]              dbi_vfunc_num       ;
reg                         dbi_vfunc_active    ;
reg    [1-1:0]              dbi_func_num        ;
wire                        lbc_dbi_ack         ;
wire   [31:0]               lbc_dbi_dout        ;

//seio
// START_IO:ELBI Signal Descriptions. EP Mode Only
// END_IO:ELBI Signal Descriptions.
wire  [1:0]                 sedo;
wire  [1:0]                 sedo_en;
wire  [1:0]                 sedi;
wire  [1:0]                 sedi_ack;

wire                        wake_core_out   ;
reg  [7:0]                  wake_shift    ;

wire power_up_rst_n;

assign power_up_rst_n = ~power_up_rst;
//rst sync
//always @ (posedge pclk_div2 or negedge power_up_rst_n)
//begin
//    if(!power_up_rst_n)
//        ram_test_mode_n_sync <= 2'b11;
//    else
//        ram_test_mode_n_sync <= {ram_test_mode_n_sync[0],ram_test_mode_n};
//end

//assign mac_phy_rate = ~ram_test_mode_n_sync[1] ? 2'b10 : mac_phy_rate_i;

always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(!phy_rst_n)
        mac_phy_txdeemph <= 144'b0;
    else
        mac_phy_txdeemph <= mac_phy_txdeemph_i_d2[48] ? {mac_phy_txdeemph_i[47:0],mac_phy_txdeemph_i_d1[47:0],mac_phy_txdeemph_i_d2[47:0]} : mac_phy_txdeemph;
end

always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(!phy_rst_n)
    begin
        phy_mac_local_tx_coef_valid_d1 <= 8'b0;
        phy_mac_local_tx_coef_valid_d2 <= 8'b0;
        mac_phy_txdeemph_i_d1          <= 49'b0;
        mac_phy_txdeemph_i_d2          <= 49'b0;
    end
    else
    begin
        phy_mac_local_tx_coef_valid_d1 <= phy_mac_local_tx_coef_valid ;
        phy_mac_local_tx_coef_valid_d2 <= phy_mac_local_tx_coef_valid_d1;
        mac_phy_txdeemph_i_d1          <= mac_phy_txdeemph_i;
        mac_phy_txdeemph_i_d2          <= mac_phy_txdeemph_i_d1;
    end
end
reg [143:0] phy_mac_local_tx_pset_coef_latch;
reg [143:0] phy_mac_local_tx_pset_coef_k;



always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(!phy_rst_n)
    begin
        phy_mac_local_tx_pset_coef_latch <= 144'b0;
    end
    else if(|phy_mac_local_tx_coef_valid)
    begin
        phy_mac_local_tx_pset_coef_latch <= phy_mac_local_tx_pset_coef;
    end
end
always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(!phy_rst_n)
    begin
        phy_mac_local_tx_pset_coef_i<= #GPHY_TP 48'b0;
        phy_mac_local_tx_coef_valid_i <=#GPHY_TP  8'b0;
    end
    else
    begin
        phy_mac_local_tx_coef_valid_i <= #GPHY_TP phy_mac_local_tx_coef_valid_d2;
        case({|phy_mac_local_tx_coef_valid_d2,|phy_mac_local_tx_coef_valid_d1,|phy_mac_local_tx_coef_valid})
            3'b001 : phy_mac_local_tx_pset_coef_i <= #GPHY_TP phy_mac_local_tx_pset_coef[47:0];
            3'b010 : phy_mac_local_tx_pset_coef_i <= #GPHY_TP phy_mac_local_tx_pset_coef_latch[95:48];
            3'b100 : phy_mac_local_tx_pset_coef_i <= #GPHY_TP phy_mac_local_tx_pset_coef_latch[143:96];
            default: phy_mac_local_tx_pset_coef_i <= #GPHY_TP 48'b0;
        endcase
    end
end

wire smlh_req_rst;
wire link_req_rst;

assign smlh_req_rst_not = ~smlh_req_rst;
assign link_req_rst_not = ~link_req_rst;
assign  axis_master1_tuser  = axis_master1_tuser_i;
wire  [5:0]                     cfg_num_vf_i;

assign cfg_num_vf = {13'b0,cfg_num_vf_i[5:3],13'b0,cfg_num_vf_i[2:0]};

//wake
always @(posedge user_clk or negedge user_rst_n)
begin
    if(!user_rst_n)
        wake_shift <= 8'd0;
    else
        wake_shift <= {wake_shift[6:0],wake_core_out};
end

assign wake = |wake_shift;

// SEIO begin
ips2t_pcie_seio_intf_v1_0 u_pcie_seio_pf0(
    .pclk_div2      (user_clk           ),
    .user_rst_n     (user_rst_n         ),

    .sedo_in        (sedo[0]            ),
    .sedo_en_in     (sedo_en[0]         ),
    .sedi           (sedi[0]            ),
    .sedi_ack       (sedi_ack[0]        )
);

ips2t_pcie_seio_intf_v1_0 u_pcie_seio_pf1(
    .pclk_div2      (user_clk           ),
    .user_rst_n     (user_rst_n         ),

    .sedo_in        (sedo[1]            ),
    .sedo_en_in     (sedo_en[1]         ),
    .sedi           (sedi[1]            ),
    .sedi_ack       (sedi_ack[1]        )
);

//********************************************************************
//              APB2DBI BASE_ADDR=0x0B00_0000         UNIT 12
//********************************************************************
ips2t_pcie_apb2dbi_v1_1 u_pcie_apb2dbi(
    .pclk_div2                      (apb_clk                    ),
    .apb_rst_n                      (apb_rst_n                  ),
    .p_sel                          (apb_sel                    ),
    .p_strb                         (apb_strb                   ),
    .p_addr                         (apb_addr                   ),
    .p_wdata                        (apb_wdata                  ),
    .p_ce                           (apb_ce                     ),
    .p_we                           (apb_we                     ),
    .p_rdy                          (apb_rdy                    ),
    .p_rdata                        (apb_rdata                  ),
    .dbi_addr                       (apb_dbi_addr               ),
    .dbi_din                        (apb_dbi_din                ),
    .dbi_cs                         (apb_dbi_cs                 ),
    .dbi_cs2                        (apb_dbi_cs2                ),
    .dbi_wr                         (apb_dbi_wr                 ),
    .dbi_vfunc_num                  (apb_dbi_vfunc_num          ),
    .dbi_vfunc_active               (apb_dbi_vfunc_active       ),
    .dbi_func_num                   (apb_dbi_func_num           ),
    .app_dbi_ro_wr_disable          (apb_dbi_ro_wr_disable      ),
    .lbc_dbi_ack                    (lbc_dbi_ack                ),
    .lbc_dbi_dout                   (lbc_dbi_dout               ),
    .dbi_halt                       (1'b0                       )       //need not this halt in this design
);

//********************************************************************
//              Configuration Register initialize
//********************************************************************
ips2t_pcie_cfg_init_v1_8 #(
    // PF0 Config Only
    .DEVICE_TYPE                      (DEVICE_TYPE                      ),  // EP-> 4'b0000; RC->4'b0100;
    .MULTI_EN                         (MULTI_EN                         ),
    .PF1_ENABLE                       (PF1_ENABLE                       ),
    .PCIE_CAP_RCB                     (PCIE_CAP_RCB                     ),
    .PCIE_CAP_CRS                     (PCIE_CAP_CRS                     ),
    .PCIE_CAP_ATOMIC_EN               (PCIE_CAP_ATOMIC_EN               ),
    .SCRAMBLE_DISABLE                 (SCRAMBLE_DISABLE                 ),
    .AUTO_LANE_FLIP_CTRL_EN           (AUTO_LANE_FLIP_CTRL_EN           ),
    .PCIE_CAP_HW_AUTO_SPEED_DISABLE   (PCIE_CAP_HW_AUTO_SPEED_DISABLE   ),
    .DO_DESKEW_FOR_SRIS               (DO_DESKEW_FOR_SRIS               ),
    .TPH_REQ_NEXT_PTR                 (TPH_REQ_NEXT_PTR                 ),
    .UPCONFIGURE_SUPPORT              (UPCONFIGURE_SUPPORT              ),
    .TARGET_LINK_SPEED                (TARGET_LINK_SPEED                ),
    .LINK_CAPABLE                     (LINK_CAPABLE                     ),  // 4-lanes
    .NUM_OF_LANES                     (NUM_OF_LANES                     ),
    // PF0 an PF1 Config Same value
    .MAX_LINK_WIDTH                   (MAX_LINK_WIDTH                   ),  // x4
    .MAX_LINK_SPEED                   (MAX_LINK_SPEED                   ),  // gen2
    .EXT_TAG_EN                       (EXT_TAG_EN                       ),
    .EXT_TAG_SUPP                     (EXT_TAG_SUPP                     ),
    .INT_DISABLE                      (INT_DISABLE                      ),
    // PF0 an PF1 Config Different value
    .PF0_DEVICE_ID                    (PF0_DEVICE_ID                    ),
    .PF0_SUBSYS_DEV_ID                (PF0_SUBSYS_DEV_ID                ),
    .PF0_VENDOR_ID                    (PF0_VENDOR_ID                    ),
    .PF0_SUBSYS_VENDOR_ID             (PF0_SUBSYS_VENDOR_ID             ),
    .PF0_BASE_CLASS_CODE              (PF0_BASE_CLASS_CODE              ),
    .PF0_SUBCLASS_CODE                (PF0_SUBCLASS_CODE                ),
    .PF0_PROGRAM_INTERFACE            (PF0_PROGRAM_INTERFACE            ),
    .PF0_REVISION_ID                  (PF0_REVISION_ID                  ),
    .PF0_MAX_PAYLOAD_SIZE             (PF0_MAX_PAYLOAD_SIZE             ),
    .PF0_INT_PIN                      (PF0_INT_PIN                      ),
    .PF0_MSI_64_BIT_ADDR_CAP          (PF0_MSI_64_BIT_ADDR_CAP          ),
    .PF0_MSI_MULTIPLE_MSG_CAP         (PF0_MSI_MULTIPLE_MSG_CAP         ),
    .PF0_MSI_ENABLE                   (PF0_MSI_ENABLE                   ),
    .PF0_MSI_CAP_NEXT_OFFSET          (PF0_MSI_CAP_NEXT_OFFSET          ),
    .PF0_CAP_POINTER                  (PF0_CAP_POINTER                  ),
    .PF0_PCIE_CAP_NEXT_PTR            (PF0_PCIE_CAP_NEXT_PTR            ),
    .PF0_BAR0_PREFETCH                (PF0_BAR0_PREFETCH                ),
    .PF0_BAR0_TYPE                    (PF0_BAR0_TYPE                    ),
    .PF0_BAR0_MEM_IO                  (PF0_BAR0_MEM_IO                  ),
    .PF0_BAR0_ENABLED                 (PF0_BAR0_ENABLED                 ),
    .PF0_BAR0_MASK                    (PF0_BAR0_MASK                    ),
    .PF0_BAR1_PREFETCH                (PF0_BAR1_PREFETCH                ),
    .PF0_BAR1_TYPE                    (PF0_BAR1_TYPE                    ),
    .PF0_BAR1_MEM_IO                  (PF0_BAR1_MEM_IO                  ),
    .PF0_BAR1_ENABLED                 (PF0_BAR1_ENABLED                 ),
    .PF0_BAR1_MASK                    (PF0_BAR1_MASK                    ),
    .PF0_BAR2_PREFETCH                (PF0_BAR2_PREFETCH                ),
    .PF0_BAR2_TYPE                    (PF0_BAR2_TYPE                    ),
    .PF0_BAR2_MEM_IO                  (PF0_BAR2_MEM_IO                  ),
    .PF0_BAR2_ENABLED                 (PF0_BAR2_ENABLED                 ),
    .PF0_BAR2_MASK                    (PF0_BAR2_MASK                    ),
    .PF0_BAR3_PREFETCH                (PF0_BAR3_PREFETCH                ),
    .PF0_BAR3_TYPE                    (PF0_BAR3_TYPE                    ),
    .PF0_BAR3_MEM_IO                  (PF0_BAR3_MEM_IO                  ),
    .PF0_BAR3_ENABLED                 (PF0_BAR3_ENABLED                 ),
    .PF0_BAR3_MASK                    (PF0_BAR3_MASK                    ),
    .PF0_BAR4_PREFETCH                (PF0_BAR4_PREFETCH                ),
    .PF0_BAR4_TYPE                    (PF0_BAR4_TYPE                    ),
    .PF0_BAR4_MEM_IO                  (PF0_BAR4_MEM_IO                  ),
    .PF0_BAR4_ENABLED                 (PF0_BAR4_ENABLED                 ),
    .PF0_BAR4_MASK                    (PF0_BAR4_MASK                    ),
    .PF0_BAR5_PREFETCH                (PF0_BAR5_PREFETCH                ),
    .PF0_BAR5_TYPE                    (PF0_BAR5_TYPE                    ),
    .PF0_BAR5_MEM_IO                  (PF0_BAR5_MEM_IO                  ),
    .PF0_BAR5_ENABLED                 (PF0_BAR5_ENABLED                 ),
    .PF0_BAR5_MASK                    (PF0_BAR5_MASK                    ),
    .PF0_ROM_BAR_ENABLE               (PF0_ROM_BAR_ENABLE               ),
    .PF0_ROM_BAR_ENABLED              (PF0_ROM_BAR_ENABLED              ),
    .PF0_ROM_MASK                     (PF0_ROM_MASK                     ),
    .PF0_ECRC_CHECK_EN                (PF0_ECRC_CHECK_EN                ),
    .PF0_ECRC_GEN_EN                  (PF0_ECRC_GEN_EN                  ),
    .PF0_PCI_MSIX_ENABLE              (PF0_PCI_MSIX_ENABLE              ),
    .PF0_PCI_FUNCTION_MASK            (PF0_PCI_FUNCTION_MASK            ),
    .PF0_PCI_MSIX_TABLE_SIZE          (PF0_PCI_MSIX_TABLE_SIZE          ),
    .PF0_PCI_MSIX_CAP_NEXT_OFFSET     (PF0_PCI_MSIX_CAP_NEXT_OFFSET     ),
    .PF0_PCI_MSIX_TABLE_OFFSET        (PF0_PCI_MSIX_TABLE_OFFSET        ),
    .PF0_PCI_MSIX_BIR                 (PF0_PCI_MSIX_BIR                 ),
    .PF0_PCI_MSIX_PBA_OFFSET          (PF0_PCI_MSIX_PBA_OFFSET          ),
    .PF0_PCI_MSIX_PBA_BIR             (PF0_PCI_MSIX_PBA_BIR             ),
    .PF0_AER_CAP_NEXT_OFFSET          (PF0_AER_CAP_NEXT_OFFSET          ),
    .PF0_RESBAR_BAR0_MAX_SUPP_SIZE    (PF0_RESBAR_BAR0_MAX_SUPP_SIZE    ),
    .PF0_RESBAR_BAR0_INIT_SIZE        (PF0_RESBAR_BAR0_INIT_SIZE        ),
    .PF0_RESBAR_BAR1_MAX_SUPP_SIZE    (PF0_RESBAR_BAR1_MAX_SUPP_SIZE    ),
    .PF0_RESBAR_BAR1_INIT_SIZE        (PF0_RESBAR_BAR1_INIT_SIZE        ),
    .PF0_RESBAR_BAR2_MAX_SUPP_SIZE    (PF0_RESBAR_BAR2_MAX_SUPP_SIZE    ),
    .PF0_RESBAR_BAR2_INIT_SIZE        (PF0_RESBAR_BAR2_INIT_SIZE        ),
    .PF1_DEVICE_ID                    (PF1_DEVICE_ID                    ),
    .PF1_SUBSYS_DEV_ID                (PF1_SUBSYS_DEV_ID                ),
    .PF1_VENDOR_ID                    (PF1_VENDOR_ID                    ),
    .PF1_SUBSYS_VENDOR_ID             (PF1_SUBSYS_VENDOR_ID             ),
    .PF1_BASE_CLASS_CODE              (PF1_BASE_CLASS_CODE              ),
    .PF1_SUBCLASS_CODE                (PF1_SUBCLASS_CODE                ),
    .PF1_PROGRAM_INTERFACE            (PF1_PROGRAM_INTERFACE            ),
    .PF1_REVISION_ID                  (PF1_REVISION_ID                  ),
    .PF1_MAX_PAYLOAD_SIZE             (PF1_MAX_PAYLOAD_SIZE             ),
    .PF1_INT_PIN                      (PF1_INT_PIN                      ),
    .PF1_MSI_64_BIT_ADDR_CAP          (PF1_MSI_64_BIT_ADDR_CAP          ),
    .PF1_MSI_MULTIPLE_MSG_CAP         (PF1_MSI_MULTIPLE_MSG_CAP         ),
    .PF1_MSI_ENABLE                   (PF1_MSI_ENABLE                   ),
    .PF1_MSI_CAP_NEXT_OFFSET          (PF1_MSI_CAP_NEXT_OFFSET          ),
    .PF1_CAP_POINTER                  (PF1_CAP_POINTER                  ),
    .PF1_PCIE_CAP_NEXT_PTR            (PF1_PCIE_CAP_NEXT_PTR            ),
    .PF1_BAR0_PREFETCH                (PF1_BAR0_PREFETCH                ),
    .PF1_BAR0_TYPE                    (PF1_BAR0_TYPE                    ),
    .PF1_BAR0_MEM_IO                  (PF1_BAR0_MEM_IO                  ),
    .PF1_BAR0_ENABLED                 (PF1_BAR0_ENABLED                 ),
    .PF1_BAR0_MASK                    (PF1_BAR0_MASK                    ),
    .PF1_BAR1_PREFETCH                (PF1_BAR1_PREFETCH                ),
    .PF1_BAR1_TYPE                    (PF1_BAR1_TYPE                    ),
    .PF1_BAR1_MEM_IO                  (PF1_BAR1_MEM_IO                  ),
    .PF1_BAR1_ENABLED                 (PF1_BAR1_ENABLED                 ),
    .PF1_BAR1_MASK                    (PF1_BAR1_MASK                    ),
    .PF1_BAR2_PREFETCH                (PF1_BAR2_PREFETCH                ),
    .PF1_BAR2_TYPE                    (PF1_BAR2_TYPE                    ),
    .PF1_BAR2_MEM_IO                  (PF1_BAR2_MEM_IO                  ),
    .PF1_BAR2_ENABLED                 (PF1_BAR2_ENABLED                 ),
    .PF1_BAR2_MASK                    (PF1_BAR2_MASK                    ),
    .PF1_BAR3_PREFETCH                (PF1_BAR3_PREFETCH                ),
    .PF1_BAR3_TYPE                    (PF1_BAR3_TYPE                    ),
    .PF1_BAR3_MEM_IO                  (PF1_BAR3_MEM_IO                  ),
    .PF1_BAR3_ENABLED                 (PF1_BAR3_ENABLED                 ),
    .PF1_BAR3_MASK                    (PF1_BAR3_MASK                    ),
    .PF1_BAR4_PREFETCH                (PF1_BAR4_PREFETCH                ),
    .PF1_BAR4_TYPE                    (PF1_BAR4_TYPE                    ),
    .PF1_BAR4_MEM_IO                  (PF1_BAR4_MEM_IO                  ),
    .PF1_BAR4_ENABLED                 (PF1_BAR4_ENABLED                 ),
    .PF1_BAR4_MASK                    (PF1_BAR4_MASK                    ),
    .PF1_BAR5_PREFETCH                (PF1_BAR5_PREFETCH                ),
    .PF1_BAR5_TYPE                    (PF1_BAR5_TYPE                    ),
    .PF1_BAR5_MEM_IO                  (PF1_BAR5_MEM_IO                  ),
    .PF1_BAR5_ENABLED                 (PF1_BAR5_ENABLED                 ),
    .PF1_BAR5_MASK                    (PF1_BAR5_MASK                    ),
    .PF1_ROM_BAR_ENABLE               (PF1_ROM_BAR_ENABLE               ),
    .PF1_ROM_BAR_ENABLED              (PF1_ROM_BAR_ENABLED              ),
    .PF1_ROM_MASK                     (PF1_ROM_MASK                     ),
    .PF1_ECRC_CHECK_EN                (PF1_ECRC_CHECK_EN                ),
    .PF1_ECRC_GEN_EN                  (PF1_ECRC_GEN_EN                  ),
    .PF1_PCI_MSIX_ENABLE              (PF1_PCI_MSIX_ENABLE              ),
    .PF1_PCI_FUNCTION_MASK            (PF1_PCI_FUNCTION_MASK            ),
    .PF1_PCI_MSIX_TABLE_SIZE          (PF1_PCI_MSIX_TABLE_SIZE          ),
    .PF1_PCI_MSIX_CAP_NEXT_OFFSET     (PF1_PCI_MSIX_CAP_NEXT_OFFSET     ),
    .PF1_PCI_MSIX_TABLE_OFFSET        (PF1_PCI_MSIX_TABLE_OFFSET        ),
    .PF1_PCI_MSIX_BIR                 (PF1_PCI_MSIX_BIR                 ),
    .PF1_PCI_MSIX_PBA_OFFSET          (PF1_PCI_MSIX_PBA_OFFSET          ),
    .PF1_PCI_MSIX_PBA_BIR             (PF1_PCI_MSIX_PBA_BIR             ),
    .PF1_AER_CAP_NEXT_OFFSET          (PF1_AER_CAP_NEXT_OFFSET          ),
    .PF1_RESBAR_BAR0_MAX_SUPP_SIZE    (PF1_RESBAR_BAR0_MAX_SUPP_SIZE    ),
    .PF1_RESBAR_BAR0_INIT_SIZE        (PF1_RESBAR_BAR0_INIT_SIZE        ),
    .PF1_RESBAR_BAR1_MAX_SUPP_SIZE    (PF1_RESBAR_BAR1_MAX_SUPP_SIZE    ),
    .PF1_RESBAR_BAR1_INIT_SIZE        (PF1_RESBAR_BAR1_INIT_SIZE        ),
    .PF1_RESBAR_BAR2_MAX_SUPP_SIZE    (PF1_RESBAR_BAR2_MAX_SUPP_SIZE    ),
    .PF1_RESBAR_BAR2_INIT_SIZE        (PF1_RESBAR_BAR2_INIT_SIZE        ),
    .PF0_SRIOV_EXT_CAP_NXT_OFFSET     (PF0_SRIOV_EXT_CAP_NXT_OFFSET     ),
    .PF0_SRIOV_EXT_CAP_VER            (PF0_SRIOV_EXT_CAP_VER            ),
    .PF0_SRIOV_INITIAL_VFS            (PF0_SRIOV_INITIAL_VFS            ),
    .PF0_SRIOV_VF_OFFSET              (PF0_SRIOV_VF_OFFSET              ),
    .PF0_SRIOV_VF_DEVICE_ID           (PF0_SRIOV_VF_DEVICE_ID           ),
    .PF0_SRIOV_VF_BAR0_PREFETCH       (PF0_SRIOV_VF_BAR0_PREFETCH       ),
    .PF0_SRIOV_VF_BAR0_TYPE           (PF0_SRIOV_VF_BAR0_TYPE           ),
    .PF0_SRIOV_VF_BAR0_MEM_IO         (PF0_SRIOV_VF_BAR0_MEM_IO         ),
    .PF0_SRIOV_VF_BAR0_ENABLED        (PF0_SRIOV_VF_BAR0_ENABLED        ),
    .PF0_SRIOV_VF_BAR0_MASK           (PF0_SRIOV_VF_BAR0_MASK           ),
    .PF0_SRIOV_VF_BAR1_PREFETCH       (PF0_SRIOV_VF_BAR1_PREFETCH       ),
    .PF0_SRIOV_VF_BAR1_TYPE           (PF0_SRIOV_VF_BAR1_TYPE           ),
    .PF0_SRIOV_VF_BAR1_MEM_IO         (PF0_SRIOV_VF_BAR1_MEM_IO         ),
    .PF0_SRIOV_VF_BAR1_ENABLED        (PF0_SRIOV_VF_BAR1_ENABLED        ),
    .PF0_SRIOV_VF_BAR1_MASK           (PF0_SRIOV_VF_BAR1_MASK           ),
    .PF0_SRIOV_VF_BAR2_PREFETCH       (PF0_SRIOV_VF_BAR2_PREFETCH       ),
    .PF0_SRIOV_VF_BAR2_TYPE           (PF0_SRIOV_VF_BAR2_TYPE           ),
    .PF0_SRIOV_VF_BAR2_MEM_IO         (PF0_SRIOV_VF_BAR2_MEM_IO         ),
    .PF0_SRIOV_VF_BAR2_ENABLED        (PF0_SRIOV_VF_BAR2_ENABLED        ),
    .PF0_SRIOV_VF_BAR2_MASK           (PF0_SRIOV_VF_BAR2_MASK           ),
    .PF0_SRIOV_VF_BAR3_PREFETCH       (PF0_SRIOV_VF_BAR3_PREFETCH       ),
    .PF0_SRIOV_VF_BAR3_TYPE           (PF0_SRIOV_VF_BAR3_TYPE           ),
    .PF0_SRIOV_VF_BAR3_MEM_IO         (PF0_SRIOV_VF_BAR3_MEM_IO         ),
    .PF0_SRIOV_VF_BAR3_ENABLED        (PF0_SRIOV_VF_BAR3_ENABLED        ),
    .PF0_SRIOV_VF_BAR3_MASK           (PF0_SRIOV_VF_BAR3_MASK           ),
    .PF0_SRIOV_VF_BAR4_PREFETCH       (PF0_SRIOV_VF_BAR4_PREFETCH       ),
    .PF0_SRIOV_VF_BAR4_TYPE           (PF0_SRIOV_VF_BAR4_TYPE           ),
    .PF0_SRIOV_VF_BAR4_MEM_IO         (PF0_SRIOV_VF_BAR4_MEM_IO         ),
    .PF0_SRIOV_VF_BAR4_ENABLED        (PF0_SRIOV_VF_BAR4_ENABLED        ),
    .PF0_SRIOV_VF_BAR4_MASK           (PF0_SRIOV_VF_BAR4_MASK           ),
    .PF0_SRIOV_VF_BAR5_PREFETCH       (PF0_SRIOV_VF_BAR5_PREFETCH       ),
    .PF0_SRIOV_VF_BAR5_TYPE           (PF0_SRIOV_VF_BAR5_TYPE           ),
    .PF0_SRIOV_VF_BAR5_MEM_IO         (PF0_SRIOV_VF_BAR5_MEM_IO         ),
    .PF0_SRIOV_VF_BAR5_ENABLED        (PF0_SRIOV_VF_BAR5_ENABLED        ),
    .PF0_SRIOV_VF_BAR5_MASK           (PF0_SRIOV_VF_BAR5_MASK           ),
    .PF0_SRIOV_MSI_64_BIT_ADDR_CAP    (PF0_SRIOV_MSI_64_BIT_ADDR_CAP    ),
    .PF0_SRIOV_MSI_MULTIPLE_MSG_CAP   (PF0_SRIOV_MSI_MULTIPLE_MSG_CAP   ),
    .PF0_SRIOV_MSI_ENABLE             (PF0_SRIOV_MSI_ENABLE             ),
    .PF0_SRIOV_MSI_CAP_NEXT_OFFSET    (PF0_SRIOV_MSI_CAP_NEXT_OFFSET    ),
    .PF1_SRIOV_EXT_CAP_NXT_OFFSET     (PF1_SRIOV_EXT_CAP_NXT_OFFSET     ),
    .PF1_SRIOV_EXT_CAP_VER            (PF1_SRIOV_EXT_CAP_VER            ),
    .PF1_SRIOV_INITIAL_VFS            (PF1_SRIOV_INITIAL_VFS            ),
    .PF1_SRIOV_VF_OFFSET              (PF1_SRIOV_VF_OFFSET              ),
    .PF1_SRIOV_VF_DEVICE_ID           (PF1_SRIOV_VF_DEVICE_ID           ),
    .PF1_SRIOV_VF_BAR0_PREFETCH       (PF1_SRIOV_VF_BAR0_PREFETCH       ),
    .PF1_SRIOV_VF_BAR0_TYPE           (PF1_SRIOV_VF_BAR0_TYPE           ),
    .PF1_SRIOV_VF_BAR0_MEM_IO         (PF1_SRIOV_VF_BAR0_MEM_IO         ),
    .PF1_SRIOV_VF_BAR0_ENABLED        (PF1_SRIOV_VF_BAR0_ENABLED        ),
    .PF1_SRIOV_VF_BAR0_MASK           (PF1_SRIOV_VF_BAR0_MASK           ),
    .PF1_SRIOV_VF_BAR1_PREFETCH       (PF1_SRIOV_VF_BAR1_PREFETCH       ),
    .PF1_SRIOV_VF_BAR1_TYPE           (PF1_SRIOV_VF_BAR1_TYPE           ),
    .PF1_SRIOV_VF_BAR1_MEM_IO         (PF1_SRIOV_VF_BAR1_MEM_IO         ),
    .PF1_SRIOV_VF_BAR1_ENABLED        (PF1_SRIOV_VF_BAR1_ENABLED        ),
    .PF1_SRIOV_VF_BAR1_MASK           (PF1_SRIOV_VF_BAR1_MASK           ),
    .PF1_SRIOV_VF_BAR2_PREFETCH       (PF1_SRIOV_VF_BAR2_PREFETCH       ),
    .PF1_SRIOV_VF_BAR2_TYPE           (PF1_SRIOV_VF_BAR2_TYPE           ),
    .PF1_SRIOV_VF_BAR2_MEM_IO         (PF1_SRIOV_VF_BAR2_MEM_IO         ),
    .PF1_SRIOV_VF_BAR2_ENABLED        (PF1_SRIOV_VF_BAR2_ENABLED        ),
    .PF1_SRIOV_VF_BAR2_MASK           (PF1_SRIOV_VF_BAR2_MASK           ),
    .PF1_SRIOV_VF_BAR3_PREFETCH       (PF1_SRIOV_VF_BAR3_PREFETCH       ),
    .PF1_SRIOV_VF_BAR3_TYPE           (PF1_SRIOV_VF_BAR3_TYPE           ),
    .PF1_SRIOV_VF_BAR3_MEM_IO         (PF1_SRIOV_VF_BAR3_MEM_IO         ),
    .PF1_SRIOV_VF_BAR3_ENABLED        (PF1_SRIOV_VF_BAR3_ENABLED        ),
    .PF1_SRIOV_VF_BAR3_MASK           (PF1_SRIOV_VF_BAR3_MASK           ),
    .PF1_SRIOV_VF_BAR4_PREFETCH       (PF1_SRIOV_VF_BAR4_PREFETCH       ),
    .PF1_SRIOV_VF_BAR4_TYPE           (PF1_SRIOV_VF_BAR4_TYPE           ),
    .PF1_SRIOV_VF_BAR4_MEM_IO         (PF1_SRIOV_VF_BAR4_MEM_IO         ),
    .PF1_SRIOV_VF_BAR4_ENABLED        (PF1_SRIOV_VF_BAR4_ENABLED        ),
    .PF1_SRIOV_VF_BAR4_MASK           (PF1_SRIOV_VF_BAR4_MASK           ),
    .PF1_SRIOV_VF_BAR5_PREFETCH       (PF1_SRIOV_VF_BAR5_PREFETCH       ),
    .PF1_SRIOV_VF_BAR5_TYPE           (PF1_SRIOV_VF_BAR5_TYPE           ),
    .PF1_SRIOV_VF_BAR5_MEM_IO         (PF1_SRIOV_VF_BAR5_MEM_IO         ),
    .PF1_SRIOV_VF_BAR5_ENABLED        (PF1_SRIOV_VF_BAR5_ENABLED        ),
    .PF1_SRIOV_VF_BAR5_MASK           (PF1_SRIOV_VF_BAR5_MASK           ),
    .PF1_SRIOV_MSI_64_BIT_ADDR_CAP    (PF1_SRIOV_MSI_64_BIT_ADDR_CAP    ),
    .PF1_SRIOV_MSI_MULTIPLE_MSG_CAP   (PF1_SRIOV_MSI_MULTIPLE_MSG_CAP   ),
    .PF1_SRIOV_MSI_ENABLE             (PF1_SRIOV_MSI_ENABLE             ),
    .PF1_SRIOV_MSI_CAP_NEXT_OFFSET    (PF1_SRIOV_MSI_CAP_NEXT_OFFSET    )
) U_CFG_INIT
(
    .clk                              (user_clk              ),
    .rst_n                            (user_rst_n            ),
    .start                            (cfg_init_start        ),
    .dbi_ack                          (lbc_dbi_ack           ),
    .dbi_cs                           (init_dbi_cs           ),
    .dbi_cs2                          (init_dbi_cs2          ),
    .dbi_addr                         (init_dbi_addr         ),
    .dbi_din                          (init_dbi_din          ),
    .dbi_wr                           (init_dbi_wr           ),
    .dbi_ro_wr_disable                (init_dbi_ro_wr_disable),
    .dbi_vfunc_num                    (init_dbi_vfunc_num    ),
    .dbi_vfunc_active                 (init_dbi_vfunc_active ),
    .dbi_func_num                     (init_dbi_func_num     ),
    .init_finish                      (init_finish           )
);

ips2t_pcie_sync_v1_0  tx_rst_done_sync (.clk(user_clk),.rst_n(user_rst_n),.sig_async(tx_rst_done),.sig_synced(s_tx_rst_done));

//lock init start
always @(posedge user_clk or negedge user_rst_n)
begin
    if(!user_rst_n)
        cfg_init_start <= 1'b0;
    else if(s_tx_rst_done)
        cfg_init_start <= 1'b1;
end

always @(*) begin
    if (!init_finish) begin
        dbi_addr              = init_dbi_addr               ;
        dbi_din               = init_dbi_din                ;
        dbi_cs                = init_dbi_cs                 ;
        dbi_cs2               = init_dbi_cs2                ;
        dbi_wr                = init_dbi_wr                 ;
        dbi_vfunc_num         = init_dbi_vfunc_num          ;
        dbi_vfunc_active      = init_dbi_vfunc_active       ;
        dbi_func_num          = init_dbi_func_num           ;
        app_dbi_ro_wr_disable = init_dbi_ro_wr_disable      ;
    end
    else begin
        dbi_addr              = apb_dbi_addr                 ;
        dbi_din               = apb_dbi_din                  ;
        dbi_cs                = apb_dbi_cs                   ;
        dbi_cs2               = apb_dbi_cs2                  ;
        dbi_wr                = apb_dbi_wr                   ;
        dbi_vfunc_num         = apb_dbi_vfunc_num            ;
        dbi_vfunc_active      = apb_dbi_vfunc_active         ;
        dbi_func_num          = apb_dbi_func_num             ;
        app_dbi_ro_wr_disable = apb_dbi_ro_wr_disable        ;
    end
end

assign app_ltssm_enable = init_finish;


GTP_PCIEGEN3
#(
.PF1_ENABLE                         (PF1_ENABLE           ),
.FLT_SHORT_TLP                      (FLT_SHORT_TLP        ),
.APP_DEV_NUM                        (APP_DEV_NUM          ),
.APP_BUS_NUM                        (APP_BUS_NUM          ),
.DEBUG_INFO_SEL                     (DEBUG_INFO_SEL       ),
.DYN_DEBUG_SEL_EN                   (DYN_DEBUG_SEL_EN     ),
.GRS_EN                             ("FALSE"              ),
.VF_ER_REPORT_EN                    (VF_ER_REPORT_EN      ),
.ATOMIC_DISABLE                     (ATOMIC_DISABLE       ),
.VC_DISABLE                         (VC_DISABLE           ),
.SRIOV_DISABLE                      (SRIOV_DISABLE        ),
.BAR_RESIZABLE                      (BAR_RESIZABLE        ),
.NUM_OF_RBARS                       (NUM_OF_RBARS         ),
.MSI_PVM_DISABLE                    (MSI_PVM_DISABLE      ),
.BAR_MASK_WRITABLE                  (BAR_MASK_WRITABLE    )
)U_GTP_PCIEGEN3(
///////////////////////////
/////PORT DECLARATIONS/////
///////////////////////////
//clk & rst
.PCLK                               (pclk                 ),
.PCLK_DIV2                          (pclk_div2            ),
.MEM_CLK                            (mem_clk              ),
.USER_CLK                           (user_clk             ),
.BUTTON_RST                         (button_rst           ),   //modify                     high active
.POWER_UP_RST                       (power_up_rst         ),   //modify                     high active
.PERST                              (perst                ),   //modify                     high active
.USER_RST_N                         (user_rst_n           ),
.TRAINING_RST_N                     (training_rst_n       ),
.APP_INIT_RST                       (app_init_rst         ),
.PHY_RST_N                          (phy_rst_n            ),
//system control
.DEVICE_TYPE                        (DEVICE_TYPE          ),
.RX_LANE_FLIP_EN                    (rx_lane_flip_en      ),
.TX_LANE_FLIP_EN                    (tx_lane_flip_en      ),
.APP_LTSSM_ENABLE                   (app_ltssm_enable     ),
.SMLH_LINK_UP                       (smlh_link_up         ),
.RDLH_LINK_UP                       (rdlh_link_up         ),
.APP_REQ_RETRY_EN                   (app_req_retry_en     ),
.SMLH_LTSSM_STATE                   (smlh_ltssm_state     ),
.CFG_2ND_RESET                      (cfg_2nd_reset        ),
.LINK_REQ_RST                       (link_req_rst         ),           //link_req_rst_not
.APP_PF_REQ_RETRY_EN                (app_pf_req_retry_en  ),
.CFG_VF_BME                         (cfg_vf_bme           ),
.APP_VF_REQ_RETRY_EN                (app_vf_req_retry_en  ),
.SMLH_REQ_RST                       (smlh_req_rst         ),           //smlh_req_rst_not
//**********************************************************************
//AXIS master0 interface
.AXIS_MASTER0_TDATA                 (axis_master0_tdata   ),
.AXIS_MASTER0_TKEEP                 (axis_master0_tkeep   ),
.AXIS_MASTER0_TLAST                 (axis_master0_tlast   ),
.AXIS_MASTER0_TUSER                 (axis_master0_tuser   ),
.AXIS_MASTER0_TVALID                (axis_master0_tvalid  ),
.AXIS_MASTER0_TREADY                (axis_master0_tready  ),
.USER_RCVD_NP_READY                 (user_rcvd_np_ready   ),
.CORE_AVL_NP_CNT                    (core_avl_np_cnt      ),
.USER_RCVD_P_READY                  (user_rcvd_p_ready    ),
.CORE_AVL_P_CNT                     (core_avl_p_cnt       ),
//AXIS master1 interface
.AXIS_MASTER1_TDATA                 (axis_master1_tdata   ),
.AXIS_MASTER1_TKEEP                 (axis_master1_tkeep   ),
.AXIS_MASTER1_TUSER                 (axis_master1_tuser_i ),
.AXIS_MASTER1_TVALID                (axis_master1_tvalid  ),
//**********************************************************************
//axis slave 0 interface
.AXIS_SLAVE0_TDATA                  (axis_slave0_tdata    ),
.AXIS_SLAVE0_TLAST                  (axis_slave0_tlast    ),
.AXIS_SLAVE0_TUSER                  (axis_slave0_tuser    ),
.AXIS_SLAVE0_TVALID                 (axis_slave0_tvalid   ),
.AXIS_SLAVE0_TREADY                 (axis_slave0_tready   ),

//axis slave 1 interface
.AXIS_SLAVE1_TDATA                  (axis_slave1_tdata     ),
.AXIS_SLAVE1_TLAST                  (axis_slave1_tlast     ),
.AXIS_SLAVE1_TUSER                  (axis_slave1_tuser     ),
.AXIS_SLAVE1_TVALID                 (axis_slave1_tvalid    ),
.AXIS_SLAVE1_TREADY                 (axis_slave1_tready    ),

//axis slave 2 interface
.AXIS_SLAVE2_TDATA                  (axis_slave2_tdata    ),
.AXIS_SLAVE2_TLAST                  (axis_slave2_tlast    ),
.AXIS_SLAVE2_TUSER                  (axis_slave2_tuser    ),
.AXIS_SLAVE2_TVALID                 (axis_slave2_tvalid   ),
.AXIS_SLAVE2_TREADY                 (axis_slave2_tready   ),
//**********************************************************************
//timeout interface
.RADM_CPL_TIMEOUT                   (radm_cpl_timeout             ),
.RADM_TIMEOUT_CPL_ATTR              (radm_timeout_cpl_attr        ),
.RADM_TIMEOUT_CPL_LEN               (radm_timeout_cpl_len         ),
.RADM_TIMEOUT_CPL_TAG               (radm_timeout_cpl_tag         ),
.RADM_TIMEOUT_CPL_TC                (radm_timeout_cpl_tc          ),
.RADM_TIMEOUT_FUNC_NUM              (radm_timeout_func_num        ),
.RADM_TIMEOUT_VFUNC_ACTIVE          (radm_timeout_vfunc_active    ),
.RADM_TIMEOUT_VFUNC_NUM             (radm_timeout_vfunc_num       ),
//**********************************************************************
// DBI interface
.APP_DBI_RO_WR_DISABLE              (app_dbi_ro_wr_disable    ),
.DBI_ADDR                           (dbi_addr                 ),
.DBI_CS                             (dbi_cs                   ),
.DBI_CS2                            (dbi_cs2                  ),
.DBI_DIN                            (dbi_din                  ),
.DBI_FUNC_NUM                       (dbi_func_num             ),
.DBI_VFUNC_ACTIVE                   (dbi_vfunc_active         ),
.DBI_VFUNC_NUM                      (dbi_vfunc_num            ),
.DBI_WR                             (dbi_wr                   ),
.LBC_DBI_ACK                        (lbc_dbi_ack              ),
.LBC_DBI_DOUT                       (lbc_dbi_dout             ),
//**********************************************************************
//ELBI to SEIO interface
.SEDI                               (sedi                     ),
.SEDI_ACK                           (sedi_ack                 ),
.SEDO                               (sedo                     ),
.SEDO_EN                            (sedo_en                  ),
//**********************************************************************
//legacy interrupt
.SYS_INT                            (sys_int                  ),
.CFG_INT_DISABLE                    (cfg_int_disable          ),
.INT_GRT                            (int_grt                  ),
//*********************************************************************
//msi
.CFG_MSI_PENDING                    (cfg_msi_pending          ),
.CFG_VF_MSI_PENDING                 (cfg_vf_msi_pending       ),
.VEN_MSI_FUNC_NUM                   (ven_msi_func_num         ),
.VEN_MSI_REQ                        (ven_msi_req              ),
.VEN_MSI_TC                         (ven_msi_tc               ),
.VEN_MSI_VECTOR                     (ven_msi_vector           ),
.VEN_MSI_VFUNC_ACTIVE               (ven_msi_vfunc_active     ),
.VEN_MSI_VFUNC_NUM                  (ven_msi_vfunc_num        ),
.CFG_MSI_EN                         (cfg_msi_en               ),
.CFG_MSI_MASK_UPDATE                (cfg_msi_mask_update      ),
.CFG_MULTI_MSI_EN                   (cfg_multi_msi_en         ),
.CFG_VF_MSI_EN                      (cfg_vf_msi_en            ),
.CFG_VF_MULTI_MSI_EN                (cfg_vf_multi_msi_en      ),
.VEN_MSI_GRANT                      (ven_msi_grant            ),
//***********************************************************************
// msi-x interface
.MSIX_ADDR                          (msix_addr                ),
.MSIX_DATA                          (msix_data                ),
.CFG_MSIX_EN                        (cfg_msix_en              ),
.CFG_MSIX_FUNC_MASK                 (cfg_msix_func_mask       ),
.CFG_VF_MSIX_EN                     (cfg_vf_msix_en           ),
.CFG_VF_MSIX_FUNC_MASK              (cfg_vf_msix_func_mask    ),
//**********************************************************************
//configuration signals
.CFG_BW_MGT_MSI                     (cfg_bw_mgt_msi            ),
.CFG_LINK_AUTO_BW_MSI               (cfg_link_auto_bw_msi      ),
.CFG_PME_MSI                        (cfg_pme_msi               ),
.CFG_BW_MGT_INT                     (cfg_bw_mgt_int            ),
.CFG_LINK_AUTO_BW_INT               (cfg_link_auto_bw_int      ),
.CFG_LINK_EQ_REQ_INT                (cfg_link_eq_req_int       ),
.CFG_PME_INT                        (cfg_pme_int               ),

.CFG_NF_ERR_RPT_EN                  (cfg_nf_err_rpt_en         ),
.CFG_NO_SNOOP_EN                    (cfg_no_snoop_en           ),
.CFG_OBFF_EN                        (cfg_obff_en               ),
.CFG_PBUS_DEV_NUM                   (cfg_pbus_dev_num          ),
.CFG_PBUS_NUM                       (cfg_pbus_num              ),
.CFG_MEM_SPACE_EN                   (cfg_mem_space_en          ),
.CFG_EXT_TAG_EN                     (cfg_ext_tag_en            ),
.CFG_F_ERR_RPT_EN                   (cfg_f_err_rpt_en          ),
.CFG_ARI_FWD_EN                     (cfg_ari_fwd_en            ),
.CFG_ATOMIC_EGRESS_BLOCK            (cfg_atomic_egress_block   ),
.CFG_ATOMIC_REQ_EN                  (cfg_atomic_req_en         ),
.CFG_BUS_MASTER_EN                  (cfg_bus_master_en         ),
.CFG_COR_ERR_RPT_EN                 (cfg_cor_err_rpt_en        ),
.CFG_CRS_SW_VIS_EN                  (cfg_crs_sw_vis_en         ),
.CFG_MAX_PAYLOAD_SIZE               (cfg_max_payload_size      ),
.CFG_MAX_RD_REQ_SIZE                (cfg_max_rd_req_size       ),
.CFG_VF_EN                          (cfg_vf_en                 ),
.CFG_TC_ENABLE                      (cfg_tc_enable             ),
.CFG_RCB                            (cfg_rcb                   ),
.CFG_REG_SERREN                     (cfg_reg_serren            ),
.CFG_RELAX_ORDER_EN                 (cfg_relax_order_en        ),
.RBAR_CTRL_UPDATE                   (rbar_ctrl_update          ),
//**********************************************************************
//power management
.APP_CLK_PM_EN                      (app_clk_pm_en               ),
.APPS_PM_VF_XMT_PME                 (apps_pm_vf_xmt_pme          ),
.APPS_PM_XMT_PME                    (apps_pm_xmt_pme             ),
.APPS_PM_XMT_TURNOFF                (apps_pm_xmt_turnoff         ),
.APP_UNLOCK_MSG                     (app_unlock_msg              ),
.AUX_PM_EN                          (aux_pm_en                   ),
.PM_DSTATE                          (pm_dstate                   ),
.PM_MASTER_STATE                    (pm_master_state             ),
.PM_PME_EN                          (pm_pme_en                   ),
.PM_SLAVE_STATE                     (pm_slave_state              ),
.PM_STATUS                          (pm_status                   ),
.PM_VF_DSTATE                       (pm_vf_dstate                ),
.PM_VF_PME_EN                       (pm_vf_pme_en                ),
.PM_VF_STATUS                       (pm_vf_status                ),
.PM_XTLH_BLOCK_TLP                  (pm_xtlh_block_tlp           ),
.APP_READY_ENTR_L23                 (app_ready_entr_l23          ),
.APP_REQ_ENTR_L1                    (app_req_entr_l1             ),
.APP_REQ_EXIT_L1                    (app_req_exit_l1             ),
.CFG_PWR_BUDGET_DATA_REG            (cfg_pwr_budget_data_reg     ),
.CFG_PWR_BUDGET_FUNC_NUM            (cfg_pwr_budget_func_num     ),
.CFG_PWR_BUDGET_VALID               (cfg_pwr_budget_valid        ),
.DPA_SUBSTATE_UPDATE                (dpa_substate_update         ),
.WAKE                               (wake_core_out               ),
.CFG_PWR_BUDGET_DATA_SEL_REG        (cfg_pwr_budget_data_sel_reg ),
.CFG_PWR_BUDGET_SEL                 (cfg_pwr_budget_sel          ),
.APP_XFER_PENDING                   (app_xfer_pending            ),
//**********************************************************************
//error handling
.APP_HDR_LOG                        (app_hdr_log                ),
.APP_HDR_VALID                      (app_hdr_valid              ),
.APP_ERR_ADVISORY                   (app_err_advisory           ),
.APP_ERR_BUS                        (app_err_bus                ),
.APP_ERR_FUNC_NUM                   (app_err_func_num           ),
.APP_ERR_VFUNC_ACTIVE               (app_err_vfunc_active       ),
.APP_ERR_VFUNC_NUM                  (app_err_vfunc_num          ),
.CFG_SEND_COR_ERR                   (cfg_send_cor_err           ),
.CFG_SEND_F_ERR                     (cfg_send_f_err             ),
.CFG_SEND_NF_ERR                    (cfg_send_nf_err            ),
.CFG_AER_RC_ERR_INT                 (cfg_aer_rc_err_int         ),
.CFG_AER_RC_ERR_MSI                 (cfg_aer_rc_err_msi         ),
.CFG_SYS_ERR_RC                     (cfg_sys_err_rc             ),
//**********************************************************************
//ltr
.APP_LTR_MSG_FUNC_NUM               (app_ltr_msg_func_num       ),
.APP_LTR_MSG_LATENCY                (app_ltr_msg_latency        ),
.APP_LTR_MSG_REQ                    (app_ltr_msg_req            ),
.APP_LTR_MSG_GRANT                  (app_ltr_msg_grant          ),
.CFG_LTR_M_EN                       (cfg_ltr_m_en               ),
.CFG_DISABLE_LTR_CLR_MSG            (cfg_disable_ltr_clr_msg    ),
//**********************************************************************
//flr interface
.APP_FLR_PF_DONE                    (app_flr_pf_done            ),
.APP_FLR_VF_DONE                    (app_flr_vf_done            ),
.CFG_FLR_PF_ACTIVE                  (cfg_flr_pf_active          ),
.CFG_FLR_VF_ACTIVE                  (cfg_flr_vf_active          ),
.CFG_START_VFI                      (cfg_start_vfi              ),
.CFG_NUM_VF                         (cfg_num_vf_i               ),
//**********************************************************************
//obff interface
.APP_OBFF_CPU_ACTIVE_MSG_REQ        (app_obff_cpu_active_msg_req  ),
.APP_OBFF_IDLE_MSG_REQ              (app_obff_idle_msg_req        ),
.APP_OBFF_OBFF_MSG_REQ              (app_obff_obff_msg_req        ),
.APP_OBFF_MSG_GRANT                 (app_obff_msg_grant           ),
//**********************************************************************
//MSG interface
.MSG_RCVD                           (msg_rcvd                   ),
.MSG_RCVD_DATA                      (msg_rcvd_data              ),
.MSG_RCVD_TYPE                      (msg_rcvd_type              ),
//**********************************************************************
//debug interface
.APP_RAS_DES_SD_HOLD_LTSSM          (app_ras_des_sd_hold_ltssm   ),
.DIAG_CTRL_BUS                      (diag_ctrl_bus               ),
.DYN_DEBUG_INFO_SEL                 (dyn_debug_info_sel          ),
.DEBUG_INFO_MUX                     (debug_info_mux              ),
//*********************************************************************
//misc
.CFG_IDO_CPL_EN                     (cfg_ido_cpl_en              ),
.CFG_IDO_REQ_EN                     (cfg_ido_req_en              ),
.XADM_CPLD_CDTS                     (xadm_cpld_cdts              ),
.XADM_CPLH_CDTS                     (xadm_cplh_cdts              ),
.XADM_NPD_CDTS                      (xadm_npd_cdts               ),
.XADM_NPH_CDTS                      (xadm_nph_cdts               ),
.XADM_PD_CDTS                       (xadm_pd_cdts                ),
.XADM_PH_CDTS                       (xadm_ph_cdts                ),
.RADM_Q_NOT_EMPTY                   (radm_q_not_empty            ),
.RADM_QOVERFLOW                     (radm_qoverflow              ),
//**********************************************************************
// PIPE INTERFACE
.PHY_MAC_DIRFEEDBACK                (phy_mac_dirfeedback         ),
.PHY_MAC_FOMFEEDBACK                (phy_mac_fomfeedback         ),
.PHY_MAC_LOCALFS                    (phy_mac_localfs             ),
.PHY_MAC_LOCALLF                    (phy_mac_locallf             ),
.PHY_MAC_LOCAL_TX_COEF_VALID        (phy_mac_local_tx_coef_valid_i),
.PHY_MAC_LOCAL_TX_PSET_COEF         (phy_mac_local_tx_pset_coef_i),           //144bit -> 48bit
.PHY_MAC_PHYSTATUS                  (phy_mac_phystatus           ),
.PHY_MAC_RXDATA                     (phy_mac_rxdata              ),
.PHY_MAC_RXDATAK                    (phy_mac_rxdatak             ),
.PHY_MAC_RXDATAVALID                (phy_mac_rxdatavalid         ),
.PHY_MAC_RXELECIDLE                 (phy_mac_rxelecidle          ),
.PHY_MAC_RXSTARTBLOCK               (phy_mac_rxstartblock        ),
.PHY_MAC_RXSTATUS                   (phy_mac_rxstatus            ),
.PHY_MAC_RXSYNCHEADER               (phy_mac_rxsyncheader        ),
.PHY_MAC_RXVALID                    (phy_mac_rxvalid             ),
.MAC_PHY_BLOCKALIGNCONTROL          (mac_phy_blockaligncontrol   ),
.MAC_PHY_DIRCHANGE                  (mac_phy_dirchange           ),
.MAC_PHY_FS                         (mac_phy_fs                  ),
.MAC_PHY_GETLOCAL_PSET_COEF         (mac_phy_getlocal_pset_coef  ),
.MAC_PHY_INVALID_REQ                (mac_phy_invalid_req         ),
.MAC_PHY_LF                         (mac_phy_lf                  ),
.MAC_PHY_LOCAL_PSET_INDEX           (mac_phy_local_pset_index    ),
.MAC_PHY_POWERDOWN                  (mac_phy_powerdown           ),
.MAC_PHY_RATE                       (mac_phy_rate                ),
.MAC_PHY_RXEQEVAL                   (mac_phy_rxeqeval            ),
.MAC_PHY_RXEQINPROGRESS             (mac_phy_rxeqinprogress      ),
.MAC_PHY_RXPOLARITY                 (mac_phy_rxpolarity          ),
.MAC_PHY_RXPRESETHINT               (mac_phy_rxpresethint        ),
.MAC_PHY_TXCOMPLIANCE               (mac_phy_txcompliance        ),
.MAC_PHY_TXDATA                     (mac_phy_txdata              ),
.MAC_PHY_TXDATAK                    (mac_phy_txdatak             ),
.MAC_PHY_TXDATAVALID                (mac_phy_txdatavalid         ),
.MAC_PHY_TXDEEMPH                   (mac_phy_txdeemph_i          ), //144bit -> 49bit
.MAC_PHY_TXDETECTRX_LOOPBACK        (mac_phy_txdetectrx_loopback ),
.MAC_PHY_TXELECIDLE_H               (mac_phy_txelecidle_h        ),
.MAC_PHY_TXELECIDLE_L               (mac_phy_txelecidle_l        ),
.MAC_PHY_TXMARGIN                   (mac_phy_txmargin            ),
.MAC_PHY_TXSTARTBLOCK               (mac_phy_txstartblock        ),
.MAC_PHY_TXSWING                    (mac_phy_txswing             ),
.MAC_PHY_TXSYNCHEADER               (mac_phy_txsyncheader        ),
//**********************************************************************
// memory interface
.PNP_RAM_RD_ADDR                    (pnp_ram_rd_addr        ),
.PNP_RAM_RD_EN                      (pnp_ram_rd_en          ),
.PNP_RAM_WR_ADDR                    (pnp_ram_wr_addr        ),
.PNP_RAM_WR_DATA                    (pnp_ram_wr_data        ),
.PNP_RAM_WR_EN                      (pnp_ram_wr_en          ),
.PNP_RAM_RD_DATA                    (pnp_ram_rd_data        ),

.RETRYRAM_XDLH_DATA                 (retryram_xdlh_data     ),
.XDLH_RETRYRAM_ADDR                 (xdlh_retryram_addr     ),
.XDLH_RETRYRAM_DATA                 (xdlh_retryram_data     ),
.XDLH_RETRYRAM_EN                   (xdlh_retryram_en       ),
.XDLH_RETRYRAM_WE                   (xdlh_retryram_we       ),
//**********************************************************************
// TPH interface
.CFG_PF_TPH_ST_MODE                 (cfg_pf_tph_st_mode        ),
.CFG_TPH_REQ_EN                     (cfg_tph_req_en            ),
.CFG_VF_TPH_REQ_EN                  (cfg_vf_tph_req_en         ),
.CFG_VF_TPH_ST_MODE                 (cfg_vf_tph_st_mode        ),
.TPH_RD_DATA_VALID                  (tph_rd_data_valid         ),
.TPH_RAM_RD_DATA                    (tph_ram_rd_data           ),       //modify                     32bit -> 16bit
.TPH_RAM_ADDR                       (tph_ram_addr              ),
.TPH_RAM_FUNC_NUM                   (tph_ram_func_number       ),
.TPH_RAM_FUNC_ACTIVE                (tph_ram_func_active       ),         //add
.TPH_RAM_WR_BYTE_EN                 (tph_ram_wr_byte_en_core   ),         //modify                     4bit -> 2bit
.TPH_RAM_WR_DATA                    (tph_ram_wr_data_core      ),         //modify                     32bit -> 16bit
.TPH_RAM_WR_EN                      (tph_ram_wr_en_core        ),
//**********************************************************************
//RAM test
.RAM_TEST_EN                        (1'b0                      ),
.RAM_TEST_ADDRH                     (1'b0                      ),
.RETRY_TEST_DATA_EN                 (1'b0                      ),
.RAM_TEST_MODE_N                    (1'b1                      )
);

reg [1:0] cfg_flr_pf_active_d1;
reg [5:0] cfg_flr_vf_active_d1;
wire pf0_initial_start_p;
wire pf1_initial_start_p;
wire vf0_initial_start_p;
wire vf1_initial_start_p;
wire vf2_initial_start_p;
wire vf3_initial_start_p;
wire vf4_initial_start_p;
wire vf5_initial_start_p;
wire vf0_in_pf0;
wire vf1_in_pf0;
wire vf2_in_pf0;
wire vf3_in_pf0;
wire vf4_in_pf0;
wire vf5_in_pf0;
wire vf0_in_pf1;
wire vf1_in_pf1;
wire vf2_in_pf1;
wire vf3_in_pf1;
wire vf4_in_pf1;
wire vf5_in_pf1;

reg pf0_initial_done_p;
reg pf1_initial_done_p;
reg vf0_initial_done_p;
reg vf1_initial_done_p;
reg vf2_initial_done_p;
reg vf3_initial_done_p;
reg vf4_initial_done_p;
reg vf5_initial_done_p;

wire  pf0_initial_en;
wire  pf1_initial_en;
wire  vf0_initial_en;
wire  vf1_initial_en;
wire  vf2_initial_en;
wire  vf3_initial_en;
wire  vf4_initial_en;
wire  vf5_initial_en;

reg  pf0_initial_en_r;
reg  pf1_initial_en_r;
reg  vf0_initial_en_r;
reg  vf1_initial_en_r;
reg  vf2_initial_en_r;
reg  vf3_initial_en_r;
reg  vf4_initial_en_r;
reg  vf5_initial_en_r;

reg [5:0] vf_in_pf0;
reg [5:0] vf_in_pf1;

reg       initial_en;
reg [3:0] curr_state_r;

reg [3:0] curr_state;
reg [3:0] next_state;
reg [7:0] flr_initial_done;

reg core_rst_div2_n;
reg core_rst_div2_n_d1;
reg clear_st_table;
reg clear_st_table_r;
wire rst_clr_st_table;
reg  [4:0] flr_wr_addr;


//debug only

//wire [2:0] app_pf0_vf_num = 3;
//wire [2:0] app_pf1_vf_num = 3;

//debug end
//************************************************************
//----------------------------------TPH logic processing
//************************************************************
localparam NORMAL_ACC = 4'd0;
localparam PF0_INIT   = 4'd1;
localparam PF1_INIT   = 4'd2;
localparam VF0_INIT   = 4'd3;
localparam VF1_INIT   = 4'd4;
localparam VF2_INIT   = 4'd5;
localparam VF3_INIT   = 4'd6;
localparam VF4_INIT   = 4'd7;
localparam VF5_INIT   = 4'd8;

always @ (posedge pclk_div2 or negedge user_rst_n)
begin
    if(~user_rst_n)
    begin
        core_rst_div2_n_d1 <= 1'b0;
        core_rst_div2_n    <= 1'b0;
    end
    else
    begin
        core_rst_div2_n_d1 <= 1'b1;
        core_rst_div2_n    <= core_rst_div2_n_d1;
    end
end

always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
    begin
        clear_st_table <= 1'b1;
        clear_st_table_r <= 1'b1;
    end
    else
    begin
        clear_st_table <= 1'b0;
        clear_st_table_r <= clear_st_table;
    end
end
assign   rst_clr_st_table =  ~clear_st_table  & clear_st_table_r;

integer i;
generate
always @ (*)
begin:VF_IN_PF
    for(i=0;i<6;i=i+1)
        if(i<app_pf0_vf_num)
        begin
            vf_in_pf0[i] = 1;
            vf_in_pf1[i] = 0;
        end
        else if((app_pf0_vf_num <= i ) & (i < (app_pf0_vf_num + app_pf1_vf_num)))
        begin
            vf_in_pf0[i] = 0;
            vf_in_pf1[i] = 1;
        end
        else
         begin
            vf_in_pf0[i] = 0;
            vf_in_pf1[i] = 0;
        end
end
endgenerate

assign {vf5_in_pf0,vf4_in_pf0,vf3_in_pf0,vf2_in_pf0,vf1_in_pf0,vf0_in_pf0} = vf_in_pf0;
assign {vf5_in_pf1,vf4_in_pf1,vf3_in_pf1,vf2_in_pf1,vf1_in_pf1,vf0_in_pf1} = vf_in_pf1;


//tph st table need initial to 0 when flr
 assign pf0_initial_start_p = cfg_flr_pf_active[0] &  ~cfg_flr_pf_active_d1[0]; //clear pf0 when flr pf0,pulse
 assign pf1_initial_start_p = cfg_flr_pf_active[1] &  ~cfg_flr_pf_active_d1[1]; // clear pf1 when flr pf1.pulse
 assign vf0_initial_start_p = cfg_flr_vf_active[0] &  ~cfg_flr_vf_active_d1[0]   | vf0_in_pf0 & pf0_initial_start_p | vf0_in_pf1 & pf1_initial_start_p ;//clear vf0 when flr vf0 or (flr pf0 & vf0 belong to pf0) or (flr pf1 & vf0 belong to pf1)
 assign vf1_initial_start_p = cfg_flr_vf_active[1] &  ~cfg_flr_vf_active_d1[1]   | vf1_in_pf0 & pf0_initial_start_p | vf1_in_pf1 & pf1_initial_start_p ;//clear vf1 when flr vf1 or (flr pf0 & vf1 belong to pf0) or (flr pf1 & vf1 belong to pf1)
 assign vf2_initial_start_p = cfg_flr_vf_active[2] &  ~cfg_flr_vf_active_d1[2]   | vf2_in_pf0 & pf0_initial_start_p | vf2_in_pf1 & pf1_initial_start_p ;//clear vf2 when flr vf2 or (flr pf0 & vf2 belong to pf0) or (flr pf1 & vf2 belong to pf1)
 assign vf3_initial_start_p = cfg_flr_vf_active[3] &  ~cfg_flr_vf_active_d1[3]   | vf3_in_pf0 & pf0_initial_start_p | vf3_in_pf1 & pf1_initial_start_p ;//clear vf3 when flr vf3 or (flr pf0 & vf3 belong to pf0) or (flr pf1 & vf3 belong to pf1)
 assign vf4_initial_start_p = cfg_flr_vf_active[4] &  ~cfg_flr_vf_active_d1[4]   | vf4_in_pf0 & pf0_initial_start_p | vf4_in_pf1 & pf1_initial_start_p ;//clear vf4 when flr vf4 or (flr pf0 & vf4 belong to pf0) or (flr pf1 & vf4 belong to pf1)
 assign vf5_initial_start_p = cfg_flr_vf_active[5] &  ~cfg_flr_vf_active_d1[5]   | vf5_in_pf0 & pf0_initial_start_p | vf5_in_pf1 & pf1_initial_start_p ;//clear vf5 when flr vf5 or (flr pf0 & vf5 belong to pf0) or (flr pf1 & vf5 belong to pf1)

 assign pf0_initial_en = (pf0_initial_start_p | rst_clr_st_table) ? 1'b1 : pf0_initial_done_p ? 1'b0 : pf0_initial_en_r; //assert initial en until initial done
 assign pf1_initial_en = (pf1_initial_start_p | rst_clr_st_table) ? 1'b1 : pf1_initial_done_p ? 1'b0 : pf1_initial_en_r;
 assign vf0_initial_en = (vf0_initial_start_p | rst_clr_st_table) ? 1'b1 : vf0_initial_done_p ? 1'b0 : vf0_initial_en_r;
 assign vf1_initial_en = (vf1_initial_start_p | rst_clr_st_table) ? 1'b1 : vf1_initial_done_p ? 1'b0 : vf1_initial_en_r;
 assign vf2_initial_en = (vf2_initial_start_p | rst_clr_st_table) ? 1'b1 : vf2_initial_done_p ? 1'b0 : vf2_initial_en_r;
 assign vf3_initial_en = (vf3_initial_start_p | rst_clr_st_table) ? 1'b1 : vf3_initial_done_p ? 1'b0 : vf3_initial_en_r;
 assign vf4_initial_en = (vf4_initial_start_p | rst_clr_st_table) ? 1'b1 : vf4_initial_done_p ? 1'b0 : vf4_initial_en_r;
 assign vf5_initial_en = (vf5_initial_start_p | rst_clr_st_table) ? 1'b1 : vf5_initial_done_p ? 1'b0 : vf5_initial_en_r;

always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
     if(~core_rst_div2_n)
     begin
      pf0_initial_en_r <= 1'b0;
      pf1_initial_en_r <= 1'b0;
      vf0_initial_en_r <= 1'b0;
      vf1_initial_en_r <= 1'b0;
      //vf2_initial_en_r <= 1'b0;
      //vf3_initial_en_r <= 1'b0;
      vf2_initial_en_r <= 1'b0;
      vf3_initial_en_r <= 1'b0;
      vf4_initial_en_r <= 1'b0;
      vf5_initial_en_r <= 1'b0;
      cfg_flr_pf_active_d1 <= 2'b0;
      cfg_flr_vf_active_d1 <= 6'b0;
    end
    else
    begin
      pf0_initial_en_r <= pf0_initial_en;
      pf1_initial_en_r <= pf1_initial_en;
      vf0_initial_en_r <= vf0_initial_en;
      vf1_initial_en_r <= vf1_initial_en;
      //vf2_initial_en_r <= vf2_initial_en;
      //vf3_initial_en_r <= vf3_initial_en;
      vf2_initial_en_r <= vf2_initial_en;
      vf3_initial_en_r <= vf3_initial_en;
      vf4_initial_en_r <= vf4_initial_en;
      vf5_initial_en_r <= vf5_initial_en;
      cfg_flr_pf_active_d1 <= cfg_flr_pf_active;
      cfg_flr_vf_active_d1 <= cfg_flr_vf_active;
    end
end
always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(!core_rst_div2_n)
        initial_en <= 1'b0;
    else
        initial_en <= |{pf0_initial_en,pf1_initial_en,vf0_initial_en,vf1_initial_en,vf2_initial_en,vf3_initial_en,vf4_initial_en,vf5_initial_en};
end

always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
        curr_state <= NORMAL_ACC;
    else
        curr_state <= next_state;
end

always @ (*)
begin
    case(curr_state)
        NORMAL_ACC,PF0_INIT:
        begin
            if(pf0_initial_en_r)
                next_state = PF0_INIT;
            else if(initial_en)
                next_state = PF1_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        PF1_INIT :
        begin
            if(pf1_initial_en_r)
                next_state = PF1_INIT;
            else if(initial_en)
                next_state = VF0_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        VF0_INIT :
        begin
            if(vf0_initial_en_r)
                next_state = VF0_INIT;
            else if(initial_en)
                next_state = VF1_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        VF1_INIT :
        begin
            if(vf1_initial_en_r)
                next_state = VF1_INIT;
            else if(initial_en)
                next_state = VF2_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        VF2_INIT :
        begin
            if(vf2_initial_en_r)
                next_state = VF2_INIT;
            else if(initial_en)
                next_state = VF3_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        VF3_INIT :
        begin
            if(vf3_initial_en_r)
                next_state = VF3_INIT;
            else if(initial_en)
                next_state = VF4_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        VF4_INIT :
        begin
            if(vf4_initial_en_r)
                next_state = VF4_INIT;
            else if(initial_en)
                next_state = VF5_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf5_initial_en_r)
            //    next_state = VF5_INIT;
            else
                next_state = NORMAL_ACC;
        end
        default : //VF5_INIT
        begin
            if(vf5_initial_en_r)
                next_state = VF5_INIT;
            else if(initial_en)
                next_state = PF0_INIT;
            //else if(pf0_initial_en_r)
            //    next_state = PF0_INIT;
            //else if(pf1_initial_en_r)
            //    next_state = PF1_INIT;
            //else if(vf0_initial_en_r)
            //    next_state = VF0_INIT;
            //else if(vf1_initial_en_r)
            //    next_state = VF1_INIT;
            //else if(vf2_initial_en_r)
            //    next_state = VF2_INIT;
            //else if(vf3_initial_en_r)
            //    next_state = VF3_INIT;
            //else if(vf4_initial_en_r)
            //    next_state = VF4_INIT;
            else
                next_state = NORMAL_ACC;
        end
     endcase
end

//assign {vf5_initial_done_p,vf4_initial_done_p,vf3_initial_done_p,vf2_initial_done_p,
//        vf1_initial_done_p,vf0_initial_done_p,pf1_initial_done_p,pf0_initial_done_p} = flr_initial_done;
always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
        {vf5_initial_done_p,vf4_initial_done_p,vf3_initial_done_p,vf2_initial_done_p,
         vf1_initial_done_p,vf0_initial_done_p,pf1_initial_done_p,pf0_initial_done_p}  <= 8'b0;
    else
        {vf5_initial_done_p,vf4_initial_done_p,vf3_initial_done_p,vf2_initial_done_p,
         vf1_initial_done_p,vf0_initial_done_p,pf1_initial_done_p,pf0_initial_done_p} <= flr_initial_done;
end

always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
        curr_state_r  <= 4'b0;
    else
        curr_state_r  <= curr_state ;
end
always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
        flr_wr_addr  <= 5'b0;
    else if(curr_state_r != curr_state || |flr_initial_done)
        flr_wr_addr  <= 5'b0;
    else
        flr_wr_addr  <= flr_wr_addr + 5'b1;
end

always @ (*)
begin
    flr_initial_done = 8'b0;
   case(curr_state)
    NORMAL_ACC:
    begin
         tph_ram_wr_en = tph_ram_wr_en_core;
         tph_ram_wr_addr = {tph_ram_func_number,tph_ram_addr};
         tph_ram_wr_byte_en = tph_ram_wr_byte_en_core;
         tph_ram_wr_data =  tph_ram_wr_data_core;
    end
    PF0_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd0,flr_wr_addr};
         flr_initial_done = {7'b0,&flr_wr_addr};
    end
    PF1_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd1,flr_wr_addr};
         flr_initial_done = {6'b0,&flr_wr_addr,1'b0};
    end
    VF0_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd2,flr_wr_addr};
         flr_initial_done = {5'b0,&flr_wr_addr,2'b0};
    end
    VF1_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd3,flr_wr_addr};
         flr_initial_done = {4'b0,&flr_wr_addr,3'b0};
    end
    VF2_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd4,flr_wr_addr};
         flr_initial_done = {3'b0,&flr_wr_addr,4'b0};
    end
    VF3_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd5,flr_wr_addr};
         flr_initial_done = {2'b0,&flr_wr_addr,5'b0};
    end
    VF4_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd6,flr_wr_addr};
         flr_initial_done = {1'b0,&flr_wr_addr,6'b0};
    end
    VF5_INIT:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b11;
         tph_ram_wr_en  = 1'b1;
         tph_ram_wr_addr = {3'd7,flr_wr_addr};
         flr_initial_done = {&flr_wr_addr,7'b0};
    end
   default:
    begin
         tph_ram_wr_data  = 16'b0;
         tph_ram_wr_byte_en = 2'b0;
         tph_ram_wr_en  = 1'b0;
         tph_ram_wr_addr = 8'b0;
         flr_initial_done = 8'b0;
    end
  endcase
end

reg  tph_rd_data_valid_r1;
reg  tph_rd_data_valid_r2;

always @ (posedge pclk_div2 or negedge core_rst_div2_n)
begin
    if(~core_rst_div2_n)
    begin
        tph_rd_data_valid_r1  <= 1'b0;
        tph_rd_data_valid_r2  <= 1'b0;
    end
    else
    begin
        tph_rd_data_valid_r1  <= tph_ram_func_active & ~tph_ram_wr_en_core;
        tph_rd_data_valid_r2  <= tph_rd_data_valid_r1;
    end

end

assign #MEM_TP tph_rd_data_valid =  tph_rd_data_valid_r2 | tph_ram_wr_en_core ;

wire [134:0] retryram_xdlh_data_i;
wire [15:0] tph_ram_rd_data_i;
wire [134:0] pnp_ram_rd_data_i;

assign #MEM_TP retryram_xdlh_data = retryram_xdlh_data_i;
assign #MEM_TP tph_ram_rd_data    = tph_ram_rd_data_i;
assign #MEM_TP pnp_ram_rd_data    = pnp_ram_rd_data_i;
transmit_retry_ram pcie3_iip_exretry_rams(
  .addr         (xdlh_retryram_addr),
  .wr_data      (xdlh_retryram_data),
  .wr_en        (xdlh_retryram_we),
  .rd_data      (retryram_xdlh_data_i),
  .clk          (mem_clk),
  .rst          (1'b0)
);

tph_st_ram pcie3_iip_tph_rams(
  .addr         (tph_ram_wr_addr),
  .wr_data      (tph_ram_wr_data),
  .wr_en        (tph_ram_wr_en),
  .rd_data      (tph_ram_rd_data_i),
  .clk          (pclk_div2),
  .wr_byte_en   (tph_ram_wr_byte_en),
  .rst          (1'b0)
);


data_rcv_ram pcie3_iip_exrcvdata_rams(
  .wr_addr      (pnp_ram_wr_addr),
  .rd_addr      (pnp_ram_rd_addr),
  .wr_data      (pnp_ram_wr_data),
  .wr_en        (pnp_ram_wr_en),
  .rd_data      (pnp_ram_rd_data_i),

  .wr_clk       (mem_clk),
  .rd_clk       (mem_clk),
  .rd_rst       (1'b0),
  .wr_rst       (1'b0)
);

endmodule
