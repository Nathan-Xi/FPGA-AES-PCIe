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

module hsst_pg2t_rxeqeval_gen3_v1_8
(
input pclk_div2,
input phy_rst_n,
input [2:0] em_error_cnt,
input mac_phy_rxeqeval,

output reg [1:0] em_mode_ctrl,
output reg eq_fdbk_done,
output [7:0] phy_mac_fomfeedback,
output [5:0] phy_mac_dirfeedback,

output reg [7:0] rx_pic_eye,
output reg [7:0] rx_eye_tap
);

localparam IDLE = 3'd0;
localparam EQ_FEEDBACK_PHASE_0 = 3'd1;
localparam EQ_FEEDBACK_PHASE_1 = 3'd2;
localparam EQ_FEEDBACK_PHASE_2 = 3'd3;
localparam EQ_FEEDBACK_PHASE_3 = 3'd4;
localparam EQ_FEEDBACK_DONE    = 3'd5;

reg [2:0] rxeq_eval_next_state;
reg [2:0] rxeq_eval_cur_state;
reg [3:0] eq_phase_done;
wire start_rx_fdbk_pos;
reg mac_phy_rxeqeval_r;
always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
        mac_phy_rxeqeval_r <= 1'b0;
    else
        mac_phy_rxeqeval_r <=  mac_phy_rxeqeval;
end

assign start_rx_fdbk_pos = mac_phy_rxeqeval & ~mac_phy_rxeqeval_r;

reg [16:0] timeout_cnt;
wire clear;
wire [16:0] time_300us;
wire [16:0] time_400us;
reg  timeout_400us;
//eye monotor  400us per phase
always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
        timeout_cnt[9:0] <= 10'b0;
    else if(clear)
         timeout_cnt[9:0] <= 10'b0;
    else
         timeout_cnt[9:0] <= timeout_cnt[9:0] + 10'b1;
end

always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
        timeout_cnt[16:10] <= 7'b0;
    else if(clear)
         timeout_cnt[16:10] <= 7'b0;
    else if(&timeout_cnt[9:0])
         timeout_cnt[16:10] <= timeout_cnt[16:10] + 17'b1;
end

assign clear = (rxeq_eval_next_state != rxeq_eval_cur_state);


`ifdef IPS2T_PCIE_SPEEDUP_SIM
    assign time_300us = 75;
    assign time_400us = 100;
`else
    assign time_300us = 75000;
    assign time_400us = 100000;
