//////////////////////////////////////////////////////////////////////////////
//
// Copyright (c) 2023 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//
// THE SOURCE CODE CONTAINED HEREIN IS PROPRIETARY TO PANGO MICROSYSTEMS, INC.
// IT SHALL NOT BE REPRODUCED OR DISCLOSED IN WHOLE OR IN PART OR USED BY
// PARTIES WITHOUT WRITTEN AUTHORIZATION FROM THE OWNER.
//
//////////////////////////////////////////////////////////////////////////////
//
// Library:
// Filename: ipmxj_axi_ram_ipm2l_dpram_v1_6_top.v
// Description: ipmxj_axi_ram_ipm2l_dpram_v1_6_top
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module ipmxj_axi_ram_ipm2l_dpram_v1_6_top#(
    parameter CAS_MODE     = "36K"  ,
    parameter A_ADDR_WIDTH = 12     ,
    parameter A_DATA_WIDTH = 32     ,
    parameter A_BE_WIDTH   = 4      ,
    parameter A_OUTPUT_REG = 0      ,
    parameter B_ADDR_WIDTH = 12     ,
    parameter B_DATA_WIDTH = 32     ,
    parameter B_BE_WIDTH   = 4      ,
    parameter B_OUTPUT_REG = 0      
) (
    a_addr        ,
    a_wr_data     ,
    a_rd_data     ,
    a_wr_en       ,
    
    a_rst         ,
    
    a_wr_byte_en  ,
    
    a_clk         ,

    b_addr        ,
    b_wr_data     ,
    b_rd_data     ,
    b_wr_en       ,
    
    b_rst         ,
    
    b_wr_byte_en  ,
    
    b_clk
);


// localparam CAS_MODE = "36K" ; // @IPC enum 18K,36K,64K

localparam POWER_OPT = 0 ; // @IPC bool

localparam RESET_TYPE = "ASYNC" ; // @IPC enum SYNC,ASYNC

localparam SAMEWIDTH_EN = 1 ; // @IPC bool

localparam WR_BYTE_EN = 1 ; // @IPC bool

localparam BYTE_SIZE = 8 ; // @IPC enum 8,9

// localparam A_ADDR_WIDTH = 12 ; // @IPC int 10,20

// localparam A_DATA_WIDTH = 32 ; // @IPC int 1,1152

// localparam A_BE_WIDTH = 4 ; // @IPC int 1,128

localparam A_WRITE_MODE = "TRANSPARENT_WRITE"; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam A_CLK_EN = 0 ; // @IPC bool

localparam A_ADDR_STROBE_EN = 0 ; // @IPC bool

// localparam A_OUTPUT_REG = 0 ; // @IPC bool

localparam A_RD_OCE_EN = 0 ; // @IPC bool

localparam A_CLK_OR_POL_INV = 0 ; // @IPC bool

localparam A_FAB_REG = 0 ; // @IPC bool

// localparam B_ADDR_WIDTH = 12 ; // @IPC int 10,20

// localparam B_DATA_WIDTH = 32 ; // @IPC int 1,1152

// localparam B_BE_WIDTH = 4 ; // @IPC int 1,128

localparam B_WRITE_MODE = "TRANSPARENT_WRITE"; // @IPC enum NORMAL_WRITE,TRANSPARENT_WRITE,READ_BEFORE_WRITE

localparam B_CLK_EN = 0 ; // @IPC bool

localparam B_ADDR_STROBE_EN = 0 ; // @IPC bool

// localparam B_OUTPUT_REG = 0 ; // @IPC bool

localparam B_RD_OCE_EN = 0 ; // @IPC bool

localparam B_CLK_OR_POL_INV = 0 ; // @IPC bool

localparam B_FAB_REG = 0 ; // @IPC bool

localparam INIT_EN = 0 ; // @IPC bool

localparam INIT_FILE = "NONE" ; // @IPC string

localparam INIT_FORMAT = "BIN" ; // @IPC enum BIN,HEX

localparam RST_VAL_EN = 0 ; // @IPC bool


input [A_ADDR_WIDTH-1 : 0]   a_addr        ;
input [A_DATA_WIDTH-1 : 0]   a_wr_data     ;
output[A_DATA_WIDTH-1 : 0]   a_rd_data     ;
input                        a_wr_en       ;
input                        a_clk         ;

input                        a_rst         ;

input [A_BE_WIDTH-1 : 0]     a_wr_byte_en  ;

input [B_ADDR_WIDTH-1 : 0]   b_addr        ;
input [B_DATA_WIDTH-1 : 0]   b_wr_data     ;
output[B_DATA_WIDTH-1 : 0]   b_rd_data     ;
input                        b_wr_en       ;
input                        b_clk         ;

