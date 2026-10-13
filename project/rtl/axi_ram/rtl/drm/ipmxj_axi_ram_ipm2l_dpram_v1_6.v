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
// Filename: ipmxj_axi_ram_ipm2l_dpram_v1_6.v
// Description: ipmxj_axi_ram_ipm2l_dpram_v1_6
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`timescale 1ns/1ps
module ipmxj_axi_ram_ipm2l_dpram_v1_6  #(
    parameter   c_CAS_MODE              = "18K"             ,   // "18K", "36K", "64K"
    parameter   c_A_ADDR_WIDTH          = 10                ,
    parameter   c_A_DATA_WIDTH          = 32                ,
    parameter   c_B_ADDR_WIDTH          = 10                ,
    parameter   c_B_DATA_WIDTH          = 32                ,
    parameter   c_A_OUTPUT_REG          = 0                 ,
    parameter   c_A_RD_OCE_EN           = 0                 ,
    parameter   c_A_FAB_REG             = 0                 ,
    parameter   c_A_ADDR_STROBE_EN      = 0                 ,
    parameter   c_A_CLK_EN              = 0                 ,
    parameter   c_B_OUTPUT_REG          = 0                 ,
    parameter   c_B_RD_OCE_EN           = 0                 ,
    parameter   c_B_FAB_REG             = 0                 ,
    parameter   c_B_ADDR_STROBE_EN      = 0                 ,
    parameter   c_B_CLK_EN              = 0                 ,
    parameter   c_RESET_TYPE            = "ASYNC"           ,
    parameter   c_A_CLK_OR_POL_INV      = 0                 ,
    parameter   c_B_CLK_OR_POL_INV      = 0                 ,
    parameter   c_POWER_OPT             = 0                 ,
    parameter   c_INIT_FILE             = "NONE"            ,
    parameter   c_INIT_FORMAT           = "BIN"             ,
    parameter   c_WR_BYTE_EN            = 0                 ,
    parameter   c_A_BE_WIDTH            = 8                 ,
    parameter   c_B_BE_WIDTH            = 8                 ,
    parameter   c_A_WRITE_MODE          = "NORMAL_WRITE"    ,
    parameter   c_B_WRITE_MODE          = "NORMAL_WRITE"
) (
    input   wire    [c_A_ADDR_WIDTH-1 : 0]  a_addr          ,
    input   wire    [c_A_DATA_WIDTH-1 : 0]  a_wr_data       ,
    output  wire    [c_A_DATA_WIDTH-1 : 0]  a_rd_data       ,
    input   wire                            a_wr_en         ,
    input   wire                            a_clk           ,
    input   wire                            a_clk_en        ,
    input   wire                            a_rst           ,
    input   wire    [c_A_BE_WIDTH-1 : 0]    a_wr_byte_en    ,
    input   wire                            a_rd_oce        ,
    input   wire                            a_addr_strobe   ,

    input   wire    [c_B_ADDR_WIDTH-1 : 0]  b_addr          ,
    input   wire    [c_B_DATA_WIDTH-1 : 0]  b_wr_data       ,
    output  wire    [c_B_DATA_WIDTH-1 : 0]  b_rd_data       ,
    input   wire                            b_wr_en         ,
    input   wire                            b_clk           ,
    input   wire                            b_clk_en        ,
    input   wire                            b_rst           ,
    input   wire    [c_B_BE_WIDTH-1:0]      b_wr_byte_en    ,
    input   wire                            b_rd_oce        ,
    input   wire                            b_addr_strobe
);

localparam INIT_EN = 0 ; // @IPC bool
localparam RST_VAL_EN = 0 ; // @IPC bool

    localparam  c_WR_BYTE_WIDTH = c_WR_BYTE_EN ? (c_A_DATA_WIDTH/(c_A_BE_WIDTH==0 ? 1 : c_A_BE_WIDTH)) : ( (c_A_DATA_WIDTH%9 ==0) ? 9 : (c_A_DATA_WIDTH%8 ==0) ? 8 : 9 );

    //WIDTH_RATIO = 1
    localparam  DATA_WIDTH_WIDE  = (c_A_DATA_WIDTH >= c_B_DATA_WIDTH) ? c_A_DATA_WIDTH :c_B_DATA_WIDTH ;
    localparam  ADDR_WIDTH_WIDE  = (c_A_DATA_WIDTH >= c_B_DATA_WIDTH) ? c_A_ADDR_WIDTH :c_B_ADDR_WIDTH ;

    localparam  N_DATA_1_WIDTH   =  (ADDR_WIDTH_WIDE <= 10) ? ((DATA_WIDTH_WIDE%9) == 0 ? 36 : (DATA_WIDTH_WIDE%8) == 0 ? 32 : 36) :
                                    (ADDR_WIDTH_WIDE == 11) ? ((DATA_WIDTH_WIDE%9) == 0 ? 18 : (DATA_WIDTH_WIDE%8) == 0 ? 16 : 18) :
                                    (ADDR_WIDTH_WIDE == 12) ? ((DATA_WIDTH_WIDE%9) == 0 ? 9  : (DATA_WIDTH_WIDE%8) == 0 ? 8  : 9 ) :
                                    (ADDR_WIDTH_WIDE == 13) ? 4 :
                                    (ADDR_WIDTH_WIDE == 14) ? 2 :
                                                              1 ;

    localparam  L_DATA_1_WIDTH   =  (DATA_WIDTH_WIDE == 1)  ? 1 :
                                    (DATA_WIDTH_WIDE == 2)  ? 2 :
                                    (DATA_WIDTH_WIDE <= 4)  ? 4 :
                                    (DATA_WIDTH_WIDE <= 9)  ? ((DATA_WIDTH_WIDE%9) == 0 ? 9  : (DATA_WIDTH_WIDE%8) == 0 ? 8  : 9 ) :
                                    (DATA_WIDTH_WIDE <= 18) ? ((DATA_WIDTH_WIDE%9) == 0 ? 18 : (DATA_WIDTH_WIDE%8) == 0 ? 16 : 18) :
                                                              ((DATA_WIDTH_WIDE%9) == 0 ? 36 : (DATA_WIDTH_WIDE%8) == 0 ? 32 : 36) ;

    //WIDTH_RATIO = 2
    localparam  N_DATA_WIDTH_2_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ?  ((ADDR_WIDTH_WIDE <= 10) ? 36 : 18) :
    	                                      (( ADDR_WIDTH_WIDE <= 10 ) ? 32 :
                                           (ADDR_WIDTH_WIDE <= 11) ?  16 :
                                            (ADDR_WIDTH_WIDE == 12) ?  8  :
                                            (ADDR_WIDTH_WIDE == 13) ?  4  :
                                                                       2  );

    localparam  L_DATA_WIDTH_2_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ? ((DATA_WIDTH_WIDE <= 18) ? 18 : 36) :
                                         ((DATA_WIDTH_WIDE == 2)    ? 2  :
                                          (DATA_WIDTH_WIDE == 4)    ? 4  :
                                          (DATA_WIDTH_WIDE == 8)    ? 8  :
                                          (DATA_WIDTH_WIDE == 16)   ? 16 :
                                                                      32 );

    //WIDTH_RATIO == 4
    localparam  N_DATA_WIDTH_4_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ? 36 :
                                              ADDR_WIDTH_WIDE <= 10 ? 32 :
                                              ADDR_WIDTH_WIDE == 11 ? 16 :
                                              ADDR_WIDTH_WIDE == 12 ? 8  :
                                                                      4  ;

    localparam  L_DATA_WIDTH_4_WIDE   =  ((DATA_WIDTH_WIDE%9) == 0) ? 36 :
                                            (DATA_WIDTH_WIDE == 4)  ? 4  :
                                            (DATA_WIDTH_WIDE == 8)  ? 8  :
                                            (DATA_WIDTH_WIDE == 16) ? 16 :
                                                                      32 ;

    //WIDTH_RATIO == 8
    localparam  N_DATA_WIDTH_8_WIDE   =  (ADDR_WIDTH_WIDE <= 10) ? 32 :
                                         (ADDR_WIDTH_WIDE == 11) ? 16 :
                                                                   8  ;

    localparam  L_DATA_WIDTH_8_WIDE   =  (DATA_WIDTH_WIDE == 8)  ? 8  :
                                         (DATA_WIDTH_WIDE == 16) ? 16 :
                                                                   32 ;

    //WIDTH_RATIO == 16
    localparam  N_DATA_WIDTH_16_WIDE  =  (ADDR_WIDTH_WIDE <= 10) ? 32 :
                                                                   16 ;

    localparam  L_DATA_WIDTH_16_WIDE  =  (DATA_WIDTH_WIDE == 16)  ? 16  :
                                                                   32 ;
    //WIDTH_RATIO == 32
    localparam  N_DATA_WIDTH_32_WIDE  =  32 ;
    localparam  L_DATA_WIDTH_32_WIDE  =  32 ;

    //**************************************************************************
    //BYTE ENABLE parameter
    //byte_enable==1 && WIDTH_RATIO = 1
    localparam  N_BYTE_DATA_1_WIDTH = (c_WR_BYTE_WIDTH == 8) ? ((ADDR_WIDTH_WIDE <= 10) ? 32 : 16) : ((ADDR_WIDTH_WIDE <= 10) ? 36 : 18);
    localparam  L_BYTE_DATA_1_WIDTH = (c_WR_BYTE_WIDTH == 8) ? ((DATA_WIDTH_WIDE >  16) ? 32 : 16) : ((DATA_WIDTH_WIDE >  18) ? 36 : 18);

    //byte_enable==1 && WIDTH_RATIO = 2
    localparam  N_BYTE_DATA_WIDTH_2_WIDE = (c_WR_BYTE_WIDTH == 8) ? ((ADDR_WIDTH_WIDE <= 10) ? 32 : 16) : ((ADDR_WIDTH_WIDE <= 10) ? 36 : 18);
    localparam  L_BYTE_DATA_WIDTH_2_WIDE = (c_WR_BYTE_WIDTH == 8) ? ((DATA_WIDTH_WIDE >  16) ? 32 : 16) : ((DATA_WIDTH_WIDE >  18) ? 36 : 18);

    //byte_enable==1 && WIDTH_RATIO = 4
    localparam  N_BYTE_DATA_WIDTH_4_WIDE = (c_WR_BYTE_WIDTH == 8) ? 32 : 36;
    localparam  L_BYTE_DATA_WIDTH_4_WIDE = (c_WR_BYTE_WIDTH == 8) ? 32 : 36;

    //**************************************************************************
    localparam  WIDTH_RATIO  =  (c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? (c_A_DATA_WIDTH/c_B_DATA_WIDTH) : (c_B_DATA_WIDTH/c_A_DATA_WIDTH);

    localparam  N_DRM_DATA_WIDTH_A  = (WIDTH_RATIO == 1)  ? N_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_2_WIDE  : (N_DATA_WIDTH_2_WIDE/2)  ):
                                      (WIDTH_RATIO == 4)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_4_WIDE  : (N_DATA_WIDTH_4_WIDE/4)  ):
                                      (WIDTH_RATIO == 8)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_8_WIDE  : (N_DATA_WIDTH_8_WIDE/8)  ):
                                      (WIDTH_RATIO == 16) ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_16_WIDE : (N_DATA_WIDTH_16_WIDE/16)):
                                                            ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_DATA_WIDTH_32_WIDE : (N_DATA_WIDTH_32_WIDE/32));

    localparam  L_DRM_DATA_WIDTH_A  = (WIDTH_RATIO == 1)  ? L_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_2_WIDE  : (L_DATA_WIDTH_2_WIDE/2)  ):
                                      (WIDTH_RATIO == 4)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_4_WIDE  : (L_DATA_WIDTH_4_WIDE/4)  ):
                                      (WIDTH_RATIO == 8)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_8_WIDE  : (L_DATA_WIDTH_8_WIDE/8)  ):
                                      (WIDTH_RATIO == 16) ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_16_WIDE : (L_DATA_WIDTH_16_WIDE/16)):
                                                            ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_DATA_WIDTH_32_WIDE : (L_DATA_WIDTH_32_WIDE/32));

    localparam  N_DRM_DATA_WIDTH_B  = (WIDTH_RATIO == 1)  ? N_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_2_WIDE  : (N_DATA_WIDTH_2_WIDE/2)  ):
                                      (WIDTH_RATIO == 4)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_4_WIDE  : (N_DATA_WIDTH_4_WIDE/4)  ):
                                      (WIDTH_RATIO == 8)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_8_WIDE  : (N_DATA_WIDTH_8_WIDE/8)  ):
                                      (WIDTH_RATIO == 16) ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_16_WIDE : (N_DATA_WIDTH_16_WIDE/16)):
                                                            ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_DATA_WIDTH_32_WIDE : (N_DATA_WIDTH_32_WIDE/32));

    localparam  L_DRM_DATA_WIDTH_B  = (WIDTH_RATIO == 1)  ? L_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_2_WIDE  : (L_DATA_WIDTH_2_WIDE/2)  ):
                                      (WIDTH_RATIO == 4)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_4_WIDE  : (L_DATA_WIDTH_4_WIDE/4)  ):
                                      (WIDTH_RATIO == 8)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_8_WIDE  : (L_DATA_WIDTH_8_WIDE/8)  ):
                                      (WIDTH_RATIO == 16) ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_16_WIDE : (L_DATA_WIDTH_16_WIDE/16)):
                                                            ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_DATA_WIDTH_32_WIDE : (L_DATA_WIDTH_32_WIDE/32));

    //**************************************************************************
    //byte_enable  DRM DATA WIDTH
    localparam  N_BYTE_DATA_WIDTH_A = (WIDTH_RATIO == 1)  ? N_BYTE_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_2_WIDE  : (N_BYTE_DATA_WIDTH_2_WIDE/2)) :
                                                            ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_4_WIDE  : (N_BYTE_DATA_WIDTH_4_WIDE/4)) ;

    localparam  L_BYTE_DATA_WIDTH_A = (WIDTH_RATIO == 1)  ? L_BYTE_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_2_WIDE  : (L_BYTE_DATA_WIDTH_2_WIDE/2)) :
                                                            ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_4_WIDE  : (L_BYTE_DATA_WIDTH_4_WIDE/4)) ;

    localparam  N_BYTE_DATA_WIDTH_B = (WIDTH_RATIO == 1)  ? N_BYTE_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_2_WIDE  : (N_BYTE_DATA_WIDTH_2_WIDE/2)) :
                                                            ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? N_BYTE_DATA_WIDTH_4_WIDE  : (N_BYTE_DATA_WIDTH_4_WIDE/4)) ;

    localparam  L_BYTE_DATA_WIDTH_B = (WIDTH_RATIO == 1)  ? L_BYTE_DATA_1_WIDTH :
                                      (WIDTH_RATIO == 2)  ? ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_2_WIDE  : (L_BYTE_DATA_WIDTH_2_WIDE/2)) :
                                                            ((c_B_DATA_WIDTH > c_A_DATA_WIDTH) ? L_BYTE_DATA_WIDTH_4_WIDE  : (L_BYTE_DATA_WIDTH_4_WIDE/4)) ;

    //**************************************************************************
    //DRM_DATA_WIDTH_A is the  port A parameter  of DRM
    localparam  DRM_DATA_WIDTH_A  = (c_POWER_OPT == 1) ? ((c_WR_BYTE_EN ==1) ? L_BYTE_DATA_WIDTH_A : L_DRM_DATA_WIDTH_A):
                                                         ((c_WR_BYTE_EN ==1) ? N_BYTE_DATA_WIDTH_A : N_DRM_DATA_WIDTH_A);

    //DRM_DATA_WIDTH_A is the  port B parameter  of DRM
    localparam  DRM_DATA_WIDTH_B  = (c_POWER_OPT == 1) ? ((c_WR_BYTE_EN ==1) ? L_BYTE_DATA_WIDTH_B : L_DRM_DATA_WIDTH_B):
                                                         ((c_WR_BYTE_EN ==1) ? N_BYTE_DATA_WIDTH_B : N_DRM_DATA_WIDTH_B);

    //DATA_LOOP_NUM difine how many loop to cascade the c_A_DATA_WIDTH
    localparam  DATA_LOOP_NUM   = (c_A_DATA_WIDTH%DRM_DATA_WIDTH_A == 0) ? (c_A_DATA_WIDTH/DRM_DATA_WIDTH_A):(c_A_DATA_WIDTH/DRM_DATA_WIDTH_A + 1);

    //DRM_ADDR_WIDTH is the ADDR_WIDTH of INSTANCE DRM primitives
    localparam  DRM_ADDR_WIDTH_A = (DRM_DATA_WIDTH_A == 1 ) ? 15:
                                   (DRM_DATA_WIDTH_A == 2 ) ? 14:
                                   (DRM_DATA_WIDTH_A == 4 ) ? 13:
                                   (DRM_DATA_WIDTH_A == 8 ) ? 12:
                                   (DRM_DATA_WIDTH_A == 9 ) ? 12:
                                   (DRM_DATA_WIDTH_A == 16) ? 11:
                                   (DRM_DATA_WIDTH_A == 18) ? 11:
                                   (DRM_DATA_WIDTH_A == 32) ? 10:
                                                              10;

    localparam  DRM_ADDR_WIDTH_B = (DRM_DATA_WIDTH_B == 1 ) ? 15:
                                   (DRM_DATA_WIDTH_B == 2 ) ? 14:
                                   (DRM_DATA_WIDTH_B == 4 ) ? 13:
                                   (DRM_DATA_WIDTH_B == 8 ) ? 12:
                                   (DRM_DATA_WIDTH_B == 9 ) ? 12:
                                   (DRM_DATA_WIDTH_B == 16) ? 11:
                                   (DRM_DATA_WIDTH_B == 18) ? 11:
                                   (DRM_DATA_WIDTH_B == 32) ? 10:
                                                              10;

    //CS_ADDR_WIDTH_A is the CS address width to choose the DRM18K CS_ADDR_WIDTH_A=  [ extra-addres + cs[2]+csp[1]+cs[0] ]
    localparam  ADDR_WIDTH_A     = (c_A_ADDR_WIDTH > DRM_ADDR_WIDTH_A) ? c_A_ADDR_WIDTH : DRM_ADDR_WIDTH_A;
    localparam  CS_ADDR_WIDTH_A  = ADDR_WIDTH_A - DRM_ADDR_WIDTH_A; //CS mean select

    localparam  ADDR_WIDTH_B     = (c_B_ADDR_WIDTH > DRM_ADDR_WIDTH_B) ? c_B_ADDR_WIDTH : DRM_ADDR_WIDTH_B;
    localparam  CS_ADDR_WIDTH_B  = ADDR_WIDTH_B - DRM_ADDR_WIDTH_B;

    //ADDR_LOOP_NUM_A difine how many loops to cascade the c_A_ADDR_WIDTH
    localparam  ADDR_LOOP_NUM_A  = 2**CS_ADDR_WIDTH_A;
    localparam  ADDR_LOOP_NUM_B  = 2**CS_ADDR_WIDTH_B;

    //CAS_DATA_WIDTH_A is the cascaded  data width
    localparam  CAS_DATA_WIDTH_A  =  DRM_DATA_WIDTH_A*DATA_LOOP_NUM ;  //CAS mean cascade
    localparam  CAS_DATA_WIDTH_B  =  DRM_DATA_WIDTH_B*DATA_LOOP_NUM ;

    localparam  A_WR_BYTE_WIDTH   =  (c_WR_BYTE_EN == 1) ? c_WR_BYTE_WIDTH :
                                     (((DRM_DATA_WIDTH_A >=8) || (DRM_DATA_WIDTH_A >=9)) ? ((c_A_DATA_WIDTH%9 == 0) ? 9 : 8 ) : 1 );
    localparam  B_WR_BYTE_WIDTH   =  (c_WR_BYTE_EN == 1) ? c_WR_BYTE_WIDTH :
                                     (((DRM_DATA_WIDTH_B >=8) || (DRM_DATA_WIDTH_B >=9)) ? ((c_B_DATA_WIDTH%9 == 0) ? 9 : 8 ) : 1 );

    //MASK_NUM the mask base value
    localparam  MASK_NUM_A  = (ADDR_LOOP_NUM_A > 8) ? 4 : 8;
    localparam  MASK_NUM_B  = (ADDR_LOOP_NUM_B > 8) ? 4 : 8;

    initial begin
        if( (2**c_A_ADDR_WIDTH*c_A_DATA_WIDTH) != (2**c_B_ADDR_WIDTH*c_B_DATA_WIDTH) ) begin
            $display("IPSpecCheck: 04030028 ipm2l_flex_dpram parameter setting error !!!: 2**c_A_ADDR_WIDTH*c_A_DATA_WIDTH must be equal to 2**c_B_ADDR_WIDTH*c_B_DATA_WIDTH")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( c_A_ADDR_WIDTH>20  || c_A_ADDR_WIDTH<10 ) begin
            $display("IPSpecCheck: 04030029 ipm2l_flex_dpram parameter setting error !!!: c_A_ADDR_WIDTH must between 10-20 when DRM Resource is 36K")/* PANGO PAP_CRITICAL_WARNING */;
//            $finish;
        end
        else if( c_B_ADDR_WIDTH>20  || c_B_ADDR_WIDTH<10 ) begin
            $display("IPSpecCheck: 04030030 ipm2l_flex_dpram parameter setting error !!!: c_B_ADDR_WIDTH must between 10-20 when DRM Resource is 36K")/* PANGO PAP_CRITICAL_WARNING */;
//            $finish;
        end
        else if( c_A_DATA_WIDTH>1152  || c_A_DATA_WIDTH <1 ) begin
            $display("IPSpecCheck: 04030031 ipm2l_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH must between 1-1152")/* PANGO PAP_CRITICAL_WARNING */;
//            $finish;
        end
        else if( c_B_DATA_WIDTH>1152  || c_B_DATA_WIDTH <1 ) begin
            $display("IPSpecCheck: 04030032 ipm2l_flex_dpram parameter setting error !!!: c_B_DATA_WIDTH must between 1-1152")/* PANGO PAP_CRITICAL_WARNING */;
//            $finish;
        end
        else if( (c_A_OUTPUT_REG!=1 && c_A_OUTPUT_REG!=0) || (c_B_OUTPUT_REG!=1 && c_B_OUTPUT_REG!=0) ) begin
            $display("IPSpecCheck: 04030033 ipm2l_flex_dpram parameter setting error !!!: c_A_OUTPUT_REG or c_B_OUTPUT_REG must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( (c_A_RD_OCE_EN!=1 && c_A_RD_OCE_EN!=0) || (c_B_RD_OCE_EN!=1 && c_B_RD_OCE_EN!=0) ) begin
            $display("IPSpecCheck: 04030034 ipm2l_flex_dpram parameter setting error !!!: c_A_RD_OCE_EN or c_B_RD_OCE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( (c_A_CLK_OR_POL_INV!=1 && c_A_CLK_OR_POL_INV!=0 ) || (c_B_CLK_OR_POL_INV!=1 && c_B_CLK_OR_POL_INV!=0) ) begin
            $display("IPSpecCheck: 04030035 ipm2l_flex_dpram parameter setting error !!!: c_A_CLK_OR_POL_INV or c_B_CLK_OR_POL_INV must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if ( (c_A_FAB_REG!=1 && c_A_FAB_REG!=0) || (c_B_FAB_REG!=1 && c_B_FAB_REG!=0) ) begin
            $display("IPSpecCheck: 04030053 ipm2l_flex_dpram parameter setting error !!!: c_A_FAB_REG or c_B_FAB_REG must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( (c_A_RD_OCE_EN==1 && (c_A_OUTPUT_REG==0 && c_A_FAB_REG==0)) || (c_B_RD_OCE_EN==1 && (c_B_OUTPUT_REG==0 && c_B_FAB_REG==0)) ) begin
            $display("IPSpecCheck: 04030009 ipm2l_flex_dpram parameter setting error !!!: c_A|B_OUTPUT_REG and c_A|B_FAB_REG could not be 0 at same time when c_A|B_RD_OCE_EN is 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( (c_A_CLK_OR_POL_INV==1 && (c_A_OUTPUT_REG==0 && c_A_FAB_REG==0)) || (c_B_CLK_OR_POL_INV==1 && (c_B_OUTPUT_REG==0 && c_B_FAB_REG==0)) ) begin
            $display("IPSpecCheck: 04030010 ipm2l_flex_dpram parameter setting error !!!: c_A|B_OUTPUT_REG and c_A|B_FAB_REG could not be 0 at same time when c_A|B_CLK_OR_POL_INV is 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if ( (c_A_CLK_EN!=0 && c_A_CLK_EN!=1) || (c_B_CLK_EN!=0 && c_B_CLK_EN!=1) ) begin
            $display("IPSpecCheck: 04030038 ipm2l_flex_dpram parameter setting error !!!: c_A_CLK_EN or c_B_CLK_EN must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if ( (c_A_ADDR_STROBE_EN!=0 && c_A_ADDR_STROBE_EN!=1) || (c_B_ADDR_STROBE_EN!=0 && c_B_ADDR_STROBE_EN!=1) ) begin
            $display("IPSpecCheck: 04030039 ipm2l_flex_dpram parameter setting error !!!: c_A_ADDR_STROBE_EN or c_B_ADDR_STROBE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_RESET_TYPE!="ASYNC" && c_RESET_TYPE!="SYNC") begin
            $display("IPSpecCheck: 04030040 ipm2l_flex_dpram parameter setting error !!!: c_RESET_TYPE must be ASYNC or SYNC")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_POWER_OPT!=1 && c_POWER_OPT!=0 ) begin
            $display("IPSpecCheck: 04030041 ipm2l_flex_dpram parameter setting error !!!: c_POWER_OPT must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_INIT_FORMAT!="BIN" && c_INIT_FORMAT!="HEX" ) begin
            $display("IPSpecCheck: 04030042 ipm2l_flex_dpram parameter setting error !!!: c_INIT_FORMAT must be BIN or HEX ")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_WR_BYTE_EN!=0 && c_WR_BYTE_EN!=1 ) begin
            $display("IPSpecCheck: 04030043 ipm2l_flex_dpram parameter setting error !!!: c_WR_BYTE_EN must be 0 or 1")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_A_WRITE_MODE!="NORMAL_WRITE" && c_A_WRITE_MODE!="TRANSPARENT_WRITE" && c_A_WRITE_MODE!="READ_BEFORE_WRITE") begin
            $display("IPSpecCheck: 04030046 ipm2l_flex_dpram parameter setting error !!!: c_A_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_B_WRITE_MODE!="NORMAL_WRITE" && c_B_WRITE_MODE!="TRANSPARENT_WRITE" && c_B_WRITE_MODE!="READ_BEFORE_WRITE") begin
            $display("IPSpecCheck: 04030047 ipm2l_flex_dpram parameter setting error !!!: c_B_WRITE_MODE must be NORMAL_WRITE or TRANSPARENT_WRITE or READ_BEFORE_WRITE")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( ((WIDTH_RATIO > 32) && (c_WR_BYTE_EN == 0)) ) begin
            $display("IPSpecCheck: 04030048 ipm2l_flex_dpram parameter setting error !!!: Data Width Ratio is 1~32 when disable Byte Write and DRM Resource is 36K")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if( ((WIDTH_RATIO > 4) && (c_WR_BYTE_EN == 1)) ) begin
            $display("IPSpecCheck: 04030049 ipm2l_flex_dpram parameter setting error !!!: Data Width Ratio is 1~4 when enable Byte Write and DRM Resource is 36K")/* PANGO PAP_ERROR */;
            $finish;
        end
        else if(c_WR_BYTE_EN==1) begin
            if(c_WR_BYTE_WIDTH!=8 &&  c_WR_BYTE_WIDTH!=9 ) begin
                $display("IPSpecCheck: 04030044 ipm2l_flex_dpram parameter setting error !!!: c_WR_BYTE_WIDTH must be 8 or 9")/* PANGO PAP_ERROR */;
                $finish;
            end
            if( (c_A_DATA_WIDTH%8)!=0 && (c_B_DATA_WIDTH%9)!=0 ) begin
                $display("IPSpecCheck: 04030045 ipm2l_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH must be 8*N or 9*N")/* PANGO PAP_ERROR */;
                $finish;
            end
        end 
      
        else if(c_A_DATA_WIDTH != c_B_DATA_WIDTH) begin
            if( c_A_DATA_WIDTH%9 == 0 || c_B_DATA_WIDTH%9 == 0 ) begin
                if ( (c_A_DATA_WIDTH/9)&(c_A_DATA_WIDTH/9-1) || (c_B_DATA_WIDTH/9)&(c_B_DATA_WIDTH/9-1) ) begin
                    $display("IPSpecCheck: 04030027 ipm2l_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH and c_B_DATA_WIDTH must be 2^N or 9*2^N when mixed data width")/* PANGO PAP_ERROR */;
                    $finish;
                end
                else if ( WIDTH_RATIO>4 ) begin
                    $display("IPSpecCheck: 04030028 ipm2l_flex_dpram parameter setting error !!!: Data Width Ratio is 1~4 when c_A_DATA_WIDTH and c_B_DATA_WIDTH is 9*2^N and DRM Resource is 36K")/* PANGO PAP_ERROR */;
                    $finish;
                end
            end
            else begin
                if ( c_A_DATA_WIDTH&(c_A_DATA_WIDTH-1) || c_B_DATA_WIDTH&(c_B_DATA_WIDTH-1) ) begin
                    $display("IPSpecCheck: 04030027 ipm2l_flex_dpram parameter setting error !!!: c_A_DATA_WIDTH and c_B_DATA_WIDTH must be 2^N or 9*2^N when mixed data width")/* PANGO PAP_ERROR */;
                    $finish;
                end
            end
        end
    end

    //main code
    //******************************************************************************
    //inner variables
    wire  [CAS_DATA_WIDTH_A-1:0]                  a_wr_data_bus    ;
    reg   [CAS_DATA_WIDTH_A-1:0]                  a_wr_data_mix_bus;
    wire  [CAS_DATA_WIDTH_A*ADDR_LOOP_NUM_A-1:0]  a_rd_data_bus    ;
    wire  [ADDR_WIDTH_A-1:0]                      a_addr_bus       ;
    reg   [DATA_LOOP_NUM*16-1:0]                  drm_a_addr       ;
    reg                                           a_cs_bit0        ;
    reg                                           a_cs_bit1        ;
    reg   [ADDR_LOOP_NUM_A-1:0]                   a_cs_bit2_bus    ;
    reg   [DATA_LOOP_NUM-1:0 ]                    a_wr_en_bus      ;

    reg   [CAS_DATA_WIDTH_A-1:0]                  a_rd_mix_data    ;
    reg   [CAS_DATA_WIDTH_A-1:0]                  a_rd_full_data   ;

    wire  [CAS_DATA_WIDTH_B-1:0]                  b_wr_data_bus    ;
    reg   [CAS_DATA_WIDTH_B-1:0]                  b_wr_data_mix_bus;
    wire  [CAS_DATA_WIDTH_B*ADDR_LOOP_NUM_B-1:0]  b_rd_data_bus    ;
    wire  [ADDR_WIDTH_B-1:0]                      b_addr_bus       ;
    reg   [DATA_LOOP_NUM*16-1:0]                  drm_b_addr       ;
    reg                                           b_cs_bit0        ;
    reg                                           b_cs_bit1        ;
    reg   [ADDR_LOOP_NUM_B-1:0]                   b_cs_bit2_bus    ;
    reg   [DATA_LOOP_NUM-1:0]                     b_wr_en_bus      ;

    reg   [CAS_DATA_WIDTH_B-1:0]                  b_rd_mix_data    ;
    reg   [CAS_DATA_WIDTH_B-1:0]                  b_rd_full_data   ;

    wire  [8*DATA_LOOP_NUM-1 : 0]      a_wr_byte_en_bus_p;
    wire  [4*DATA_LOOP_NUM-1 : 0]      b_wr_byte_en_bus_p;
    reg   [8*DATA_LOOP_NUM-1 : 0]      a_wr_byte_en_bus;
    reg   [4*DATA_LOOP_NUM-1 : 0]      b_wr_byte_en_bus;
    wire  [8*DATA_LOOP_NUM-1 : 0]      a_wr_byte_en_bus_m;
    wire  [4*DATA_LOOP_NUM-1 : 0]      b_wr_byte_en_bus_m;

    assign  a_wr_data_bus[CAS_DATA_WIDTH_A-1:0] = {{(CAS_DATA_WIDTH_A-c_A_DATA_WIDTH){1'b0}},a_wr_data[c_A_DATA_WIDTH-1:0]};
    assign  b_wr_data_bus[CAS_DATA_WIDTH_B-1:0] = {{(CAS_DATA_WIDTH_B-c_B_DATA_WIDTH){1'b0}},b_wr_data[c_B_DATA_WIDTH-1:0]};

    assign  a_addr_bus[ADDR_WIDTH_A-1:0] = {{(ADDR_WIDTH_A-c_A_ADDR_WIDTH){1'b0}},a_addr[c_A_ADDR_WIDTH-1:0]};
    assign  b_addr_bus[ADDR_WIDTH_B-1:0] = {{(ADDR_WIDTH_B-c_B_ADDR_WIDTH){1'b0}},b_addr[c_B_ADDR_WIDTH-1:0]};

    //drm_a_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
    //generate drm_a_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
    integer gen_drm_a;
    generate
    always@(*) begin
       for(gen_drm_a=0;gen_drm_a < DATA_LOOP_NUM;gen_drm_a = gen_drm_a +1 ) begin
//          if (DRM_DATA_WIDTH_B == 32 || DRM_DATA_WIDTH_B == 36) begin
//             case(DRM_DATA_WIDTH_A)
//                1      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[4],a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):5],a_addr_bus[3:0]};
//                2      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[3],a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):4],a_addr_bus[2:0],1'b0};
//                4      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[2],a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):3],a_addr_bus[1:0],2'b00};
//                8,9    : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[1],a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):2],a_addr_bus[0],3'b000};
//                16,18  : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[0],a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):1],4'b0000};
//                32,36  : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],5'b00000};
//                default: drm_a_addr[gen_drm_a*16 +: 16]  = 16'b0;
//             endcase
//          end
//          else begin
             case(DRM_DATA_WIDTH_A)
                1      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0]};
                2      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],1'b0};
                4      : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],2'b00};
                8,9    : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],3'b000};
                16,18  : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],4'b0000};
                32,36  : drm_a_addr[gen_drm_a*16 +: 16]  = {1'b1,a_addr_bus[(ADDR_WIDTH_A-CS_ADDR_WIDTH_A-1):0],5'b00000};
                default: drm_a_addr[gen_drm_a*16 +: 16]  = 16'b0;
             endcase
//          end
       end
    end
    endgenerate
    //******************************************************************************
    //generate wr_data_mix_bus, a_wr_en_bus and a_wr_byte_en_bus
    assign a_wr_byte_en_bus_p = (c_WR_BYTE_EN == 0) ? {{8*DATA_LOOP_NUM}{1'b1}} : {{(8*DATA_LOOP_NUM-c_A_BE_WIDTH){1'b0}},a_wr_byte_en[c_A_BE_WIDTH-1:0]};
    assign b_wr_byte_en_bus_p = (c_WR_BYTE_EN == 0) ? {{4*DATA_LOOP_NUM}{1'b1}} : {{(4*DATA_LOOP_NUM-c_B_BE_WIDTH){1'b0}},b_wr_byte_en[c_B_BE_WIDTH-1:0]};

    genvar  gen_i_ad,gen_j_ad;
    localparam DATA_DUTY_RATIO = (DRM_DATA_WIDTH_A < c_A_DATA_WIDTH) ? 1 : (DRM_DATA_WIDTH_A / c_A_DATA_WIDTH);
    generate
    //generate a_wr_data_mix_bus
        if((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
            for ( gen_i_ad=0;gen_i_ad<DATA_LOOP_NUM;gen_i_ad=gen_i_ad+1 )
                for( gen_j_ad=0;gen_j_ad<WIDTH_RATIO;gen_j_ad=gen_j_ad+1 )
                    always@(*)
                    a_wr_data_mix_bus[gen_i_ad*DRM_DATA_WIDTH_A+gen_j_ad*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B] = a_wr_data_bus[(gen_i_ad + gen_j_ad*DATA_LOOP_NUM)*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
        end
        else if ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM==1)&&(DRM_DATA_WIDTH_A > c_A_DATA_WIDTH)) begin
            for( gen_j_ad=0;gen_j_ad<WIDTH_RATIO;gen_j_ad=gen_j_ad+1 )
                always@(*)
                    a_wr_data_mix_bus[gen_j_ad*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B] =  {{(DRM_DATA_WIDTH_B-c_B_DATA_WIDTH){1'b0}},a_wr_data_bus[gen_j_ad*c_B_DATA_WIDTH +:c_B_DATA_WIDTH]};
        end
        else begin
            always@(*)
                a_wr_data_mix_bus = a_wr_data_bus;
        end
        //generate a_wr_en_bus
        for (gen_i_ad=0;gen_i_ad < DATA_LOOP_NUM;gen_i_ad =gen_i_ad+1)
            always@(*)
            a_wr_en_bus[gen_i_ad] = a_wr_en;
        //generate a_wr_byte_en_bus
        if( c_A_DATA_WIDTH > c_B_DATA_WIDTH && DATA_LOOP_NUM > 1 && c_WR_BYTE_EN == 1) begin
            for (gen_i_ad=0;gen_i_ad < DATA_LOOP_NUM;gen_i_ad =gen_i_ad+1)
                for( gen_j_ad=0;gen_j_ad<WIDTH_RATIO;gen_j_ad=gen_j_ad+1 )
                    always@(*)
                    a_wr_byte_en_bus[gen_i_ad*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)+gen_j_ad*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)] = a_wr_byte_en_bus_p[(gen_i_ad + gen_j_ad*DATA_LOOP_NUM)*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)];
        end
        else if( c_A_DATA_WIDTH > c_B_DATA_WIDTH && DRM_DATA_WIDTH_A > c_A_DATA_WIDTH && DATA_LOOP_NUM == 1 && c_WR_BYTE_EN == 1) begin
            for(gen_i_ad=0;gen_i_ad < WIDTH_RATIO;gen_i_ad =gen_i_ad+1)
                always@(*) begin
                    a_wr_byte_en_bus[gen_i_ad*c_A_BE_WIDTH*DATA_DUTY_RATIO/WIDTH_RATIO +:c_A_BE_WIDTH*DATA_DUTY_RATIO/WIDTH_RATIO] = {{((DRM_DATA_WIDTH_A/(c_WR_BYTE_WIDTH*WIDTH_RATIO))-c_A_BE_WIDTH/WIDTH_RATIO){1'b1}},a_wr_byte_en_bus_p[gen_i_ad*c_A_BE_WIDTH/WIDTH_RATIO +:c_A_BE_WIDTH/WIDTH_RATIO]};
                end
            if(8*DATA_LOOP_NUM>c_A_BE_WIDTH*DATA_DUTY_RATIO)
                always@(*) begin
                    a_wr_byte_en_bus[8*DATA_LOOP_NUM-1 : c_A_BE_WIDTH*DATA_DUTY_RATIO] = {(8*DATA_LOOP_NUM - c_A_BE_WIDTH*DATA_DUTY_RATIO){1'b0}};
                end
        end
        else
            always@(*)
            a_wr_byte_en_bus = a_wr_byte_en_bus_p;//{{CAS_DATA_WIDTH_A/A_WR_BYTE_WIDTH}{1'b1}};
    
    endgenerate
    //******************************************************************************
    //drm_b_addr connect to the instance DRM directly ,based on DRM_DATA_WIDTH
    integer gen_drm_b;
    generate
    always@(*) begin
       for(gen_drm_b=0;gen_drm_b < DATA_LOOP_NUM;gen_drm_b = gen_drm_b+1) begin
//          if (DRM_DATA_WIDTH_A == 32 || DRM_DATA_WIDTH_A == 36) begin
//             case(DRM_DATA_WIDTH_B)
//                1      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[4],b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):5],b_addr_bus[3:0]};
//                2      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[3],b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):4],b_addr_bus[2:0],1'b0};
//                4      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[2],b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):3],b_addr_bus[1:0],2'b00};
//                8,9    : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[1],b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):2],b_addr_bus[0],3'b000};
//                16,18  : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[0],b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):1],4'b0000};
//                32,36  : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],5'b00000};
//                default: drm_b_addr[gen_drm_b*16 +: 16] = 16'b0;
//             endcase
//          end
//          else begin
             case(DRM_DATA_WIDTH_B)
                1      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0]};
                2      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],1'b0};
                4      : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],2'b00};
                8,9    : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],3'b000};
                16,18  : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],4'b0000};
                32,36  : drm_b_addr[gen_drm_b*16 +: 16] = {1'b1,b_addr_bus[(ADDR_WIDTH_B - CS_ADDR_WIDTH_B-1):0],5'b00000};
                default: drm_b_addr[gen_drm_b*16 +: 16] = 16'b0;
             endcase
//          end
       end
    end
    endgenerate
    //******************************************************************************
    //generate b_wr_data_mix_bus, b_wr_en_bus and b_wr_byte_en_bus
    genvar  gen_i_bd,gen_j_bd;
    generate
   
        //generate b_wr_data_mix_bus
        if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
            for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
                for(gen_j_bd=0;gen_j_bd < WIDTH_RATIO ; gen_j_bd = gen_j_bd+1 )
                    always@(*) begin
                        b_wr_data_mix_bus[gen_i_bd*DRM_DATA_WIDTH_B+gen_j_bd*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A] = b_wr_data_bus[(gen_i_bd + gen_j_bd*DATA_LOOP_NUM)*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
                    end
        end
        else if( (c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM==1)&&( DRM_DATA_WIDTH_B > c_B_DATA_WIDTH ) ) begin
            for(gen_j_bd=0;gen_j_bd < WIDTH_RATIO ; gen_j_bd = gen_j_bd+1 )
                always@(*) begin
                    b_wr_data_mix_bus[gen_j_bd*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A] =  {{(DRM_DATA_WIDTH_A-c_A_DATA_WIDTH){1'b0}},b_wr_data_bus[gen_j_bd*c_A_DATA_WIDTH +:c_A_DATA_WIDTH]};
                end
        end
        else begin
            always@(*)
                b_wr_data_mix_bus = b_wr_data_bus;
        end

        for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
            always@(*)
            b_wr_en_bus[gen_i_bd] = b_wr_en;
        //generate b_wr_byte_en_bus
        if( c_B_DATA_WIDTH > c_A_DATA_WIDTH && DATA_LOOP_NUM > 1 && c_WR_BYTE_EN == 1) begin
            for (gen_i_bd=0;gen_i_bd < DATA_LOOP_NUM;gen_i_bd =gen_i_bd+1)
                for( gen_j_bd=0;gen_j_bd<WIDTH_RATIO;gen_j_bd=gen_j_bd+1 )
                    always@(*)
                        b_wr_byte_en_bus[gen_i_bd*(DRM_DATA_WIDTH_B/B_WR_BYTE_WIDTH)+gen_j_bd*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)] = b_wr_byte_en_bus_p[(gen_i_bd + gen_j_bd*DATA_LOOP_NUM)*(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH) +:(DRM_DATA_WIDTH_A/A_WR_BYTE_WIDTH)];
        end
        else if( c_A_DATA_WIDTH < c_B_DATA_WIDTH && DRM_DATA_WIDTH_B > c_B_DATA_WIDTH && DATA_LOOP_NUM == 1 && c_WR_BYTE_EN == 1) begin
            for(gen_i_bd=0;gen_i_bd < WIDTH_RATIO;gen_i_bd =gen_i_bd+1)
                always@(*) begin
                    b_wr_byte_en_bus[gen_i_bd*c_B_BE_WIDTH*DATA_DUTY_RATIO/WIDTH_RATIO +:c_B_BE_WIDTH*DATA_DUTY_RATIO/WIDTH_RATIO] = {{((DRM_DATA_WIDTH_B/(c_WR_BYTE_WIDTH*WIDTH_RATIO))-c_B_BE_WIDTH/WIDTH_RATIO){1'b1}},b_wr_byte_en_bus_p[gen_i_bd*c_B_BE_WIDTH/WIDTH_RATIO +:c_B_BE_WIDTH/WIDTH_RATIO]};
                end
            if(4*DATA_LOOP_NUM>c_B_BE_WIDTH*DATA_DUTY_RATIO)
                always@(*) begin
                    b_wr_byte_en_bus[4*DATA_LOOP_NUM-1 : c_B_BE_WIDTH*DATA_DUTY_RATIO] = {(4*DATA_LOOP_NUM - c_B_BE_WIDTH*DATA_DUTY_RATIO){1'b0}};
                end
        end
        else begin
            always@(*)
            b_wr_byte_en_bus = b_wr_byte_en_bus_p;//{{CAS_DATA_WIDTH_B/B_WR_BYTE_WIDTH}{1'b1}};
        end
    
    endgenerate

    localparam  CS_ADDR_A_4_LSB = (CS_ADDR_WIDTH_A >= 4) ? (ADDR_WIDTH_A-1-CS_ADDR_WIDTH_A+3) : (ADDR_WIDTH_A-2);
    localparam  CS_ADDR_B_4_LSB = (CS_ADDR_WIDTH_B >= 4) ? (ADDR_WIDTH_B-1-CS_ADDR_WIDTH_B+3) : (ADDR_WIDTH_B-2);

    //generate CSA and CSB
    integer  gen_cs;
    generate
    always@(*) begin
       if(CS_ADDR_WIDTH_A == 0) begin
          a_cs_bit0 = 0;
          a_cs_bit1 = 0;
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
             a_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_A == 1) begin
          a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A];
          a_cs_bit1 = 0;
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
             a_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_A == 2) begin
          a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-2];
          a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-1];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
             a_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_A == 3) begin
          a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-3];
          a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-2];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
             a_cs_bit2_bus[gen_cs] = a_addr_bus[ADDR_WIDTH_A-1];
       end
       else if(CS_ADDR_WIDTH_A >= 4) begin
          a_cs_bit0 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A];
          a_cs_bit1 = a_addr_bus[ADDR_WIDTH_A-CS_ADDR_WIDTH_A+1];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_A;gen_cs=gen_cs+1)
             a_cs_bit2_bus[gen_cs] = (a_addr_bus[(ADDR_WIDTH_A-1):CS_ADDR_A_4_LSB] == (gen_cs/4)) ? 0 : 1;
       end

       //generate CSB
       if(CS_ADDR_WIDTH_B == 0) begin
          b_cs_bit0 = 0;
          b_cs_bit1 = 0;
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
             b_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_B == 1) begin
          b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B];
          b_cs_bit1 = 0;
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
             b_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_B == 2) begin
          b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-2];
          b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-1];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
             b_cs_bit2_bus[gen_cs] = 0;
       end
       else if(CS_ADDR_WIDTH_B == 3) begin
          b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-3];
          b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-2];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
             b_cs_bit2_bus[gen_cs] = b_addr_bus[ADDR_WIDTH_B-1];
       end
       else if(CS_ADDR_WIDTH_B >= 4) begin
          b_cs_bit0 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B];
          b_cs_bit1 = b_addr_bus[ADDR_WIDTH_B-CS_ADDR_WIDTH_B+1];
          for(gen_cs=0;gen_cs<ADDR_LOOP_NUM_B;gen_cs=gen_cs+1)
             b_cs_bit2_bus[gen_cs] = (b_addr_bus[(ADDR_WIDTH_B-1):CS_ADDR_B_4_LSB] == (gen_cs/4) ) ? 0 : 1;
       end
    end
    endgenerate

    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM_A-1:0]  QA_bus;
    wire [36*DATA_LOOP_NUM*ADDR_LOOP_NUM_B-1:0]  QB_bus;
    wire [36*DATA_LOOP_NUM-1:0]                  DA_bus;
    wire [36*DATA_LOOP_NUM-1:0]                  DB_bus;

    //generate constructs: ADDR_LOOP to cascade request address  and  DATA LOOP to cascade request data
    genvar gen_i,gen_j;
    generate
    for(gen_j=0;gen_j<ADDR_LOOP_NUM_A;gen_j=gen_j+1) begin:ADDR_LOOP
        for(gen_i=0;gen_i<DATA_LOOP_NUM;gen_i=gen_i+1) begin:DATA_LOOP
            //write data
            if(DRM_DATA_WIDTH_A == 32 ) begin:QA_MAP
               assign  a_rd_data_bus[(gen_i*DRM_DATA_WIDTH_A+gen_j*CAS_DATA_WIDTH_A) +:DRM_DATA_WIDTH_A] = {QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+27) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+18) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DA_bus[(gen_i*36+27) +:8 ],DA_bus[gen_i*36+18 +:8],DA_bus[(gen_i*36+9) +:8 ],DA_bus[gen_i*36 +:8]} = a_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
            end
            else if(DRM_DATA_WIDTH_A == 16 ) begin:QA_MAP
               assign  a_rd_data_bus[(gen_i*DRM_DATA_WIDTH_A+gen_j*CAS_DATA_WIDTH_A) +:DRM_DATA_WIDTH_A] = {QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DA_bus[(gen_i*36+9) +:8 ],DA_bus[gen_i*36 +:8]} = a_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
            end
            else begin:QA_MAP
               assign  a_rd_data_bus[(gen_i*DRM_DATA_WIDTH_A+gen_j*CAS_DATA_WIDTH_A) +:DRM_DATA_WIDTH_A] = QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:DRM_DATA_WIDTH_A];
               assign  DA_bus[gen_i*36 +:DRM_DATA_WIDTH_A] = a_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
            end

            if(DRM_DATA_WIDTH_B == 32 ) begin:QB_MAP
               assign  b_rd_data_bus[(gen_i*DRM_DATA_WIDTH_B+gen_j*CAS_DATA_WIDTH_B) +:DRM_DATA_WIDTH_B] = {QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+27) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+18) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DB_bus[(gen_i*36+27) +:8],DB_bus[gen_i*36+18 +:8],DB_bus[(gen_i*36+9) +:8],DB_bus[gen_i*36 +:8]} = b_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
            end
            else if(DRM_DATA_WIDTH_B == 16 ) begin:QB_MAP
               assign  b_rd_data_bus[(gen_i*DRM_DATA_WIDTH_B+gen_j*CAS_DATA_WIDTH_B) +:DRM_DATA_WIDTH_B] = {QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM+9) +:8],QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:8]};
               assign  {DB_bus[(gen_i*36+9) +:8],DB_bus[gen_i*36 +:8]} = b_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
            end
            else begin:QB_MAP
               assign  b_rd_data_bus[(gen_i*DRM_DATA_WIDTH_B+gen_j*CAS_DATA_WIDTH_B) +:DRM_DATA_WIDTH_B] = QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:DRM_DATA_WIDTH_B];
               assign  DB_bus[gen_i*36 +:DRM_DATA_WIDTH_B] = b_wr_data_mix_bus[gen_i*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
            end

            case(DRM_DATA_WIDTH_A)
               1      : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  a_wr_byte_en_bus;
               2      : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  a_wr_byte_en_bus;
               4      : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  a_wr_byte_en_bus;
               8,9    : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  a_wr_byte_en_bus;
               16,18  : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ? {6'b00_0000, a_wr_byte_en_bus[gen_i*2 +:2]} : a_wr_byte_en_bus;
               32,36  : assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  (c_WR_BYTE_EN == 1) ? {4'b0000,    a_wr_byte_en_bus[gen_i*4 +:4]} : a_wr_byte_en_bus;
               default: assign a_wr_byte_en_bus_m[gen_i*8 +: 8]  =  8'b0;
            endcase

            case(DRM_DATA_WIDTH_B)
               1      : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  b_wr_byte_en_bus;
               2      : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  b_wr_byte_en_bus;
               4      : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  b_wr_byte_en_bus;
               8,9    : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  b_wr_byte_en_bus;
               16,18  : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  (c_WR_BYTE_EN == 1) ? {2'b00, b_wr_byte_en_bus[gen_i*2 +:2]}  : b_wr_byte_en_bus;
               32,36  : assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  (c_WR_BYTE_EN == 1) ? b_wr_byte_en_bus[gen_i*4 +:4]           : b_wr_byte_en_bus;
               default: assign b_wr_byte_en_bus_m[gen_i*4 +: 4]  =  4'b0;
            endcase

            GTP_DRM36K_E1 # (

                .GRS_EN                   ( "FALSE"                  ),
                .CSA_MASK                 ( gen_j%MASK_NUM_A         ),
                .CSB_MASK                 ( gen_j%MASK_NUM_B         ),
                .DATA_WIDTH_A             ( DRM_DATA_WIDTH_A         ),
                .DATA_WIDTH_B             ( DRM_DATA_WIDTH_B         ),
                .WRITE_MODE_A             ( c_A_WRITE_MODE           ),
                .WRITE_MODE_B             ( c_B_WRITE_MODE           ),
                .DOA_REG                  ( c_A_OUTPUT_REG           ),
                .DOB_REG                  ( c_B_OUTPUT_REG           ),
                .DOA_REG_CLKINV           ( c_A_CLK_OR_POL_INV       ),
                .DOB_REG_CLKINV           ( c_B_CLK_OR_POL_INV       ),

                .RST_TYPE                 ( c_RESET_TYPE             ),
                .RAM_MODE                 ( "TRUE_DUAL_PORT"         ),
                .INIT_FILE                ( c_INIT_FILE              ),
                .RAM_CASCADE              ( "NONE"                   ),
                .ECC_WRITE_EN             ( "FALSE"                  ),
                .ECC_READ_EN              ( "FALSE"                  ),
                .BLOCK_X                  ( gen_i                    ),
                .BLOCK_Y                  ( gen_j                    ),
                .RAM_ADDR_WIDTH           ( ADDR_WIDTH_A             ),
                .RAM_DATA_WIDTH           ( CAS_DATA_WIDTH_A         ),
                .INIT_FORMAT              ( c_INIT_FORMAT            )
            ) U_GTP_DRM36K_E1 (
                .DOA                      ( QA_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRA                    ( drm_a_addr[gen_i*16 +:16]                       ),
                .ADDRA_HOLD               ( a_addr_strobe                                   ),
                .BWEA                     ( a_wr_byte_en_bus_m[gen_i*8 +:8]                 ),
                .DIA                      ( DA_bus[gen_i*36 +:36]                           ),
                .CSA                      ( {a_cs_bit2_bus[gen_j],a_cs_bit1,a_cs_bit0}      ),
                .WEA                      ( a_wr_en_bus[gen_i]                              ),
                .CLKA                     ( a_clk                                           ),
                .CEA                      ( a_clk_en                                        ),
                .ORCEA                    ( a_rd_oce                                        ),
                .RSTA                     ( a_rst                                           ),
                .CINA                     (                                                 ),
                .COUTA                    (                                                 ),

                .DOB                      ( QB_bus[(gen_i*36+gen_j*36*DATA_LOOP_NUM) +:36]  ),
                .ADDRB                    ( drm_b_addr[gen_i*16 +:16]                       ),
                .ADDRB_HOLD               ( b_addr_strobe                                   ),
                .BWEB                     ( b_wr_byte_en_bus_m[gen_i*4 +:4]                 ),
                .DIB                      ( DB_bus[gen_i*36 +:36]                           ),
                .CSB                      ( {b_cs_bit2_bus[gen_j],b_cs_bit1,b_cs_bit0}      ),
                .WEB                      ( b_wr_en_bus[gen_i]                              ),
                .CLKB                     ( b_clk                                           ),
                .CEB                      ( b_clk_en                                        ),
                .ORCEB                    ( b_rd_oce                                        ),
                .RSTB                     ( b_rst                                           ),
                .CINB                     (                                                 ),
                .COUTB                    (                                                 ),

                .INJECT_SBITERR           (                                                 ),
                .INJECT_DBITERR           (                                                 ),
                .ECC_SBITERR              (                                                 ),
                .ECC_DBITERR              (                                                 ),
                .ECC_RDADDR               (                                                 ),
                .ECC_PARITY               (                                                 )
            );
        end
    end
    endgenerate

    //******************************************************************************
    //generate a_rd_data
    localparam   A_ADDR_SEL_LSB = (CS_ADDR_WIDTH_A > 0) ? (ADDR_WIDTH_A - CS_ADDR_WIDTH_A) : (ADDR_WIDTH_A - 1);
    //rd_data: extra mux combination  logic
    wire [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_sel;
    reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce;
    reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce_ff;
    wire [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_ce_mux;
    reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_oce;
    reg  [CS_ADDR_WIDTH_A-1:0]   a_addr_bus_rd_invt;

    reg     a_wr_en_ff;

    //CE
    always @(posedge a_clk)
    begin
        if (~a_addr_strobe & a_clk_en)
            a_addr_bus_rd_ce <= a_addr_bus[(ADDR_WIDTH_A-1): A_ADDR_SEL_LSB];
    end

    always @(posedge a_clk)
    begin
        if (a_clk_en)
            a_wr_en_ff <= a_wr_en;
    end

    always @(posedge a_clk)
    begin
        if (~a_wr_en_ff)
            a_addr_bus_rd_ce_ff <= a_addr_bus_rd_ce;
    end

    assign a_addr_bus_rd_ce_mux = (c_A_WRITE_MODE != "NORMAL_WRITE") ? a_addr_bus_rd_ce : a_wr_en_ff ? a_addr_bus_rd_ce_ff : a_addr_bus_rd_ce;

    //OCE
    always @(posedge a_clk)
    begin
        if (a_rd_oce)
            a_addr_bus_rd_oce <= a_addr_bus_rd_ce_mux;
    end

    //INVT
    always @(negedge a_clk)
    begin
        if (a_rd_oce)
            a_addr_bus_rd_invt <= a_addr_bus_rd_ce_mux;
    end

    assign  a_addr_bus_rd_sel = (c_A_CLK_OR_POL_INV == 1) ? a_addr_bus_rd_invt : (c_A_OUTPUT_REG == 1) ? a_addr_bus_rd_oce : a_addr_bus_rd_ce_mux;

    //******************************************************************************
    //generate a_rd_data_bus from rd_data_mix_bus
    integer rd_a_n;
    generate
    always@(*) begin
       a_rd_mix_data = 'b0;
       if(ADDR_LOOP_NUM_A>1) begin
          for(rd_a_n=0;rd_a_n<ADDR_LOOP_NUM_A;rd_a_n=rd_a_n+1) begin
             if(a_addr_bus_rd_sel== rd_a_n)
                   a_rd_mix_data = a_rd_data_bus[rd_a_n*CAS_DATA_WIDTH_A +:CAS_DATA_WIDTH_A];
          end
       end
       else begin
          a_rd_mix_data = a_rd_data_bus;
       end
    end
    endgenerate

    genvar gen_i_rad,gen_j_rad;
    generate
       if((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM>1)) begin
           for (gen_i_rad=0;gen_i_rad < WIDTH_RATIO;gen_i_rad = gen_i_rad + 1)
               for(gen_j_rad=0;gen_j_rad < DATA_LOOP_NUM  ;gen_j_rad = gen_j_rad+1)
                   always@(*)
                       a_rd_full_data[gen_i_rad*(CAS_DATA_WIDTH_A/WIDTH_RATIO)+gen_j_rad*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B] = a_rd_mix_data[(gen_i_rad + gen_j_rad*WIDTH_RATIO)*DRM_DATA_WIDTH_B +:DRM_DATA_WIDTH_B];
       end
       else if ((c_A_DATA_WIDTH > c_B_DATA_WIDTH) && (DATA_LOOP_NUM==1)&&(DRM_DATA_WIDTH_A>c_A_DATA_WIDTH)) begin
           for (gen_i_rad=0;gen_i_rad < WIDTH_RATIO;gen_i_rad = gen_i_rad + 1) begin
               always@(*) begin
                   a_rd_full_data[gen_i_rad*c_B_DATA_WIDTH +:c_B_DATA_WIDTH] = a_rd_mix_data[gen_i_rad*DRM_DATA_WIDTH_B +:c_B_DATA_WIDTH];
               end
           end
           always@(*) begin
               a_rd_full_data[CAS_DATA_WIDTH_A-1:c_A_DATA_WIDTH] = {(CAS_DATA_WIDTH_A-c_A_DATA_WIDTH){1'b0}};
           end
       end
       else begin
           always@(*)
               a_rd_full_data = a_rd_mix_data;
       end
    
    endgenerate

    assign  a_rd_data = a_rd_full_data[c_A_DATA_WIDTH-1:0];

    //******************************************************************************
    //generate   b_rd_data
    localparam   B_ADDR_SEL_LSB = (CS_ADDR_WIDTH_B > 0) ? (ADDR_WIDTH_B - CS_ADDR_WIDTH_B) : (ADDR_WIDTH_B - 1);

    wire [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_sel;
    reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_ce;
    reg  [CS_ADDR_WIDTH_A-1:0]   b_addr_bus_rd_ce_ff;
    wire [CS_ADDR_WIDTH_A-1:0]   b_addr_bus_rd_ce_mux;
    reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_oce;
    reg  [CS_ADDR_WIDTH_B-1:0]   b_addr_bus_rd_invt;

    reg     b_wr_en_ff;

    //CE
    always @(posedge b_clk)
    begin
        if (~b_addr_strobe & b_clk_en)
            b_addr_bus_rd_ce <= b_addr_bus[(ADDR_WIDTH_B-1): B_ADDR_SEL_LSB];
    end

    always @(posedge b_clk)
    begin
        if (b_clk_en)
            b_wr_en_ff <= b_wr_en;
    end

    always @(posedge b_clk)
    begin
        if (~b_wr_en_ff)
            b_addr_bus_rd_ce_ff <= b_addr_bus_rd_ce;
    end

    assign b_addr_bus_rd_ce_mux = (c_B_WRITE_MODE != "NORMAL_WRITE") ? b_addr_bus_rd_ce : b_wr_en_ff ? b_addr_bus_rd_ce_ff : b_addr_bus_rd_ce;

    //OCE
    always @(posedge b_clk)
    begin
        if (b_rd_oce)
            b_addr_bus_rd_oce <= b_addr_bus_rd_ce_mux;
    end

    //INVT
    always @(negedge b_clk)
    begin
        if (b_rd_oce)
            b_addr_bus_rd_invt <= b_addr_bus_rd_ce_mux;
    end

    assign  b_addr_bus_rd_sel = (c_B_CLK_OR_POL_INV == 1) ? b_addr_bus_rd_invt : (c_B_OUTPUT_REG == 1) ? b_addr_bus_rd_oce : b_addr_bus_rd_ce_mux;

    integer rd_b_n;
    generate
    always@(*) begin
       b_rd_mix_data = 'b0;
       if(ADDR_LOOP_NUM_B > 1) begin
          for(rd_b_n=0;rd_b_n<ADDR_LOOP_NUM_B;rd_b_n=rd_b_n+1) begin
             if(b_addr_bus_rd_sel == rd_b_n)
                b_rd_mix_data = b_rd_data_bus[rd_b_n*CAS_DATA_WIDTH_B +:CAS_DATA_WIDTH_B];
          end
       end
       else begin
          b_rd_mix_data = b_rd_data_bus;
       end
    end
    endgenerate

    genvar gen_i_rbd,gen_j_rbd;
    generate
       if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM > 1)) begin
          for (gen_i_rbd=0;gen_i_rbd < WIDTH_RATIO;gen_i_rbd = gen_i_rbd + 1)
             for(gen_j_rbd=0;gen_j_rbd < DATA_LOOP_NUM  ;gen_j_rbd = gen_j_rbd+1)
                 always@(*)
                    b_rd_full_data[gen_i_rbd*(CAS_DATA_WIDTH_B/WIDTH_RATIO)+gen_j_rbd*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A] = b_rd_mix_data[(gen_i_rbd + gen_j_rbd*WIDTH_RATIO)*DRM_DATA_WIDTH_A +:DRM_DATA_WIDTH_A];
       end
       else if((c_B_DATA_WIDTH > c_A_DATA_WIDTH) && (DATA_LOOP_NUM==1)&&(DRM_DATA_WIDTH_B>c_B_DATA_WIDTH)) begin
           for (gen_i_rbd=0;gen_i_rbd < WIDTH_RATIO;gen_i_rbd = gen_i_rbd + 1)
               always@(*)
                   b_rd_full_data[gen_i_rbd*c_A_DATA_WIDTH+:c_A_DATA_WIDTH] = b_rd_mix_data[gen_i_rbd*DRM_DATA_WIDTH_A +:c_A_DATA_WIDTH];
           always@(*)
                b_rd_full_data[CAS_DATA_WIDTH_B-1:c_B_DATA_WIDTH] = {(CAS_DATA_WIDTH_B-c_B_DATA_WIDTH){1'b0}};
       end
       else begin
           always@(*)
               b_rd_full_data = b_rd_mix_data;
       end
    
    endgenerate

    assign  b_rd_data = b_rd_full_data[c_B_DATA_WIDTH-1 : 0];

endmodule
