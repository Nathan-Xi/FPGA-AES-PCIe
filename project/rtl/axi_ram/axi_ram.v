
//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2019 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
// Library:
// Filename:axi_ram.v
//////////////////////////////////////////////////////////////////////////////
module axi_ram #(
    parameter MEMORY_DEPTH = 2048,
    parameter AXI_DATA_WIDTH = 128,
    parameter AXI_ID_WIDTH = 2
)(
    s_axi_aclk         ,
    s_axi_aresetn      ,

    s_axi_awid         ,
    
    s_axi_awaddr       ,
    s_axi_awlen        ,
    s_axi_awsize       ,
    s_axi_awburst      ,
    s_axi_awlock       ,
    s_axi_awcache      ,
    s_axi_awprot       ,
    s_axi_awvalid      ,
    s_axi_awready      ,
                     
    s_axi_wdata        ,
    s_axi_wstrb        ,
    s_axi_wlast        ,
    s_axi_wvalid       ,
    s_axi_wready       ,
                     
    s_axi_bid          ,
    
    s_axi_bresp        ,
    s_axi_bvalid       ,
    s_axi_bready       ,
                     
    s_axi_arid         ,
    
    s_axi_araddr       ,
    s_axi_arlen        ,
    s_axi_arsize       ,
    s_axi_arburst      ,
    s_axi_arlock       ,
    s_axi_arcache      ,
    s_axi_arprot       ,
    s_axi_arvalid      ,
    s_axi_arready      ,
                     
    s_axi_rid          ,
    
    s_axi_rdata        ,
    s_axi_rresp        ,
    s_axi_rlast        ,
    s_axi_rvalid       ,
    s_axi_rready       

);


//localparam MEMORY_DEPTH =  1024  ; // @IPC enum 1024,2048,4096,8192,16384,32768,131072,262144

//localparam AXI_DATA_WIDTH = 128 ; // @IPC enum 32,64,128,256,512,1024


//localparam AXI_ID_WIDTH = 1 ; // @IPC enum 0-32

localparam AXI_PROTOCOL = "AXI4" ; // @IPC enum AXI4,AXI4LITE

localparam AXI_SUPPORTS_NARROW = "No" ; // @IPC enum Yes,No


localparam READ_LATENCY = 1 ; // @IPC enum 1-128


localparam SINGLE_PORT_DRM = "DPRAM" ; // @IPC enum SPRAM,DPRAM

localparam ECC_EN = "No" ; // @IPC enum Yes,No

localparam ECC_TYPE = "Hamming" ; // @IPC enum Hamming

localparam FAULT_INJECT_EN = "No" ; // @IPC enum Yes,No

localparam DRM_INST_MODE = "INTERNAL" ; // @IPC enum EXTERNAL,INTERNAL


localparam ECC_RESET_VALUE = 0 ; // @IPC enum 0,1

localparam ECC_WIDTH           = (ECC_EN == "Yes") ? ((AXI_DATA_WIDTH==32 || AXI_DATA_WIDTH==64) ? 8 : ((AXI_DATA_WIDTH==128) ? 9  : 1)) : 1 ;
localparam ECC_FULL_WIDTH      = (ECC_EN == "Yes") ? ((AXI_DATA_WIDTH==32 || AXI_DATA_WIDTH==64) ? 8 : ((AXI_DATA_WIDTH==128) ? 16 : 1)) : 1 ;
localparam ECC_EN_INT = (ECC_EN == "Yes") ? 1 : 0;
localparam AXI_ADDR_WIDTH = $clog2(MEMORY_DEPTH*AXI_DATA_WIDTH/8);

input                                               s_axi_aclk         ;
input                                               s_axi_aresetn      ;

input  [AXI_ID_WIDTH-1:0]                           s_axi_awid         ;
                                             
input  [31:0]                                       s_axi_awaddr       ;
input  [7:0]                                        s_axi_awlen        ;
input  [2:0]                                        s_axi_awsize       ;
input  [1:0]                                        s_axi_awburst      ;
input                                               s_axi_awlock       ;
input  [3:0]                                        s_axi_awcache      ;
input  [2:0]                                        s_axi_awprot       ;
input                                               s_axi_awvalid      ;
output                                              s_axi_awready      ;
                                                                     
input  [AXI_DATA_WIDTH-1:0]                         s_axi_wdata        ;
input  [AXI_DATA_WIDTH/8-1:0]                       s_axi_wstrb        ;
input                                               s_axi_wlast        ;
input                                               s_axi_wvalid       ;
output                                              s_axi_wready       ;
                                                         
output [AXI_ID_WIDTH-1:0]                           s_axi_bid          ;
                                             
