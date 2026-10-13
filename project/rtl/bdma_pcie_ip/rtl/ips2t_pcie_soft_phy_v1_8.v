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

module ips2t_pcie_soft_phy_v1_8 #(
    parameter integer   HSST_LANE_NUM   = 8         ,//1:X1 2:X2 4:X4 8:X8
    parameter           HPLL_EN         = "TRUE"    //TRUE, FALSE; for HPLL enable
)(
    input                       refclk_p,
    input                       refclk_n,
    input                       phy_rst_n,
    input                       power_up_rst_n,
    input                       button_rst_n,
    output                      pclk,
    output                      pclk_div2,
    input                       user_pll_lock,

    output  [1:0]               p_calib_done,
    output                      tx_rst_done,
    // SerDes tx/rx
    input   [HSST_LANE_NUM-1:0] rxp,
    input   [HSST_LANE_NUM-1:0] rxn,
    output  [HSST_LANE_NUM-1:0] txp,
    output  [HSST_LANE_NUM-1:0] txn,
    //--------fabric Port--------//
    input                       p_cfg_clk       ,
    input                       p_cfg_rst_n     ,
    input                       p_cfg_psel      ,
    input                       p_cfg_enable    ,
    input                       p_cfg_write     ,
    input       [15:0]          p_cfg_addr      ,
    input       [7:0]           p_cfg_wdata     ,
    output wire                 p_cfg_ready     ,
    output wire [7:0]           p_cfg_rdata     ,
    output wire                 p_cfg_int       ,
    // PIPE Data
    input   [255:0]             mac_phy_txdata,
    input   [31:0]              mac_phy_txdatak,
    input   [7:0]               mac_phy_txdatavalid,
    input   [7:0]               mac_phy_txstartblock,
    input   [15:0]              mac_phy_txsyncheader,

    output  [255:0]             phy_mac_rxdata,
    output  [31:0]              phy_mac_rxdatak,
    output  reg [7:0]           phy_mac_rxvalid,
    output  [7:0]               phy_mac_rxdatavalid,
    output  [7:0]               phy_mac_rxstartblock,
    output  [15:0]              phy_mac_rxsyncheader,

    // PIPE control
    input   [1:0]               mac_phy_rate,
    input   [7:0]               mac_phy_txdetectrx_loopback,
    input   [7:0]               mac_phy_rxpolarity,
    input                       mac_phy_blockaligncontrol,

    //comment the elecidle and update to high and low 2 signals
    input   [7:0]               mac_phy_txelecidle_h,
    input   [7:0]               mac_phy_txelecidle_l,
    input   [7:0]               mac_phy_txcompliance,
    input   [143:0]             mac_phy_txdeemph,
    input   [2:0]               mac_phy_txmargin,
    input                       mac_phy_txswing,

    output  [23:0]              phy_mac_rxstatus,
    output  [7:0]               phy_mac_rxelecidle,

    //prbs
    input                       prbs_en,
    input                       force_loss_signal,
    input                       force_cdr_align,
    input                       force_word_align,

    //iscan
    input  [HSST_LANE_NUM-1:0]  rx_eye_rst,
    input  [HSST_LANE_NUM-1:0]  rx_eye_en,
    input  [HSST_LANE_NUM*8-1:0]rx_eye_tap,
    input  [HSST_LANE_NUM*8-1:0]rx_pic_eye,
    input  [HSST_LANE_NUM-1:0]  em_rd_trigger,
    input  [HSST_LANE_NUM*2-1:0]em_mode_ctrl,
    output [HSST_LANE_NUM-1:0]  txlane_done,
    output [HSST_LANE_NUM-1:0]  rxlane_done,
    output                      pll_done,
    output [HSST_LANE_NUM-1:0]  rx_sigdet_sta,
    output [HSST_LANE_NUM-1:0]  lx_cdr_align,

    //loopback
    input  [HSST_LANE_NUM-1:0]  pcs_nearend_loop,
    input  [HSST_LANE_NUM-1:0]  pma_nearend_ploop,
    input  [HSST_LANE_NUM-1:0]  pma_nearend_sloop,
    // EQ interface
    input   [7:0]               mac_phy_invalid_req,
    input   [7:0]               mac_phy_rxeqeval,
    input   [31:0]              mac_phy_local_pset_index,
    input   [7:0]               mac_phy_getlocal_pset_coef,
    input   [7:0]               mac_phy_rxeqinprogress,
    input   [23:0]              mac_phy_rxpresethint,
    input   [47:0]              mac_phy_fs,
    input   [47:0]              mac_phy_lf,
    output  [47:0]              phy_mac_localfs,
    output  [47:0]              phy_mac_locallf,
    output  [47:0]              phy_mac_dirfeedback,
    output  [63:0]              phy_mac_fomfeedback,
    output  reg [143:0]         phy_mac_local_tx_pset_coef,
    output  reg [7:0]           phy_mac_local_tx_coef_valid,

    // powerdown interface
    input   [1:0]               mac_phy_powerdown, //[3:2] is not used
    //ltssm
    input   [5:0]               smlh_ltssm_state,
    // main PIPE ack signal
    output                      refclk2core,
    output  [7:0]               phy_mac_phystatus
);

//localparam CHANNEL0_EN        = "TRUE"  ; //TRUE, FALSE; for Channel0 enable must enable
localparam CHANNEL1_EN        = (HSST_LANE_NUM != 1) ? "TRUE" : "FALSE" ;//TRUE, FALSE; for Channel1 enable
localparam CHANNEL2_EN        = (HSST_LANE_NUM == 4 | HSST_LANE_NUM == 8) ? "TRUE" : "FALSE";//TRUE, FALSE; for Channel2 enable
localparam CHANNEL3_EN        = (HSST_LANE_NUM == 4 | HSST_LANE_NUM == 8) ? "TRUE" : "FALSE";//TRUE, FALSE; for Channel3 enable
//localparam CH0_MULT_LANE_MODE = (HSST_LANE_NUM == 8) ? 4 : HSST_LANE_NUM;//Lane0 --> 1: Singel Lane 2:Two Lane 4:Four Lane
//localparam CH1_MULT_LANE_MODE = (HSST_LANE_NUM == 8) ? 4 : HSST_LANE_NUM;//Lane1 --> 1: Singel Lane 2:Two Lane 4:Four Lane
//localparam CH2_MULT_LANE_MODE = (HSST_LANE_NUM == 8) ? 4 : HSST_LANE_NUM;//Lane2 --> 1: Singel Lane 2:Two Lane 4:Four Lane
//localparam CH3_MULT_LANE_MODE = (HSST_LANE_NUM == 8) ? 4 : HSST_LANE_NUM;//Lane3 --> 1: Singel Lane 2:Two Lane 4:Four Lane
localparam CH_MULT_LANE_MODE = (HSST_LANE_NUM == 8) ? 4 : HSST_LANE_NUM;//Lane3 --> 1: Singel Lane 2:Two Lane 4:Four Lane

localparam HSST_CAS_EN        = (HSST_LANE_NUM == 8) ? "TRUE" : "FALSE"; //only for X8 PCIe,enable lane4-lane7

localparam CALIB_EN           = "TRUE";

//localparam HSST_T_HPLL_EN     = (HSST_CAS_EN == "TRUE" | CALIB_EN == "TRUE") ? "TRUE" : "FALSE";

`ifdef IPM2T_HSST_SPEEDUP_SIM
    localparam LANE_NUM = (HSST_LANE_NUM == 1) ? 2 : HSST_LANE_NUM;
`else
    localparam LANE_NUM = HSST_LANE_NUM;
