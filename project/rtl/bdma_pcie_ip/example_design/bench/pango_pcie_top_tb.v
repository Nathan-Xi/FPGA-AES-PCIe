
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
`timescale 1ns/1ps
`define  IPS2T_PCIE_SPEEDUP_SIM
`define  IPM2T_HSST_SPEEDUP_SIM
//`define  SIM_ON
module pango_pcie_top_tb;
reg                 button_rst_n;
reg                 perst_n;
//clk and rst
reg                 ref_clk_n;
wire                ref_clk_p;
//rc
wire                rc_smlh_link_up;
wire                rc_rdlh_link_up;

//ep
wire                ep_smlh_link_up;
wire                ep_rdlh_link_up;

//LED signals

//difference signals

wire    [7:0]       rc_rxn;
wire    [7:0]       rc_rxp;
wire    [7:0]       rc_txn;
wire    [7:0]       rc_txp;


initial
    begin
        // $fsdbDumpfile("ftd_local_test_tb.fsdb");
        $fsdbAutoSwitchDumpfile(500, "pango_pcie_top_tb.fsdb", 20, "pango_pcie_top_tb.log");
        //$fsdbDumpvars(0, pango_pcie_top_tb.u_pcie_rc.u_pcie_dma_pio);
        //$fsdbDumpvars(0, pango_pcie_top_tb.u_pcie_ep.u_pcie_dma_pio);
        $fsdbDumpvars(7, pango_pcie_top_tb.u_pcie_rc);
        $fsdbDumpvars(7, pango_pcie_top_tb.u_pcie_ep);
        $fsdbDumpvars(2, pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy);
        $fsdbDumpvars(2, pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy);
    end

//***************************************DUT*****************************
pango_pcie_top_sim

#(
    .APP_DEV_NUM        (0                  ),      // set device_number
    .APP_BUS_NUM        (0                  )       // set bus_number
)
u_pcie_rc (

    .button_rst_n       (button_rst_n       ),
    .perst_n            (button_rst_n       ),
    //UART interface
    .txd                (                   ),
    .rxd                (                   ),
    //clk and rst
    .ref_clk_n          (ref_clk_n          ),      //100 Mhz
    .ref_clk_p          (ref_clk_p          ),      //100 Mhz
    //diff signals
    .rxn                (rc_rxn             ),
    .rxp                (rc_rxp             ),
    .txn                (rc_txn             ),
    .txp                (rc_txp             ),
    //LED signals
    .ref_led            (                   ),
    .pclk_led           (                   ),
    .pclk_div2_led      (                   ),
    .user_led           (                   ),

    .smlh_link_up       (rc_smlh_link_up    ),
    .rdlh_link_up       (rc_rdlh_link_up    )
);

pango_pcie_top

u_pcie_ep (

    .button_rst_n       (button_rst_n       ),
    .perst_n            (button_rst_n       ),
    //UART interface
    .txd                (                   ),
    .rxd                (                   ),
    //clk and rst
    .ref_clk_n          (ref_clk_n          ),      //100 Mhz
    .ref_clk_p          (ref_clk_p          ),      //100 Mhz
    //diff signals
    .rxn                (rc_txn             ),
    .rxp                (rc_txp             ),
    .txn                (rc_rxn             ),
    .txp                (rc_rxp             ),
    //LED signals
    .ref_led            (                   ),
    .pclk_led           (                   ),
    .pclk_div2_led      (                   ),
    .user_led           (                   ),

    .smlh_link_up       (ep_smlh_link_up    ),
    .rdlh_link_up       (ep_rdlh_link_up    )
);