input                        b_rst         ;

input [B_BE_WIDTH-1:0]       b_wr_byte_en  ;


wire [A_ADDR_WIDTH-1 : 0]    a_addr        ;
wire [A_DATA_WIDTH-1 : 0]    a_wr_data     ;
wire [A_DATA_WIDTH-1 : 0]    a_rd_data     ;
wire                         a_wr_en       ;
wire                         a_clk         ;
wire                         a_clk_en      ;
wire                         a_rst         ;
wire [A_BE_WIDTH-1 : 0]      a_wr_byte_en  ;
wire                         a_rd_oce      ;
wire                         a_addr_strobe ;

wire [B_ADDR_WIDTH-1 : 0]    b_addr        ;
wire [B_DATA_WIDTH-1 : 0]    b_wr_data     ;
wire [B_DATA_WIDTH-1 : 0]    b_rd_data     ;
wire                         b_wr_en       ;
wire                         b_clk         ;
wire                         b_clk_en      ;
wire                         b_rst         ;
wire [B_BE_WIDTH-1:0]        b_wr_byte_en  ;
wire                         b_rd_oce      ;
wire                         b_addr_strobe ;

wire [A_BE_WIDTH-1:0]        a_wr_byte_en_mux  ;
wire                         a_rd_oce_mux2d    ;
wire                         a_rd_oce_mux2f    ;
wire [B_BE_WIDTH-1:0]        b_wr_byte_en_mux  ;
wire                         b_rd_oce_mux2d    ;
wire                         b_rd_oce_mux2f    ;
wire                         a_clk_en_mux      ;
wire                         b_clk_en_mux      ;
wire                         a_addr_strobe_mux ;
wire                         b_addr_strobe_mux ;

wire [A_DATA_WIDTH-1 : 0]    a_rd_data_d;
wire [B_DATA_WIDTH-1 : 0]    b_rd_data_d;
reg  [A_DATA_WIDTH-1 : 0]    a_fab_reg_invt;
reg  [A_DATA_WIDTH-1 : 0]    a_fab_reg;
reg  [B_DATA_WIDTH-1 : 0]    b_fab_reg_invt;
reg  [B_DATA_WIDTH-1 : 0]    b_fab_reg;