`endif
wire    [7:0]   pad_rx_sdp;
wire    [7:0]   pad_rx_sdn;
wire    [7:0]   pad_tx_sdp;
wire    [7:0]   pad_tx_sdn;

wire    [7:0]   p_pcs_nearend_loop;
wire    [7:0]   p_pma_nearend_ploop;
wire    [7:0]   p_pma_nearend_sloop;

wire  pll_lock_2quad;
wire  [7:0] P_LX_ALOS_STA;
wire  [7:0] P_LX_CDR_ALIGN;
wire  refclk_div_sync;
wire  hpll_div_sync;
wire  pma_powerdown;
wire [2:0] tx_rate_i;
wire [1:0] tx_rate;
wire tx_lane_powerdown;
wire [7:0] rx_lane_powerdown;

wire pma_powerdownn;
wire pll_powerdown;
wire pll_rst;
wire tx_rate_change_on;
wire [1:0] pll_lock;
wire pma_lane_powerdown;
wire [7:0] pma_lane_rst;
wire [7:0] tx_pma_rst;
wire [7:0] rx_pma_rst;
wire [7:0] rx_cdr_rst;
wire [7:0] rx_clkpath_rst;
wire [1:0] rx_rate;
wire [2:0] rx_rate_i;
wire [7:0] cdr_align;


wire [7:0] pcs_rx_rst;
wire [7:0] pcs_tx_rst;
wire [7:0] pcs_rx_cb_rst;
wire tx_enc_type;
wire rx_dec_type;
wire [5:0] q0_rxstatus_0;
wire [5:0] q0_rxstatus_1;
wire [5:0] q0_rxstatus_2;
wire [5:0] q0_rxstatus_3;
wire [5:0] q1_rxstatus_4;
wire [5:0] q1_rxstatus_5;
wire [5:0] q1_rxstatus_6;
wire [5:0] q1_rxstatus_7;

wire refclk;
wire [127:0] mac_phy_tx_deemp_gen3;
wire [127:0] mac_phy_tx_gen2_no_deemp;
wire [127:0] mac_phy_tx_deemp_gen3_convert;
wire [15:0]  mac_phy_tx_deemp_gen2;
wire rst_n;
reg pclk_unstable;
reg [7:0] loopback_en;
reg [31:0] mac_phy_txdatak_w;
reg [255:0] mac_phy_txdata_w;
reg [7:0]  mac_phy_txdatavalid_w;
reg [7:0]  mac_phy_txstartblock_w;
reg [15:0] mac_phy_txsyncheader_w;
reg [31:0] mac_phy_txdatak_pipe;
reg [255:0] mac_phy_txdata_pipe;
reg [7:0]  mac_phy_txdatavalid_pipe;
reg [7:0]  mac_phy_txstartblock_pipe;
reg [15:0] mac_phy_txsyncheader_pipe;
//wire tx_rst_done;
wire [7:0] start_rx_det;
reg [7:0] start_rx_det_ff;
wire [7:0] start_rx_det_pos;
reg  rx_detect_en;
reg  [5:0] det_cnt;
reg  [7:0] lx_rxdct_out_d;
wire [7:0] tx_rxdet_en;
wire [7:0] rx_det_done;
wire [7:0]tx_rxdet_status;
wire [7:0] pcs_lsm_synced;
wire [7:0] rx_sigdet_status;
wire hsst_rst;
wire rate_change_done;
wire [7:0] hsst_ch_ready;
wire [7:0] rx_valid_i;
assign  phy_mac_rxelecidle = ~rx_sigdet_status;
integer lpbk_i;
integer lpbk_j;
reg [7:0] mac_phy_rxeqeval_r;
reg rx_fdbk_en;
reg [3:0] fdbk_cnt;
wire rate_done;
wire [7:0] phy_status_feedback;
wire  start_rx_fdbk_pos;
reg [1:0] mac_phy_rate_r;
reg [1:0] mac_phy_rate_i;
wire [7:0] lpbk_slave_gen3;
wire [23:0] em_error_cnt;
wire [15:0] em_mode_ctrl_eval;
wire [7:0] eq_fdbk_done;
wire [63:0] rx_pic_eye_eval;
wire [63:0] rx_eye_tap_eval;
wire [2:0] em_error_cnt_7,em_error_cnt_6,em_error_cnt_5,em_error_cnt_4,
           em_error_cnt_3,em_error_cnt_2,em_error_cnt_1,em_error_cnt_0;

reg     [7:0]   p_rx_eye_rst;
wire    [7:0]   p_rx_eye_en;
reg     [7:0]   p_em_rd_trigger;
reg     [63:0]  p_rx_pic_eye;
reg     [63:0]  p_rx_eye_tap;
reg     [15:0]  p_em_mode_ctrl;//2 bit per lane
wire    [HSST_LANE_NUM-1:0]   rx_eye_rst_sync;
//wire    [HSST_LANE_NUM-1:0]   rx_eye_en_sync;
wire    [HSST_LANE_NUM*8-1:0] rx_eye_tap_sync;
wire    [HSST_LANE_NUM*8-1:0] rx_pic_eye_sync;
wire    [HSST_LANE_NUM-1:0]   em_rd_trigger_sync;
wire    [HSST_LANE_NUM*2-1:0] em_mode_ctrl_sync;

wire [2:0] pma_tx_buswidth;
wire [2:0] pma_tx_freerun_buswidth;
wire [2:0] pma_rx_buswidth;
wire [7:0] tx_compliance_l;
reg [7:0] tx_compliance_h;
wire [7:0] rx_lane_powerdown_ref;
wire [7:0] rx_lane_powerdown_i;

wire [7:0] rx_pma_rst_ref;
wire [7:0] rx_pma_rst_i;
wire      ltssm_in_l0;
reg       ltssm_in_l0_ref_loc;
wire  ltssm_in_l0_ref;
reg   ltssm_in_l0_ref_r;
reg  [7:0] phy_mac_rxvalid_ref_loc;
wire [7:0] phy_mac_rxvalid_ref;
wire    ref_rst_n;
//wire    hsst_apb_rst_n;

wire    tx_sync_refsync ;
wire    refclk_sync_refsync;
wire    div_sync_refsync;

wire    tx_sync_refsync_cas;
wire    refclk_sync_refsync_cas;
wire    div_sync_refsync_cas;

wire lpll_powerdown;
wire lpll_rst;
wire lpll_lock;
wire tx_sync;
//wire p_calib_done;

//apb mux
wire        p_cfg_l_psel ;
wire        p_cfg_t_psel ;
wire        p_cfg_l_ready;
wire        p_cfg_t_ready;
wire        p_cfg_l_int;
wire        p_cfg_t_int;
wire [7:0]  p_cfg_l_rdata;
wire [7:0]  p_cfg_t_rdata;

assign pad_rx_sdp          = {{(8-HSST_LANE_NUM){1'b0}}, rxp};
assign pad_rx_sdn          = {{(8-HSST_LANE_NUM){1'b0}}, rxn};
assign txp                 = pad_tx_sdp[HSST_LANE_NUM-1:0];
assign txn                 = pad_tx_sdn[HSST_LANE_NUM-1:0];
assign p_pcs_nearend_loop  = {{(8-HSST_LANE_NUM){1'b0}}, pcs_nearend_loop};
assign p_pma_nearend_ploop = {{(8-HSST_LANE_NUM){1'b0}}, pma_nearend_ploop};
assign p_pma_nearend_sloop = {{(8-HSST_LANE_NUM){1'b0}}, pma_nearend_sloop};

assign p_cfg_l_psel = p_cfg_addr[15] ? 1'b0       : p_cfg_psel ;  //0~4
assign p_cfg_t_psel = p_cfg_addr[15] ? p_cfg_psel : 1'b0       ;  //8~c

assign p_cfg_ready  = p_cfg_addr[15] ? p_cfg_t_ready : p_cfg_l_ready;
assign p_cfg_rdata  = p_cfg_addr[15] ? p_cfg_t_rdata : p_cfg_l_rdata;
assign p_cfg_int    = p_cfg_addr[15] ? p_cfg_t_int   : p_cfg_l_int;


assign ltssm_in_l0 = (smlh_ltssm_state == 6'h11);

always @ (posedge refclk or negedge ref_rst_n)
begin
    if(!ref_rst_n)
        ltssm_in_l0_ref_r <= 1'b0;
    else
        ltssm_in_l0_ref_r <= ltssm_in_l0_ref;
end


always @ (posedge refclk or negedge ref_rst_n)
begin
    if(!ref_rst_n)
        ltssm_in_l0_ref_loc <= 1'b0;
    else if(ltssm_in_l0_ref & ~ltssm_in_l0_ref_r)
        ltssm_in_l0_ref_loc <= 1'b1;
    else if(~ltssm_in_l0_ref & ltssm_in_l0_ref_r)
         ltssm_in_l0_ref_loc <= 1'b0;
end

always @ (posedge refclk or negedge ref_rst_n)
begin
    if(!ref_rst_n)
         phy_mac_rxvalid_ref_loc <= 8'b0;
    else if((ltssm_in_l0_ref & ~ltssm_in_l0_ref_r))
         phy_mac_rxvalid_ref_loc <= phy_mac_rxvalid_ref;
end


//turn off unused lane in l0
wire [7:0] pma_rx_turnoff;
assign pma_rx_turnoff = {8{ltssm_in_l0_ref_loc}} & ~phy_mac_rxvalid_ref_loc;
assign rx_lane_powerdown = pma_rx_turnoff | rx_lane_powerdown_ref;
assign rx_pma_rst        = pma_rx_turnoff | rx_pma_rst_ref;

ips_hsst_rst_sync_v1_0    hsst_pciex4_sync_hsst_rx_pd
    (
    .clk        (refclk             ),
    .rst_n      (ref_rst_n            ),
    .sig_async  (ltssm_in_l0  ),
    .sig_synced (ltssm_in_l0_ref      )
    );
generate
    genvar n;
    for(n=0;n<=7;n=n+1)
    ips_hsst_rst_sync_v1_0    hsst_pciex4_sync_hsst_rxvalid
    (
    .clk        (refclk             ),
    .rst_n      (ref_rst_n            ),
    .sig_async  (phy_mac_rxvalid[n]  ),
    .sig_synced (phy_mac_rxvalid_ref[n] )
    );
endgenerate


genvar l;
generate
for(l=0;l<=7;l=l+1)
    //always @ (*)
    //tx_compliance_h[l] =
    always @ (posedge pclk_div2)
    tx_compliance_h[l] <=
                         ((mac_phy_txdata[32*l+31:32*l+16] == 16'hB5BC)   & (mac_phy_txdatak[4*l+3:4*l+2] == 2'b01))
                          & ~((mac_phy_txdata[32*l+15:32*l] == 16'hBCBC) & (mac_phy_txdatak[4*l+1:4*l] == 2'b11))
                          & mac_phy_txcompliance[l]
                        | ((mac_phy_txdata[32*l+31:32*l+16] == 16'hBCBC) & (mac_phy_txdatak[4*l+3:4*l+2] == 2'b11))
                          & ~((mac_phy_txdata[32*l+15:32*l] == 16'hBCBC) & (mac_phy_txdatak[4*l+1:4*l] == 2'b11))
                          & mac_phy_txcompliance[l] ;
endgenerate

assign tx_compliance_l = ~tx_compliance_h & mac_phy_txcompliance;
assign em_error_cnt = {em_error_cnt_7,em_error_cnt_6,em_error_cnt_5,em_error_cnt_4,
                       em_error_cnt_3,em_error_cnt_2,em_error_cnt_1,em_error_cnt_0};

assign pma_tx_buswidth = mac_phy_rate_i[1] ? 3'b100 : 3'b011;
assign pma_rx_buswidth = pma_tx_buswidth;
assign pma_tx_freerun_buswidth =  mac_phy_rate_i[1] ? 3'b010 : 3'b011;

//----------obtain eye_monitor_ctrl START------------
//hsst status out
assign  txlane_done   = {HSST_LANE_NUM{tx_rst_done}};
assign  rxlane_done   = hsst_ch_ready[HSST_LANE_NUM-1:0];
assign  pll_done      = pll_lock_2quad;
assign  rx_sigdet_sta = ~P_LX_ALOS_STA[HSST_LANE_NUM-1:0];
assign  lx_cdr_align  = P_LX_CDR_ALIGN[HSST_LANE_NUM-1:0];
//cdc, sync usr port from refclk to pclk_div2
genvar gv_i;
generate
    for(gv_i=0;gv_i<=HSST_LANE_NUM-1;gv_i=gv_i+1) begin:gblk_em_sync
        ips_hsst_rst_sync_v1_0 u_rx_eye_rst_sync(
            .clk        (pclk_div2             ),
            .rst_n      (rst_n                 ),
            .sig_async  (rx_eye_rst[gv_i]      ),
            .sig_synced (rx_eye_rst_sync[gv_i] )
        );
//      ips_hsst_rst_sync_v1_0 u_rx_eye_en_sync(
//          .clk        (pclk_div2            ),
//          .rst_n      (rst_n                ),
//          .sig_async  (rx_eye_en[gv_i]      ),
//          .sig_synced (rx_eye_en_sync[gv_i] )
//      );
        ips_hsst_rst_sync_v1_0 u_em_rd_trigger_sync(
            .clk        (pclk_div2                ),
            .rst_n      (rst_n                    ),
            .sig_async  (em_rd_trigger[gv_i]      ),
            .sig_synced (em_rd_trigger_sync[gv_i] )
        );
    end
    for(gv_i=0;gv_i<=HSST_LANE_NUM-1;gv_i=gv_i+1) begin:gblk_em_msync
        hsst_mutileout_byte_adapter_nonvalid #(
            .DW(8)
        ) u_rx_eye_tap_sync(
            .sc_pcie_hard_en(1'b1),
            .ctrl_clk       (refclk                     ), // input
            .ctrl_rst_n     (ref_rst_n                  ), // input
            .dout_core      (rx_eye_tap[8*gv_i+:8]      ), // input
            .user_clk       (pclk_div2                  ), // input
            .user_rst_n     (rst_n                      ), // input
            .dout_usr_o     (rx_eye_tap_sync[8*gv_i+:8] )  // output
        );
        hsst_mutileout_byte_adapter_nonvalid #(
            .DW(8)
        ) u_rx_pic_eye_sync(
            .sc_pcie_hard_en(1'b1),
            .ctrl_clk       (refclk                     ), // input
            .ctrl_rst_n     (ref_rst_n                  ), // input
            .dout_core      (rx_pic_eye[8*gv_i+:8]      ), // input
            .user_clk       (pclk_div2                  ), // input
            .user_rst_n     (rst_n                      ), // input
            .dout_usr_o     (rx_pic_eye_sync[8*gv_i+:8] )  // output
        );
        hsst_mutileout_byte_adapter_nonvalid #(
            .DW(2)
        ) u_em_mode_ctrl_sync(
            .sc_pcie_hard_en(1'b1),
            .ctrl_clk       (refclk                       ), // input
            .ctrl_rst_n     (ref_rst_n                    ), // input
            .dout_core      (em_mode_ctrl[2*gv_i+:2]      ), // input
            .user_clk       (pclk_div2                    ), // input
            .user_rst_n     (rst_n                        ), // input
            .dout_usr_o     (em_mode_ctrl_sync[2*gv_i+:2] )  // output
        );
    end
endgenerate

genvar eq_i;
generate
for(eq_i=0;eq_i<=7;eq_i=eq_i+1)
hsst_pg2t_rxeqeval_gen3_v1_8 hsst_pg2t_rxeqeval_gen3
(
    .pclk_div2(pclk_div2),
    .phy_rst_n(phy_rst_n),
    .em_error_cnt(em_error_cnt[3*eq_i+2:3*eq_i]),
    .mac_phy_rxeqeval(mac_phy_rxeqeval[eq_i]),
    .em_mode_ctrl(em_mode_ctrl_eval[2*eq_i+1:2*eq_i]),
    .eq_fdbk_done(eq_fdbk_done[eq_i]),
    .phy_mac_fomfeedback(phy_mac_fomfeedback[8*eq_i+7:8*eq_i]),
    .phy_mac_dirfeedback(phy_mac_dirfeedback[6*eq_i+5:6*eq_i]),
    .rx_pic_eye(rx_pic_eye_eval[8*eq_i+7:8*eq_i]),
    .rx_eye_tap(rx_eye_tap_eval[8*eq_i+7:8*eq_i])
);
endgenerate

//mux, hsst iscan port connect to rxeqeval when ltssm is in EQ, otherwise connect to usr port.
always @(posedge pclk_div2)begin
    if(smlh_ltssm_state[5])begin
        p_rx_eye_rst    <= {8{1'b0}};
//      p_rx_eye_en     <= {8{1'b1}};
        p_em_rd_trigger <= {8{1'b0}};
        p_em_mode_ctrl  <= em_mode_ctrl_eval;
        p_rx_pic_eye    <= rx_pic_eye_eval;
        p_rx_eye_tap    <= rx_eye_tap_eval;
    end
    else begin
        p_rx_eye_rst    <= {{(8-HSST_LANE_NUM){1'b0}},rx_eye_rst_sync};
//      p_rx_eye_en     <= {{(8-HSST_LANE_NUM){1'b0}},rx_eye_en_sync};
        p_em_rd_trigger <= {{(8-HSST_LANE_NUM){1'b0}},em_rd_trigger_sync};
        p_em_mode_ctrl  <= {{(8-HSST_LANE_NUM)*2{1'b0}},em_mode_ctrl_sync};
        p_rx_pic_eye    <= {{(8-HSST_LANE_NUM)*8{1'b0}},rx_pic_eye_sync};
        p_rx_eye_tap    <= {{(8-HSST_LANE_NUM)*8{1'b0}},rx_eye_tap_sync};
    end
end
assign  p_rx_eye_en      = {8{1'b1}};
//for dv only
//
//
always @(posedge pclk_div2 or negedge rst_n)
begin
    if(!rst_n)
        mac_phy_rate_r <=2'b0;
    else
        mac_phy_rate_r <= mac_phy_rate_i;
end


always @(posedge pclk_div2 or negedge rst_n)
begin
    if(!rst_n)
        pclk_unstable <= 1'b0;
    else if(mac_phy_rate_i != mac_phy_rate_r)
        pclk_unstable <= 1'b1;
    else if(rate_done)
        pclk_unstable <= 1'b0;
end
//dv end


always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n)
         mac_phy_rxeqeval_r  <= 8'h0;
    else
         mac_phy_rxeqeval_r  <= mac_phy_rxeqeval;
end

assign start_rx_fdbk_pos = ~(|mac_phy_rxeqeval_r) & (|mac_phy_rxeqeval);


assign  phy_status_feedback = eq_fdbk_done;


wire [87:0] pcs_rdata0;
wire [87:0] pcs_rdata1;
wire [87:0] pcs_rdata2;
wire [87:0] pcs_rdata3;
wire [87:0] pcs_rdata4;
wire [87:0] pcs_rdata5;
wire [87:0] pcs_rdata6;
wire [87:0] pcs_rdata7;
wire [7:0]  rclk2fabric;
wire [7:0]  tclk2fabric;

assign pclk = rclk2fabric[0];
assign pclk_div2 = tclk2fabric[0];

`ifdef HSST_FAKE_PHY
    assign rx_rate = mac_phy_rate_i[1] ? 2'b11 :  (mac_phy_rate_i[0] ? 2'b10 : 2'b01);
    assign tx_rate = rx_rate;
`else
    assign rx_rate = tx_rate_i[1:0];
    assign tx_rate = tx_rate_i[1:0];
`endif


