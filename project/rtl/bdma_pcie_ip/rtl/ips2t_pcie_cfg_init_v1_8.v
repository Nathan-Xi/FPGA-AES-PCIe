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

module ips2t_pcie_cfg_init_v1_8 #(
    parameter DEVICE_TYPE                       = 4'b000        ,  // EP-> 4'b0000; RC->4'b0100;
    // PF0 Config Only
    parameter PF1_ENABLE                        = "FALSE"       ,  // FALSE, TRUE
    parameter MULTI_EN                          = 1'b0          ,
    parameter PCIE_CAP_RCB                      = 1'b1          ,
    parameter PCIE_CAP_CRS                      = 1'b0          ,
    parameter PCIE_CAP_ATOMIC_EN                = 1'b0          ,
    parameter SCRAMBLE_DISABLE                  = 1'b0          ,
    parameter AUTO_LANE_FLIP_CTRL_EN            = 1'b1          ,
    parameter PCIE_CAP_HW_AUTO_SPEED_DISABLE    = 1'b0          ,
    parameter DO_DESKEW_FOR_SRIS                = 1'b1          ,
    parameter TPH_REQ_NEXT_PTR                  = 12'h0         ,
    parameter UPCONFIGURE_SUPPORT               = 1'b1          ,
    parameter TARGET_LINK_SPEED                 = 4'h1          ,
    parameter LINK_CAPABLE                      = 6'b00_0111    ,  // 4-lanes
    parameter NUM_OF_LANES                      = 5'b0_0001     ,
    // PF0 and PF1 Config Same value
    parameter MAX_LINK_WIDTH                    = 6'b00_0100    ,  // x4
    parameter MAX_LINK_SPEED                    = 4'b0010       ,  // gen2
    parameter EXT_TAG_EN                        = 1'b1          ,
    parameter EXT_TAG_SUPP                      = 1'b1          ,
    parameter INT_DISABLE                       = 1'b1          ,
    parameter GEN3_EQ_PSET_REQ_VEC              = 16'h0000      ,  // use preset hint from dsp
    // PF0 and PF1 Config Different value
    // PF0
    parameter PF0_DEVICE_ID                     = 16'h0755      ,
    parameter PF0_SUBSYS_DEV_ID                 = 16'h0000      ,
    parameter PF0_VENDOR_ID                     = 16'h0755      ,
    parameter PF0_SUBSYS_VENDOR_ID              = 16'h0000      ,
    parameter PF0_BASE_CLASS_CODE               = 8'h05         ,
    parameter PF0_SUBCLASS_CODE                 = 8'h80         ,
    parameter PF0_PROGRAM_INTERFACE             = 8'h00         ,
    parameter PF0_REVISION_ID                   = 8'h00         ,
    parameter PF0_MAX_PAYLOAD_SIZE              = 3'b001        ,  // 1024-bytes
    parameter PF0_INT_PIN                       = 8'h0          ,
    parameter PF0_MSI_64_BIT_ADDR_CAP           = 1'b1          ,
    parameter PF0_MSI_MULTIPLE_MSG_CAP          = 3'b101        ,
    parameter PF0_MSI_ENABLE                    = 1'b0          ,
    parameter PF0_MSI_CAP_NEXT_OFFSET           = 8'h70         ,
    parameter PF0_CAP_POINTER                   = 8'h50         ,
    parameter PF0_PCIE_CAP_NEXT_PTR             = 8'hB0         ,
    parameter PF0_BAR0_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR0_TYPE                     = 2'b0          ,
    parameter PF0_BAR0_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR0_ENABLED                  = 1'b1          ,
    parameter PF0_BAR0_MASK                     = 31'h0000_0fff ,
    parameter PF0_BAR1_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR1_TYPE                     = 2'b0          ,
    parameter PF0_BAR1_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR1_ENABLED                  = 1'b1          ,
    parameter PF0_BAR1_MASK                     = 31'h0000_07ff ,
    parameter PF0_BAR2_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR2_TYPE                     = 2'b10         ,
    parameter PF0_BAR2_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR2_ENABLED                  = 1'b1          ,
    parameter PF0_BAR2_MASK                     = 31'h0000_0fff ,
    parameter PF0_BAR3_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR3_TYPE                     = 2'b0          ,
    parameter PF0_BAR3_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR3_ENABLED                  = 1'b0          ,
    parameter PF0_BAR3_MASK                     = 31'd0         ,
    parameter PF0_BAR4_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR4_TYPE                     = 2'b0          ,
    parameter PF0_BAR4_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR4_ENABLED                  = 1'b0          ,
    parameter PF0_BAR4_MASK                     = 31'd0         ,
    parameter PF0_BAR5_PREFETCH                 = 1'b0          ,
    parameter PF0_BAR5_TYPE                     = 2'b0          ,
    parameter PF0_BAR5_MEM_IO                   = 1'b0          ,
    parameter PF0_BAR5_ENABLED                  = 1'b0          ,
    parameter PF0_BAR5_MASK                     = 31'd0         ,
    parameter PF0_ROM_BAR_ENABLE                = 1'b0          ,
    parameter PF0_ROM_BAR_ENABLED               = 1'd0          ,
    parameter PF0_ROM_MASK                      = 31'd0         ,
    parameter PF0_ECRC_CHECK_EN                 = 1'b1          ,
    parameter PF0_ECRC_GEN_EN                   = 1'b1          ,
    parameter PF0_PCI_MSIX_ENABLE               = 1'b0          ,
    parameter PF0_PCI_FUNCTION_MASK             = 1'b0          ,
    parameter PF0_PCI_MSIX_TABLE_SIZE           = 11'h0         ,
    parameter PF0_PCI_MSIX_CAP_NEXT_OFFSET      = 8'h0          ,
    parameter PF0_PCI_MSIX_TABLE_OFFSET         = 29'h0         ,
    parameter PF0_PCI_MSIX_BIR                  = 3'h0          ,
    parameter PF0_PCI_MSIX_PBA_OFFSET           = 29'h0         ,
    parameter PF0_PCI_MSIX_PBA_BIR              = 3'h0          ,
    parameter PF0_AER_CAP_NEXT_OFFSET           = 12'h0         ,
    parameter PF0_RESBAR_BAR0_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF0_RESBAR_BAR0_INIT_SIZE         = 5'h13         ,
    parameter PF0_RESBAR_BAR1_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF0_RESBAR_BAR1_INIT_SIZE         = 5'h13         ,
    parameter PF0_RESBAR_BAR2_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF0_RESBAR_BAR2_INIT_SIZE         = 5'hb          ,
    // PF1
    parameter PF1_DEVICE_ID                     = 16'h0755      ,
    parameter PF1_SUBSYS_DEV_ID                 = 16'h0000      ,
    parameter PF1_VENDOR_ID                     = 16'h0755      ,
    parameter PF1_SUBSYS_VENDOR_ID              = 16'h0000      ,
    parameter PF1_BASE_CLASS_CODE               = 8'h05         ,
    parameter PF1_SUBCLASS_CODE                 = 8'h80         ,
    parameter PF1_PROGRAM_INTERFACE             = 8'h00         ,
    parameter PF1_REVISION_ID                   = 8'h00         ,
    parameter PF1_MAX_PAYLOAD_SIZE              = 3'b011        ,  // 1024-bytes
    parameter PF1_INT_PIN                       = 8'h0          ,
    parameter PF1_MSI_64_BIT_ADDR_CAP           = 1'b1          ,
    parameter PF1_MSI_MULTIPLE_MSG_CAP          = 3'b101        ,
    parameter PF1_MSI_ENABLE                    = 1'b1          ,
    parameter PF1_MSI_CAP_NEXT_OFFSET           = 8'h70         ,
    parameter PF1_CAP_POINTER                   = 8'h50         ,
    parameter PF1_PCIE_CAP_NEXT_PTR             = 8'hB0         ,
    parameter PF1_BAR0_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR0_TYPE                     = 2'b0          ,
    parameter PF1_BAR0_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR0_ENABLED                  = 1'b1          ,
    parameter PF1_BAR0_MASK                     = 31'h0000_0fff ,
    parameter PF1_BAR1_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR1_TYPE                     = 2'b0          ,
    parameter PF1_BAR1_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR1_ENABLED                  = 1'b1          ,
    parameter PF1_BAR1_MASK                     = 31'h0000_07ff ,
    parameter PF1_BAR2_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR2_TYPE                     = 2'b10         ,
    parameter PF1_BAR2_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR2_ENABLED                  = 1'b1          ,
    parameter PF1_BAR2_MASK                     = 31'h0000_0fff ,
    parameter PF1_BAR3_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR3_TYPE                     = 2'b0          ,
    parameter PF1_BAR3_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR3_ENABLED                  = 1'b0          ,
    parameter PF1_BAR3_MASK                     = 31'd0         ,
    parameter PF1_BAR4_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR4_TYPE                     = 2'b0          ,
    parameter PF1_BAR4_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR4_ENABLED                  = 1'b0          ,
    parameter PF1_BAR4_MASK                     = 31'd0         ,
    parameter PF1_BAR5_PREFETCH                 = 1'b0          ,
    parameter PF1_BAR5_TYPE                     = 2'b0          ,
    parameter PF1_BAR5_MEM_IO                   = 1'b0          ,
    parameter PF1_BAR5_ENABLED                  = 1'b0          ,
    parameter PF1_BAR5_MASK                     = 31'd0         ,
    parameter PF1_ROM_BAR_ENABLE                = 1'b0          ,
    parameter PF1_ROM_BAR_ENABLED               = 1'd0          ,
    parameter PF1_ROM_MASK                      = 31'd0         ,
    parameter PF1_ECRC_CHECK_EN                 = 1'b1          ,
    parameter PF1_ECRC_GEN_EN                   = 1'b1          ,
    parameter PF1_PCI_MSIX_ENABLE               = 1'b0          ,
    parameter PF1_PCI_FUNCTION_MASK             = 1'b0          ,
    parameter PF1_PCI_MSIX_TABLE_SIZE           = 11'h0         ,
    parameter PF1_PCI_MSIX_CAP_NEXT_OFFSET      = 8'h0          ,
    parameter PF1_PCI_MSIX_TABLE_OFFSET         = 29'h0         ,
    parameter PF1_PCI_MSIX_BIR                  = 3'h0          ,
    parameter PF1_PCI_MSIX_PBA_OFFSET           = 29'h0         ,
    parameter PF1_PCI_MSIX_PBA_BIR              = 3'h0          ,
    parameter PF1_AER_CAP_NEXT_OFFSET           = 12'h0         ,
    parameter PF1_RESBAR_BAR0_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF1_RESBAR_BAR0_INIT_SIZE         = 5'h13         ,
    parameter PF1_RESBAR_BAR1_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF1_RESBAR_BAR1_INIT_SIZE         = 5'h13         ,
    parameter PF1_RESBAR_BAR2_MAX_SUPP_SIZE     = 20'hf_ffff    ,
    parameter PF1_RESBAR_BAR2_INIT_SIZE         = 5'hb          ,
    //SRIOV CAP
    parameter PF0_SRIOV_EXT_CAP_NXT_OFFSET      = 12'h0         ,
    parameter PF0_SRIOV_EXT_CAP_VER             = 4'h0          ,
    parameter PF0_SRIOV_INITIAL_VFS             = 16'h3         ,
    parameter PF0_SRIOV_VF_OFFSET               = 16'h0         ,
    parameter PF0_SRIOV_VF_DEVICE_ID            = 16'h0755      ,
    parameter PF0_SRIOV_VF_BAR0_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR0_TYPE            = 2'b0          ,
    parameter PF0_SRIOV_VF_BAR0_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR0_ENABLED         = 1'b1          ,
    parameter PF0_SRIOV_VF_BAR0_MASK            = 31'h0000_0fff ,
    parameter PF0_SRIOV_VF_BAR1_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR1_TYPE            = 2'b0          ,
    parameter PF0_SRIOV_VF_BAR1_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR1_ENABLED         = 1'b1          ,
    parameter PF0_SRIOV_VF_BAR1_MASK            = 31'h0000_07ff ,
    parameter PF0_SRIOV_VF_BAR2_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR2_TYPE            = 2'b10         ,
    parameter PF0_SRIOV_VF_BAR2_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR2_ENABLED         = 1'b1          ,
    parameter PF0_SRIOV_VF_BAR2_MASK            = 31'h0000_0fff ,
    parameter PF0_SRIOV_VF_BAR3_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR3_TYPE            = 2'b0          ,
    parameter PF0_SRIOV_VF_BAR3_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR3_ENABLED         = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR3_MASK            = 31'd0         ,
    parameter PF0_SRIOV_VF_BAR4_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR4_TYPE            = 2'b0          ,
    parameter PF0_SRIOV_VF_BAR4_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR4_ENABLED         = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR4_MASK            = 31'd0         ,
    parameter PF0_SRIOV_VF_BAR5_PREFETCH        = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR5_TYPE            = 2'b0          ,
    parameter PF0_SRIOV_VF_BAR5_MEM_IO          = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR5_ENABLED         = 1'b0          ,
    parameter PF0_SRIOV_VF_BAR5_MASK            = 31'd0         ,
    parameter PF0_SRIOV_MSI_64_BIT_ADDR_CAP     = 1'b1          ,
    parameter PF0_SRIOV_MSI_MULTIPLE_MSG_CAP    = 3'b101        ,
    parameter PF0_SRIOV_MSI_ENABLE              = 1'b0          ,
    parameter PF0_SRIOV_MSI_CAP_NEXT_OFFSET     = 8'h70         ,
    parameter PF1_SRIOV_EXT_CAP_NXT_OFFSET      = 12'h0         ,
    parameter PF1_SRIOV_EXT_CAP_VER             = 4'h0          ,
    parameter PF1_SRIOV_INITIAL_VFS             = 16'h3         ,
    parameter PF1_SRIOV_VF_OFFSET               = 16'h0         ,
    parameter PF1_SRIOV_VF_DEVICE_ID            = 16'h0755      ,
    parameter PF1_SRIOV_VF_BAR0_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR0_TYPE            = 2'b0          ,
    parameter PF1_SRIOV_VF_BAR0_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR0_ENABLED         = 1'b1          ,
    parameter PF1_SRIOV_VF_BAR0_MASK            = 31'h0000_0fff ,
    parameter PF1_SRIOV_VF_BAR1_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR1_TYPE            = 2'b0          ,
    parameter PF1_SRIOV_VF_BAR1_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR1_ENABLED         = 1'b1          ,
    parameter PF1_SRIOV_VF_BAR1_MASK            = 31'h0000_07ff ,
    parameter PF1_SRIOV_VF_BAR2_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR2_TYPE            = 2'b10         ,
    parameter PF1_SRIOV_VF_BAR2_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR2_ENABLED         = 1'b1          ,
    parameter PF1_SRIOV_VF_BAR2_MASK            = 31'h0000_0fff ,
    parameter PF1_SRIOV_VF_BAR3_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR3_TYPE            = 2'b0          ,
    parameter PF1_SRIOV_VF_BAR3_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR3_ENABLED         = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR3_MASK            = 31'd0         ,
    parameter PF1_SRIOV_VF_BAR4_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR4_TYPE            = 2'b0          ,
    parameter PF1_SRIOV_VF_BAR4_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR4_ENABLED         = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR4_MASK            = 31'd0         ,
    parameter PF1_SRIOV_VF_BAR5_PREFETCH        = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR5_TYPE            = 2'b0          ,
    parameter PF1_SRIOV_VF_BAR5_MEM_IO          = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR5_ENABLED         = 1'b0          ,
    parameter PF1_SRIOV_VF_BAR5_MASK            = 31'd0         ,
    parameter PF1_SRIOV_MSI_64_BIT_ADDR_CAP     = 1'b1          ,
    parameter PF1_SRIOV_MSI_MULTIPLE_MSG_CAP    = 3'b101        ,
    parameter PF1_SRIOV_MSI_ENABLE              = 1'b0          ,
    parameter PF1_SRIOV_MSI_CAP_NEXT_OFFSET     = 8'h70
)(
    input                       clk                 ,
    input                       rst_n               ,
    input                       start               ,
    input                       dbi_ack             ,
    output reg                  dbi_cs              ,
    output reg                  dbi_cs2             ,
    output reg  [31:0]          dbi_addr            ,
    output reg  [31:0]          dbi_din             ,
    output reg  [3:0]           dbi_wr              ,
    output reg                  dbi_ro_wr_disable   ,
    output reg  [4-2:0]         dbi_vfunc_num       ,
    output reg                  dbi_vfunc_active    ,
    output reg  [1-1:0]         dbi_func_num        ,
    output reg                  init_finish
);