assign a_wr_byte_en_mux  = (WR_BYTE_EN       == 1) ? a_wr_byte_en  : {A_BE_WIDTH{1'b1}} ;
assign a_rd_oce_mux2d    = ((A_FAB_REG       == 1) && (A_OUTPUT_REG == 1)) ? 1 :
                            (A_OUTPUT_REG    == 1) ? ((A_RD_OCE_EN  == 1)  ? a_rd_oce : 1'b1) : 1'b0 ;
assign a_rd_oce_mux2f    =  (A_FAB_REG       == 1) ? ((A_RD_OCE_EN  == 1)  ? a_rd_oce : 1'b1) : 1'b0 ;

assign b_wr_byte_en_mux  = (WR_BYTE_EN       == 1) ? b_wr_byte_en  : {B_BE_WIDTH{1'b1}} ;
assign b_rd_oce_mux2d    = ((B_FAB_REG       == 1) && (B_OUTPUT_REG == 1)) ? 1 :
                            (B_OUTPUT_REG    == 1) ? ((B_RD_OCE_EN  == 1)  ? b_rd_oce : 1'b1) : 1'b0 ;
assign b_rd_oce_mux2f    =  (B_FAB_REG       == 1) ? ((B_RD_OCE_EN  == 1)  ? b_rd_oce : 1'b1) : 1'b0 ;
assign a_clk_en_mux      = (A_CLK_EN         == 1) ? a_clk_en      : 1'b1 ;
assign b_clk_en_mux      = (B_CLK_EN         == 1) ? b_clk_en      : 1'b1 ;
assign a_addr_strobe_mux = (A_ADDR_STROBE_EN == 1) ? a_addr_strobe : 1'b0 ;
assign b_addr_strobe_mux = (B_ADDR_STROBE_EN == 1) ? b_addr_strobe : 1'b0 ;

ipmxj_axi_ram_ipm2l_dpram_v1_6 #(
    .c_CAS_MODE                (CAS_MODE                     ),
    .c_A_ADDR_WIDTH            (A_ADDR_WIDTH                 ),
    .c_A_DATA_WIDTH            (A_DATA_WIDTH                 ),
    .c_B_ADDR_WIDTH            (B_ADDR_WIDTH                 ),
    .c_B_DATA_WIDTH            (B_DATA_WIDTH                 ),
    .c_A_OUTPUT_REG            (A_OUTPUT_REG                 ),
    .c_B_OUTPUT_REG            (B_OUTPUT_REG                 ),
    .c_A_RD_OCE_EN             (A_RD_OCE_EN                  ),
    .c_B_RD_OCE_EN             (B_RD_OCE_EN                  ),
    .c_A_FAB_REG               (A_FAB_REG                    ),
    .c_B_FAB_REG               (B_FAB_REG                    ),
    .c_A_ADDR_STROBE_EN        (A_ADDR_STROBE_EN             ),
    .c_B_ADDR_STROBE_EN        (B_ADDR_STROBE_EN             ),
    .c_A_CLK_EN                (A_CLK_EN                     ),
    .c_B_CLK_EN                (B_CLK_EN                     ),
    .c_RESET_TYPE              (RESET_TYPE                   ),
    .c_A_CLK_OR_POL_INV        (A_CLK_OR_POL_INV             ),
    .c_B_CLK_OR_POL_INV        (B_CLK_OR_POL_INV             ),
    .c_POWER_OPT               (POWER_OPT                    ),
    .c_INIT_FILE               ("NONE"                       ),
    .c_INIT_FORMAT             (INIT_FORMAT                  ),
    .c_WR_BYTE_EN              (WR_BYTE_EN                   ),
    .c_A_BE_WIDTH              (A_BE_WIDTH                   ),
    .c_B_BE_WIDTH              (B_BE_WIDTH                   ),
    .c_A_WRITE_MODE            (A_WRITE_MODE                 ),
    .c_B_WRITE_MODE            (B_WRITE_MODE                 )
) ipm2l_dpram_v1_6_drm36K (
    .a_addr        ( a_addr             ),
    .a_wr_data     ( a_wr_data          ),
    
    .a_rd_data     ( a_rd_data          ),
    
    .a_wr_en       ( a_wr_en            ),
    .a_clk         ( a_clk              ),
    .a_clk_en      ( a_clk_en_mux       ),
    .a_rst         ( a_rst              ),
    .a_wr_byte_en  ( a_wr_byte_en_mux   ),
    .a_rd_oce      ( a_rd_oce_mux2d     ),
    .a_addr_strobe ( a_addr_strobe_mux  ),
    .b_addr        ( b_addr             ),
    .b_wr_data     ( b_wr_data          ),
    
    .b_rd_data     ( b_rd_data          ),
    
    .b_wr_en       ( b_wr_en            ),
    .b_clk         ( b_clk              ),
    .b_clk_en      ( b_clk_en_mux       ),
    .b_rst         ( b_rst              ),
    .b_wr_byte_en  ( b_wr_byte_en_mux   ),
    .b_rd_oce      ( b_rd_oce_mux2d     ),
    .b_addr_strobe ( b_addr_strobe_mux  )
);


generate
    if (A_FAB_REG == 1) begin

        assign a_rd_data = (A_FAB_REG == 1) ? ((A_CLK_OR_POL_INV == 1) ? a_fab_reg_invt : a_fab_reg) : a_rd_data_d ;
        if (A_CLK_OR_POL_INV == 1) begin
            always @(negedge a_clk or posedge a_rst) begin
                if (a_rst)
                    a_fab_reg_invt      <= {A_DATA_WIDTH{1'b0}};
                else if (a_rd_oce_mux2f)
                    a_fab_reg_invt      <= a_rd_data_d;                    
            end
        end
        else begin
            always @(posedge a_clk or posedge a_rst) begin
                if (a_rst)
                    a_fab_reg           <= {A_DATA_WIDTH{1'b0}};
                else if (a_rd_oce_mux2f)
                    a_fab_reg           <= a_rd_data_d;
            end
        end
    end

    if (B_FAB_REG == 1) begin

        assign b_rd_data = (B_FAB_REG == 1) ? ((B_CLK_OR_POL_INV == 1) ? b_fab_reg_invt : b_fab_reg) : b_rd_data_d ;
        if (B_CLK_OR_POL_INV == 1) begin
            always @(negedge b_clk or posedge b_rst) begin
                if (b_rst)
                    b_fab_reg_invt      <= {B_DATA_WIDTH{1'b0}};
                else if (b_rd_oce_mux2f)
                    b_fab_reg_invt      <= b_rd_data_d;                    
            end
        end
        else begin
            always @(posedge b_clk or posedge b_rst) begin
                if (b_rst)
                    b_fab_reg           <= {B_DATA_WIDTH{1'b0}};
                else if (b_rd_oce_mux2f)
                    b_fab_reg           <= b_rd_data_d;
            end
        end
    end
endgenerate


endmodule