assign lpbk_slave_gen3 = loopback_en &  {8{mac_phy_rate_i[1]}};
always @ (*)
begin
    for(lpbk_i=0;lpbk_i<=7;lpbk_i=lpbk_i+1)
    begin
        if( mac_phy_powerdown==4'b0 & mac_phy_txelecidle_h[lpbk_i] == 1'b0 & mac_phy_txelecidle_l[lpbk_i] == 1'b0)
           loopback_en[lpbk_i] = mac_phy_txdetectrx_loopback[lpbk_i];
        else
           loopback_en[lpbk_i] = 1'b0;
        if(loopback_en[lpbk_i])
        begin
            mac_phy_txdatavalid_pipe[lpbk_i]         = phy_mac_rxdatavalid[lpbk_i];
            mac_phy_txstartblock_pipe[lpbk_i]        = phy_mac_rxstartblock[lpbk_i];

            for(lpbk_j = 4*lpbk_i;lpbk_j<= 3+4*lpbk_i;lpbk_j=lpbk_j+1)
                mac_phy_txdatak_pipe[lpbk_j]   = phy_mac_rxdatak[lpbk_j];
            for(lpbk_j = 32*lpbk_i;lpbk_j<= 31+32*lpbk_i;lpbk_j=lpbk_j+1)
                mac_phy_txdata_pipe[lpbk_j] = phy_mac_rxdata[lpbk_j];
            for(lpbk_j = 2*lpbk_i;lpbk_j<= 1+2*lpbk_i;lpbk_j=lpbk_j+1)
                mac_phy_txsyncheader_pipe[lpbk_j] = phy_mac_rxsyncheader[lpbk_j];
        end
        else
        begin
            mac_phy_txdatavalid_pipe[lpbk_i]         = mac_phy_txdatavalid[lpbk_i];
            mac_phy_txstartblock_pipe[lpbk_i]        = mac_phy_txstartblock[lpbk_i];

            for(lpbk_j = 4*lpbk_i;lpbk_j<= 3+4*lpbk_i;lpbk_j=lpbk_j+1)
                 mac_phy_txdatak_pipe[lpbk_j]   = mac_phy_txdatak[lpbk_j];
            for(lpbk_j = 32*lpbk_i;lpbk_j<= 31+32*lpbk_i;lpbk_j=lpbk_j+1)
                 mac_phy_txdata_pipe[lpbk_j] = mac_phy_txdata[lpbk_j];
            for(lpbk_j = 2*lpbk_i;lpbk_j<= 1+2*lpbk_i;lpbk_j=lpbk_j+1)
                 mac_phy_txsyncheader_pipe[lpbk_j] = mac_phy_txsyncheader[lpbk_j];
        end
    end
end
always@(posedge pclk_div2)
begin
    mac_phy_txdatavalid_w[7:0]   <= mac_phy_txdatavalid_pipe[7:0];
    mac_phy_txstartblock_w[7:0]  <= mac_phy_txstartblock_pipe[7:0];
    mac_phy_txdatak_w[31:0]      <= mac_phy_txdatak_pipe[31:0];
    mac_phy_txdata_w[255:0]      <= mac_phy_txdata_pipe[255:0];
    mac_phy_txsyncheader_w[15:0] <= mac_phy_txsyncheader_pipe[15:0];
end

function [43:0]  tx_data_gen;
    input [1:0]  mac_phy_powerdown;
    input        mac_phy_txelecidle_h;
    input        mac_phy_txelecidle_l;
    input [3:0]  mac_phy_txdatak;
    input [31:0] mac_phy_txdata;
    input [1:0]  mac_phy_txsyncheader;
    input        mac_phy_txdatavalid;
    input        mac_phy_txstartblock;
    input [1:0]  rate;
    input        mac_phy_txcompliance_h;
    input        mac_phy_txcompliance_l;

    begin
        tx_data_gen = rate[1] ? {1'b0,mac_phy_txsyncheader,mac_phy_txdata[31:24],1'b0,mac_phy_txstartblock,mac_phy_txdatavalid,mac_phy_txdata[23:16],3'b0,mac_phy_txdata[15:8],3'b0,mac_phy_txdata[7:0]}
                              :  {mac_phy_txdatak[3], 2'd0, mac_phy_txdata[31 :24],
                                  mac_phy_txdatak[2], mac_phy_txcompliance_h, 1'b0,mac_phy_txdata[23 :16],
                                  mac_phy_txdatak[1], 2'd0, mac_phy_txdata[15 :8],
                                  mac_phy_txdatak[0], mac_phy_txcompliance_l, 1'b0, mac_phy_txdata[7:0]
                             };
    end
endfunction

wire [87:0] pcs_tdata0;
wire [87:0] pcs_tdata1;
wire [87:0] pcs_tdata2;
wire [87:0] pcs_tdata3;
wire [87:0] pcs_tdata4;
wire [87:0] pcs_tdata5;
wire [87:0] pcs_tdata6;
wire [87:0] pcs_tdata7;
wire [7:0]  phy_mac_rxdatavalid_i;
wire [7:0]  phy_mac_rxstartblock_i;
wire [15:0] phy_mac_rxsyncheader_i;

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata0
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[0]),
   .lx_rxdct_out_d(lx_rxdct_out_d[0]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q0_rxstatus_0),
   .P_RDATA(pcs_rdata0[43:0]),

   .phy_mac_rxdata(phy_mac_rxdata[31:0]),
   .phy_mac_rxdatak(phy_mac_rxdatak[3:0]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[0]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[1:0]),
   .phy_mac_rxstatus(phy_mac_rxstatus[2:0])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata1
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[1]),
   .lx_rxdct_out_d(lx_rxdct_out_d[1]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q0_rxstatus_1),
   .P_RDATA(pcs_rdata1[43:0]),

   .phy_mac_rxdata(phy_mac_rxdata[63:32]),
   .phy_mac_rxdatak(phy_mac_rxdatak[7:4]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[1]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[3:2]),
   .phy_mac_rxstatus(phy_mac_rxstatus[5:3])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata2
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[2]),
   .lx_rxdct_out_d(lx_rxdct_out_d[2]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q0_rxstatus_2),
   .P_RDATA(pcs_rdata2[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[95:64]),
   .phy_mac_rxdatak(phy_mac_rxdatak[11:8]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[2]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[5:4]),
   .phy_mac_rxstatus(phy_mac_rxstatus[8:6])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata3
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[3]),
   .lx_rxdct_out_d(lx_rxdct_out_d[3]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q0_rxstatus_3),
   .P_RDATA(pcs_rdata3[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[127:96]),
   .phy_mac_rxdatak(phy_mac_rxdatak[15:12]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[3]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[7:6]),
   .phy_mac_rxstatus(phy_mac_rxstatus[11:9])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata4
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[4]),
   .lx_rxdct_out_d(lx_rxdct_out_d[4]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q1_rxstatus_4),
   .P_RDATA(pcs_rdata4[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[159:128]),
   .phy_mac_rxdatak(phy_mac_rxdatak[19:16]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[4]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[9:8]),
   .phy_mac_rxstatus(phy_mac_rxstatus[14:12])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata5
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[5]),
   .lx_rxdct_out_d(lx_rxdct_out_d[5]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q1_rxstatus_5),
   .P_RDATA(pcs_rdata5[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[191:160]),
   .phy_mac_rxdatak(phy_mac_rxdatak[23:20]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[5]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[11:10]),
   .phy_mac_rxstatus(phy_mac_rxstatus[17:15])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata6
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[6]),
   .lx_rxdct_out_d(lx_rxdct_out_d[6]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q1_rxstatus_6),
   .P_RDATA(pcs_rdata6[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[223:192]),
   .phy_mac_rxdatak(phy_mac_rxdatak[27:24]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[6]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[13:12]),
   .phy_mac_rxstatus(phy_mac_rxstatus[20:18])
);

hsst_pg2t_phy_mac_rdata_proc phy_mac_rxdata7
(
   .pclk(pclk_div2),
   .rst_n(phy_rst_n),
   .rx_det_done(rx_det_done[7]),
   .lx_rxdct_out_d(lx_rxdct_out_d[7]),
   .mac_phy_rate(mac_phy_rate_i[1:0]),
   .pcs_rx_status(q1_rxstatus_7),
   .P_RDATA(pcs_rdata7[43:0]),
   .phy_mac_rxdata(phy_mac_rxdata[255:224]),
   .phy_mac_rxdatak(phy_mac_rxdatak[31:28]),
   .phy_mac_startblock(phy_mac_rxstartblock_i[7]),
   .phy_mac_syncheader(phy_mac_rxsyncheader_i[15:14]),
   .phy_mac_rxstatus(phy_mac_rxstatus[23:21])
);
assign  pcs_tdata0 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[0],mac_phy_txelecidle_l[0],mac_phy_txdatak_w[3:0],
                     mac_phy_txdata_w[31:0],mac_phy_txsyncheader_w[1:0],mac_phy_txdatavalid_w[0],mac_phy_txstartblock_w[0],mac_phy_rate_i,tx_compliance_h[0],tx_compliance_l[0])};

assign  pcs_tdata1 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[1],mac_phy_txelecidle_l[1],mac_phy_txdatak_w[7:4],
                     mac_phy_txdata_w[63:32],mac_phy_txsyncheader_w[3:2],mac_phy_txdatavalid_w[1],mac_phy_txstartblock_w[1],mac_phy_rate_i,tx_compliance_h[1],tx_compliance_l[1])};
assign  pcs_tdata2 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[2],mac_phy_txelecidle_l[2],mac_phy_txdatak_w[11:8],
                     mac_phy_txdata_w[95:64],mac_phy_txsyncheader_w[5:4],mac_phy_txdatavalid_w[2],mac_phy_txstartblock_w[2],mac_phy_rate_i,tx_compliance_h[2],tx_compliance_l[2])};
assign  pcs_tdata3 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[3],mac_phy_txelecidle_l[3],mac_phy_txdatak_w[15:12],
                     mac_phy_txdata_w[127:96],mac_phy_txsyncheader_w[7:6],mac_phy_txdatavalid_w[3],mac_phy_txstartblock_w[3],mac_phy_rate_i,tx_compliance_h[3],tx_compliance_l[3])};
assign  pcs_tdata4 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[4],mac_phy_txelecidle_l[4],mac_phy_txdatak_w[19:16],
                     mac_phy_txdata_w[159:128],mac_phy_txsyncheader_w[9:8],mac_phy_txdatavalid_w[4],mac_phy_txstartblock_w[4],mac_phy_rate_i,tx_compliance_h[4],tx_compliance_l[4])};
assign  pcs_tdata5 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[5],mac_phy_txelecidle_l[5],mac_phy_txdatak_w[23:20],
                     mac_phy_txdata_w[191:160],mac_phy_txsyncheader_w[11:10],mac_phy_txdatavalid_w[5],mac_phy_txstartblock_w[5],mac_phy_rate_i,tx_compliance_h[5],tx_compliance_l[5])};
assign  pcs_tdata6 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[6],mac_phy_txelecidle_l[6],mac_phy_txdatak_w[27:24],
                     mac_phy_txdata_w[223:192],mac_phy_txsyncheader_w[13:12],mac_phy_txdatavalid_w[6],mac_phy_txstartblock_w[6],mac_phy_rate_i,tx_compliance_h[6],tx_compliance_l[6])};
assign  pcs_tdata7 = {44'b0,tx_data_gen(mac_phy_powerdown,mac_phy_txelecidle_h[7],mac_phy_txelecidle_l[7],mac_phy_txdatak_w[31:28],
                     mac_phy_txdata_w[255:224],mac_phy_txsyncheader_w[15:14],mac_phy_txdatavalid_w[7],mac_phy_txstartblock_w[7],mac_phy_rate_i,tx_compliance_h[7],tx_compliance_l[7])};

reg [7:0]  rxstartblock_det;
reg [7:0]  phy_mac_rxdatavalid_r;
reg [7:0]  phy_mac_rxdatavalid_r2;
reg [7:0]  phy_mac_rxdatavalid_r3;

always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
    begin
        phy_mac_rxdatavalid_r <= 8'h0;
        phy_mac_rxdatavalid_r2 <= 8'h0;
        phy_mac_rxdatavalid_r3 <= 8'h0;
    end
    else
    begin
        phy_mac_rxdatavalid_r <= phy_mac_rxdatavalid_i;
        phy_mac_rxdatavalid_r2 <= phy_mac_rxdatavalid_r;
        phy_mac_rxdatavalid_r3 <= phy_mac_rxdatavalid_r2;
    end
end

generate
genvar k;
for(k=0;k<8;k=k+1)begin
ips_hsst_rst_sync_v1_0    hsst_pciex4_sync_hsst_ch_ready
    (
    .clk        ( pclk_div2             ),
    .rst_n      ( rst_n            ),
    .sig_async  ( hsst_ch_ready[k] ),
    .sig_synced ( rx_valid_i[k]      )
    );
end
endgenerate


//in gen3 ,align rxvalid with rxstartblock
genvar blk_i;
generate
for(blk_i=0;blk_i<=7;blk_i=blk_i+1)
    always @ (posedge pclk_div2 or negedge rst_n)
    if(~rst_n)
        rxstartblock_det[blk_i] <= 1'b0;
    else if(!phy_mac_rxvalid[blk_i])
        rxstartblock_det[blk_i] <= 1'b0;
    else if(phy_mac_rxstartblock_i[blk_i] & ~phy_mac_rxdatavalid_r2[blk_i] &  phy_mac_rxdatavalid_r[blk_i] &  phy_mac_rxdatavalid_r3[blk_i])
        rxstartblock_det[blk_i] <= 1'b1;
endgenerate
always @ (*)
begin
    if(|rx_valid_i)
        if(mac_phy_rate_i[1]) //align rx_valid with start_block in gen3 mode
            phy_mac_rxvalid = pcs_lsm_synced  & (rxstartblock_det | (phy_mac_rxstartblock_i & ~phy_mac_rxdatavalid_r2 & phy_mac_rxdatavalid_r & phy_mac_rxdatavalid_r3));//first block of every 16 block
        else
            phy_mac_rxvalid = pcs_lsm_synced;
    else
        phy_mac_rxvalid = 8'h0;
end
assign phy_mac_rxdatavalid = mac_phy_rate_i[1] ? (phy_mac_rxvalid & phy_mac_rxdatavalid_r) : 8'hff;
assign phy_mac_rxstartblock = mac_phy_rate_i[1] ? (phy_mac_rxvalid & phy_mac_rxstartblock_i) : 8'h00;
assign phy_mac_rxsyncheader = phy_mac_rxsyncheader_i;


generate
    for(gv_i=0;gv_i<=8-1;gv_i=gv_i+1) begin:gblk_tx_deemp_gen2
        assign mac_phy_tx_deemp_gen2[2*gv_i+:2] =  (mac_phy_rate == 2'd2) ? 2'b00 : //Gen3 select 00
          					                       (mac_phy_rate == 2'd1) ? ((mac_phy_txdeemph[18*gv_i+1] == 1'b1) ? 2'b00 : ((mac_phy_txdeemph[18*gv_i] == 1'b1) ? 2'b01 : 2'b10)) : //Gen2 select from PCIe Controller instruction 
                                                   			                2'b01;  //Gen1 select 01
    end