// ROM Define
localparam ROM_CNT = (PF1_ENABLE=="TRUE") ? 10'd142 : 10'd77;
// PF1 Enable

wire [48:0] init_rom [ROM_CNT-1:0] /* synthesis syn_romstyle = "select_rom" */;
wire dbi_standby;

reg [9:0] rom_raddr;
//================================================
//  init parameter
//================================================
//------------------------------------------------
//  rom width = 49-bits
//  |--> [48] = 1-bits = dbi_func_num
//  |--> [47:44] = 4-bits = dbi_wr
//  |--> [43:32] = 12-bits = dbi_addr
//  |--> [31:0] = 32-bits = dbi_data
//------------------------------------------------
//
//----------------------
// offset 0XB(00) +0xC
//PF1_ENABLE[23] enable pf1
//----------------------
localparam [48:0] PF0_INI_0 =(DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0100, 12'h00c, 8'h0, MULTI_EN, 23'h0};
//----------------------
// offset 0xB(70)+0x10
//----------------------
localparam [48:0] PF0_INI_1 = (DEVICE_TYPE==3'b100) ? {1'b0, 4'b0001, 12'h080, 28'h0, PCIE_CAP_RCB , 3'h0} : {1'b0, 4'b0001, 12'h080, 28'h0, 1'b1 , 3'h0};
//----------------------
// offset 0xB(70)+0x1c
//----------------------
//rc
localparam [48:0] PF0_INI_2 = (DEVICE_TYPE==3'b100) ? {1'b0, 4'b0001, 12'h08c, 27'h0, PCIE_CAP_CRS, 4'h0} : {49'd0};
//----------------------
// offset 0xB(70)+0x28
//----------------------
// PCIE_CAP_ATOMIC_EN[6]
localparam [48:0] PF0_INI_3 = {1'b0, 4'b0001, 12'h098, 24'h0, 1'b0, PCIE_CAP_ATOMIC_EN, 2'b0 , 4'h0};
//----------------------
// offset 0xa0
//----------------------
//PCIE_CAP_HW_AUTO_SPEED_DISABLE @[5]
// TARGET_LINK_SPEED @[3:0]
localparam [48:0] PF0_INI_4 = {1'b0, 4'b0001, 12'h0a0, 26'd0, PCIE_CAP_HW_AUTO_SPEED_DISABLE, 1'b0, TARGET_LINK_SPEED};
//----------------------
// offset 0x708
//----------------------
// DO_DESKEW_FOR_SRIS @[23]
localparam [48:0] PF0_INI_5 = {1'b0, 4'b0100, 12'h708, 8'd0, DO_DESKEW_FOR_SRIS, 23'd0};
//----------------------
// offset=0x710
//----------------------
// link_capable     @[21:16]
// scramble_disable @[1]
localparam [48:0] PF0_INI_6 = {1'b0, 4'b0101, 12'h710, 10'h00, LINK_CAPABLE, 8'h0, 6'b0010_00, SCRAMBLE_DISABLE, 1'b0};
//----------------------
// offset=0x80c
//----------------------
// auto_lane_flip_ctrl_en @[16]
// num_of_lanes  @[12:8]
localparam [48:0] PF0_INI_7 = {1'b0, 4'b0110, 12'h80c, 15'h01, AUTO_LANE_FLIP_CTRL_EN, 3'h0, NUM_OF_LANES, 8'h00};
//----------------------
// offset 0x8c0
//----------------------
// UPCONFIGURE_SUPPORT [7] no use
localparam [48:0] PF0_INI_8 = {1'b0, 4'b0000, 12'h8c0, 24'h0, UPCONFIGURE_SUPPORT, 7'h0};
//----------------------
// B=0x00, offset=B+0x0, = 0x00
//----------------------
// vendor_id [15:0]
// device_id [31:16]
localparam [48:0] PF0_INI_9 = {1'b0, 4'b1111, 12'h000, PF0_DEVICE_ID, PF0_VENDOR_ID};
//----------------------
// B=0x00, offset=B+0x2c, = 0x2c
//----------------------
// subsys_dev_id    @[31:16]
// subsys_vendor_id @[15:0]
localparam [48:0] PF0_INI_10 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b1111, 12'h02c, PF0_SUBSYS_DEV_ID, PF0_SUBSYS_VENDOR_ID};
//----------------------
// B=0x70, offset=B+0x4, = 0x74
//----------------------
// EXT_TAG_SUPP @[5]
// max_payload_size[2:0]
localparam [48:0] PF0_INI_11 = {1'b0, 4'b0001, 12'h074, 26'b0, EXT_TAG_SUPP, 2'b0, PF0_MAX_PAYLOAD_SIZE};
//----------------------
// offset 0xB(70)+0x8
//----------------------
// EXT_TAG_EN @[8]
localparam [48:0] PF0_INI_12 = {1'b0, 4'b0010, 12'h078, 8'h0, 4'h1, 4'h0, 4'h2, 3'h0, EXT_TAG_EN, 4'h1, 4'h0};
//----------------------
// B=0x70, offset=B+0xc, = 0x7c
//----------------------
// max_link_width @[9:4]
// max_link_speed @[3:0]
localparam [48:0] PF0_INI_13 = {1'b0, 4'b0011, 12'h07c, 16'd0, 4'hf, 2'b10, MAX_LINK_WIDTH, MAX_LINK_SPEED};
//----------------------
// B=0x50, offset=B+0x0, = 0x50
//----------------------
// msi_64_bit_addr_cap @[23]
// msi_multiple_msg_cap @[19:17]
// msi_enable @[16]
// msi_cap_next_offset @[15:8]
localparam [48:0] PF0_INI_14 = {1'b0, 4'b1110, 12'h050, 8'd0, PF0_MSI_64_BIT_ADDR_CAP, 3'd0, PF0_MSI_MULTIPLE_MSG_CAP, PF0_MSI_ENABLE, PF0_MSI_CAP_NEXT_OFFSET, 8'd0};
//----------------------
// B=0x00, offset=B+0x4, = 0x4
//----------------------
// INT_DISABLE[10]
localparam [48:0] PF0_INI_15 = {1'b0, 4'b0010, 12'h004, 16'd0, 5'd0, INT_DISABLE, 10'd0};
//----------------------
// B=0x00, offset=B+0x8, = 0x8
//----------------------
// base_class_code  @[31:24]
// subclass_code    @[23:16]
// program_interface@[15:8]
// revision_id      @[7:0]
localparam [48:0] PF0_INI_16 = {1'b0, 4'b1111, 12'h008, PF0_BASE_CLASS_CODE, PF0_SUBCLASS_CODE, PF0_PROGRAM_INTERFACE, PF0_REVISION_ID};
//----------------------
// PF0 BAR Reset
//----------------------
// bar0 reset 0
localparam [48:0] PF0_INI_17 = {1'b0, 4'b0001, 12'h010, 32'd0};
localparam [48:0] PF0_INI_18 = {1'b0, 4'b1111, 12'h011, 32'd0};
// bar1 reset 0
localparam [48:0] PF0_INI_19 = {1'b0, 4'b0001, 12'h014, 32'd0};
localparam [48:0] PF0_INI_20 = {1'b0, 4'b1111, 12'h015, 32'd0};
// bar2 reset 0
localparam [48:0] PF0_INI_21 = {1'b0, 4'b0001, 12'h018, 32'd0};
localparam [48:0] PF0_INI_22 = {1'b0, 4'b1111, 12'h019, 32'd0};
// bar3 reset 0
localparam [48:0] PF0_INI_23 = {1'b0, 4'b0001, 12'h01c, 32'd0};
localparam [48:0] PF0_INI_24 = {1'b0, 4'b1111, 12'h01d, 32'd0};
// bar4 reset 0
localparam [48:0] PF0_INI_25 = {1'b0, 4'b0001, 12'h020, 32'd0};
localparam [48:0] PF0_INI_26 = {1'b0, 4'b1111, 12'h021, 32'd0};
// bar5 reset 0
localparam [48:0] PF0_INI_27 = {1'b0, 4'b0001, 12'h024, 32'd0};
localparam [48:0] PF0_INI_28 = {1'b0, 4'b1111, 12'h025, 32'd0};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// bar0_enabled @[0]
// bar0_mask    @[31:1]
localparam [48:0] PF0_INI_29 = {1'b0, 4'b1111, 12'h011, PF0_BAR0_MASK, PF0_BAR0_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// bar0_prefetch @[3]
// bar0_type     @[2:1]
// bar0_mem_io   @[0]
localparam [48:0] PF0_INI_30 = {1'b0, 4'b0001, 12'h010, 28'd0, PF0_BAR0_PREFETCH, PF0_BAR0_TYPE, PF0_BAR0_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// bar1_enabled @[0]
// bar1_mask    @[31:1]
localparam [48:0] PF0_INI_31 = {1'b0, 4'b1111, 12'h015, PF0_BAR1_MASK, PF0_BAR1_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// bar1_prefetch @[3]
// bar1_type     @[2:1]
// bar1_mem_io   @[0]
localparam [48:0] PF0_INI_32 = {1'b0, 4'b0001, 12'h014, 28'd0, PF0_BAR1_PREFETCH, PF0_BAR1_TYPE, PF0_BAR1_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR2_enabled @[0]
// BAR2_mask    @[31:1]
localparam [48:0] PF0_INI_33 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b1111, 12'h019, PF0_BAR2_MASK, PF0_BAR2_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR2_prefetch @[3]
// BAR2_type     @[2:1]
// BAR2_mem_io   @[0]
localparam [48:0] PF0_INI_34 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b0001, 12'h018, 28'd0, PF0_BAR2_PREFETCH, PF0_BAR2_TYPE, PF0_BAR2_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR3_enabled @[0]
// BAR3_mask    @[31:1]
localparam [48:0] PF0_INI_35 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b1111, 12'h01d, PF0_BAR3_MASK, PF0_BAR3_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR3_prefetch @[3]
// BAR3_type     @[2:1]
// BAR3_mem_io   @[0]
localparam [48:0] PF0_INI_36 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b0001, 12'h01c, 28'd0, PF0_BAR3_PREFETCH, PF0_BAR3_TYPE, PF0_BAR3_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR4_enabled @[0]
// BAR4_mask    @[31:1]
localparam [48:0] PF0_INI_37 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b1111, 12'h021, PF0_BAR4_MASK, PF0_BAR4_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR4_prefetch @[3]
// BAR4_type     @[2:1]
// BAR4_mem_io   @[0]
localparam [48:0] PF0_INI_38 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b0001, 12'h020, 28'd0, PF0_BAR4_PREFETCH, PF0_BAR4_TYPE, PF0_BAR4_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR5_enabled @[0]
// BAR5_mask    @[31:1]
localparam [48:0] PF0_INI_39 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b1111, 12'h025, PF0_BAR5_MASK, PF0_BAR5_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR5_prefetch @[3]
// BAR5_type     @[2:1]
// BAR5_mem_io   @[0]
localparam [48:0] PF0_INI_40 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b0, 4'b0001, 12'h024, 28'd0, PF0_BAR5_PREFETCH, PF0_BAR5_TYPE, PF0_BAR5_MEM_IO};
//----------------------
// B=0x00, offset=B+0x34, = 0x34
//----------------------
// cap_pointer @[7:0]
localparam [48:0] PF0_INI_41 = {1'b0, 4'b0001, 12'h034, 24'd0, PF0_CAP_POINTER};
//----------------------
// B=0x00,
// ep-> offset=B+0x30, = 0x30
// rc-> offset=B+0x38, = 0x38
//----------------------
// rom_bar_enable @[0]
localparam [48:0] PF0_INI_42 = (DEVICE_TYPE==3'b100) ? {1'b0, 4'b0001, 12'h038, 31'd0, PF0_ROM_BAR_ENABLE} : {1'b0, 4'b0001, 12'h030, 31'd0, PF0_ROM_BAR_ENABLE};
//----------------------
// B=0x00,
// ep-> offset=B+0x31, = 0x31
// rc-> offset=B+0x39, = 0x39
//----------------------
// rom_bar_enabled  @[0]
// rom_mask         @[31:1]
localparam [48:0] PF0_INI_43 = (DEVICE_TYPE==3'b100) ? {1'b0, 4'b1111, 12'h039, PF0_ROM_MASK, PF0_ROM_BAR_ENABLED} : {1'b0, 4'b1111, 12'h031, PF0_ROM_MASK, PF0_ROM_BAR_ENABLED};
//----------------------
// B=0x70, offset=B+0x0, = 0x70
//----------------------
// pcie_cap_next_ptr @[15:8]
localparam [48:0] PF0_INI_44 = {1'b0, 4'b0010, 12'h070, 16'd0, PF0_PCIE_CAP_NEXT_PTR, 8'd0};
//----------------------
// B=0x0, offset=B+0x3c, = 0x3c
//----------------------
// INT_PIN [15:8]
localparam [48:0] PF0_INI_45 = {1'd0, 4'b0010, 12'h03c, 16'd0, PF0_INT_PIN, 8'd0};
//----------------------
// offset 0xB(b0)+0x00
//----------------------
//PCI_MSIX_ENABLE           [31]
//PCI_FUNCTION_MASK         [30]
//PCI_MSIX_TABLE_SIZE       [26:16]
//PCI_MSIX_CAP_NEXT_OFFSET  [15:8]
localparam [48:0] PF0_INI_46 = {1'b0, 4'b1110, 12'h0b0, PF0_PCI_MSIX_ENABLE, PF0_PCI_FUNCTION_MASK, 3'h0, PF0_PCI_MSIX_TABLE_SIZE, PF0_PCI_MSIX_CAP_NEXT_OFFSET, 8'h0};
//----------------------
// offset 0xB(b0)+0x04
//----------------------
//PCI_MSIX_TABLE_OFFSET     [31:3]
//PCI_MSIX_BIR              [2:0]
localparam [48:0] PF0_INI_47 = {1'b0, 4'b1111, 12'h0b4, PF0_PCI_MSIX_TABLE_OFFSET, PF0_PCI_MSIX_BIR};
//----------------------
// offset 0xB(b0)+0x08
//----------------------
// PCI_MSIX_PBA_OFFSET      [31:3]
// PCI_MSIX_PBA_BIR         [2:0]
localparam [48:0] PF0_INI_48 = {1'b0, 4'b1111, 12'h0b8, PF0_PCI_MSIX_PBA_OFFSET, PF0_PCI_MSIX_PBA_BIR};
//----------------------
// offset 0x(100)+0x00
//----------------------
// AER_CAP_NEXT_OFFSET [31:20]
localparam [48:0] PF0_INI_49 = {1'b0, 4'b1100, 12'h100, PF0_AER_CAP_NEXT_OFFSET, 4'h2, 16'h0};
//----------------------
// offset 0xB+0x18
//----------------------
// ECRC_CHECK_EN    @[8]
// ECRC_GEN_EN      @[6]
localparam [48:0] PF0_INI_50 = {1'b0, 4'b0011, 12'h118, 16'd0, 7'd0, PF0_ECRC_CHECK_EN, 1'd1, PF0_ECRC_GEN_EN, 1'd1, 5'd0};
//----------------------
// offset 0x(158)+0x00
//----------------------
// TPH_REQ_NEXT_PTR [31:20]
localparam [48:0] PF0_INI_51 = {1'b0, 4'b0000, 12'h158, TPH_REQ_NEXT_PTR, 4'h1, 16'h0};
//----------------------
// offset 0x(2E4)+0x04
//----------------------
// RESBAR_BAR0_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF0_INI_52 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2E8, 8'h0,PF0_RESBAR_BAR0_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x08
//----------------------
// RESBAR_BAR0_INIT_SIZE [12:8]
// RESBAR_BAR0_INDEX
localparam [48:0] PF0_INI_53 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2EC, 19'h0,PF0_RESBAR_BAR0_INIT_SIZE, 8'h0};
//----------------------
// offset 0x(2E4)+0x0C
//----------------------
// RESBAR_BAR1_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF0_INI_54 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2F0, 8'h0,PF0_RESBAR_BAR1_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x10
//----------------------
// RESBAR_BAR1_INIT_SIZE [12:8]
localparam [48:0] PF0_INI_55 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2F4, 19'h0,PF0_RESBAR_BAR1_INIT_SIZE, 8'h0};
//----------------------
// offset 0x(2E4)+0x14
//----------------------
// RESBAR_BAR2_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF0_INI_56 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2F8, 8'h0,PF0_RESBAR_BAR2_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x18
//----------------------
// RESBAR_BAR2_INIT_SIZE [12:8]
localparam [48:0] PF0_INI_57 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b0, 4'b0000, 12'h2FC, 19'h0,PF0_RESBAR_BAR2_INIT_SIZE, 8'h0};
//----------------------
// offset 0x(700)+0x1a8
//----------------------
// GEN3_EQ_PSET_REQ_VEC [23:8]
localparam [48:0] PF0_INI_58 = {1'b0, 4'b0110, 12'h8a8, 8'h0, GEN3_EQ_PSET_REQ_VEC, 8'h0};
//---------------------------------------------------------------------------------------------------------------------------------
//  PF1 Init
//---------------------------------------------------------------------------------------------------------------------------------
//----------------------
// B=0x00, offset=B+0x0, = 0x00
//----------------------
// vendor_id [15:0]
// device_id [31:16]
localparam [48:0] PF1_INI_0 = {1'b1, 4'b1111, 12'h000, PF1_DEVICE_ID, PF1_VENDOR_ID};
//----------------------
// B=0x00, offset=B+0x2c, = 0x2c
//----------------------
// subsys_dev_id    @[31:16]
// subsys_vendor_id @[15:0]
localparam [48:0] PF1_INI_1 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b1111, 12'h02c, PF1_SUBSYS_DEV_ID, PF1_SUBSYS_VENDOR_ID};
//----------------------
// B=0x70, offset=B+0x4, = 0x74
//----------------------
// EXT_TAG_SUPP @[5]
// max_payload_size[2:0]
localparam [48:0] PF1_INI_2 = {1'b1, 4'b0001, 12'h074, 26'b0, EXT_TAG_SUPP, 2'b0, PF1_MAX_PAYLOAD_SIZE};
//----------------------
// offset 0xB(70)+0x8
//----------------------
// EXT_TAG_EN @[8]
localparam [48:0] PF1_INI_3 = {1'b1, 4'b0010, 12'h078, 8'h0, 4'h1, 4'h0, 4'h2, 3'h0, EXT_TAG_EN, 4'h1, 4'h0};
//----------------------
// B=0x70, offset=B+0xc, = 0x7c
//----------------------
// max_link_width @[9:4]
// max_link_speed @[3:0]
localparam [48:0] PF1_INI_4 = {1'b1, 4'b0011, 12'h07c, 16'd0, 4'hf, 2'b10, MAX_LINK_WIDTH, MAX_LINK_SPEED};
//----------------------
// B=0x50, offset=B+0x0, = 0x50
//----------------------
// msi_64_bit_addr_cap @[23]
// msi_multiple_msg_cap @[19:17]
// msi_enable @[16]
// msi_cap_next_offset @[15:8]
localparam [48:0] PF1_INI_5 = {1'b1, 4'b1110, 12'h050, 8'd0, PF1_MSI_64_BIT_ADDR_CAP, 3'd0, PF1_MSI_MULTIPLE_MSG_CAP, PF1_MSI_ENABLE, PF1_MSI_CAP_NEXT_OFFSET, 8'd0};
//----------------------
// B=0x00, offset=B+0x4, = 0x4
//----------------------
// INT_DISABLE[10]
localparam [48:0] PF1_INI_6 = {1'b1, 4'b0010, 12'h004, 16'd0, 5'd0, INT_DISABLE, 10'd0};
//----------------------
// B=0x00, offset=B+0x8, = 0x8
//----------------------
// base_class_code  @[31:24]
// subclass_code    @[23:16]
// program_interface@[15:8]
// revision_id      @[7:0]
localparam [48:0] PF1_INI_7 = {1'b1, 4'b1111, 12'h008, PF1_BASE_CLASS_CODE, PF1_SUBCLASS_CODE, PF1_PROGRAM_INTERFACE, PF1_REVISION_ID};
//----------------------
// PF1 BAR Reset
//----------------------
// bar0 reset 0
localparam [48:0] PF1_INI_8 = {1'b1, 4'b0001, 12'h010, 32'd0};
localparam [48:0] PF1_INI_9 = {1'b1, 4'b1111, 12'h011, 32'd0};
// bar1 reset 0
localparam [48:0] PF1_INI_10 = {1'b1, 4'b0001, 12'h014, 32'd0};
localparam [48:0] PF1_INI_11 = {1'b1, 4'b1111, 12'h015, 32'd0};
// bar2 reset 0
localparam [48:0] PF1_INI_12 = {1'b1, 4'b0001, 12'h018, 32'd0};
localparam [48:0] PF1_INI_13 = {1'b1, 4'b1111, 12'h019, 32'd0};
// bar3 reset 0
localparam [48:0] PF1_INI_14 = {1'b1, 4'b0001, 12'h01c, 32'd0};
localparam [48:0] PF1_INI_15 = {1'b1, 4'b1111, 12'h01d, 32'd0};
// bar4 reset 0
localparam [48:0] PF1_INI_16 = {1'b1, 4'b0001, 12'h020, 32'd0};
localparam [48:0] PF1_INI_17 = {1'b1, 4'b1111, 12'h021, 32'd0};
// bar5 reset 0
localparam [48:0] PF1_INI_18 = {1'b1, 4'b0001, 12'h024, 32'd0};
localparam [48:0] PF1_INI_19 = {1'b1, 4'b1111, 12'h025, 32'd0};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// bar0_enabled @[0]
// bar0_mask    @[31:1]
localparam [48:0] PF1_INI_20 = {1'b1, 4'b1111, 12'h011, PF1_BAR0_MASK, PF1_BAR0_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// bar0_prefetch @[3]
// bar0_type     @[2:1]
// bar0_mem_io   @[0]
localparam [48:0] PF1_INI_21 = {1'b1, 4'b0001, 12'h010, 28'd0, PF1_BAR0_PREFETCH, PF1_BAR0_TYPE, PF1_BAR0_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// bar1_enabled @[0]
// bar1_mask    @[31:1]
localparam [48:0] PF1_INI_22 = {1'b1, 4'b1111, 12'h015, PF1_BAR1_MASK, PF1_BAR1_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// bar1_prefetch @[3]
// bar1_type     @[2:1]
// bar1_mem_io   @[0]
localparam [48:0] PF1_INI_23 = {1'b1, 4'b0001, 12'h014, 28'd0, PF1_BAR1_PREFETCH, PF1_BAR1_TYPE, PF1_BAR1_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR2_enabled @[0]
// BAR2_mask    @[31:1]
localparam [48:0] PF1_INI_24 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b1111, 12'h019, PF1_BAR2_MASK, PF1_BAR2_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR2_prefetch @[3]
// BAR2_type     @[2:1]
// BAR2_mem_io   @[0]
localparam [48:0] PF1_INI_25 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b0001, 12'h018, 28'd0, PF1_BAR2_PREFETCH, PF1_BAR2_TYPE, PF1_BAR2_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR3_enabled @[0]
// BAR3_mask    @[31:1]
localparam [48:0] PF1_INI_26 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b1111, 12'h01d, PF1_BAR3_MASK, PF1_BAR3_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR3_prefetch @[3]
// BAR3_type     @[2:1]
// BAR3_mem_io   @[0]
localparam [48:0] PF1_INI_27 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b0001, 12'h01c, 28'd0, PF1_BAR3_PREFETCH, PF1_BAR3_TYPE, PF1_BAR3_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR4_enabled @[0]
// BAR4_mask    @[31:1]
localparam [48:0] PF1_INI_28 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b1111, 12'h021, PF1_BAR4_MASK, PF1_BAR4_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR4_prefetch @[3]
// BAR4_type     @[2:1]
// BAR4_mem_io   @[0]
localparam [48:0] PF1_INI_29 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b0001, 12'h020, 28'd0, PF1_BAR4_PREFETCH, PF1_BAR4_TYPE, PF1_BAR4_MEM_IO};
//----------------------
// B=0x00, offset=B+0x11, = 0x11
//----------------------
// BAR5_enabled @[0]
// BAR5_mask    @[31:1]
localparam [48:0] PF1_INI_30 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b1111, 12'h025, PF1_BAR5_MASK, PF1_BAR5_ENABLED};
//----------------------
// B=0x00, offset=B+0x10, = 0x10
//----------------------
// BAR5_prefetch @[3]
// BAR5_type     @[2:1]
// BAR5_mem_io   @[0]
localparam [48:0] PF1_INI_31 = (DEVICE_TYPE==3'b100) ? 49'd0 : {1'b1, 4'b0001, 12'h024, 28'd0, PF1_BAR5_PREFETCH, PF1_BAR5_TYPE, PF1_BAR5_MEM_IO};
//----------------------
// B=0x00, offset=B+0x34, = 0x34
//----------------------
// cap_pointer @[7:0]
localparam [48:0] PF1_INI_32 = {1'b1, 4'b0001, 12'h034, 24'd0, PF1_CAP_POINTER};
//----------------------
// B=0x00,
// ep-> offset=B+0x30, = 0x30
// rc-> offset=B+0x38, = 0x38
//----------------------
// rom_bar_enable @[0]
localparam [48:0] PF1_INI_33 = (DEVICE_TYPE==3'b100) ? {1'b1, 4'b0001, 12'h038, 31'd0, PF1_ROM_BAR_ENABLE} : {1'b1, 4'b0001, 12'h030, 31'd0, PF1_ROM_BAR_ENABLE};
//----------------------
// B=0x00,
// ep-> offset=B+0x31, = 0x31
// rc-> offset=B+0x39, = 0x39
//----------------------
// rom_bar_enabled  @[0]
// rom_mask         @[31:1]
localparam [48:0] PF1_INI_34 = (DEVICE_TYPE==3'b100) ? {1'b1, 4'b1111, 12'h039, PF1_ROM_MASK, PF1_ROM_BAR_ENABLED} : {1'b1, 4'b1111, 12'h031, PF1_ROM_MASK, PF1_ROM_BAR_ENABLED};
//----------------------
// B=0x70, offset=B+0x0, = 0x70
//----------------------
// pcie_cap_next_ptr @[15:8]
localparam [48:0] PF1_INI_35 = {1'b1, 4'b0010, 12'h070, 16'd0, PF1_PCIE_CAP_NEXT_PTR, 8'd0};
//----------------------
// B=0x0, offset=B+0x3c, = 0x3c
//----------------------
// INT_PIN [15:8]
localparam [48:0] PF1_INI_36 = {1'd1, 4'b0010, 12'h03c, 16'd0, PF1_INT_PIN, 8'd0};
//----------------------
// offset 0xB(b0)+0x00
//----------------------
//PCI_MSIX_ENABLE           [31]
//PCI_FUNCTION_MASK         [30]
//PCI_MSIX_TABLE_SIZE       [26:16]
//PCI_MSIX_CAP_NEXT_OFFSET  [15:8]
localparam [48:0] PF1_INI_37 = {1'b1, 4'b1110, 12'h0b0, PF1_PCI_MSIX_ENABLE, PF1_PCI_FUNCTION_MASK, 3'h0, PF1_PCI_MSIX_TABLE_SIZE, PF1_PCI_MSIX_CAP_NEXT_OFFSET, 8'h0};
//----------------------
// offset 0xB(b0)+0x04
//----------------------
//PCI_MSIX_TABLE_OFFSET     [31:3]
//PCI_MSIX_BIR              [2:0]
localparam [48:0] PF1_INI_38 = {1'b1, 4'b1111, 12'h0b4, PF1_PCI_MSIX_TABLE_OFFSET, PF1_PCI_MSIX_BIR};
//----------------------
// offset 0xB(b0)+0x08
//----------------------
// PCI_MSIX_PBA_OFFSET      [31:3]
// PCI_MSIX_PBA_BIR         [2:0]
localparam [48:0] PF1_INI_39 = {1'b1, 4'b1111, 12'h0b8, PF1_PCI_MSIX_PBA_OFFSET, PF1_PCI_MSIX_PBA_BIR};
//----------------------
// offset 0x(100)+0x00
//----------------------
// AER_CAP_NEXT_OFFSET [31:20]
localparam [48:0] PF1_INI_40 = {1'b1, 4'b1100, 12'h100, PF1_AER_CAP_NEXT_OFFSET, 4'h2, 16'h0};
//----------------------
// offset 0xB+0x18
//----------------------
// ECRC_CHECK_EN    @[8]
// ECRC_GEN_EN      @[6]
localparam [48:0] PF1_INI_41 = {1'b1, 4'b0011, 12'h118, 16'd0, 7'd0, PF1_ECRC_CHECK_EN, 1'd1, PF1_ECRC_GEN_EN, 1'd1, 5'd0};
//----------------------
// offset 0x(2E4)+0x04
//----------------------
// RESBAR_BAR0_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF1_INI_42 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2E8, 8'h0,PF1_RESBAR_BAR0_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x08
//----------------------
// RESBAR_BAR0_INIT_SIZE [12:8]
localparam [48:0] PF1_INI_43 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2EC, 19'h0,PF1_RESBAR_BAR0_INIT_SIZE, 8'h0};
//----------------------
// offset 0x(2E4)+0x0C
//----------------------
// RESBAR_BAR1_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF1_INI_44 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2F0, 8'h0,PF1_RESBAR_BAR1_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x10
//----------------------
// RESBAR_BAR1_INIT_SIZE [12:8]
localparam [48:0] PF1_INI_45 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2F4, 19'h0,PF1_RESBAR_BAR1_INIT_SIZE, 8'h0};
//----------------------
// offset 0x(2E4)+0x14
//----------------------
// RESBAR_BAR2_MAX_SUPP_SIZE [23:4]
localparam [48:0] PF1_INI_46 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2F8, 8'h0,PF1_RESBAR_BAR2_MAX_SUPP_SIZE, 4'h0};
//----------------------
// offset 0x(2E4)+0x18
//----------------------
// RESBAR_BAR2_INIT_SIZE [12:8]
localparam [48:0] PF1_INI_47 = (DEVICE_TYPE==3'b100) ? {49'd0} : {1'b1, 4'b0000, 12'h2FC, 19'h0,PF1_RESBAR_BAR2_INIT_SIZE, 8'h0};

//************************************* SRIOV CAP *************************************
localparam [48:0] PF0_INI_59 = {1'b0, 4'b1100, 12'h1b4, PF0_SRIOV_EXT_CAP_NXT_OFFSET,PF0_SRIOV_EXT_CAP_VER,16'h0};
//----------------------
// offset 0x(1b4)+0xc
//----------------------
// SRIOV_INITIAL_VFS [15:0]
localparam [48:0] PF0_INI_60 = {1'b0, 4'b0011, 12'h1c0, 16'h0,PF0_SRIOV_INITIAL_VFS};
//----------------------
// offset 0x(1b4)+0x14
//----------------------
// SRIOV_VF_STRIDE [31:16] SRIOV_VF_OFFSET [15:0]
localparam [48:0] PF0_INI_61 = {1'b0, 4'b0011, 12'h1c8, 16'd0 , PF0_SRIOV_VF_OFFSET};//16'd1
//----------------------
// offset 0x(1b4)+0x18
//----------------------
// SRIOV_VF_DEVICE_ID [31:16]
localparam [48:0] PF0_INI_62 = {1'b0, 4'b1100, 12'h1cc, PF0_SRIOV_VF_DEVICE_ID , 16'b0};
//----------------------
// offset 0x(1b4)+0x24 + cs2
//----------------------
// PCI_SRIOV_VF_BAR0_MASK [31:1] PCI_SRIOV_VF_BAR0_ENABLED [0]
localparam [48:0] PF0_INI_63 = {1'b0, 4'b1111, 12'h1d9, PF0_SRIOV_VF_BAR0_MASK , PF0_SRIOV_VF_BAR0_ENABLED};
//----------------------
// offset 0x(1b4)+0x28 + cs2
//----------------------
// PCI_SRIOV_VF_BAR1_MASK [31:1] PCI_SRIOV_VF_BAR1_ENABLED [0]
localparam [48:0] PF0_INI_64 = {1'b0, 4'b1111, 12'h1dd, PF0_SRIOV_VF_BAR1_MASK , PF0_SRIOV_VF_BAR1_ENABLED};
//----------------------
// offset 0x(1b4)+0x2c + cs2
//----------------------
// PCI_SRIOV_VF_BAR2_MASK [31:1] PCI_SRIOV_VF_BAR2_ENABLED [0]
localparam [48:0] PF0_INI_65 = {1'b0, 4'b1111, 12'h1e1, PF0_SRIOV_VF_BAR2_MASK , PF0_SRIOV_VF_BAR2_ENABLED};
//----------------------
// offset 0x(1b4)+0x30 + cs2
//----------------------
// PCI_SRIOV_VF_BAR3_MASK [31:1] PCI_SRIOV_VF_BAR3_ENABLED [0]
localparam [48:0] PF0_INI_66 = {1'b0, 4'b1111, 12'h1e5, PF0_SRIOV_VF_BAR3_MASK , PF0_SRIOV_VF_BAR3_ENABLED};
//----------------------
// offset 0x(1b4)+0x34 + cs2
//----------------------
// PCI_SRIOV_VF_BAR4_MASK [31:1] PCI_SRIOV_VF_BAR4_ENABLED [0]
localparam [48:0] PF0_INI_67 = {1'b0, 4'b1111, 12'h1e9, PF0_SRIOV_VF_BAR4_MASK , PF0_SRIOV_VF_BAR4_ENABLED};
//----------------------
// offset 0x(1b4)+0x38 + cs2
//----------------------
// PCI_SRIOV_VF_BAR5_MASK [31:1] PCI_SRIOV_VF_BAR5_ENABLED [0]
localparam [48:0] PF0_INI_68 = {1'b0, 4'b1111, 12'h1ed, PF0_SRIOV_VF_BAR5_MASK , PF0_SRIOV_VF_BAR5_ENABLED};
//----------------------
// offset 0x(1b4)+0x24
//----------------------
// SRIOV_VF_BAR0_PREFETCH [3] SRIOV_VF_BAR0_TYPE [2:1]
localparam [48:0] PF0_INI_69 = {1'b0, 4'b0001, 12'h1d8, 28'd0 , PF0_SRIOV_VF_BAR0_PREFETCH , PF0_SRIOV_VF_BAR0_TYPE,PF0_SRIOV_VF_BAR0_MEM_IO};
//----------------------
// offset 0x(1b4)+0x28
//----------------------
// SRIOV_VF_BAR1_PREFETCH [3] SRIOV_VF_BAR1_TYPE [2:1]
localparam [48:0] PF0_INI_70 = {1'b0, 4'b0001, 12'h1dc, 28'd0 , PF0_SRIOV_VF_BAR1_PREFETCH , PF0_SRIOV_VF_BAR1_TYPE,PF0_SRIOV_VF_BAR1_MEM_IO};
//----------------------
// offset 0x(1b4)+0x2c
//----------------------
// SRIOV_VF_BAR2_PREFETCH [3] SRIOV_VF_BAR2_TYPE [2:1]
localparam [48:0] PF0_INI_71 = {1'b0, 4'b0001, 12'h1e0, 28'd0 , PF0_SRIOV_VF_BAR2_PREFETCH , PF0_SRIOV_VF_BAR2_TYPE,PF0_SRIOV_VF_BAR2_MEM_IO};
//----------------------
// offset 0x(1b4)+0x30
//----------------------
// SRIOV_VF_BAR3_PREFETCH [3] SRIOV_VF_BAR3_TYPE [2:1]
localparam [48:0] PF0_INI_72 = {1'b0, 4'b0001, 12'h1e4, 28'd0 , PF0_SRIOV_VF_BAR3_PREFETCH , PF0_SRIOV_VF_BAR3_TYPE,PF0_SRIOV_VF_BAR3_MEM_IO};
//----------------------
// offset 0x(1b4)+0x34
//----------------------
// SRIOV_VF_BAR4_PREFETCH [3] SRIOV_VF_BAR4_TYPE [2:1]
localparam [48:0] PF0_INI_73 = {1'b0, 4'b0001, 12'h1e8, 28'd0 , PF0_SRIOV_VF_BAR4_PREFETCH , PF0_SRIOV_VF_BAR4_TYPE,PF0_SRIOV_VF_BAR4_MEM_IO};
//----------------------
// offset 0x(1b4)+0x38
//----------------------
// SRIOV_VF_BAR5_PREFETCH [3] SRIOV_VF_BAR5_TYPE [2:1]
localparam [48:0] PF0_INI_74 = {1'b0, 4'b0001, 12'h1ec, 28'd0 , PF0_SRIOV_VF_BAR5_PREFETCH , PF0_SRIOV_VF_BAR5_TYPE,PF0_SRIOV_VF_BAR5_MEM_IO};

localparam [48:0] PF0_INI_75 = {1'b0, 4'b0111, 12'h050, 8'd0 ,PF0_SRIOV_MSI_64_BIT_ADDR_CAP, 3'h0 , PF0_SRIOV_MSI_MULTIPLE_MSG_CAP , PF0_SRIOV_MSI_ENABLE , PF0_SRIOV_MSI_CAP_NEXT_OFFSET};

/////////PF1
localparam [48:0] PF1_INI_48 = {1'b1, 4'b1100, 12'h1b4, PF1_SRIOV_EXT_CAP_NXT_OFFSET,PF1_SRIOV_EXT_CAP_VER,16'h0};
//----------------------
// offset 0x(1b4)+0xc
//----------------------
// SRIOV_INITIAL_VFS [15:0]
localparam [48:0] PF1_INI_49 = {1'b1, 4'b0011, 12'h1c0, 16'h0,PF1_SRIOV_INITIAL_VFS};
//----------------------
// offset 0x(1b4)+0x14
//----------------------
// SRIOV_VF_STRIDE [31:16] SRIOV_VF_OFFSET [15:0]
localparam [48:0] PF1_INI_50 = {1'b1, 4'b0011, 12'h1c8, 16'd0 , PF1_SRIOV_VF_OFFSET};
//----------------------
// offset 0x(1b4)+0x18
//----------------------
// SRIOV_VF_DEVICE_ID [31:16]
localparam [48:0] PF1_INI_51 = {1'b1, 4'b1100, 12'h1cc, PF1_SRIOV_VF_DEVICE_ID , 16'b0};
//----------------------
// offset 0x(1b4)+0x24 + cs2
//----------------------
// PCI_SRIOV_VF_BAR0_MASK [31:1] PCI_SRIOV_VF_BAR0_ENABLED [0]
localparam [48:0] PF1_INI_52 = {1'b1, 4'b1111, 12'h1d9, PF1_SRIOV_VF_BAR0_MASK , PF1_SRIOV_VF_BAR0_ENABLED};
//----------------------
// offset 0x(1b4)+0x28 + cs2
//----------------------
// PCI_SRIOV_VF_BAR1_MASK [31:1] PCI_SRIOV_VF_BAR1_ENABLED [0]
localparam [48:0] PF1_INI_53 = {1'b1, 4'b1111, 12'h1dd, PF1_SRIOV_VF_BAR1_MASK , PF1_SRIOV_VF_BAR1_ENABLED};
//----------------------
// offset 0x(1b4)+0x2c + cs2
//----------------------
// PCI_SRIOV_VF_BAR2_MASK [31:1] PCI_SRIOV_VF_BAR2_ENABLED [0]
localparam [48:0] PF1_INI_54 = {1'b1, 4'b1111, 12'h1e1, PF1_SRIOV_VF_BAR2_MASK , PF1_SRIOV_VF_BAR2_ENABLED};
//----------------------
// offset 0x(1b4)+0x30 + cs2
//----------------------
// PCI_SRIOV_VF_BAR3_MASK [31:1] PCI_SRIOV_VF_BAR3_ENABLED [0]
localparam [48:0] PF1_INI_55 = {1'b1, 4'b1111, 12'h1e5, PF1_SRIOV_VF_BAR3_MASK , PF1_SRIOV_VF_BAR3_ENABLED};
//----------------------
// offset 0x(1b4)+0x34 + cs2
//----------------------
// PCI_SRIOV_VF_BAR4_MASK [31:1] PCI_SRIOV_VF_BAR4_ENABLED [0]
localparam [48:0] PF1_INI_56 = {1'b1, 4'b1111, 12'h1e9, PF1_SRIOV_VF_BAR4_MASK , PF1_SRIOV_VF_BAR4_ENABLED};
//----------------------
// offset 0x(1b4)+0x38 + cs2
//----------------------
// PCI_SRIOV_VF_BAR5_MASK [31:1] PCI_SRIOV_VF_BAR5_ENABLED [0]
localparam [48:0] PF1_INI_57 = {1'b1, 4'b1111, 12'h1ed, PF1_SRIOV_VF_BAR5_MASK , PF1_SRIOV_VF_BAR5_ENABLED};
//----------------------
// offset 0x(1b4)+0x24
//----------------------
// SRIOV_VF_BAR0_PREFETCH [3] SRIOV_VF_BAR0_TYPE [2:1]
localparam [48:0] PF1_INI_58 = {1'b1, 4'b0001, 12'h1d8, 28'd0 , PF1_SRIOV_VF_BAR0_PREFETCH , PF1_SRIOV_VF_BAR0_TYPE,PF1_SRIOV_VF_BAR0_MEM_IO};
//----------------------
// offset 0x(1b4)+0x28
//----------------------
// SRIOV_VF_BAR1_PREFETCH [3] SRIOV_VF_BAR1_TYPE [2:1]
localparam [48:0] PF1_INI_59 = {1'b1, 4'b0001, 12'h1dc, 28'd0 , PF1_SRIOV_VF_BAR1_PREFETCH , PF1_SRIOV_VF_BAR1_TYPE,PF1_SRIOV_VF_BAR1_MEM_IO};
//----------------------
// offset 0x(1b4)+0x2c
//----------------------
// SRIOV_VF_BAR2_PREFETCH [3] SRIOV_VF_BAR2_TYPE [2:1]
localparam [48:0] PF1_INI_60 = {1'b1, 4'b0001, 12'h1e0, 28'd0 , PF1_SRIOV_VF_BAR2_PREFETCH , PF1_SRIOV_VF_BAR2_TYPE,PF1_SRIOV_VF_BAR2_MEM_IO};
//----------------------
// offset 0x(1b4)+0x30
//----------------------
// SRIOV_VF_BAR3_PREFETCH [3] SRIOV_VF_BAR3_TYPE [2:1]
localparam [48:0] PF1_INI_61 = {1'b1, 4'b0001, 12'h1e4, 28'd0 , PF1_SRIOV_VF_BAR3_PREFETCH , PF1_SRIOV_VF_BAR3_TYPE,PF1_SRIOV_VF_BAR3_MEM_IO};
//----------------------
// offset 0x(1b4)+0x34
//----------------------
// SRIOV_VF_BAR4_PREFETCH [3] SRIOV_VF_BAR4_TYPE [2:1]
localparam [48:0] PF1_INI_62 = {1'b1, 4'b0001, 12'h1e8, 28'd0 , PF1_SRIOV_VF_BAR4_PREFETCH , PF1_SRIOV_VF_BAR4_TYPE,PF1_SRIOV_VF_BAR4_MEM_IO};
//----------------------
// offset 0x(1b4)+0x38
//----------------------
// SRIOV_VF_BAR5_PREFETCH [3] SRIOV_VF_BAR5_TYPE [2:1]
localparam [48:0] PF1_INI_63 = {1'b1, 4'b0001, 12'h1ec, 28'd0 , PF1_SRIOV_VF_BAR5_PREFETCH , PF1_SRIOV_VF_BAR5_TYPE,PF1_SRIOV_VF_BAR5_MEM_IO};

localparam [48:0] PF1_INI_64 = {1'b1, 4'b0111, 12'h050, 8'd0 ,PF1_SRIOV_MSI_64_BIT_ADDR_CAP, 3'h0 , PF1_SRIOV_MSI_MULTIPLE_MSG_CAP , PF1_SRIOV_MSI_ENABLE , PF1_SRIOV_MSI_CAP_NEXT_OFFSET};

//*********************************** SRIOV CAP END *************************************

// ROM Initial
assign init_rom[0]  = PF0_INI_0;
assign init_rom[1]  = PF0_INI_1;
assign init_rom[2]  = PF0_INI_2;
assign init_rom[3]  = PF0_INI_3;
assign init_rom[4]  = PF0_INI_4;
assign init_rom[5]  = PF0_INI_5;
assign init_rom[6]  = PF0_INI_6;
assign init_rom[7]  = PF0_INI_7;
assign init_rom[8]  = PF0_INI_8;
assign init_rom[9]  = PF0_INI_9;
assign init_rom[10] = PF0_INI_10;
assign init_rom[11] = PF0_INI_11;
assign init_rom[12] = PF0_INI_12;
assign init_rom[13] = PF0_INI_13;
assign init_rom[14] = PF0_INI_14;
assign init_rom[15] = PF0_INI_15;
assign init_rom[16] = PF0_INI_16;
assign init_rom[17] = PF0_INI_17;
assign init_rom[18] = PF0_INI_18;
assign init_rom[19] = PF0_INI_19;
assign init_rom[20] = PF0_INI_20;
assign init_rom[21] = PF0_INI_21;
assign init_rom[22] = PF0_INI_22;
assign init_rom[23] = PF0_INI_23;
assign init_rom[24] = PF0_INI_24;
assign init_rom[25] = PF0_INI_25;
assign init_rom[26] = PF0_INI_26;
assign init_rom[27] = PF0_INI_27;
assign init_rom[28] = PF0_INI_28;
assign init_rom[29] = PF0_INI_29;
assign init_rom[30] = PF0_INI_30;
assign init_rom[31] = PF0_INI_31;
assign init_rom[32] = PF0_INI_32;
assign init_rom[33] = PF0_INI_33;
assign init_rom[34] = PF0_INI_34;
assign init_rom[35] = PF0_INI_35;
assign init_rom[36] = PF0_INI_36;
assign init_rom[37] = PF0_INI_37;
assign init_rom[38] = PF0_INI_38;
assign init_rom[39] = PF0_INI_39;
assign init_rom[40] = PF0_INI_40;
assign init_rom[41] = PF0_INI_41;
assign init_rom[42] = PF0_INI_42;
assign init_rom[43] = PF0_INI_43;
assign init_rom[44] = PF0_INI_44;
assign init_rom[45] = PF0_INI_45;//PF0_INT_PIN
assign init_rom[46] = PF0_INI_46;
assign init_rom[47] = PF0_INI_47;
assign init_rom[48] = PF0_INI_48;
assign init_rom[49] = PF0_INI_49;
assign init_rom[50] = PF0_INI_50;
assign init_rom[51] = PF0_INI_51;
assign init_rom[52] = PF0_INI_52;
assign init_rom[53] = PF0_INI_53;
assign init_rom[54] = PF0_INI_54;
assign init_rom[55] = PF0_INI_55;
assign init_rom[56] = PF0_INI_56;
assign init_rom[57] = PF0_INI_57;
assign init_rom[58] = PF0_INI_58;//GEN3_EQ_PSET_REQ_VEC
assign init_rom[59] = PF0_INI_59;//SRIOV start
assign init_rom[60] = PF0_INI_60;
assign init_rom[61] = PF0_INI_61;
assign init_rom[62] = PF0_INI_62;
assign init_rom[63] = PF0_INI_63;
assign init_rom[64] = PF0_INI_64;
assign init_rom[65] = PF0_INI_65;
assign init_rom[66] = PF0_INI_66;
assign init_rom[67] = PF0_INI_67;
assign init_rom[68] = PF0_INI_68;
assign init_rom[69] = PF0_INI_69;
assign init_rom[70] = PF0_INI_70;
assign init_rom[71] = PF0_INI_71;
assign init_rom[72] = PF0_INI_72;
assign init_rom[73] = PF0_INI_73;
assign init_rom[74] = PF0_INI_74;
assign init_rom[75] = PF0_INI_75;
generate                      
    if (PF1_ENABLE=="TRUE") begin
        assign init_rom[76]  = PF1_INI_0;
        assign init_rom[77]  = PF1_INI_1;
        assign init_rom[78]  = PF1_INI_2;
        assign init_rom[79]  = PF1_INI_3;
        assign init_rom[80]  = PF1_INI_4;
        assign init_rom[81]  = PF1_INI_5;
        assign init_rom[82]  = PF1_INI_6;
        assign init_rom[83]  = PF1_INI_7;
        assign init_rom[84]  = PF1_INI_8;
        assign init_rom[85]  = PF1_INI_9;
        assign init_rom[86]  = PF1_INI_10;
        assign init_rom[87]  = PF1_INI_11;
        assign init_rom[88]  = PF1_INI_12;
        assign init_rom[89]  = PF1_INI_13;
        assign init_rom[90]  = PF1_INI_14;
        assign init_rom[91]  = PF1_INI_15;
        assign init_rom[92]  = PF1_INI_16;
        assign init_rom[93]  = PF1_INI_17;
        assign init_rom[94]  = PF1_INI_18;
        assign init_rom[95]  = PF1_INI_19;
        assign init_rom[96]  = PF1_INI_20;
        assign init_rom[97]  = PF1_INI_21;
        assign init_rom[98]  = PF1_INI_22;
        assign init_rom[99]  = PF1_INI_23;
        assign init_rom[100] = PF1_INI_24;
        assign init_rom[101] = PF1_INI_25;
        assign init_rom[102] = PF1_INI_26;
        assign init_rom[103] = PF1_INI_27;
        assign init_rom[104] = PF1_INI_28;
        assign init_rom[105] = PF1_INI_29;
        assign init_rom[106] = PF1_INI_30;
        assign init_rom[107] = PF1_INI_31;
        assign init_rom[108] = PF1_INI_32;
        assign init_rom[109] = PF1_INI_33;
        assign init_rom[110] = PF1_INI_34;
        assign init_rom[111] = PF1_INI_35;
        assign init_rom[112] = PF1_INI_36;//PF1_INT_PIN
        assign init_rom[113] = PF1_INI_37;
        assign init_rom[114] = PF1_INI_38;
        assign init_rom[115] = PF1_INI_39;
        assign init_rom[116] = PF1_INI_40;
        assign init_rom[117] = PF1_INI_41;
        assign init_rom[118] = PF1_INI_42;
        assign init_rom[119] = PF1_INI_43;
        assign init_rom[120] = PF1_INI_44;
        assign init_rom[121] = PF1_INI_45;
        assign init_rom[122] = PF1_INI_46;
        assign init_rom[123] = PF1_INI_47;
        assign init_rom[124] = PF1_INI_48;//SRIOV start
        assign init_rom[125] = PF1_INI_49;
        assign init_rom[126] = PF1_INI_50;
        assign init_rom[127] = PF1_INI_51;
        assign init_rom[128] = PF1_INI_52;
        assign init_rom[129] = PF1_INI_53;
        assign init_rom[130] = PF1_INI_54;
        assign init_rom[131] = PF1_INI_55;
        assign init_rom[132] = PF1_INI_56;
        assign init_rom[133] = PF1_INI_57;
        assign init_rom[134] = PF1_INI_58;
        assign init_rom[135] = PF1_INI_59;
        assign init_rom[136] = PF1_INI_60;
        assign init_rom[137] = PF1_INI_61;
        assign init_rom[138] = PF1_INI_62;
        assign init_rom[139] = PF1_INI_63;
        assign init_rom[140] = PF1_INI_64;
    end
endgenerate

//assign dbi_vfunc_num    = 3'b0;
//assign dbi_vfunc_active = 1'b0;

assign dbi_standby = !(dbi_cs || dbi_ack);

reg cnt_done;
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        cnt_done <= 1'd0;
    else if (rom_raddr==(ROM_CNT-1) && dbi_ack && !dbi_cs)
    //else if (rom_raddr==(ROM_CNT) && dbi_ack && !dbi_cs)
        cnt_done <= 1'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        init_finish <= 1'b0;
    else
        init_finish <= cnt_done;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        dbi_ro_wr_disable <= 1'b1;
    else if (cnt_done)
        dbi_ro_wr_disable <= 1'b1;
    else if (start && dbi_standby && !cnt_done)
        dbi_ro_wr_disable <= 1'b0;
end

// Read Rom Adderess
always @(posedge clk or negedge rst_n) begin
    if (!rst_n)
        rom_raddr <= 10'd0;
    else if (rom_raddr == ROM_CNT-10'd1)
        rom_raddr <= rom_raddr;
    else if (dbi_ack && dbi_cs)
        rom_raddr <= rom_raddr + 10'd1;
end

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dbi_cs <= 1'b0;
        dbi_din  <= 32'd0;
        dbi_addr <= 32'd0;
        dbi_wr <= 4'd0;
        dbi_cs2 <= 1'd0;
        dbi_func_num <= 1'b0;
        dbi_vfunc_num <= 3'b0;
        dbi_vfunc_active <= 1'b0;
    end
    else if (dbi_ack) begin
        dbi_cs <= 1'b0;
        dbi_cs2 <= 1'd0;
        dbi_wr <= 4'd0;
        dbi_func_num <= 1'b0;
        dbi_vfunc_num <= 3'b0;
        dbi_vfunc_active <= 1'b0;
    end
    else if (start && dbi_standby && !cnt_done) begin
        dbi_cs <= 1'b1;
        dbi_din  <= init_rom[rom_raddr][31:0];
        dbi_addr <= {20'd0, init_rom[rom_raddr][43:32]};
        dbi_wr <= init_rom[rom_raddr][47:44];
        dbi_func_num <= init_rom[rom_raddr][48];

        if(rom_raddr == 10'd75 || rom_raddr == 10'd140)
            dbi_vfunc_active <= 1'b1;
        else
            dbi_vfunc_active <= 1'b0;

        if (init_rom[rom_raddr][32]==1'b1)
            dbi_cs2 <= 1'b1;
        else
            dbi_cs2 <= 1'b0;
    end
end

// debug logic

`ifdef IPS2T_PCIE_SPEEDUP_SIM
reg [47:44] test_wr   ;
reg [43:32] test_addr ;
reg [31:0]  test_data ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        test_wr   <= 'd0;
        test_addr <= 'd0;
        test_data <= 'd0;
    end
    else begin
        test_wr   <= init_rom[rom_raddr][47:44];
        test_addr <= init_rom[rom_raddr][43:32];
        test_data <= init_rom[rom_raddr][31:0];
    end
end
`else
`endif

endmodule