output [1:0]                                        s_axi_bresp        ;
output                                              s_axi_bvalid       ;
input                                               s_axi_bready       ;
                                                          
input  [AXI_ID_WIDTH-1:0]                           s_axi_arid         ;
                                             
input  [31:0]                                       s_axi_araddr       ;
input  [7:0]                                        s_axi_arlen        ;
input  [2:0]                                        s_axi_arsize       ;
input  [1:0]                                        s_axi_arburst      ;
input                                               s_axi_arlock       ;
input  [3:0]                                        s_axi_arcache      ;
input  [2:0]                                        s_axi_arprot       ;
input                                               s_axi_arvalid      ;
output                                              s_axi_arready      ;
                                                          
output [AXI_ID_WIDTH-1:0]                           s_axi_rid          ;
    
output [AXI_DATA_WIDTH-1:0]                         s_axi_rdata        ;
output [1:0]                                        s_axi_rresp        ;
output                                              s_axi_rlast        ;
output                                              s_axi_rvalid       ;
input                                               s_axi_rready       ;                                             
 
//AXI RAM IP instance
ipmxj_axi_ram_ctrl_top_v1_2 #(         
    .DRM_INST_MODE       (DRM_INST_MODE                      ),
    .MEMORY_DEPTH        (MEMORY_DEPTH                       ),
    .AXI_ADDR_WIDTH      (32                                 ),
    .AXI_DATA_WIDTH      (AXI_DATA_WIDTH                     ),
    .AXI_ID_WIDTH        (AXI_ID_WIDTH                       ),
    .AXI_PROTOCOL        (AXI_PROTOCOL                       ),
    .AXI_SUPPORTS_NARROW (AXI_SUPPORTS_NARROW == "Yes" ? 1 : 0),
    .SINGLE_PORT_DRM     (SINGLE_PORT_DRM == "SPRAM" ? 1 : 0 ),
    .READ_LATENCY        (READ_LATENCY                       ),
    .RD_OPTIMIZATION     (0                                  ),
    .AXI_CTRL_ADDR_WIDTH (32                                 ),
    .AXI_CTRL_DATA_WIDTH (32                                 ),
                            
    .ECC_EN              (ECC_EN_INT                         ),
    .ECC_TYPE            (ECC_TYPE == "Hamming" ? 0 : 1      ),
    .ECC_WIDTH           (ECC_WIDTH                          ),
    .ECC_FULL_WIDTH      (ECC_FULL_WIDTH                     ),
    .FAULT_INJECT_EN     (FAULT_INJECT_EN == "Yes" ? 1 : 0   ),
    .ECC_RESET_VALUE     (ECC_RESET_VALUE                    )
) axi_ram_ctrl_top (
    .s_axi_aclk        (s_axi_aclk          ),
    .s_axi_aresetn     (s_axi_aresetn       ),  

    //AW
    .s_axi_awid   (s_axi_awid   ),
    .s_axi_awaddr (s_axi_awaddr ),
    .s_axi_awlen  (s_axi_awlen  ),
    .s_axi_awsize (s_axi_awsize ),
    .s_axi_awburst(s_axi_awburst),
    .s_axi_awlock (s_axi_awlock ),
    .s_axi_awcache(s_axi_awcache),
    .s_axi_awprot (s_axi_awprot ),
    .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready),
    //W
    .s_axi_wdata  (s_axi_wdata  ),
    .s_axi_wstrb  (s_axi_wstrb  ),
    .s_axi_wlast  (s_axi_wlast  ),             
    .s_axi_wvalid (s_axi_wvalid ),
    .s_axi_wready (s_axi_wready ),
    //B 
    .s_axi_bid    (s_axi_bid    ),
    .s_axi_bresp  (s_axi_bresp  ),           
    .s_axi_bvalid (s_axi_bvalid ),
    .s_axi_bready (s_axi_bready ),
    //AR
    .s_axi_arid   (s_axi_arid   ),
    .s_axi_araddr (s_axi_araddr ),
    .s_axi_arlen  (s_axi_arlen  ),
    .s_axi_arsize (s_axi_arsize ),
    .s_axi_arburst(s_axi_arburst),
    .s_axi_arlock (s_axi_arlock ),
    .s_axi_arcache(s_axi_arcache),
    .s_axi_arprot (s_axi_arprot ),            
    .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready),
    //R
    .s_axi_rid    (s_axi_rid    ),
    .s_axi_rdata  (s_axi_rdata  ),
    .s_axi_rresp  (s_axi_rresp  ),
    .s_axi_rlast  (s_axi_rlast  ),          
    .s_axi_rvalid (s_axi_rvalid ),
    .s_axi_rready (s_axi_rready )
    
); 
endmodule