GTP_GRS GRS_INST    (.GRS_N(1'b1)) ;

always #5 ref_clk_n = ~ref_clk_n;

assign    ref_clk_p = ~ref_clk_n;

initial
begin
    button_rst_n    = 1'b0;
    ref_clk_n       = 1'b0;
    //APB interface
    #100
    button_rst_n    = 1'b1;
    //force apb
    force pango_pcie_top_tb.u_pcie_rc.uart_p_addr       = 32'h0;
    force pango_pcie_top_tb.u_pcie_rc.uart_p_sel        = 1'b0;
    force pango_pcie_top_tb.u_pcie_rc.uart_p_strb       = 4'h0;
    force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b0;
    force pango_pcie_top_tb.u_pcie_rc.uart_p_we         = 1'b0;
    force pango_pcie_top_tb.u_pcie_rc.uart_p_wdata      = 32'h0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_addr       = 32'h0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_sel        = 1'b0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_strb       = 4'h0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_we         = 1'b0;
    force pango_pcie_top_tb.u_pcie_ep.uart_p_wdata      = 32'h0;
    //PCIE_CTRL
        #1000
        wait(pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_pcie_hard_ctrl.app_ltssm_enable)
            $display ("ltssm enable!");
        wait(pango_pcie_top_tb.u_pcie_ep.rdlh_link_up)
            $display ("PCIe link up!");
        #10000
        wait(pango_pcie_top_tb.u_pcie_ep.smlh_ltssm_state[5:0] == 6'h11)
        if (pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.mac_phy_rate == 2'd2)
            $display ("link rate is 8.0GT/S");
        else if(pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.mac_phy_rate == 2'd1)
            $display ("link rate is 5.0GT/S");
        else
            $display ("link rate is 2.5GT/S");
        if (pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.pcs_lsm_synced == 8'hff)
            $display ("link width is x8");
        else if (pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.pcs_lsm_synced[3:0] == 4'hf)
            $display ("link width is x4");
        else if (pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.pcs_lsm_synced[1:0] == 2'h3)
            $display ("link width is x2");
        else
            $display ("link width is x1");
        #1000
        
        $display ("cfg start!");
        //for check ep bar reg
        // bar0_reg
        ep_apb_read(32'h7000_0010);
        
        //set rc bar0
        rc_apb_write(32'h7000_0004,32'h0000_0007,4'b0001);                          //set rc MSE IOE MEMEN
        //rc_apb_write(32'h7000_0010,32'h0000_0000,4'b1111);                          //set rc bar0 base addr

        rc_apb_write(32'h9000_0008,{7'd0,1'b1,14'd0,10'd0},4'b1000);                //set cfg_ctrl_en
        #100
                //  data        reg_num  des_id  req_id    tag fbe cfg_type fmt
        rc_cfg_test(32'h0000_0006,10'd1,16'h0100,16'h0000,8'd0,4'hf,1'b0,1'b1);     //cfgwr ep bus master enable
        
        #2000
            rc_apb_write(32'h9000_0008,{7'd0,1'b0,14'd0,10'd0},4'b1000);            //release cfg_ctrl_en
        
    //PIO 1 DW
            //rc_tx_mwr
            rc_mwr_tx(8'h00,32'h0000_0010);
            //rc_tx_mrd
            rc_mrd_tx(8'h00,32'h0000_0010);
            wait(pango_pcie_top_tb.u_pcie_rc.u_pcie_dma_pio.i_axis_master1_tdata[31:24]==8'h4a)
            $display ("rc_rcv cpld! PIO 1 DW test done");
        #3000
        
        $finish;
end


initial
    begin
        force pango_pcie_top_tb.u_pcie_rc.u_pcie_wrap.u_pcie_top.u_phy.U1_L_HSSTHP_TOP.HPLL_ENABLE.U_HPLL_WRAP.U_HPLL.U0_HSSTHP_COMMON.u_hssthp_common_top.u_pma_common_new.I18.I0.i_pll_fsm.fsm_counter_timeout =1'b1;
        force pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.U1_L_HSSTHP_TOP.HPLL_ENABLE.U_HPLL_WRAP.U_HPLL.U0_HSSTHP_COMMON.u_hssthp_common_top.u_pma_common_new.I18.I0.i_pll_fsm.fsm_counter_timeout =1'b1;
    
        force pango_pcie_top_tb.u_pcie_rc.u_pcie_wrap.u_pcie_top.u_phy.U1_T_HSSTHP_TOP.HPLL_ENABLE.U_HPLL_WRAP.U_HPLL.U0_HSSTHP_COMMON.u_hssthp_common_top.u_pma_common_new.I18.I0.i_pll_fsm.fsm_counter_timeout =1'b1;
        force pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.U1_T_HSSTHP_TOP.HPLL_ENABLE.U_HPLL_WRAP.U_HPLL.U0_HSSTHP_COMMON.u_hssthp_common_top.u_pma_common_new.I18.I0.i_pll_fsm.fsm_counter_timeout =1'b1;
    
    end


initial
begin
    force pango_pcie_top_tb.u_pcie_rc.u_pcie_wrap.u_pcie_top.u_phy.tx_rxdet_status[7:0] = 8'hff;
    force pango_pcie_top_tb.u_pcie_ep.u_pcie_wrap.u_pcie_top.u_phy.tx_rxdet_status[7:0] = 8'hff;
end

initial
begin
    $monitor ($time, ,"rc ltssm is %h,ep ltssm is %h", pango_pcie_top_tb.u_pcie_rc.smlh_ltssm_state,pango_pcie_top_tb.u_pcie_ep.smlh_ltssm_state);
end

//                    //data        reg_num  des_id  req_id tag  fbe cfg_type fmt
//        rc_cfg_test(32'h0755_0755,10'd2,16'h1001,16'h0011,8'd1,4'hf,1'b0,1'b1);

task    rc_cfg_test;
        input [31:0]  data;
       // input         cfg_ctrl_en;
        input [9:0]   reg_num;
        input [15:0]  des_id;
        input [15:0]  req_id;
        input [ 7:0]  tag;
        input [ 3:0]  fbe;
        input         cfg_type; //0:type0     1:type1
        input         fmt;      //0:mrd       1:mwr

        begin
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            rc_apb_write(32'h9000_0000,{16'd0,tag,2'b0,fbe,cfg_type,fmt},4'b0011);
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            rc_apb_write(32'h9000_0004,{des_id,req_id},4'b1111);
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            rc_apb_write(32'h9000_0008,{7'd0,1'd0,14'd0,reg_num},4'b0011);
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            rc_apb_write(32'h9000_000c,data,4'b1111);
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            //set ep tx end
            rc_apb_write(32'h9000_0000,32'h0100_0000,4'b1000);
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            //release ep tx end
            rc_apb_write(32'h9000_0000,32'h0000_0000,4'b1000);
        end

endtask

task    rc_apb_write;
        input [31:0]    addr;
        input [31:0]    wdata;
        input [3:0]     strb;
        begin
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_addr       = addr;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_sel        = 1'b1;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_strb       = strb;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_we         = 1'b1;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_wdata      = wdata;
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b1;
            //wait(pango_pcie_top_tb.u_pcie_rc.uart_p_rdy)
            //@(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            @(negedge pango_pcie_top_tb.u_pcie_rc.uart_p_rdy)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_addr       = 32'h0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_sel        = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_strb       = 4'h0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_we         = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_wdata      = 32'h0;
        end
endtask

task    rc_apb_read;
        input   [31:0]  addr;
        begin
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_sel        =  1'b1;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_addr       =  addr;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         =  1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_we         =  1'b0;
            @(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b1;
            //wait(pango_pcie_top_tb.u_pcie_rc.uart_p_rdy)
            //@(posedge pango_pcie_top_tb.u_pcie_rc.ref_clk)
            @(negedge pango_pcie_top_tb.u_pcie_rc.uart_p_rdy)
            #1
                force pango_pcie_top_tb.u_pcie_rc.uart_p_sel        = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_addr       = 32'h0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_rc.uart_p_we         = 1'b0;
        end
endtask

task    ep_apb_write;
        input [31:0]    addr;
        input [31:0]    wdata;
        input [3:0]     strb;
        begin
            @(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_addr       = addr;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_sel        = 1'b1;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_strb       = strb;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_we         = 1'b1;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_wdata      = wdata;
            @(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b1;
            //wait(pango_pcie_top_tb.u_pcie_ep.uart_p_rdy)
            //@(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            @(negedge pango_pcie_top_tb.u_pcie_ep.uart_p_rdy)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_addr       = 32'h0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_sel        = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_strb       = 4'h0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_we         = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_wdata      = 32'h0;
        end
endtask

task    ep_apb_read;
        input   [31:0]  addr;
        begin
            @(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_sel        =  1'b1;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_addr       =  addr;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         =  1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_we         =  1'b0;
            @(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b1;
            //wait(pango_pcie_top_tb.u_pcie_ep.uart_p_rdy)
            //@(posedge pango_pcie_top_tb.u_pcie_ep.ref_clk)
            @(negedge pango_pcie_top_tb.u_pcie_ep.uart_p_rdy)
            #1
                force pango_pcie_top_tb.u_pcie_ep.uart_p_sel        = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_addr       = 32'h0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_ce         = 1'b0;
                force pango_pcie_top_tb.u_pcie_ep.uart_p_we         = 1'b0;
        end
endtask

task    rc_mwr_tx;
        input   [7:0]   length;
        input   [31:0]  addr;
        begin
        #1000
            //type:mwr 32bit
            rc_apb_write(32'h8000_0140,32'h0100_0000,4'b1111);
            //length:32 dw
            rc_apb_write(32'h8000_0150,{24'b0,length},4'b1111);
            //addr_l:0x0000_0000
            rc_apb_write(32'h8000_0160,addr,4'b1111);
        end
endtask

task    rc_mrd_tx;
        input   [7:0]   length;
        input   [31:0]  addr;
        begin
        #1000
            //type:mrd 32bit
            rc_apb_write(32'h8000_0140,32'h0000_0000,4'b1111);
            //length:32 dw
            rc_apb_write(32'h8000_0150,{24'b0,length},4'b1111);
            //addr_l:0x0000_0000
            rc_apb_write(32'h8000_0160,addr,4'b1111);
        end
endtask

task    rc_mwr_tx_with_data;
        input   [31:0]  addr;
        input   [31:0]  data;
        begin
        #1000
            //cfg cmd_reg;
            //type:mwr 32bit with data
            rc_apb_write(32'h8000_0140,32'h0100_0100,4'b1111);
            //length:1 dw
            rc_apb_write(32'h8000_0150,32'h0000_0000,4'b1111);
            //addr_l:0xf7e1_2100
            rc_apb_write(32'h8000_0160,addr,4'b1111);
            //wr_data: cfg ep tx 32mwr 32dw
            rc_apb_write(32'h8000_0180,data,4'b1111);
        end
endtask

task    rc_cfg_ep_tx;
        input   [31:0]  cmd_reg;
        input   [31:0]  addr_l_reg;
        begin
        #5000
            //ep_cmd_reg
            rc_mwr_tx_with_data(32'hf7e1_2100,cmd_reg);
            //ep_addr_l
            rc_mwr_tx_with_data(32'hf7e1_2110,addr_l_reg);
        end
endtask

task    dma_check;
        if (pango_pcie_top_tb.u_pcie_rc.u_pcie_dma_pio.u_controller.dma_check_success == 1'b1)
            $display ("DMA test pass!");
        else
            $display ("DMA test fail!");
endtask
endmodule