`endif

always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
       timeout_400us <= 1'b0;
    else
       timeout_400us <= timeout_cnt == time_400us;
end

//assign timeout_400us = (timeout_cnt == time_400us);

//eye monitor 4 phase (+HORI +VERT ; +HORI -VERT ; -HORI +VERT ; -HORI -VERT)
always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
       rxeq_eval_cur_state <= IDLE;
    else
       rxeq_eval_cur_state <= rxeq_eval_next_state;
end

always @ (*)
begin
    case(rxeq_eval_cur_state)
        IDLE:
        begin
            if(start_rx_fdbk_pos)
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_0;
            else
                rxeq_eval_next_state = IDLE;
        end
        EQ_FEEDBACK_PHASE_0:
        begin
            if(timeout_400us)
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_1;
            else
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_0;
        end
        EQ_FEEDBACK_PHASE_1:
        begin
            if(timeout_400us)
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_2;
            else
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_1;
        end
        EQ_FEEDBACK_PHASE_2:
        begin
            if(timeout_400us)
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_3;
            else
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_2;
        end
        EQ_FEEDBACK_PHASE_3:
        begin
            if(timeout_400us)
                rxeq_eval_next_state = EQ_FEEDBACK_DONE;
            else
                rxeq_eval_next_state = EQ_FEEDBACK_PHASE_3;
        end
        EQ_FEEDBACK_DONE:
        begin
          //  if(~|mac_phy_rxeqeval)
                rxeq_eval_next_state = IDLE;
          //  else
          //      rxeq_eval_next_state = EQ_FEEDBACK_DONE;
        end
        default:
           rxeq_eval_next_state = IDLE;
       endcase
end

//rx_eye_tap : each time the value goes up by 1,the voltage gose up bu 2mv.the higher bit
//is the sign bit. bit 7 = 1 means  down shift,else means up shift
//rx_pic_eye : each time the value goes up by 1,the pi gose up bu rx_rate/256
//pi.the higher bit
//is the sign bit. bit 7 = 1 means  left shift,else means right shift

always @ (*)
begin
    em_mode_ctrl = 2'b0;
    eq_phase_done = 4'b0;
    eq_fdbk_done = 1'b0;
    rx_pic_eye = 8'b0;
    rx_eye_tap = 8'b0;
    case(rxeq_eval_cur_state)
        IDLE:
            begin
                em_mode_ctrl = 2'b0;
                eq_phase_done = 4'b0;
             end
        EQ_FEEDBACK_PHASE_0:
        begin
            rx_pic_eye = 8'b0001_1110; //need update
            rx_eye_tap = 8'b0110_0001; //need update
             if(timeout_cnt == time_300us)
             begin
                eq_phase_done = 4'd1;
                em_mode_ctrl = 2'b0;
              end
           else if(timeout_cnt > time_300us)
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = 2'b0;
              end
            else
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = {1'b0,mac_phy_rxeqeval};
              end
        end
        EQ_FEEDBACK_PHASE_1:
        begin
            rx_pic_eye = 8'b0001_1110; //need update
            rx_eye_tap = 8'b1110_0001; //need update
             if(timeout_cnt == time_300us)
             begin
                eq_phase_done = 4'd2;
                em_mode_ctrl = 2'b0;
              end
            else if(timeout_cnt > time_300us)
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = 2'b0;
              end
            else
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = {1'b0,mac_phy_rxeqeval};
              end
        end
        EQ_FEEDBACK_PHASE_2:
        begin
            rx_pic_eye = 8'b1101_1110; //need update
            rx_eye_tap = 8'b0110_0001; //need update
             if(timeout_cnt == time_300us)
             begin
                eq_phase_done = 4'd4;
                em_mode_ctrl = 2'b0;
              end
            else if(timeout_cnt > time_300us)
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = 2'b0;
              end
            else
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = {1'b0,mac_phy_rxeqeval};
              end
        end
        EQ_FEEDBACK_PHASE_3:
        begin
            rx_pic_eye = 8'b1101_1110; //need update
            rx_eye_tap = 8'b1110_0001; //need update
             if(timeout_cnt == time_300us)
             begin
                eq_phase_done = 4'd8;
                em_mode_ctrl = 2'b0;
              end
            else if(timeout_cnt > time_300us)
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = 2'b0;
              end
            else
              begin
                eq_phase_done = 4'b0;
                em_mode_ctrl = {1'b0,mac_phy_rxeqeval};
              end
        end
        EQ_FEEDBACK_DONE:
        begin
            rx_pic_eye = 8'b0000_0000;
            rx_eye_tap = 8'b0000_0000;
            em_mode_ctrl = 2'b0;
            eq_phase_done = 4'b0;
            eq_fdbk_done = 1'b1;
        end
        default:
        begin
            em_mode_ctrl = 2'b0;
            eq_phase_done = 4'b0;
            eq_fdbk_done = 1'b0;
       end
       endcase
end
//****************eye monitor test done**********************
//
//
//****************capture eye monitor result ******************
wire [2:0] em_error_cnt_gray;
reg  [2:0] em_error_cnt_bin;
reg [5:0] em_error_cnt_total;
generate
genvar eq_i;
for(eq_i=0;eq_i<3;eq_i=eq_i+1)begin
ips_hsst_rst_sync_v1_0    hsst_pciex4_sync_eq_err_cnt
    (
    .clk        ( pclk_div2             ),
    .rst_n      ( phy_rst_n             ),
    .sig_async  ( em_error_cnt[eq_i]    ), //gray code
    .sig_synced ( em_error_cnt_gray[eq_i]) //gray code
    );
end
endgenerate

integer i;
 always@(*) //gray to bin
     for(i=0;i<=2;i=i+1)
     begin
         em_error_cnt_bin[i]   =    ^(em_error_cnt_gray >> i) ;
      end

//capture error cnt when eye_monitor done
always @ (posedge pclk_div2 or negedge phy_rst_n)
begin
    if(~phy_rst_n)
    begin
        em_error_cnt_total <= 6'b0;
    end
    else if(|eq_phase_done)
    begin
        em_error_cnt_total <= em_error_cnt_total + em_error_cnt_bin;
    end
    else if(~mac_phy_rxeqeval)
     begin
        em_error_cnt_total  <= 6'b0;
    end
end
//***************capture eye monitor result done ******************

assign phy_mac_fomfeedback = 255 -em_error_cnt_total;
assign phy_mac_dirfeedback = 6'b0; //need update



endmodule
