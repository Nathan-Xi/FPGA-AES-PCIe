//******************************************************************
// Copyright (c) 2015 PANGO MICROSYSTEMS, INC
// ALL RIGHTS REVERVED.
//******************************************************************
`timescale 1ns/1ps
module hsst_pg2t_rst4mcrsw_rx_v1_8 #(
    parameter LINK_X1_WIDTH  = 0, // 1 = x4
    parameter FORCE_LANE_REV = 0  //1 = Lane Reversal
)(
    input   wire                         clk,
    input   wire                         rst_n,
    input   wire    [7:0]                rxlane_soft_rst_n,

    input   wire                         tx_rst_done,
    input   wire    [1:0]                link_num,
    input   wire                         link_num_flag,
    input   wire                         P_PLL_LOCK,
    input   wire                         prbs_en,
    input   wire    [7:0]                P_LX_ALOS_STA,
    input   wire    [7:0]                P_LX_CDR_ALIGN,
    input   wire    [7:0]                P_PCS_LSM_SYNCED,

    input   wire                         ltssm_in_recovery,
    input   wire    [1:0]                rate,             // 0 = 2.5GT/s;   1 = 5.0GT/s , 2= 8.0GT/s

    output  wire    [3:0]                rx_main_fsm,
    output  wire    [3:0]                rx_init_fsm0,
    output  wire    [3:0]                rx_init_fsm1,
    output  wire    [3:0]                rx_init_fsm2,
    output  wire    [3:0]                rx_init_fsm3,
    output  wire    [7:0]                s_PCS_LSM_SYNCED,
    output  wire    [7:0]                s_LX_ALOS_STA_deb,
    output  wire    [7:0]                s_LX_CDR_ALIGN_deb,
    output  wire    [7:0]                init_done,

    output  wire    [7:0]                P_CDR_RSTN,
    output  wire    [7:0]                P_PMA_RX_PD,
    output  wire    [7:0]                P_PMA_RX_RST,
    output  wire    [7:0]                P_PCS_RX_RST,
    output  wire    [2:0]                P_LX_RX_RATE_0,
    output  wire    [2:0]                P_LX_RX_RATE_1,
    output  wire    [2:0]                P_LX_RX_RATE_2,
    output  wire    [2:0]                P_LX_RX_RATE_3,
    output  wire    [7:0]                P_PCS_CB_RST,
    output  wire                         rate_done,
    output  wire    [7:0]                hsst_ch_ready
);

localparam LOSS_DEB_RISE_CNTR_WIDTH       = 12;
localparam LOSS_DEB_RISE_CNTR_VALUE       = 4;
localparam CDR_ALIGN_DEB_RISE_CNTR_WIDTH  = 12;
localparam CDR_ALIGN_DEB_RISE_CNTR_VALUE  = 2048;
localparam WORD_ALIGN_DEB_RISE_CNTR_WIDTH = 11;
localparam WORD_ALIGN_DEB_RISE_CNTR_VALUE = 1024;

wire             [7:0]     s_LX_ALOS_STA          ;
wire             [7:0]     s_LX_CDR_ALIGN         ;

wire                       main_rst_align         ;
wire                       rx_rate_change_rst     ;
wire             [3:0]     rx_init_fsm_buf [7:0]  ;

wire             [2:0]     P_LX_RX_RATE           ;

reg              [1:0]     link_num_synced        ;
reg              link_num_flag_synced_d;
wire             [7:0]     main_done              ;
wire             main_pll_loss_rst;
wire P_RX_LANE_POWERUP;
wire P_PMA_RX_PD_m;
wire [7:0] P_RX_PMA_RSTN    ;
wire [7:0] P_PCS_RX_RSTN    ;
wire [7:0] P_PCS_CB_RSTN    ;
wire [1:0] P_LX_RX_CKDIV;
wire [7:0] P_PCS_CB_RST_I;
wire cur_rate;
wire s_P_PLL_LOCK;
// Link Number sync
hsst_rst_sync_v1_0 link_num_sync  (.clk(clk), .rst_n(rst_n), .sig_async(link_num_flag), .sig_synced(link_num_flag_synced));

// PLL Lock sync
hsst_rst_sync_v1_0 pll_lock_multi_sw_sync (.clk(clk), .rst_n(rst_n), .sig_async(P_PLL_LOCK), .sig_synced(s_P_PLL_LOCK));

always @(posedge clk or negedge rst_n)
   if (!rst_n) begin
      link_num_flag_synced_d <= 1'b0;
      link_num_synced        <= 2'd0;
   end
   else begin
      link_num_flag_synced_d <= link_num_flag_synced;
      if (link_num_flag_synced_d ^ link_num_flag_synced)
          link_num_synced  <= link_num;
   end


// Initial part
assign rx_init_fsm0 = rx_init_fsm_buf[0];
assign rx_init_fsm1 = rx_init_fsm_buf[1];
assign rx_init_fsm2 = rx_init_fsm_buf[2];
assign rx_init_fsm3 = rx_init_fsm_buf[3];

generate
genvar i;
for(i=0;i<8;i=i+1)begin
    hsst_pg2t_rst4mcrsw_rx_init_v1_8 hsst_rst4mcrsw_rx_init(
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
    .rxlane_soft_rst_n      (rxlane_soft_rst_n[i]   ),

    .ltssm_in_recovery      (ltssm_in_recovery      ),
    .pll_ready              (s_P_PLL_LOCK           ),
    .P_LX_ALOS_STA          (P_LX_ALOS_STA[i]       ),
    .P_LX_CDR_ALIGN         (P_LX_CDR_ALIGN[i]      ),
    .P_PCS_LSM_SYNCED       (P_PCS_LSM_SYNCED[i]    ),

    .main_rst_align         (main_rst_align         ),
    .main_pll_loss_rst      (main_pll_loss_rst      ),
    .cur_rate               (cur_rate),
    .rx_init_fsm            (rx_init_fsm_buf[i]     ),
    .s_LX_ALOS_STA          (s_LX_ALOS_STA[i]       ),
    .s_LX_CDR_ALIGN         (s_LX_CDR_ALIGN[i]      ),
    .s_PCS_LSM_SYNCED       (s_PCS_LSM_SYNCED[i]    ),
    .s_LX_ALOS_STA_deb      (s_LX_ALOS_STA_deb[i]   ),
    .s_LX_CDR_ALIGN_deb     (s_LX_CDR_ALIGN_deb[i]  ),

//    .P_PMA_RX_PD            (P_PMA_RX_PD_m          ),
//    .P_PMA_RX_RST           (P_PMA_RX_RST[i]        ),
    .P_RX_PLL_RSTN          (P_CDR_RSTN[i]), //NC
//    .P_PCS_RX_RST           (P_PCS_RX_RST[i]        ),

    .P_RX_LANE_POWERUP      (P_RX_LANE_POWERUP      ),
    .P_RX_PMA_RSTN          (P_RX_PMA_RSTN[i]       ),
    .P_PCS_RX_RSTN          (P_PCS_RX_RSTN[i]       ),
    .P_PCS_CB_RSTN          (P_PCS_CB_RSTN[i]       ),
    .init_done              (init_done[i]           )
    );
end

endgenerate

wire [7:0] P_PCS_RX_RST_I;
assign P_PMA_RX_PD_m = ~P_RX_LANE_POWERUP;
assign P_PMA_RX_RST  = ~P_RX_PMA_RSTN;
assign P_PCS_RX_RST_I  = ~P_PCS_RX_RSTN;
assign P_PCS_CB_RST_I  = ~P_PCS_CB_RSTN;
// Main part
hsst_pg2t_rst4mcrsw_rx_rst_fsm_v1_1 #(
    .FORCE_LANE_REV         (FORCE_LANE_REV         )
)rx_rst_fsm_multi_sw_lane(
    .clk                    (clk                    ),
    .rst_n                  (rst_n                  ),
    .tx_rst_done            (tx_rst_done            ),
    .prbs_en                (prbs_en            ),
//    .link_num               (link_num_synced        ),
    .ltssm_in_recovery      (ltssm_in_recovery      ),
    .rate                   (rate                   ),
    .init_done              (init_done              ),
    .rx_main_fsm            (rx_main_fsm            ),
    .main_rst_align         (main_rst_align         ),
    .main_pll_loss_rst      (main_pll_loss_rst      ),
    .loss_of_signal         (s_LX_ALOS_STA),
//    .P_PMA_RX_PD            (P_PMA_RX_PD_m          ),
//    .P_LX_RX_RATE           (P_LX_RX_RATE           ),
    .P_RX_LANE_POWERUP      (P_RX_LANE_POWERUP      ),
    .P_LX_RX_CKDIV          (P_LX_RX_CKDIV          ),
    .P_LX_RX_CKDIV_DYNSEL   (), //NC
    .rate_done              (rate_done              ),
    .main_done              (main_done              )
);

assign P_LX_RX_RATE = (P_LX_RX_CKDIV == 2'd0) ? 3'd3 : 3'd2;

assign cur_rate = (P_LX_RX_CKDIV == 2'd0);


assign P_PMA_RX_PD     = {8{P_PMA_RX_PD_m}} ;



assign P_PCS_RX_RST = P_PCS_RX_RST_I;
assign P_PCS_CB_RST = P_PCS_CB_RST_I;

//assign P_PCS_RX_RST[0]  = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3:1] & s_LX_ALOS_STA[0]))   ? &P_PCS_RX_RST_I[3:0] :P_PCS_RX_RST_I[0];
//assign P_PCS_RX_RST[1]  = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3:2] & s_LX_ALOS_STA[1]))  ? &P_PCS_RX_RST_I[3:1] : P_PCS_RX_RST_I[1];
//assign P_PCS_RX_RST[2]  = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3] & s_LX_ALOS_STA[2]))? &P_PCS_RX_RST_I[3:2] : P_PCS_RX_RST_I[2] ;
//assign P_PCS_RX_RST[3]  = P_PCS_RX_RST_I[3];
//
//assign P_PCS_RX_RST[4]  = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7:4] & s_LX_ALOS_STA[4]))   ? &P_PCS_RX_RST_I[7:4] :P_PCS_RX_RST_I[4];
//assign P_PCS_RX_RST[5]  = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7:4] & s_LX_ALOS_STA[5]))  ? &P_PCS_RX_RST_I[7:5] : P_PCS_RX_RST_I[5];
//assign P_PCS_RX_RST[6]  = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7] & s_LX_ALOS_STA[6]))? &P_PCS_RX_RST_I[7:6] : P_PCS_RX_RST_I[6] ;
//assign P_PCS_RX_RST[7]  = P_PCS_RX_RST_I[7];
//
//
//assign  P_PCS_CB_RST[0]  = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3:1] & s_LX_ALOS_STA[0]))   ? &P_PCS_CB_RST_I[3:0] :P_PCS_CB_RST_I[0];
//assign  P_PCS_CB_RST[1] = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3:2] & s_LX_ALOS_STA[1]))  ? &P_PCS_CB_RST_I[3:1] : P_PCS_CB_RST_I[1];
//assign  P_PCS_CB_RST[2] = ((|main_done[3:0]) | (|s_LX_CDR_ALIGN[3] & s_LX_ALOS_STA[2]))? &P_PCS_CB_RST_I[3:2] : P_PCS_CB_RST_I[2] ;
//assign  P_PCS_CB_RST[3] = P_PCS_CB_RST_I[3];
//
//assign  P_PCS_CB_RST[4]  = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7:5] & s_LX_ALOS_STA[4]))   ? &P_PCS_CB_RST_I[7:4] :P_PCS_CB_RST_I[4];
//assign  P_PCS_CB_RST[5] = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7:6] & s_LX_ALOS_STA[5]))  ? &P_PCS_CB_RST_I[7:5] : P_PCS_CB_RST_I[5];
//assign  P_PCS_CB_RST[6] = ((|main_done[7:4]) | (|s_LX_CDR_ALIGN[7] & s_LX_ALOS_STA[6]))? &P_PCS_CB_RST_I[7:6] : P_PCS_CB_RST_I[6] ;
//assign  P_PCS_CB_RST[7] = P_PCS_CB_RST_I[7];

assign P_LX_RX_RATE_0   = P_LX_RX_RATE;
assign P_LX_RX_RATE_1   = P_LX_RX_RATE;
assign P_LX_RX_RATE_2   = P_LX_RX_RATE;
assign P_LX_RX_RATE_3   = P_LX_RX_RATE;

assign hsst_ch_ready =  main_done ;
endmodule