endgenerate
assign mac_phy_tx_gen2_no_deemp = {8{tx_deemph_pma({6'd0,6'd24,6'd0})}};//no de-emphasis, pre post is 0
//assign mac_phy_tx_deemp_gen3 = {mac_phy_txdeemph[142:138],mac_phy_txdeemph[137:132],mac_phy_txdeemph[130:126],
//                                mac_phy_txdeemph[124:120],mac_phy_txdeemph[119:114],mac_phy_txdeemph[112:108],
//                                mac_phy_txdeemph[106:102],mac_phy_txdeemph[101: 96],mac_phy_txdeemph[ 94: 90],
//                                mac_phy_txdeemph[ 88: 84],mac_phy_txdeemph[ 83: 78],mac_phy_txdeemph[ 76: 72],
//                                mac_phy_txdeemph[ 70: 66],mac_phy_txdeemph[ 65: 60],mac_phy_txdeemph[ 58: 54],
//                                mac_phy_txdeemph[ 52: 48],mac_phy_txdeemph[ 47: 42],mac_phy_txdeemph[ 40: 36],
//                                mac_phy_txdeemph[ 34: 30],mac_phy_txdeemph[ 29: 24],mac_phy_txdeemph[ 22: 18],
//                                mac_phy_txdeemph[ 16: 12],mac_phy_txdeemph[ 11:  6],mac_phy_txdeemph[  4:  0]
//                                };
assign mac_phy_tx_deemp_gen3_convert = {tx_deemph_pma(mac_phy_txdeemph[143:126]),
                                		tx_deemph_pma(mac_phy_txdeemph[125:108]),
                                		tx_deemph_pma(mac_phy_txdeemph[107: 90]),
                                		tx_deemph_pma(mac_phy_txdeemph[ 89: 72]),
                                		tx_deemph_pma(mac_phy_txdeemph[ 71: 54]),
                                		tx_deemph_pma(mac_phy_txdeemph[ 53: 36]),
                                		tx_deemph_pma(mac_phy_txdeemph[ 35: 18]),
                                		tx_deemph_pma(mac_phy_txdeemph[ 17:  0])
                                		};
assign mac_phy_tx_deemp_gen3 = (mac_phy_rate[1:0] == 2'b01) ? mac_phy_tx_gen2_no_deemp :
							                                mac_phy_tx_deemp_gen3_convert; 				
//rate change after 20 pclk_div2 elecidle
reg [7:0] enter_elecidle_dly_cnt;
always @ (posedge pclk_div2 or negedge rst_n)
if(~rst_n)
    enter_elecidle_dly_cnt <= 8'b0;
else if(~((&mac_phy_txelecidle_h) & (&mac_phy_txelecidle_l))) // any lane active
    enter_elecidle_dly_cnt <= 8'b0;
else if(enter_elecidle_dly_cnt == 8'd32)
    enter_elecidle_dly_cnt <= 8'd32;
else if((&mac_phy_txelecidle_h) & (&mac_phy_txelecidle_l)) //all lane inactive
    enter_elecidle_dly_cnt <= enter_elecidle_dly_cnt + 8'b1;


always @  (posedge pclk_div2 or negedge rst_n)
begin
    if(~rst_n)
       mac_phy_rate_i <= 2'b0;
    else if(enter_elecidle_dly_cnt == 8'd32)
        mac_phy_rate_i <= mac_phy_rate;
end



assign tx_enc_type = mac_phy_rate_i[1];
assign rx_dec_type = mac_phy_rate_i[1];
assign phy_mac_locallf = {8{6'd16}};
assign phy_mac_localfs = {8{6'd48}};


wire [7:0] mac_phy_getlocal_pset_coef_i;
reg [7:0] mac_phy_getlocal_pset_coef_r1;
reg [7:0] mac_phy_getlocal_pset_coef_r2;
reg [7:0] mac_phy_getlocal_pset_coef_r3;
reg [7:0] phy_mac_local_tx_coef_valid_r1;
reg [7:0] phy_mac_local_tx_coef_valid_r2;

wire mask;
reg assert_tx_coef_valid;

always @ (posedge pclk_div2 or negedge rst_n)
begin
     if(~rst_n)
     begin
        mac_phy_getlocal_pset_coef_r1 <= 8'h0;
        mac_phy_getlocal_pset_coef_r2 <= 8'h0;
        mac_phy_getlocal_pset_coef_r3 <= 8'h0;
        phy_mac_local_tx_coef_valid_r1 <= 8'b0;
        phy_mac_local_tx_coef_valid_r2 <= 8'b0;
     end
    else
      begin
        mac_phy_getlocal_pset_coef_r1 <=mac_phy_getlocal_pset_coef;
        mac_phy_getlocal_pset_coef_r2 <= mac_phy_getlocal_pset_coef_r1;
        mac_phy_getlocal_pset_coef_r3 <= mac_phy_getlocal_pset_coef_r2 ;
        phy_mac_local_tx_coef_valid_r1 <= phy_mac_local_tx_coef_valid;
        phy_mac_local_tx_coef_valid_r2 <=  phy_mac_local_tx_coef_valid_r1;
     end
end

assign mask = (|phy_mac_local_tx_coef_valid) | (|phy_mac_local_tx_coef_valid_r1)  ;
always @ (*)
begin
     if(|mac_phy_getlocal_pset_coef_r2 & !mask )
        assert_tx_coef_valid = 1'b1;
    else
       assert_tx_coef_valid = 1'b0;
end

assign  mac_phy_getlocal_pset_coef_i = assert_tx_coef_valid ? (mac_phy_getlocal_pset_coef | mac_phy_getlocal_pset_coef_r1 | mac_phy_getlocal_pset_coef_r2) : 8'b0;


reg [31:0] mac_phy_local_pset_index_i;
reg [31:0] mac_phy_local_pset_index_i_r;
always @ (*)
begin
   mac_phy_local_pset_index_i[3:0] = mac_phy_getlocal_pset_coef[0] ? mac_phy_local_pset_index[3:0] : mac_phy_local_pset_index_i_r[3:0];
   mac_phy_local_pset_index_i[7:4] = mac_phy_getlocal_pset_coef[1] ? mac_phy_local_pset_index[7:4] : mac_phy_local_pset_index_i_r[7:4];
   mac_phy_local_pset_index_i[11:8] = mac_phy_getlocal_pset_coef[2] ? mac_phy_local_pset_index[11:8] : mac_phy_local_pset_index_i_r[11:8];
   mac_phy_local_pset_index_i[15:12] = mac_phy_getlocal_pset_coef[3] ? mac_phy_local_pset_index[15:12] : mac_phy_local_pset_index_i_r[15:12];
   mac_phy_local_pset_index_i[19:16] = mac_phy_getlocal_pset_coef[4] ? mac_phy_local_pset_index[19:16] : mac_phy_local_pset_index_i_r[19:16];
   mac_phy_local_pset_index_i[23:20] = mac_phy_getlocal_pset_coef[5] ? mac_phy_local_pset_index[23:20] : mac_phy_local_pset_index_i_r[23:20];
   mac_phy_local_pset_index_i[27:24] = mac_phy_getlocal_pset_coef[6] ? mac_phy_local_pset_index[27:24] : mac_phy_local_pset_index_i_r[27:24];
   mac_phy_local_pset_index_i[31:28] = mac_phy_getlocal_pset_coef[7] ? mac_phy_local_pset_index[31:28] : mac_phy_local_pset_index_i_r[31:28];
end

always @ (posedge pclk_div2 or negedge rst_n)
begin
    if(~rst_n)
        mac_phy_local_pset_index_i_r <= 32'b0;
    else
        mac_phy_local_pset_index_i_r <= mac_phy_local_pset_index_i;
end

genvar i;
generate
    for(i=0;i<=7;i=i+1)

        always @ (posedge pclk_div2)
        begin
            if(mac_phy_getlocal_pset_coef_i[i])
            begin
                phy_mac_local_tx_coef_valid[i] <= 1'b1;
                case(mac_phy_local_pset_index_i[4*i+3:4*i])
                4'd0:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd12,6'd36,6'd0};
                4'd1:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd8,6'd40,6'd0};
                4'd2:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd10,6'd38,6'd0};
                4'd3:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd6,6'd42,6'd0};
                4'd4:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd0,6'd48,6'd0};
                4'd5:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd0,6'd44,6'd4};
                4'd6:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd0,6'd42,6'd6};
                4'd7:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd10,6'd34,6'd4};
                4'd8:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd6,6'd36,6'd6};
                4'd9:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd0,6'd40,6'd8};
                4'd10:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd16,6'd32,6'd0};
                default:
                    phy_mac_local_tx_pset_coef[18*i+17:18*i] <= {6'd0,6'd48,6'd0};
                endcase
            end
            else
            begin
                phy_mac_local_tx_pset_coef[18*i+17:18*i]  <= 18'b0;
                phy_mac_local_tx_coef_valid[i] <= 1'b0;
            end
        end
endgenerate

assign  rx_clkpath_rst = 0;
//rate_change_done
wire rate_done_s;
reg  rate_done_s_r1;

always @ (posedge pclk_div2 or negedge rst_n)
begin
    if(~rst_n)
        rate_done_s_r1 <= 1'b0;
    else
        rate_done_s_r1 <= rate_done_s;
end

assign rate_done = rate_done_s & ~rate_done_s_r1;

assign rst_n = phy_rst_n;

assign P_LX_ALOS_STA = phy_mac_rxelecidle & (~p_pcs_nearend_loop & ~p_pma_nearend_ploop & ~p_pma_nearend_sloop) ;
assign P_LX_CDR_ALIGN = cdr_align | p_pcs_nearend_loop | p_pma_nearend_ploop;
//
//=== Rx detect ===

assign start_rx_det[0] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[0];
assign start_rx_det[1] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[1];
assign start_rx_det[2] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[2];
assign start_rx_det[3] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[3];
assign start_rx_det[4] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[4];
assign start_rx_det[5] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[5];
assign start_rx_det[6] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[6];
assign start_rx_det[7] = (mac_phy_powerdown == 2'b10) & mac_phy_txdetectrx_loopback[7];


always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n)
        start_rx_det_ff <= 8'b0;
    else
        start_rx_det_ff <= start_rx_det;
end

assign start_rx_det_pos = ~start_rx_det_ff & start_rx_det;

always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n) begin
        rx_detect_en   <= 1'b0;
        det_cnt        <= 6'd0;
        lx_rxdct_out_d <= 8'd0;
    end
    else begin
        if (rx_detect_en) begin
           if (&det_cnt) begin
              det_cnt   <= 6'd0;
              rx_detect_en <= 1'b0;
           end
           else
              det_cnt   <= det_cnt + 1;
        end
        else if (|start_rx_det_pos) begin
           rx_detect_en <= 1'b1;
           det_cnt      <= 6'd0;
        end

        if (rx_detect_en && (det_cnt == 6'd59))
           lx_rxdct_out_d <= tx_rxdet_status;
    end
end

assign tx_rxdet_en  = {8{~prbs_en}} & {8{rx_detect_en}} & start_rx_det;

assign rx_det_done = (det_cnt == 6'd60) ? tx_rxdet_en : 8'h0;

localparam P2_ENTRY_CNT_INIT   = 16;
localparam P2_EXIT_CNT_INIT    = 16;
localparam L0_TO_L0S_CNT_INIT  = 16;
localparam L0S_TO_L0_CNT_INIT  = 16;
localparam L1_TO_L0_CNT_INIT   = 16;
localparam L0_TO_L1_CNT_INIT   = 16;
localparam DEFAULT_CNT_INIT    = 16;
reg [3:0] tx_rst_done_d;
reg [7:0] phy_mac_phystatus_reset;
reg [7:0] phy_mac_phystatus_misc;
reg [7:0] phy_mac_phystatus_pm;
reg [1:0] mac_phy_powerdown_d;
reg [7:0] cnt;
always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n) begin
        tx_rst_done_d <= 4'h0;
        phy_mac_phystatus_reset <= 8'hff;
    end
    else begin
        tx_rst_done_d <= {tx_rst_done_d[2:0], tx_rst_done & ~(&rx_lane_powerdown)};

        if (tx_rst_done_d[2] & (~tx_rst_done_d[3]))
           phy_mac_phystatus_reset <= 8'h00;
    end
end

always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n) begin
        phy_mac_phystatus_misc <= 8'h0;
    end
    else begin
        if ((|rx_det_done) | rate_done)
           phy_mac_phystatus_misc <= 8'hff;
        else
           phy_mac_phystatus_misc <= 8'h0;
    end
end

always@(posedge pclk_div2 or negedge rst_n)
begin
    if (!rst_n) begin
        mac_phy_powerdown_d  <= 2'd2;
        cnt                  <= 8'd0;
        phy_mac_phystatus_pm <= 8'b0;
    end
    else begin
        mac_phy_powerdown_d  <= mac_phy_powerdown;
        if ((mac_phy_powerdown == 2'd3) & (mac_phy_powerdown_d == 2'd0)) //P0 to P2; P2 entry, to be update; also used for L0 to L1
           cnt <= P2_ENTRY_CNT_INIT;
        else if ((mac_phy_powerdown == 2'd0) & (mac_phy_powerdown_d == 2'd3)) //P2 to P0; P2 exit, to be update
           cnt <= P2_EXIT_CNT_INIT;
        else if ((mac_phy_powerdown == 2'd1) & (mac_phy_powerdown_d == 2'd0)) //L0 to L0s
           cnt <= L0_TO_L0S_CNT_INIT;
        else if ((mac_phy_powerdown == 2'd0) & (mac_phy_powerdown_d == 2'd1)) //L0s to L0
           cnt <= L0S_TO_L0_CNT_INIT;
        else if ((mac_phy_powerdown == 2'd0) & (mac_phy_powerdown_d == 2'd2)) //L1 to L0
           cnt <= L1_TO_L0_CNT_INIT;
        else if ((mac_phy_powerdown == 2'd2) & (mac_phy_powerdown_d == 2'd0)) //L0 to L1
           cnt <= L0_TO_L1_CNT_INIT;
        else if (mac_phy_powerdown != mac_phy_powerdown_d )//default
                 cnt <= DEFAULT_CNT_INIT;
        else if (cnt != 0)
           cnt <= cnt - 1;

        if (cnt == 1)
           phy_mac_phystatus_pm <= 8'hff;
        else
           phy_mac_phystatus_pm <= 8'h0;
    end
end

assign phy_mac_phystatus = phy_mac_phystatus_pm | phy_mac_phystatus_misc | phy_mac_phystatus_reset | phy_status_feedback;

ips_hsst_rst_sync_v1_0    hsst_pciex4_sync_rate_done
    (
    .clk        ( pclk_div2             ),
    .rst_n      ( rst_n            ),
    .sig_async  ( rate_change_done ),
    .sig_synced ( rate_done_s      )
    );

//prbs
wire [7:0] p_pcie_ei_h;
wire [7:0] p_pcie_ei_l;

assign p_pcie_ei_h = {8{~prbs_en}} & mac_phy_txelecidle_h;
assign p_pcie_ei_l = {8{~prbs_en}} & mac_phy_txelecidle_l;

ipm2t_pcie_hssthp_wrapper_v1_5b_v1_6 #(
    //--------Global Parameter--------//

    .HPLL_EN                           (HPLL_EN                         ),//TRUE, FALSE; for HPLL enable

    .CHANNEL0_EN                       ("TRUE"                          ),//TRUE, FALSE; for Channel0 enable

    .CHANNEL1_EN                       (CHANNEL1_EN                     ),//TRUE, FALSE; for Channel1 enable

    .CHANNEL2_EN                       (CHANNEL2_EN                     ),//TRUE, FALSE; for Channel2 enable

    .CHANNEL3_EN                       (CHANNEL3_EN                     ),//TRUE, FALSE; for Channel3 enable

    .CH0_MULT_LANE_MODE                (CH_MULT_LANE_MODE               ),//Lane0 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH1_MULT_LANE_MODE                (CH_MULT_LANE_MODE               ),//Lane1 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH2_MULT_LANE_MODE                (CH_MULT_LANE_MODE               ),//Lane2 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH3_MULT_LANE_MODE                (CH_MULT_LANE_MODE               ),//Lane3 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .HSST_LANE_NUM                     (LANE_NUM                        ),

    .REFCLK_PAD0_EN                    ("TRUE"                          ),//TRUE, FALSE; for REFCLK_PAD0 enable

    .REFCLK_PAD1_EN                    ("FALSE"                         ),//TRUE, FALSE; for REFCLK_PAD1 enable

    .PMA_REG_HPLL_REFCLK_SEL           ("REFERENCE_CLOCK_0"             ),//HPLL  REFCLK Selection

    .PMA_REG_LANE0_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL0 REFCLK Selection

    .PMA_REG_LANE1_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL1 REFCLK Selection

    .PMA_REG_LANE2_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL2 REFCLK Selection

    .PMA_REG_LANE3_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL3 REFCLK Selection

    .CALIB_EN                          (CALIB_EN                        )

) U1_L_HSSTHP_TOP (

    //APB
    .p_cfg_clk                          (p_cfg_clk                      ), // input           i_p_cfg_clk
    .p_cfg_rst                          (~p_cfg_rst_n                   ), // input           i_p_cfg_rst
    .p_cfg_psel                         (p_cfg_l_psel                   ), // input           i_p_cfg_psel
    .p_cfg_enable                       (p_cfg_enable                   ), // input           i_p_cfg_enable
    .p_cfg_write                        (p_cfg_write                    ), // input           i_p_cfg_write
    .p_cfg_addr                         (p_cfg_addr                     ), // input  [15:0]   i_p_cfg_addr
    .p_cfg_wdata                        (p_cfg_wdata                    ), // input  [7:0]    i_p_cfg_wdata
    .p_cfg_rdata                        (p_cfg_l_rdata                  ), // output [7:0]    o_p_cfg_rdata
    .p_cfg_int                          (p_cfg_l_int                    ), // output          o_p_cfg_int
    .p_cfg_ready                        (p_cfg_l_ready                  ), // output          o_p_cfg_ready
    .p_fabric_refclk                    (1'b0                           ), // input
    .p_calib_done                       (p_calib_done[0]                ),
    //HPLL
    .P_COM_POWERDOWN                    (1'b0                           ), // input
    .P_HPLL_POWERDOWN                   (pll_powerdown                  ), // input
    .P_HPLL_RST                         (pll_rst                        ), // input
    .P_TX_SYNC                          (tx_sync                        ), // input
    .P_TX_RATE_CHANGE_ON_0              (tx_rate_change_on              ), // input
    .P_TX_RATE_CHANGE_ON_1              (tx_rate_change_on              ), // input to be done
    .P_HPLL_DIV_SYNC                    (hpll_div_sync                  ), // input
    .P_REFCLK_DIV_SYNC                  (refclk_div_sync                ), // input
    .P_HPLL_VCO_CALIB_EN                (1'b1                           ), // input
    .P_HPLL_DIV_CHANGE                  (tx_enc_type                    ), // input
    //----------PMA cascade port----------//
    .TX_SYNC_REFSYNC_O                  (tx_sync_refsync                ), //output
    .REFCLK_SYNC_REFSYNC_O              (refclk_sync_refsync            ), //output
    .DIV_SYNC_REFSYNC_O                 (div_sync_refsync               ), //output
    .ANA_TX_SYNC_I                      (tx_sync_refsync                ), //input
    .ANA_HPLL_REFCLK_SYNC_I             (refclk_sync_refsync            ), //input
    .ANA_HPLL_DIV_SYNC_I                (div_sync_refsync               ), //input
    //----------PMA cascade port end----------//
    .P_REFCK2CORE_0                     (refclk                         ), // output
    .P_REFCK2CORE_1                     (                               ), // output
    .P_HPLL_READY                       (pll_lock[0]                    ), // output

    .PAD_REFCLKN_0                      (refclk_n                       ), // input
    .PAD_REFCLKP_0                      (refclk_p                       ), // input

    .PAD_REFCLKN_1                      (1'b0                           ), // input
    .PAD_REFCLKP_1                      (1'b0                           ), // input

    .P_LANE_POWERDOWN_0                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_0                       (pma_lane_rst[0]                ), // input
    .P_TX_PMA_RST_0                     (tx_pma_rst[0]                  ), // input
    .P_TX_LANE_POWERDOWN_0              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_0              (rx_lane_powerdown[0]           ), // input
    .P_TCLK2FABRIC_0                    (tclk2fabric[0]                 ), // output
    .P_TX_CLK_FR_CORE_0                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_0                  (pclk                           ), // input
    .P_RCLK2FABRIC_0                    (rclk2fabric[0]                 ), // output
    .P_RXSTATUS_0                       (q0_rxstatus_0                  ), // output
    .P_RX_CLK_FR_CORE_0                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_0                  (pclk                           ), // input
    .P_RX_PMA_RST_0                     (rx_pma_rst[0]                  ), // input
    .P_PCS_TX_RST_0                     (pcs_tx_rst[0]                  ), // input
    .P_PCS_RX_RST_0                     (pcs_rx_rst[0]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_0             (pcs_rx_cb_rst[0]               ), // input
    .P_TX_MARGIN_0                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_0                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_0                       (mac_phy_tx_deemp_gen3[15:0]    ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_0              (mac_phy_tx_deemp_gen2[1:0]     ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_0                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_0                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_0                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_0                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_0                  (                               ), // output
    .P_RX_EYE_RST_0                     (p_rx_eye_rst[0]                ), // input
    .P_RX_EYE_EN_0                      (p_rx_eye_en[0]                 ), // input
    .P_RX_EYE_TAP_0                     (p_rx_eye_tap[0*8+:8]           ), // input [7:0]
    .P_RX_PIC_EYE_0                     (p_rx_pic_eye[0*8+:8]           ), // input [7:0]
    .P_RX_PIC_FASTLOCK_0                (8'b0                           ), // input [7:0]
    .P_RX_PIC_FASTLOCK_STROBE_0         (1'b0                           ), // input
    .P_EM_RD_TRIGGER_0                  (p_em_rd_trigger[0]             ), // input
    .P_EM_MODE_CTRL_0                   (p_em_mode_ctrl[0*2+:2]         ), // input [1:0]
    .P_EM_ERROR_CNT_0                   (em_error_cnt_0                 ), // output
    .P_RX_SLIP_RST_0                    (1'b0                           ), // input
    .P_RX_SLIP_EN_0                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_0                 (lpll_powerdown                 ), // input
    .P_LPLL_RST_0                       (lpll_rst                       ), // input
    .P_LPLL_READY_0                     (lpll_lock                      ), // output
    .P_TX_LS_DATA_0                     (1'b0                           ), // input
    .P_TX_PIC_EN_0                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_0                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_0            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_0                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_0                       (1'b0                           ), // input
    .P_RX_DFE_RST_0                     (1'b0                           ), // input
    .P_RX_LEQ_RST_0                     (1'b0                           ), // input
    .P_RX_DFE_EN_0                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T1_EN_0                       (1'b1                           ), // input
    .P_RX_CDRX_EN_0                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_0                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_0                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_0             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_0            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_0               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_0              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_0              (lpbk_slave_gen3[0]             ), // input
    .P_RX_POLARITY_INVERT_0             (mac_phy_rxpolarity[0]          ), // input
    .P_PCS_MCB_EXT_EN_0                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_0               (p_pcs_nearend_loop[0]          ), // input
    .P_PCS_FAREND_LOOP_0                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_0              (p_pma_nearend_ploop[0]         ), // input
    .P_PMA_NEAREND_SLOOP_0              (p_pma_nearend_sloop[0]         ), // input
    .P_PMA_FAREND_PLOOP_0               (1'b0                           ), // input
    .P_TX_BEACON_EN_0                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_0                   (1'b0                           ), // input
    .P_TX_RATE_0                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_0                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_0               (rx_sigdet_status[0]            ), // output
    .P_RX_READY_0                       (cdr_align[0]                   ), // output
    .P_RX_SATA_COMINIT_0                (                               ), // output
    .P_RX_SATA_COMWAKE_0                (                               ), // output
    .P_TX_RXDET_REQ_0                   (tx_rxdet_en[0]                 ), // input
    .P_TX_RXDET_STATUS_0                (tx_rxdet_status[0]             ), // output
    .P_PCS_LSM_SYNCED_0                 (pcs_lsm_synced[0]              ), // output
    .P_PCS_RX_MCB_STATUS_0              (                               ), // output
    .P_TDATA_0                          (pcs_tdata0                     ), // input  [87:0]
    .P_PCIE_EI_H_0                      (p_pcie_ei_h[0]                 ), // input  [87:0]
    .P_PCIE_EI_L_0                      (p_pcie_ei_l[0]                 ), // input  [87:0]
    .P_RDATA_0                          (pcs_rdata0                     ), // output [87:0]
    .P_RXDVLD_0                         (phy_mac_rxdatavalid_i[0]       ), // output
    .P_RXDVLD_H_0                       (                               ), // output

    .P_RX_SDN_0                         (pad_rx_sdn[0]                  ),
    .P_RX_SDP_0                         (pad_rx_sdp[0]                  ),
    .P_TX_SDN_0                         (pad_tx_sdn[0]                  ), // output
    .P_TX_SDP_0                         (pad_tx_sdp[0]                  ), // output

    .P_LANE_POWERDOWN_1                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_1                       (pma_lane_rst[1]                ), // input
    .P_TX_PMA_RST_1                     (tx_pma_rst[1]                  ), // input
    .P_TX_LANE_POWERDOWN_1              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_1              (rx_lane_powerdown[1]           ), // input
    .P_TCLK2FABRIC_1                    (tclk2fabric[1]                 ), // output
    .P_TX_CLK_FR_CORE_1                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_1                  (pclk                           ), // input
    .P_RCLK2FABRIC_1                    (rclk2fabric[1]                 ), // output
    .P_RXSTATUS_1                       (q0_rxstatus_1                  ), // output
    .P_RX_CLK_FR_CORE_1                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_1                  (pclk                           ), // input
    .P_RX_PMA_RST_1                     (rx_pma_rst[1]                  ), // input
    .P_PCS_TX_RST_1                     (pcs_tx_rst[1]                  ), // input
    .P_PCS_RX_RST_1                     (pcs_rx_rst[1]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_1             (pcs_rx_cb_rst[1]               ), // input
    .P_TX_MARGIN_1                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_1                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_1                       (mac_phy_tx_deemp_gen3[31:16]   ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_1              (mac_phy_tx_deemp_gen2[3:2]     ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_1                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_1                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_1                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_1                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_1                  (                               ), // output
    .P_RX_EYE_RST_1                     (p_rx_eye_rst[1]                ), // input
    .P_RX_EYE_EN_1                      (p_rx_eye_en[1]                 ), // input
    .P_RX_EYE_TAP_1                     (p_rx_eye_tap[1*8+:8]           ), // input [7:0]
    .P_RX_PIC_EYE_1                     (p_rx_pic_eye[1*8+:8]           ), // input [7:0]
    .P_RX_PIC_FASTLOCK_1                (8'b0                           ), // input [7:0]
    .P_RX_PIC_FASTLOCK_STROBE_1         (1'b0                           ), // input
    .P_EM_RD_TRIGGER_1                  (p_em_rd_trigger[1]             ), // input
    .P_EM_MODE_CTRL_1                   (p_em_mode_ctrl[1*2+:2]         ), // input [1:0]
    .P_EM_ERROR_CNT_1                   (em_error_cnt_1                 ), // output
    .P_RX_SLIP_RST_1                    (1'b0                           ), // input
    .P_RX_SLIP_EN_1                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_1                 (1'b0                           ), // input
    .P_LPLL_RST_1                       (1'b0                           ), // input
    .P_LPLL_READY_1                     (                               ), // output
    .P_TX_LS_DATA_1                     (1'b0                           ), // input
    .P_TX_PIC_EN_1                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_1                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_1            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_1                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_1                       (1'b0                           ), // input
    .P_RX_DFE_RST_1                     (1'b0                           ), // input
    .P_RX_LEQ_RST_1                     (1'b0                           ), // input
    .P_RX_DFE_EN_1                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_1                   (1'b0                           ), // input
    .P_RX_T1_EN_1                       (1'b1                           ), // input
    .P_RX_CDRX_EN_1                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_1                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_1                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_1             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_1            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_1               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_1              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_1              (lpbk_slave_gen3[1]             ), // input
    .P_RX_POLARITY_INVERT_1             (mac_phy_rxpolarity[1]          ), // input
    .P_PCS_MCB_EXT_EN_1                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_1               (p_pcs_nearend_loop[1]          ), // input
    .P_PCS_FAREND_LOOP_1                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_1              (p_pma_nearend_ploop[1]         ), // input
    .P_PMA_NEAREND_SLOOP_1              (p_pma_nearend_sloop[1]         ), // input
    .P_PMA_FAREND_PLOOP_1               (1'b0                           ), // input
    .P_TX_BEACON_EN_1                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_1                   (1'b0                           ), // input
    .P_TX_RATE_1                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_1                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_1               (rx_sigdet_status[1]            ), // output
    .P_RX_READY_1                       (cdr_align[1]                   ), // output
    .P_RX_SATA_COMINIT_1                (                               ), // output
    .P_RX_SATA_COMWAKE_1                (                               ), // output
    .P_TX_RXDET_REQ_1                   (tx_rxdet_en[1]                 ), // input
    .P_TX_RXDET_STATUS_1                (tx_rxdet_status[1]             ), // output
    .P_PCS_LSM_SYNCED_1                 (pcs_lsm_synced[1]              ), // output
    .P_PCS_RX_MCB_STATUS_1              (                               ), // output
    .P_TDATA_1                          (pcs_tdata1                     ), // input  [87:0]
    .P_PCIE_EI_H_1                      (p_pcie_ei_h[1]                 ), // input  [87:0]
    .P_PCIE_EI_L_1                      (p_pcie_ei_l[1]                 ), // input  [87:0]
    .P_RDATA_1                          (pcs_rdata1                     ), // output [87:0]
    .P_RXDVLD_1                         (phy_mac_rxdatavalid_i[1]       ), // output
    .P_RXDVLD_H_1                       (                               ), // output

    .P_RX_SDN_1                         (pad_rx_sdn[1]                  ),
    .P_RX_SDP_1                         (pad_rx_sdp[1]                  ),
    .P_TX_SDN_1                         (pad_tx_sdn[1]                  ), // output
    .P_TX_SDP_1                         (pad_tx_sdp[1]                  ), // output

    .P_LANE_POWERDOWN_2                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_2                       (pma_lane_rst[2]                ), // input
    .P_TX_PMA_RST_2                     (tx_pma_rst[2]                  ), // input
    .P_TX_LANE_POWERDOWN_2              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_2              (rx_lane_powerdown[2]           ), // input
    .P_TCLK2FABRIC_2                    (tclk2fabric[2]                 ), // output
    .P_TX_CLK_FR_CORE_2                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_2                  (pclk                           ), // input
    .P_RCLK2FABRIC_2                    (rclk2fabric[2]                 ), // output
    .P_RXSTATUS_2                       (q0_rxstatus_2                  ), // output
    .P_RX_CLK_FR_CORE_2                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_2                  (pclk                           ), // input
    .P_RX_PMA_RST_2                     (rx_pma_rst[2]                  ), // input
    .P_PCS_TX_RST_2                     (pcs_tx_rst[2]                  ), // input
    .P_PCS_RX_RST_2                     (pcs_rx_rst[2]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_2             (pcs_rx_cb_rst[2]               ), // input
    .P_TX_MARGIN_2                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_2                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_2                       (mac_phy_tx_deemp_gen3[47:32]   ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_2              (mac_phy_tx_deemp_gen2[5:4]     ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_2                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_2                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_2                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_2                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_2                  (                               ), // output
    .P_RX_EYE_RST_2                     (p_rx_eye_rst[2]                ), // input  
    .P_RX_EYE_EN_2                      (p_rx_eye_en[2]                 ), // input  
    .P_RX_EYE_TAP_2                     (p_rx_eye_tap[2*8+:8]           ), // input [7:0] 
    .P_RX_PIC_EYE_2                     (p_rx_pic_eye[2*8+:8]           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_2                (8'b0                           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_2         (1'b0                           ), // input  
    .P_EM_RD_TRIGGER_2                  (p_em_rd_trigger[2]             ), // input  
    .P_EM_MODE_CTRL_2                   (p_em_mode_ctrl[2*2+:2]         ), // input [1:0] 
    .P_EM_ERROR_CNT_2                   (em_error_cnt_2                 ), // output
    .P_RX_SLIP_RST_2                    (1'b0                           ), // input
    .P_RX_SLIP_EN_2                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_2                 (1'b0                           ), // input
    .P_LPLL_RST_2                       (1'b0                           ), // input
    .P_LPLL_READY_2                     (                               ), // output
    .P_TX_LS_DATA_2                     (1'b0                           ), // input
    .P_TX_PIC_EN_2                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_2                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_2            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_2                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_2                       (1'b0                           ), // input
    .P_RX_DFE_RST_2                     (1'b0                           ), // input
    .P_RX_LEQ_RST_2                     (1'b0                           ), // input
    .P_RX_DFE_EN_2                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T1_EN_2                       (1'b1                           ), // input
    .P_RX_CDRX_EN_2                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_2                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_2                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_2             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_2            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_2               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_2              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_2              (lpbk_slave_gen3[2]             ), // input
    .P_RX_POLARITY_INVERT_2             (mac_phy_rxpolarity[2]          ), // input
    .P_PCS_MCB_EXT_EN_2                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_2               (p_pcs_nearend_loop[2]          ), // input
    .P_PCS_FAREND_LOOP_2                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_2              (p_pma_nearend_ploop[2]         ), // input
    .P_PMA_NEAREND_SLOOP_2              (p_pma_nearend_sloop[2]         ), // input
    .P_PMA_FAREND_PLOOP_2               (1'b0                           ), // input
    .P_TX_BEACON_EN_2                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_2                   (1'b0                           ), // input
    .P_TX_RATE_2                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_2                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_2               (rx_sigdet_status[2]            ), // output
    .P_RX_READY_2                       (cdr_align[2]                   ), // output
    .P_RX_SATA_COMINIT_2                (                               ), // output
    .P_RX_SATA_COMWAKE_2                (                               ), // output
    .P_TX_RXDET_REQ_2                   (tx_rxdet_en[2]                 ), // input
    .P_TX_RXDET_STATUS_2                (tx_rxdet_status[2]             ), // output
    .P_PCS_LSM_SYNCED_2                 (pcs_lsm_synced[2]              ), // output
    .P_PCS_RX_MCB_STATUS_2              (                               ), // output
    .P_TDATA_2                          (pcs_tdata2                     ), // input  [87:0]
    .P_PCIE_EI_H_2                      (p_pcie_ei_h[2]                 ), // input  [87:0]
    .P_PCIE_EI_L_2                      (p_pcie_ei_l[2]                 ), // input  [87:0]
    .P_RDATA_2                          (pcs_rdata2                     ), // output [87:0]
    .P_RXDVLD_2                         (phy_mac_rxdatavalid_i[2]       ), // output
    .P_RXDVLD_H_2                       (                               ), // output

    .P_RX_SDN_2                         (pad_rx_sdn[2]                  ),
    .P_RX_SDP_2                         (pad_rx_sdp[2]                  ),
    .P_TX_SDN_2                         (pad_tx_sdn[2]                  ), // output
    .P_TX_SDP_2                         (pad_tx_sdp[2]                  ), // output

    .P_LANE_POWERDOWN_3                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_3                       (pma_lane_rst[3]                ), // input
    .P_TX_PMA_RST_3                     (tx_pma_rst[3]                  ), // input
    .P_TX_LANE_POWERDOWN_3              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_3              (rx_lane_powerdown[3]           ), // input
    .P_TCLK2FABRIC_3                    (tclk2fabric[3]                 ), // output
    .P_TX_CLK_FR_CORE_3                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_3                  (pclk                           ), // input
    .P_RCLK2FABRIC_3                    (rclk2fabric[3]                 ), // output
    .P_RXSTATUS_3                       (q0_rxstatus_3                  ), // output
    .P_RX_CLK_FR_CORE_3                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_3                  (pclk                           ), // input
    .P_RX_PMA_RST_3                     (rx_pma_rst[3]                  ), // input
    .P_PCS_TX_RST_3                     (pcs_tx_rst[3]                  ), // input
    .P_PCS_RX_RST_3                     (pcs_rx_rst[3]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_3             (pcs_rx_cb_rst[3]               ), // input
    .P_TX_MARGIN_3                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_3                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_3                       (mac_phy_tx_deemp_gen3[63:48]   ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_3              (mac_phy_tx_deemp_gen2[7:6]     ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_3                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_3                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_3                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_3                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_3                  (                               ), // output
    .P_RX_EYE_RST_3                     (p_rx_eye_rst[3]                ), // input  
    .P_RX_EYE_EN_3                      (p_rx_eye_en[3]                 ), // input  
    .P_RX_EYE_TAP_3                     (p_rx_eye_tap[3*8+:8]           ), // input [7:0] 
    .P_RX_PIC_EYE_3                     (p_rx_pic_eye[3*8+:8]           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_3                (8'b0                           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_3         (1'b0                           ), // input  
    .P_EM_RD_TRIGGER_3                  (p_em_rd_trigger[3]             ), // input  
    .P_EM_MODE_CTRL_3                   (p_em_mode_ctrl[3*2+:2]         ), // input [1:0] 
    .P_EM_ERROR_CNT_3                   (em_error_cnt_3                 ), // output
    .P_RX_SLIP_RST_3                    (1'b0                           ), // input
    .P_RX_SLIP_EN_3                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_3                 (1'b0                           ), // input
    .P_LPLL_RST_3                       (1'b0                           ), // input
    .P_LPLL_READY_3                     (                               ), // output
    .P_TX_LS_DATA_3                     (1'b0                           ), // input
    .P_TX_PIC_EN_3                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_3                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_3            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_3                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_3                       (1'b0                           ), // input
    .P_RX_DFE_RST_3                     (1'b0                           ), // input
    .P_RX_LEQ_RST_3                     (1'b0                           ), // input
    .P_RX_DFE_EN_3                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T1_EN_3                       (1'b1                           ), // input
    .P_RX_CDRX_EN_3                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_3                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_3                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_3             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_3            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_3               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_3              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_3              (lpbk_slave_gen3[3]             ), // input
    .P_RX_POLARITY_INVERT_3             (mac_phy_rxpolarity[3]          ), // input
    .P_PCS_MCB_EXT_EN_3                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_3               (p_pcs_nearend_loop[3]          ), // input
    .P_PCS_FAREND_LOOP_3                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_3              (p_pma_nearend_ploop[3]         ), // input
    .P_PMA_NEAREND_SLOOP_3              (p_pma_nearend_sloop[3]         ), // input
    .P_PMA_FAREND_PLOOP_3               (1'b0                           ), // input
    .P_TX_BEACON_EN_3                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_3                   (1'b0                           ), // input
    .P_TX_RATE_3                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_3                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_3               (rx_sigdet_status[3]            ), // output
    .P_RX_READY_3                       (cdr_align[3]                   ), // output
    .P_RX_SATA_COMINIT_3                (                               ), // output
    .P_RX_SATA_COMWAKE_3                (                               ), // output
    .P_TX_RXDET_REQ_3                   (tx_rxdet_en[3]                 ), // input
    .P_TX_RXDET_STATUS_3                (tx_rxdet_status[3]             ), // output
    .P_PCS_LSM_SYNCED_3                 (pcs_lsm_synced[3]              ), // output
    .P_PCS_RX_MCB_STATUS_3              (                               ), // output
    .P_TDATA_3                          (pcs_tdata3                     ), // input  [87:0]
    .P_PCIE_EI_H_3                      (p_pcie_ei_h[3]                 ), // input  [87:0]
    .P_PCIE_EI_L_3                      (p_pcie_ei_l[3]                 ), // input  [87:0]
    .P_RDATA_3                          (pcs_rdata3                     ), // output [87:0]
    .P_RXDVLD_3                         (phy_mac_rxdatavalid_i[3]       ), // output
    .P_RXDVLD_H_3                       (                               ), // output

    .P_RX_SDN_3                         (pad_rx_sdn[3]                  ),
    .P_RX_SDP_3                         (pad_rx_sdp[3]                  ),
    .P_TX_SDN_3                         (pad_tx_sdn[3]                  ), // output
    .P_TX_SDP_3                         (pad_tx_sdp[3]                  ) // output
);

ipm2t_pcie_hssthp_wrapper_v1_5b_v1_6 #(
    //--------Global Parameter--------//

    .HPLL_EN                           (HSST_CAS_EN                     ),

    .CHANNEL0_EN                       (HSST_CAS_EN                     ),//TRUE, FALSE; for Channel0 enable

    .CHANNEL1_EN                       (HSST_CAS_EN                     ),//TRUE, FALSE; for Channel1 enable

    .CHANNEL2_EN                       (HSST_CAS_EN                     ),//TRUE, FALSE; for Channel2 enable

    .CHANNEL3_EN                       (HSST_CAS_EN                     ),//TRUE, FALSE; for Channel3 enable

    .CH0_MULT_LANE_MODE                (4                               ),//Lane0 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH1_MULT_LANE_MODE                (4                               ),//Lane1 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH2_MULT_LANE_MODE                (4                               ),//Lane2 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .CH3_MULT_LANE_MODE                (4                               ),//Lane3 --> 1: Singel Lane 2:Two Lane 4:Four Lane

    .HSST_LANE_NUM                     (LANE_NUM                        ),
    
    .REFCLK_PAD0_EN                    (HSST_CAS_EN                     ),//TRUE, FALSE; for REFCLK_PAD0 enable

    .REFCLK_PAD1_EN                    ("FALSE"                         ),//TRUE, FALSE; for REFCLK_PAD1 enable

    .PMA_REG_HPLL_REFCLK_SEL           ("REFERENCE_CLOCK_0"             ),//HPLL  REFCLK Selection

    .PMA_REG_LANE0_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL0 REFCLK Selection

    .PMA_REG_LANE1_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL1 REFCLK Selection

    .PMA_REG_LANE2_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL2 REFCLK Selection

    .PMA_REG_LANE3_PLL_REFCLK_SEL      ("REFERENCE_CLOCK_0"             ),//LPLL3 REFCLK Selection

    .HSST_CAS_EN                       (HSST_CAS_EN                     ),

    .CALIB_EN                          (HSST_CAS_EN                     )

) U1_T_HSSTHP_TOP (

    //APB
    .p_cfg_clk                          (p_cfg_clk                      ), // input
    .p_cfg_rst                          (~p_cfg_rst_n                   ), // input
    .p_cfg_psel                         (p_cfg_t_psel                   ), // input
    .p_cfg_enable                       (p_cfg_enable                   ), // input
    .p_cfg_write                        (p_cfg_write                    ), // input
    .p_cfg_addr                         ({1'b0,p_cfg_addr[14:0]}        ), // input  [15:0]
    .p_cfg_wdata                        (p_cfg_wdata                    ), // input  [7:0]
    .p_cfg_rdata                        (p_cfg_t_rdata                  ), // output [7:0]
    .p_cfg_int                          (p_cfg_t_int                    ), // output
    .p_cfg_ready                        (p_cfg_t_ready                  ), // output
    .p_fabric_refclk                    (1'b0                           ), // input
    .p_calib_done                       (p_calib_done[1]                ),
    //HPLL
    .P_COM_POWERDOWN                    (1'b0                           ), // input
    .P_HPLL_POWERDOWN                   (pll_powerdown                  ), // input
    .P_HPLL_RST                         (pll_rst                        ), // input
    .P_TX_SYNC                          (tx_sync_refsync_cas            ), // input
    .P_TX_RATE_CHANGE_ON_0              (tx_rate_change_on              ), // input
    .P_TX_RATE_CHANGE_ON_1              (tx_rate_change_on              ), // input to be done
    .P_HPLL_DIV_SYNC                    (hpll_div_sync                  ), // input
    .P_REFCLK_DIV_SYNC                  (refclk_div_sync                ), // input
    .P_HPLL_VCO_CALIB_EN                (1'b1                           ), // input
    .P_HPLL_DIV_CHANGE                  (tx_enc_type                    ), // input
    //----------PMA cascade port----------//
    .TX_SYNC_REFSYNC_O                  (                               ), //output
    .REFCLK_SYNC_REFSYNC_O              (                               ), //output
    .DIV_SYNC_REFSYNC_O                 (                               ), //output
    .ANA_TX_SYNC_I                      (tx_sync_refsync_cas            ), //input
    .ANA_HPLL_REFCLK_SYNC_I             (refclk_sync_refsync_cas        ), //input
    .ANA_HPLL_DIV_SYNC_I                (div_sync_refsync_cas           ), //input
    //----------PMA cascade port end----------//
    .P_REFCK2CORE_0                     (                               ), // output
    .P_REFCK2CORE_1                     (                               ), // output
    .P_HPLL_READY                       (pll_lock[1]                    ), // output

    .PAD_REFCLKN_0                      (refclk_n                       ), // input
    .PAD_REFCLKP_0                      (refclk_p                       ), // input

    .PAD_REFCLKN_1                      (1'b0                           ), // input
    .PAD_REFCLKP_1                      (1'b0                           ), // input

    .P_LANE_POWERDOWN_0                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_0                       (pma_lane_rst[4]                ), // input
    .P_TX_PMA_RST_0                     (tx_pma_rst[4]                  ), // input
    .P_TX_LANE_POWERDOWN_0              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_0              (rx_lane_powerdown[4]           ), // input
    .P_TCLK2FABRIC_0                    (tclk2fabric[4]                 ), // output
    .P_TX_CLK_FR_CORE_0                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_0                  (pclk                           ), // input
    .P_RCLK2FABRIC_0                    (rclk2fabric[4]                 ), // output
    .P_RXSTATUS_0                       (q1_rxstatus_4                  ), // output
    .P_RX_CLK_FR_CORE_0                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_0                  (pclk                           ), // input
    .P_RX_PMA_RST_0                     (rx_pma_rst[4]                  ), // input
    .P_PCS_TX_RST_0                     (pcs_tx_rst[4]                  ), // input
    .P_PCS_RX_RST_0                     (pcs_rx_rst[4]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_0             (pcs_rx_cb_rst[4]               ), // input
    .P_TX_MARGIN_0                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_0                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_0                       (mac_phy_tx_deemp_gen3[15+64:64]), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_0              (mac_phy_tx_deemp_gen2[9:8]     ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_0                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_0                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_0                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_0                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_0                  (                               ), // output
    .P_RX_EYE_RST_0                     (p_rx_eye_rst[4]                ), // input  
    .P_RX_EYE_EN_0                      (p_rx_eye_en[4]                 ), // input  
    .P_RX_EYE_TAP_0                     (p_rx_eye_tap[4*8+:8]           ), // input [7:0] 
    .P_RX_PIC_EYE_0                     (p_rx_pic_eye[4*8+:8]           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_0                (8'b0                           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_0         (1'b0                           ), // input  
    .P_EM_RD_TRIGGER_0                  (p_em_rd_trigger[4]             ), // input  
    .P_EM_MODE_CTRL_0                   (p_em_mode_ctrl[4*2+:2]         ), // input [1:0] 
    .P_EM_ERROR_CNT_0                   (em_error_cnt_4                 ), // output
    .P_RX_SLIP_RST_0                    (1'b0                           ), // input
    .P_RX_SLIP_EN_0                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_0                 (1'b0                           ), // input
    .P_LPLL_RST_0                       (1'b0                           ), // input
    .P_LPLL_READY_0                     (                               ), // output
    .P_TX_LS_DATA_0                     (1'b0                           ), // input
    .P_TX_PIC_EN_0                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_0                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_0            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_0                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_0                       (1'b0                           ), // input
    .P_RX_DFE_RST_0                     (1'b0                           ), // input
    .P_RX_LEQ_RST_0                     (1'b0                           ), // input
    .P_RX_DFE_EN_0                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_0                   (1'b0                           ), // input
    .P_RX_T1_EN_0                       (1'b1                           ), // input
    .P_RX_CDRX_EN_0                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_0                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_0                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_0             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_0            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_0               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_0              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_0              (lpbk_slave_gen3[4]             ), // input
    .P_RX_POLARITY_INVERT_0             (mac_phy_rxpolarity[4]          ), // input
    .P_PCS_MCB_EXT_EN_0                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_0               (p_pcs_nearend_loop[4]          ), // input
    .P_PCS_FAREND_LOOP_0                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_0              (p_pma_nearend_ploop[4]         ), // input
    .P_PMA_NEAREND_SLOOP_0              (p_pma_nearend_sloop[4]         ), // input
    .P_PMA_FAREND_PLOOP_0               (1'b0                           ), // input
    .P_TX_BEACON_EN_0                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_0                   (1'b0                           ), // input
    .P_TX_RATE_0                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_0                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_0               (rx_sigdet_status[4]            ), // output
    .P_RX_READY_0                       (cdr_align[4]                   ), // output
    .P_RX_SATA_COMINIT_0                (                               ), // output
    .P_RX_SATA_COMWAKE_0                (                               ), // output
    .P_TX_RXDET_REQ_0                   (tx_rxdet_en[4]                 ), // input
    .P_TX_RXDET_STATUS_0                (tx_rxdet_status[4]             ), // output
    .P_PCS_LSM_SYNCED_0                 (pcs_lsm_synced[4]              ), // output
    .P_PCS_RX_MCB_STATUS_0              (                               ), // output
    .P_TDATA_0                          (pcs_tdata4                     ), // input  [87:0]
    .P_PCIE_EI_H_0                      (p_pcie_ei_h[4]                 ), // input  [87:0]
    .P_PCIE_EI_L_0                      (p_pcie_ei_l[4]                 ), // input  [87:0]
    .P_RDATA_0                          (pcs_rdata4                     ), // output [87:0]
    .P_RXDVLD_0                         (phy_mac_rxdatavalid_i[4]       ), // output
    .P_RXDVLD_H_0                       (                               ), // output

    .P_RX_SDN_0                         (pad_rx_sdn[4]                  ),
    .P_RX_SDP_0                         (pad_rx_sdp[4]                  ),
    .P_TX_SDN_0                         (pad_tx_sdn[4]                  ), // output
    .P_TX_SDP_0                         (pad_tx_sdp[4]                  ), // output

    .P_LANE_POWERDOWN_1                 (pma_lane_powerdown              ), // input
    .P_LANE_RST_1                       (pma_lane_rst[5]                 ), // input
    .P_TX_PMA_RST_1                     (tx_pma_rst[5]                   ), // input
    .P_TX_LANE_POWERDOWN_1              (tx_lane_powerdown               ), // input
    .P_RX_LANE_POWERDOWN_1              (rx_lane_powerdown[5]            ), // input
    .P_TCLK2FABRIC_1                    (tclk2fabric[5]                  ), // output
    .P_TX_CLK_FR_CORE_1                 (pclk_div2                       ), // input
    .P_TCLK2_FR_CORE_1                  (pclk                            ), // input
    .P_RCLK2FABRIC_1                    (rclk2fabric[5]                  ), // output
    .P_RXSTATUS_1                       (q1_rxstatus_5                   ), // output
    .P_RX_CLK_FR_CORE_1                 (pclk_div2                       ), // input
    .P_RCLK2_FR_CORE_1                  (pclk                            ), // input
    .P_RX_PMA_RST_1                     (rx_pma_rst[5]                   ), // input
    .P_PCS_TX_RST_1                     (pcs_tx_rst[5]                   ), // input
    .P_PCS_RX_RST_1                     (pcs_rx_rst[5]                   ), // input
    .P_EXT_BRIDGE_PCS_RST_1             (pcs_rx_cb_rst[5]                ), // input
    .P_TX_MARGIN_1                      (mac_phy_txmargin                ), // input  [2:0]
    .P_TX_SWING_1                       (mac_phy_txswing                 ), // input
    .P_TX_DEEMP_1                       (mac_phy_tx_deemp_gen3[31+64:16+64] ), // input  [15:0] //TBD
    .P_TX_DEEMP_POST_SEL_1              (mac_phy_tx_deemp_gen2[11:10]    ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_1                 (mac_phy_blockaligncontrol       ), // input
    .P_TX_ENC_TYPE_1                    (tx_enc_type                     ), // input
    .P_RX_DEC_TYPE_1                    (rx_dec_type                     ), // input
    .P_PCS_PRBS_EN_1                    (1'b0                            ), // input
    .P_RX_PRBS_ERROR_1                  (                                ), // output
    .P_RX_EYE_RST_1                     (p_rx_eye_rst[5]                 ), // input  
    .P_RX_EYE_EN_1                      (p_rx_eye_en[5]                  ), // input  
    .P_RX_EYE_TAP_1                     (p_rx_eye_tap[5*8+:8]            ), // input [7:0] 
    .P_RX_PIC_EYE_1                     (p_rx_pic_eye[5*8+:8]            ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_1                (8'b0                            ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_1         (1'b0                            ), // input  
    .P_EM_RD_TRIGGER_1                  (p_em_rd_trigger[5]              ), // input  
    .P_EM_MODE_CTRL_1                   (p_em_mode_ctrl[5*2+:2]          ), // input [1:0] 
    .P_EM_ERROR_CNT_1                   (em_error_cnt_5                  ), // output
    .P_RX_SLIP_RST_1                    (1'b0                            ), // input
    .P_RX_SLIP_EN_1                     (1'b0                            ), // input
    .P_LPLL_POWERDOWN_1                 (1'b0                            ), // input
    .P_LPLL_RST_1                       (1'b0                            ), // input
    .P_LPLL_READY_1                     (                                ), // output
    .P_TX_LS_DATA_1                     (1'b0                            ), // input
    .P_TX_PIC_EN_1                      (1'b0                            ), // input
    .P_TX_BUSWIDTH_1                    (pma_tx_buswidth                 ), // input
    .P_TX_FREERUN_BUSWIDTH_1            (pma_tx_freerun_buswidth         ), // input
    .P_RX_BUSWIDTH_1                    (pma_rx_buswidth                 ), // input
    .P_RX_HIGHZ_1                       (1'b0                            ), // input
    .P_RX_DFE_RST_1                     (1'b0                            ), // input
    .P_RX_LEQ_RST_1                     (1'b0                            ), // input
    .P_RX_DFE_EN_1                      (1'b0                            ), // input
    .P_RX_T1_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T2_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T3_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T4_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T5_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T6_DFE_EN_1                   (1'b0                            ), // input
    .P_RX_T1_EN_1                       (1'b1                            ), // input
    .P_RX_CDRX_EN_1                     (1'b1                            ), // input
    .P_RX_SLIDING_EN_1                  (1'b0                            ), // input
    .P_RX_SLIDING_RST_1                 (1'b0                            ), // input
    .P_RX_SLICER_DCCAL_EN_1             (1'b1                            ), // input
    .P_RX_SLICER_DCCAL_RST_1            (1'b0                            ), // input
    .P_RX_CTLE_DCCAL_EN_1               (1'b0                            ), // input
    .P_RX_CTLE_DCCAL_RST_1              (1'b0                            ), // input
    .P_PCS_WORD_ALIGN_EN_1              (lpbk_slave_gen3[5]              ), // input
    .P_RX_POLARITY_INVERT_1             (mac_phy_rxpolarity[5]           ), // input
    .P_PCS_MCB_EXT_EN_1                 (1'b0                            ), // input
    .P_PCS_NEAREND_LOOP_1               (p_pcs_nearend_loop[5]           ), // input
    .P_PCS_FAREND_LOOP_1                (1'b0                            ), // input
    .P_PMA_NEAREND_PLOOP_1              (p_pma_nearend_ploop[5]          ), // input
    .P_PMA_NEAREND_SLOOP_1              (p_pma_nearend_sloop[5]          ), // input
    .P_PMA_FAREND_PLOOP_1               (1'b0                            ), // input
    .P_TX_BEACON_EN_1                   (1'b0                            ), // input
    .P_PCS_BIT_SLIP_1                   (1'b0                            ), // input
    .P_TX_RATE_1                        (tx_rate                         ), // input  [1:0]
    .P_RX_RATE_1                        (rx_rate                         ), // input  [1:0]
    .P_RX_SIGDET_STATUS_1               (rx_sigdet_status[5]             ), // output
    .P_RX_READY_1                       (cdr_align[5]                    ), // output
    .P_RX_SATA_COMINIT_1                (                                ), // output
    .P_RX_SATA_COMWAKE_1                (                                ), // output
    .P_TX_RXDET_REQ_1                   (tx_rxdet_en[5]                  ), // input
    .P_TX_RXDET_STATUS_1                (tx_rxdet_status[5]              ), // output
    .P_PCS_LSM_SYNCED_1                 (pcs_lsm_synced[5]               ), // output
    .P_PCS_RX_MCB_STATUS_1              (                                ), // output
    .P_TDATA_1                          (pcs_tdata5                      ), // input  [87:0]
    .P_PCIE_EI_H_1                      (p_pcie_ei_h[5]                  ), // input  [87:0]
    .P_PCIE_EI_L_1                      (p_pcie_ei_l[5]                  ), // input  [87:0]
    .P_RDATA_1                          (pcs_rdata5                      ), // output [87:0]
    .P_RXDVLD_1                         (phy_mac_rxdatavalid_i[5]        ), // output
    .P_RXDVLD_H_1                       (                                ), // output

    .P_RX_SDN_1                         (pad_rx_sdn[5]                   ),
    .P_RX_SDP_1                         (pad_rx_sdp[5]                   ),
    .P_TX_SDN_1                         (pad_tx_sdn[5]                   ), // output
    .P_TX_SDP_1                         (pad_tx_sdp[5]                   ), // output

    .P_LANE_POWERDOWN_2                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_2                       (pma_lane_rst[6]                ), // input
    .P_TX_PMA_RST_2                     (tx_pma_rst[6]                  ), // input
    .P_TX_LANE_POWERDOWN_2              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_2              (rx_lane_powerdown[6]           ), // input
    .P_TCLK2FABRIC_2                    (tclk2fabric[6]                 ), // output
    .P_TX_CLK_FR_CORE_2                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_2                  (pclk                           ), // input
    .P_RCLK2FABRIC_2                    (rclk2fabric[6]                 ), // output
    .P_RXSTATUS_2                       (q1_rxstatus_6                  ), // output
    .P_RX_CLK_FR_CORE_2                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_2                  (pclk                           ), // input
    .P_RX_PMA_RST_2                     (rx_pma_rst[6]                  ), // input
    .P_PCS_TX_RST_2                     (pcs_tx_rst[6]                  ), // input
    .P_PCS_RX_RST_2                     (pcs_rx_rst[6]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_2             (pcs_rx_cb_rst[6]               ), // input
    .P_TX_MARGIN_2                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_2                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_2                       (mac_phy_tx_deemp_gen3[47+64:32+64]   ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_2              (mac_phy_tx_deemp_gen2[13:12]   ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_2                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_2                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_2                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_2                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_2                  (                               ), // output
    .P_RX_EYE_RST_2                     (p_rx_eye_rst[6]                ), // input  
    .P_RX_EYE_EN_2                      (p_rx_eye_en[6]                 ), // input  
    .P_RX_EYE_TAP_2                     (p_rx_eye_tap[6*8+:8]           ), // input [7:0] 
    .P_RX_PIC_EYE_2                     (p_rx_pic_eye[6*8+:8]           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_2                (8'b0                           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_2         (1'b0                           ), // input  
    .P_EM_RD_TRIGGER_2                  (p_em_rd_trigger[6]             ), // input  
    .P_EM_MODE_CTRL_2                   (p_em_mode_ctrl[6*2+:2]         ), // input [1:0] 
    .P_EM_ERROR_CNT_2                   (em_error_cnt_6                 ), // output
    .P_RX_SLIP_RST_2                    (1'b0                           ), // input
    .P_RX_SLIP_EN_2                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_2                 (1'b0                           ), // input
    .P_LPLL_RST_2                       (1'b0                           ), // input
    .P_LPLL_READY_2                     (                               ), // output
    .P_TX_LS_DATA_2                     (1'b0                           ), // input
    .P_TX_PIC_EN_2                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_2                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_2            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_2                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_2                       (1'b0                           ), // input
    .P_RX_DFE_RST_2                     (1'b0                           ), // input
    .P_RX_LEQ_RST_2                     (1'b0                           ), // input
    .P_RX_DFE_EN_2                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_2                   (1'b0                           ), // input
    .P_RX_T1_EN_2                       (1'b1                           ), // input
    .P_RX_CDRX_EN_2                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_2                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_2                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_2             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_2            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_2               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_2              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_2              (lpbk_slave_gen3[6]             ), // input
    .P_RX_POLARITY_INVERT_2             (mac_phy_rxpolarity[6]          ), // input
    .P_PCS_MCB_EXT_EN_2                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_2               (p_pcs_nearend_loop[6]          ), // input
    .P_PCS_FAREND_LOOP_2                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_2              (p_pma_nearend_ploop[6]         ), // input
    .P_PMA_NEAREND_SLOOP_2              (p_pma_nearend_sloop[6]         ), // input
    .P_PMA_FAREND_PLOOP_2               (1'b0                           ), // input
    .P_TX_BEACON_EN_2                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_2                   (1'b0                           ), // input
    .P_TX_RATE_2                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_2                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_2               (rx_sigdet_status[6]            ), // output
    .P_RX_READY_2                       (cdr_align[6]                   ), // output
    .P_RX_SATA_COMINIT_2                (                               ), // output
    .P_RX_SATA_COMWAKE_2                (                               ), // output
    .P_TX_RXDET_REQ_2                   (tx_rxdet_en[6]                 ), // input
    .P_TX_RXDET_STATUS_2                (tx_rxdet_status[6]             ), // output
    .P_PCS_LSM_SYNCED_2                 (pcs_lsm_synced[6]              ), // output
    .P_PCS_RX_MCB_STATUS_2              (                               ), // output
    .P_TDATA_2                          (pcs_tdata6                     ), // input  [87:0]
    .P_PCIE_EI_H_2                      (p_pcie_ei_h[6]                 ), // input  [87:0]
    .P_PCIE_EI_L_2                      (p_pcie_ei_l[6]                 ), // input  [87:0]
    .P_RDATA_2                          (pcs_rdata6                     ), // output [87:0]
    .P_RXDVLD_2                         (phy_mac_rxdatavalid_i[6]       ), // output
    .P_RXDVLD_H_2                       (                               ), // output

    .P_RX_SDN_2                         (pad_rx_sdn[6]                  ),
    .P_RX_SDP_2                         (pad_rx_sdp[6]                  ),
    .P_TX_SDN_2                         (pad_tx_sdn[6]                  ), // output
    .P_TX_SDP_2                         (pad_tx_sdp[6]                  ), // output

    .P_LANE_POWERDOWN_3                 (pma_lane_powerdown             ), // input
    .P_LANE_RST_3                       (pma_lane_rst[7]                ), // input
    .P_TX_PMA_RST_3                     (tx_pma_rst[7]                  ), // input
    .P_TX_LANE_POWERDOWN_3              (tx_lane_powerdown              ), // input
    .P_RX_LANE_POWERDOWN_3              (rx_lane_powerdown[7]           ), // input
    .P_TCLK2FABRIC_3                    (tclk2fabric[7]                 ), // output
    .P_TX_CLK_FR_CORE_3                 (pclk_div2                      ), // input
    .P_TCLK2_FR_CORE_3                  (pclk                           ), // input
    .P_RCLK2FABRIC_3                    (rclk2fabric[7]                 ), // output
    .P_RXSTATUS_3                       (q1_rxstatus_7                  ), // output
    .P_RX_CLK_FR_CORE_3                 (pclk_div2                      ), // input
    .P_RCLK2_FR_CORE_3                  (pclk                           ), // input
    .P_RX_PMA_RST_3                     (rx_pma_rst[7]                  ), // input
    .P_PCS_TX_RST_3                     (pcs_tx_rst[7]                  ), // input
    .P_PCS_RX_RST_3                     (pcs_rx_rst[7]                  ), // input
    .P_EXT_BRIDGE_PCS_RST_3             (pcs_rx_cb_rst[7]               ), // input
    .P_TX_MARGIN_3                      (mac_phy_txmargin               ), // input  [2:0]
    .P_TX_SWING_3                       (mac_phy_txswing                ), // input
    .P_TX_DEEMP_3                       (mac_phy_tx_deemp_gen3[63+64:48+64] ), // input  [15:0]
    .P_TX_DEEMP_POST_SEL_3              (mac_phy_tx_deemp_gen2[15:14]   ), // input  [1:0]
    .P_BLK_ALIGN_CTRL_3                 (mac_phy_blockaligncontrol      ), // input
    .P_TX_ENC_TYPE_3                    (tx_enc_type                    ), // input
    .P_RX_DEC_TYPE_3                    (rx_dec_type                    ), // input
    .P_PCS_PRBS_EN_3                    (1'b0                           ), // input
    .P_RX_PRBS_ERROR_3                  (                               ), // output
    .P_RX_EYE_RST_3                     (p_rx_eye_rst[7]                ), // input  
    .P_RX_EYE_EN_3                      (p_rx_eye_en[7]                 ), // input  
    .P_RX_EYE_TAP_3                     (p_rx_eye_tap[7*8+:8]           ), // input [7:0] 
    .P_RX_PIC_EYE_3                     (p_rx_pic_eye[7*8+:8]           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_3                (8'b0                           ), // input [7:0] 
    .P_RX_PIC_FASTLOCK_STROBE_3         (1'b0                           ), // input  
    .P_EM_RD_TRIGGER_3                  (p_em_rd_trigger[7]             ), // input  
    .P_EM_MODE_CTRL_3                   (p_em_mode_ctrl[7*2+:2]         ), // input [1:0] 
    .P_EM_ERROR_CNT_3                   (em_error_cnt_7                 ), // output
    .P_RX_SLIP_RST_3                    (1'b0                           ), // input
    .P_RX_SLIP_EN_3                     (1'b0                           ), // input
    .P_LPLL_POWERDOWN_3                 (1'b0                           ), // input
    .P_LPLL_RST_3                       (1'b0                           ), // input
    .P_LPLL_READY_3                     (                               ), // output
    .P_TX_LS_DATA_3                     (1'b0                           ), // input
    .P_TX_PIC_EN_3                      (1'b0                           ), // input
    .P_TX_BUSWIDTH_3                    (pma_tx_buswidth                ), // input
    .P_TX_FREERUN_BUSWIDTH_3            (pma_tx_freerun_buswidth        ), // input
    .P_RX_BUSWIDTH_3                    (pma_rx_buswidth                ), // input
    .P_RX_HIGHZ_3                       (1'b0                           ), // input
    .P_RX_DFE_RST_3                     (1'b0                           ), // input
    .P_RX_LEQ_RST_3                     (1'b0                           ), // input
    .P_RX_DFE_EN_3                      (1'b0                           ), // input
    .P_RX_T1_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T2_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T3_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T4_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T5_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T6_DFE_EN_3                   (1'b0                           ), // input
    .P_RX_T1_EN_3                       (1'b1                           ), // input
    .P_RX_CDRX_EN_3                     (1'b1                           ), // input
    .P_RX_SLIDING_EN_3                  (1'b0                           ), // input
    .P_RX_SLIDING_RST_3                 (1'b0                           ), // input
    .P_RX_SLICER_DCCAL_EN_3             (1'b1                           ), // input
    .P_RX_SLICER_DCCAL_RST_3            (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_EN_3               (1'b0                           ), // input
    .P_RX_CTLE_DCCAL_RST_3              (1'b0                           ), // input
    .P_PCS_WORD_ALIGN_EN_3              (lpbk_slave_gen3[7]             ), // input
    .P_RX_POLARITY_INVERT_3             (mac_phy_rxpolarity[7]          ), // input
    .P_PCS_MCB_EXT_EN_3                 (1'b0                           ), // input
    .P_PCS_NEAREND_LOOP_3               (p_pcs_nearend_loop[7]          ), // input
    .P_PCS_FAREND_LOOP_3                (1'b0                           ), // input
    .P_PMA_NEAREND_PLOOP_3              (p_pma_nearend_ploop[7]         ), // input
    .P_PMA_NEAREND_SLOOP_3              (p_pma_nearend_sloop[7]         ), // input
    .P_PMA_FAREND_PLOOP_3               (1'b0                           ), // input
    .P_TX_BEACON_EN_3                   (1'b0                           ), // input
    .P_PCS_BIT_SLIP_3                   (1'b0                           ), // input
    .P_TX_RATE_3                        (tx_rate                        ), // input  [1:0]
    .P_RX_RATE_3                        (rx_rate                        ), // input  [1:0]
    .P_RX_SIGDET_STATUS_3               (rx_sigdet_status[7]            ), // output
    .P_RX_READY_3                       (cdr_align[7]                   ), // output
    .P_RX_SATA_COMINIT_3                (                               ), // output
    .P_RX_SATA_COMWAKE_3                (                               ), // output
    .P_TX_RXDET_REQ_3                   (tx_rxdet_en[7]                 ), // input
    .P_TX_RXDET_STATUS_3                (tx_rxdet_status[7]             ), // output
    .P_PCS_LSM_SYNCED_3                 (pcs_lsm_synced[7]              ), // output
    .P_PCS_RX_MCB_STATUS_3              (                               ), // output
    .P_TDATA_3                          (pcs_tdata7                     ), // input  [87:0]
    .P_PCIE_EI_H_3                      (p_pcie_ei_h[7]                 ), // input  [87:0]
    .P_PCIE_EI_L_3                      (p_pcie_ei_l[7]                 ), // input  [87:0]
    .P_RDATA_3                          (pcs_rdata7                     ), // output [87:0]
    .P_RXDVLD_3                         (phy_mac_rxdatavalid_i[7]       ), // output
    .P_RXDVLD_H_3                       (                               ), // output

    .P_RX_SDN_3                         (pad_rx_sdn[7]                  ),
    .P_RX_SDP_3                         (pad_rx_sdp[7]                  ),
    .P_TX_SDN_3                         (pad_tx_sdn[7]                  ), // output
    .P_TX_SDP_3                         (pad_tx_sdp[7]                  ) // output
);


assign tx_sync_refsync_cas     = (HSST_CAS_EN == "TRUE") ? tx_sync_refsync     : 1'b0;
assign refclk_sync_refsync_cas = (HSST_CAS_EN == "TRUE") ? refclk_sync_refsync : 1'b0;
assign div_sync_refsync_cas    = (HSST_CAS_EN == "TRUE") ? div_sync_refsync    : 1'b0;

assign pll_lock_2quad = (HSST_CAS_EN == "TRUE") ? &pll_lock :
                        (HPLL_EN == "TRUE") ? pll_lock[0] : lpll_lock;
wire [1:0] mac_phy_rate_ref;
//reg ref_rst_d1_n;
//always@(posedge refclk or negedge phy_rst_n)
//begin
//    if(~phy_rst_n)
//    begin
//     ref_rst_d1_n    <= 1'b0;
//     ref_rst_n       <= 1'b0;
//    end
//    else
//    begin
//      ref_rst_d1_n   <= 1'b1;
//      ref_rst_n      <= ref_rst_d1_n;
//    end
//end

ips2t_pcie_sync_v1_0  phy_rstn_sync (.clk(refclk), .rst_n(phy_rst_n), .sig_async(1'b1),  .sig_synced(ref_rst_n));

//ips2t_pcie_sync_v1_0  button_rstn_sync (.clk(refclk), .rst_n(button_rst_n), .sig_async(1'b1),  .sig_synced(hsst_apb_rst_n));

hsst_mutileout_byte_adapter_nonvalid #(
.DW(2)
)I_adapter_nonvalid_rate(
.sc_pcie_hard_en        (1'b1),
.user_clk               (refclk),
.user_rst_n             (ref_rst_n),
.ctrl_clk               (pclk_div2),
.ctrl_rst_n             (phy_rst_n),
.dout_core              (mac_phy_rate_i[1:0]),
.dout_usr_o             (mac_phy_rate_ref[1:0])
);
wire pma_lane_rst_i;
assign pma_lane_rst = {8{pma_lane_rst_i}};
assign lpll_powerdown = (HPLL_EN == "TRUE") ? 1'b0 : pll_powerdown;
assign lpll_rst       = (HPLL_EN == "TRUE") ? 1'b0 : pll_rst;

wire ext_rst_n;
assign ext_rst_n = power_up_rst_n;

wire [1:0] rate;
assign rate = prbs_en ? 2'd1 : mac_phy_rate_ref;

wire [7:0] loss_signal_rst;
wire [7:0] cdr_align_rst;
wire [7:0] word_align_rst;

assign loss_signal_rst = force_loss_signal ? 8'h00 : P_LX_ALOS_STA ;
assign cdr_align_rst   = force_cdr_align   ? 8'hff : P_LX_CDR_ALIGN ;
assign word_align_rst  = force_word_align  ? 8'hff : pcs_lsm_synced ;

hsst_pg2t_rst4mcrsw_v1_8 #(
    .LINK_X1_WIDTH           ( 1         ),
    .FORCE_LANE_REV          ( 0         )
) hsst_pciex4_rst (
    .clk                     (refclk          ),
    .ext_rst_n               (ext_rst_n       ),
    .txpll_soft_rst_n        ( 1'b1           ),
    .rxlane_soft_rst_n       ( 8'hff           ),
    .wtchdg_clr              ( 1'b0           ),
    .ltssm_in_recovery       ( 1'b1           ),
    .user_pll_lock           ( user_pll_lock  ),
    .prbs_en                 ( prbs_en          ),
    .rate                    ( rate             ),
    .link_num                ( 2'b0            ),
    .link_num_flag           ( 1'b0            ),
    .P_PLL_LOCK              ( pll_lock_2quad ),
    .P_LX_ALOS_STA           (loss_signal_rst ),
    .P_LX_CDR_ALIGN          (cdr_align_rst     ),
    .P_PCS_LSM_SYNCED        ( word_align_rst ),

    .P_PMA_LANE_PD           ( pma_lane_powerdown     ),
    .P_PMA_LANE_RST          ( pma_lane_rst_i           ),
    .P_HSST_RST              ( hsst_rst               ),
    .P_PLLPOWERDOWN_0        ( pll_powerdown          ),
    .P_PLL_RST_0             ( pll_rst                ),
    .P_PMA_TX_PD             ( tx_lane_powerdown      ),
    .P_RATE_CHG_TXPCLK_ON_0  ( tx_rate_change_on      ),
    .P_LANE_SYNC_0           ( tx_sync                ),
   // .P_LANE_SYNC_EN_0        ( P_LANE_SYNC_EN_0       ),
    .P_PMA_TX_RATE_0         ( tx_rate_i             ),
   // .P_PMA_TX_RATE_1         ( P_PMA_TX_RATE_1        ),
   // .P_PMA_TX_RATE_2         ( P_PMA_TX_RATE_2        ),
   // .P_PMA_TX_RATE_3         ( P_PMA_TX_RATE_3        ),
    .P_PMA_TX_RST            ( tx_pma_rst             ),
   // .P_PMA_TX_RST_1          ( P_PMA_TX_RST_1         ),
  //  .P_PMA_TX_RST_2          ( P_PMA_TX_RST_2         ),
  //  .P_PMA_TX_RST_3          ( P_PMA_TX_RST_3         ),
    .P_PCS_TX_RST           ( pcs_tx_rst             ),
 //   .P_PCS_TX_RST_1          ( P_PCS_TX_RST_1         ),
//    .P_PCS_TX_RST_2          ( P_PCS_TX_RST_2         ),
//    .P_PCS_TX_RST_3          ( P_PCS_TX_RST_3         ),
    .tx_rst_done             ( tx_rst_done            ),
    //rx
    .P_PMA_RX_PD             ( rx_lane_powerdown_ref      ),
    .P_PMA_RX_RST            ( rx_pma_rst_ref              ),
  //  .P_PMA_RX_RST_1          ( P_PMA_RX_RST_1         ),
  //  .P_PMA_RX_RST_2          ( P_PMA_RX_RST_2         ),
  //  .P_PMA_RX_RST_3          ( P_PMA_RX_RST_3         ),
    .P_PCS_RX_RST            ( pcs_rx_rst         ),
  //  .P_PCS_RX_RST_1          ( P_PCS_RX_RST_1         ),
  //  .P_PCS_RX_RST_2          ( P_PCS_RX_RST_2         ),
  //  .P_PCS_RX_RST_3          ( P_PCS_RX_RST_3         ),
    .P_LX_RX_RATE           (  rx_rate_i      ),
 //   .P_LX_RX_RATE_1          ( P_LX_RX_RATE_1         ),
 //   .P_LX_RX_RATE_2          ( P_LX_RX_RATE_2         ),
//    .P_LX_RX_RATE_3          ( P_LX_RX_RATE_3         ),
    .refclk_div_sync         (refclk_div_sync),
    .hpll_div_sync           (hpll_div_sync),
    .pma_powerdownn          (pma_powerdown),
    .rate_done               ( rate_change_done       ),
    .hsst_ch_ready           ( hsst_ch_ready          ),
    .P_RX_CDR_RST         ( rx_cdr_rst         ),
    .P_PCS_CB_RST            (pcs_rx_cb_rst),
    .mac_clk_req_n           (1'b0)
);

assign refclk2core = refclk;

//output = input * 3/2			
function [15:0] tx_deemph_pma;
    input [17:0] mac_phy_tx_deemph;
    reg [5:0] c0;//c-1
    reg [5:0] c1;//c0
    reg [5:0] c2;//c+1
    begin
        c0 = (mac_phy_tx_deemph[5:0] + (mac_phy_tx_deemph[5:0] >> 1));
        c1 = (mac_phy_tx_deemph[11:6] + (mac_phy_tx_deemph[11:6] >> 1));
        c2 = (mac_phy_tx_deemph[17:12] + (mac_phy_tx_deemph[17:12] >> 1));
        tx_deemph_pma = {c2[4:0],c1[5:0],c0[4:0]};
    end
endfunction

endmodule