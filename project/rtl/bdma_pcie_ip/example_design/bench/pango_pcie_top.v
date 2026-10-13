
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
//
// Library:
// Filename:pango_pcie_top.v
//////////////////////////////////////////////////////////////////////////////
module pango_pcie_top

(
    input                   button_rst_n        ,
    input                   perst_n             ,
    //UART interface
    output  wire            txd                 ,
    input                   rxd                 ,
    //clk and rst
    input                   ref_clk_n           ,      //100 Mhz
    input                   ref_clk_p           ,      //100 Mhz
    //diff signals

    input           [7:0]   rxp,
    input           [7:0]   rxn,
    output  wire    [7:0]   txp,
    output  wire    [7:0]   txn,

    //clk led
    output  reg             ref_led             ,
    output  reg             pclk_led            ,
    output  reg             pclk_div2_led       ,
    output  reg             user_led            ,

    output  wire            smlh_link_up        ,
    output  wire            rdlh_link_up
    //output  wire    [5:0]   smlh_ltssm_state
);


localparam  DEVICE_TYPE = 4'b0000;  // EP-> 4'b0000; RC->4'b0100;

localparam TEST_MODE = "PIO";

//*********************************************************************
//              internal signals define
//*********************************************************************
wire                        ref_clk;
wire                        user_clk;
wire                        pclk_div2;
wire                        pclk;
wire                        user_rst_n;

wire    [5:0]               smlh_ltssm_state;

wire    [1*8-1:0]           xadm_ph_cdts;
wire    [1*12-1:0]          xadm_pd_cdts;
wire    [1*8-1:0]           xadm_nph_cdts;
wire    [1*12-1:0]          xadm_npd_cdts;
wire    [1*8-1:0]           xadm_cplh_cdts;
wire    [1*12-1:0]          xadm_cpld_cdts;

wire    [2-1:0]             cfg_bus_master_en    ;  //
wire    [2-1:0]             cfg_mem_space_en     ;  //
wire    [6-1:0]             cfg_max_payload_size ;  //
wire    [2-1:0]             cfg_rcb              ;  //
wire    [2-1:0]             cfg_dma_space_en     ;  //
wire    [6-1:0]             cfg_max_rd_req_size  ;  //
wire    [8-1:0]             cfg_pbus_num         ;  //
wire    [5-1:0]             cfg_pbus_dev_num     ;  //
wire    [2-1:0]             cfg_ext_tag_en       ;

// completion timeout interface
//AXIS master interface : master0 for remote request
wire                        axis_master0_tvalid;
wire                        axis_master0_tready;
wire    [255:0]             axis_master0_tdata;
wire    [7:0]               axis_master0_tkeep;
wire                        axis_master0_tlast;
wire    [12:0]              axis_master0_tuser;//{rom_in_range , dma_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                      //   function number  , vf number , vf active }
wire                        user_rcvd_np_ready;
wire    [5:0]               core_avl_np_cnt;
wire                        user_rcvd_p_ready;
wire    [5:0]               core_avl_p_cnt;
//AXIS master interface : master1 for remote completion
wire                        axis_master1_tvalid;
wire    [255:0]             axis_master1_tdata;
wire    [7:0]               axis_master1_tkeep;
wire    [33:0]              axis_master1_tuser;//{rom_in_range , dma_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                //   function number  , vf number , vf active spill_cpl_data }
//**********************************************************************
//cpl intf
wire                        axis_master_cpl_tready  ;
wire                        axis_master_cpl_tvalid  ;
wire    [255:0]             axis_master_cpl_tdata   ;
wire    [  7:0]             axis_master_cpl_tkeep   ;
wire    [  5:0]             axis_master_cpl_tuser   ;
wire                        axis_master_cpl_tlast   ;
wire    [ 3:0]              tlp_abort               ;
wire    [13:0]              fifo_space              ;
//axis slave 0 interface
wire                        axis_slave0_tready;
wire                        axis_slave0_tvalid;
wire    [255:0]             axis_slave0_tdata;
wire                        axis_slave0_tlast;
wire    [5:0]               axis_slave0_tuser;//{bad eot , function number  , vf number , vf active}

//axis slave 1 interface
wire                        axis_slave1_tready;
wire                        axis_slave1_tvalid;
wire    [255:0]             axis_slave1_tdata;
wire                        axis_slave1_tlast;
wire    [5:0]               axis_slave1_tuser;

//axis slave 2 interface
wire                        axis_slave2_tready;
wire                        axis_slave2_tvalid;
wire    [255:0]             axis_slave2_tdata;
wire                        axis_slave2_tlast;
wire    [5:0]               axis_slave2_tuser;

wire                        pm_xtlh_block_tlp;      //ask about the processing latency

//uart2apb 32bits (ref_clk)
wire                        uart_p_sel              ;
wire    [3:0]               uart_p_strb             ;
wire    [31:0]              uart_p_addr             ;
wire    [31:0]              uart_p_wdata            ;
wire                        uart_p_ce               ;
wire                        uart_p_we               ;
wire                        uart_p_rdy              ;
wire    [31:0]              uart_p_rdata            ;
//APB (user_clk)
wire    [3:0]               user_p_strb             ;
wire    [31:0]              user_p_addr             ;
wire    [31:0]              user_p_wdata            ;
wire                        user_p_ce               ;
wire                        user_p_we               ;

//apb mux
wire                        p_sel_pcie              ;       //0~6:Reserved 7:pcie
wire                        p_sel_cfg               ;       //8: cfg
wire                        p_sel_dma               ;       //9: dma

wire    [31:0]              p_rdata_pcie            ;       //0~6:Reserved 7:pcie
wire    [31:0]              p_rdata_cfg             ;       //8: cfg
wire    [31:0]              p_rdata_dma             ;       //9: dma

wire                        p_rdy_pcie              ;       //0~6:Reserved 7:pcie
wire                        p_rdy_cfg               ;       //8: cfg
wire                        p_rdy_dma               ;       //9: dma
wire                        dma_axis_slave0_tvalid  ;
wire    [255:0]             dma_axis_slave0_tdata   ;
wire                        dma_axis_slave0_tlast   ;
wire    [  5:0]             dma_axis_slave0_tuser   ;

wire                        dma_axis_master_cpl_tready ;
wire                        dma_axis_master_cpl_tvalid ;
wire    [255:0]             dma_axis_master_cpl_tdata  ;
wire    [  7:0]             dma_axis_master_cpl_tkeep  ;
wire    [  5:0]             dma_axis_master_cpl_tuser  ;
wire                        dma_axis_master_cpl_tlast  ;
//cfg ctrl
wire                        pcie_cfg_ctrl_en;

wire                        cfg_axis_slave_tvalid   ;
wire    [255:0]             cfg_axis_slave_tdata    ;
wire                        cfg_axis_slave_tlast    ;
wire    [  5:0]             cfg_axis_slave_tuser    ;

wire                        axis_master_cpl_tready_cfg;

// led lights up
reg     [ 22:0]             ref_led_cnt             ;
reg     [ 26:0]             pclk_led_cnt            ;
reg     [ 26:0]             pclk_div2_led_cnt       ;
reg     [ 26:0]             user_led_cnt            ;

wire                        o_cross_4kb_boundary    ;

wire    [  1:0]             p_calib_done            ;
wire                        power_up_rst_n          ;

//********************************************************************
//              reset debounce and sync processing
//*********************************************************************
//---------------debounce button_rst_n (ref_clk)
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2T_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_buttonrstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (button_rst_n       ),
    .rstn_out           (sync_button_rst_n  )
);

//---------------debounce  perst_n   (ref_clk)
hsst_rst_cross_sync_v1_0 #(
    `ifdef IPS2T_PCIE_SPEEDUP_SIM
    .RST_CNTR_VALUE     (16'h10             )
    `else
    .RST_CNTR_VALUE     (16'hC000           )
    `endif
)
u_refclk_perstn_debounce(
    .clk                (ref_clk            ),
    .rstn_in            (perst_n            ),
    .rstn_out           (sync_perst_n       )
);

//---------------pclk_div2_button_rst_n (pclk_div2)
ips2t_pcie_sync_v1_0  u_pclk_div2_button_rstn_sync(
    .clk                (pclk_div2              ),
    .rst_n              (sync_button_rst_n      ),
    .sig_async          (1'b1                   ),
    .sig_synced         (pclk_div2_button_rst_n )
);

//---------------user_button_rst_n (user_clk)
ips2t_pcie_sync_v1_0  u_user_button_rstn_sync(
    .clk                (user_clk           ),
    .rst_n              (sync_button_rst_n  ),
    .sig_async          (1'b1               ),
    .sig_synced         (user_button_rst_n  )
);

//---------------pclk_button_rst_n (pclk_div2)
ips2t_pcie_sync_v1_0  u_pclk_button_rstn_sync(
    .clk                (pclk                   ),
    .rst_n              (sync_button_rst_n      ),
    .sig_async          (1'b1                   ),
    .sig_synced         (pclk_button_rst_n      )
);

//---------------pclk_user_rst_n
ips2t_pcie_sync_v1_0  u_pclk_user_rst_n(
    .clk                (pclk                   ),
    .rst_n              (user_rst_n             ),
    .sig_async          (1'b1                   ),
    .sig_synced         (pclk_user_rst_n        )
);

//---------------pclk_div2_user_rst_n
ips2t_pcie_sync_v1_0  u_pclk_div2_user_rst_n(
    .clk                (pclk_div2              ),
    .rst_n              (user_rst_n             ),
    .sig_async          (1'b1                   ),
    .sig_synced         (pclk_div2_user_rst_n        )
);


//----------------------------------------------------------clk led ----------------------------------------------------------
always @(posedge ref_clk or negedge sync_perst_n)
begin
    if (!sync_perst_n)
        ref_led_cnt    <= 23'd0;
    else
        ref_led_cnt    <= ref_led_cnt + 23'd1;
end

always @(posedge ref_clk or negedge sync_perst_n)
begin
    if (!sync_perst_n)
        ref_led        <= 1'b1;
    else if(&ref_led_cnt)
        ref_led        <= ~ref_led;
end

always @(posedge pclk or negedge pclk_user_rst_n)
begin
    if (!pclk_user_rst_n)
        pclk_led_cnt    <= 27'd0;
    else
        pclk_led_cnt    <= pclk_led_cnt + 27'd1;
end

always @(posedge pclk or negedge pclk_user_rst_n)
begin
    if (!pclk_user_rst_n)
        pclk_led        <= 1'b1;
    else if(&pclk_led_cnt)
        pclk_led        <= ~pclk_led;
end

always @(posedge pclk_div2 or negedge pclk_div2_user_rst_n)
begin
    if (!pclk_div2_user_rst_n)
        pclk_div2_led_cnt    <= 27'd0;
    else
        pclk_div2_led_cnt    <= pclk_div2_led_cnt + 27'd1;
end

always @(posedge pclk_div2 or negedge pclk_div2_user_rst_n)
begin
    if (!pclk_div2_user_rst_n)
        pclk_div2_led        <= 1'b1;
    else if(&pclk_div2_led_cnt)
        pclk_div2_led        <= ~pclk_div2_led;
end

always @(posedge user_clk or negedge user_rst_n)
begin
    if (!user_rst_n)
        user_led_cnt    <= 27'd0;
    else
        user_led_cnt    <= user_led_cnt + 27'd1;
end

always @(posedge user_clk or negedge user_rst_n)
begin
    if (!user_rst_n)
        user_led        <= 1'b1;
    else if(&user_led_cnt)
        user_led        <= ~user_led;
end


//********************************************************************
//              PLL user_clk gen
//*********************************************************************

ips2t_pll_user  u_user_clk_pll(
.clkout0    (           ), //62.5Mhz gen1
.clkout1    (           ), //125Mhz  gen2
.clkout2    (user_clk   ), //250Mhz  gen3
.clkin1     (ref_clk    ),
.rst        (~(perst_n & button_rst_n) ),
.lock       (user_pll_lock )      //clock stable indicator
);

//********************************************************************
//              uart2apb
//*********************************************************************
pgr_uart2apb_top_32bit
#(
    .CLK_FREQ                     (100               ),
    .FIFO_D                       (16                ),
    .AW                           (32                ),
    .DW                           (32                ),
    .SW                           (4                 )
)u_uart2apb_top(
    .i_clk                        (ref_clk            ), //input
    .i_rst_n                      (sync_button_rst_n  ), //input,
    .o_p_sel                      (uart_p_sel         ), //output,
    .o_p_strb                     (uart_p_strb        ), //output [SW-1:0]
    .o_p_addr                     (uart_p_addr        ), //output [AW-1:0]
    .o_p_wdata                    (uart_p_wdata       ), //output [DW-1:0]
    .o_p_enable                   (uart_p_ce          ), //output
    .o_p_we                       (uart_p_we          ), //output
    .i_p_ready                    (uart_p_rdy         ), //input
    .i_p_rdata                    (uart_p_rdata       ), //input [DW-1:0]
    .i_apb_en                     (1'b1               ), //input
    .i_strb_en                    (1'b1               ), //input
    .i_uart_rxd                   (rxd                ), //input
    .o_uart_txd                   (txd                ), //output
    .o_uart_txvld                 (                   ), //output
    .i_uart_txreq                 (1'b0               ), //input
    .i_uart_txdata                (8'h0               ), //input
    .i_uart_rxreq                 (1'b0               ), //input
    .o_uart_rxdata                (                   ), //output
    .o_uart_rxvld                 (                   ) //output
);

//********************************************************************
//              APB2APB clock cross mux COMMON MODULES
//*********************************************************************
ips2t_expd_apb_mux u_pcie_expd_apb_mux(
    //from uart domain
    .i_uart_clk             (ref_clk                ),
    .i_uart_rst_n           (sync_button_rst_n      ),
    .i_uart_p_sel           (uart_p_sel             ),
    .i_uart_p_strb          (uart_p_strb            ),
    .i_uart_p_addr          (uart_p_addr            ),
    .i_uart_p_wdata         (uart_p_wdata           ),
    .i_uart_p_ce            (uart_p_ce              ),
    .i_uart_p_we            (uart_p_we              ),
    .o_uart_p_rdy           (uart_p_rdy             ),
    .o_uart_p_rdata         (uart_p_rdata           ),
    //to user_clk domain
    .i_user_clk             (user_clk               ),
    .i_user_rst_n           (user_button_rst_n      ),
    .o_user_p_strb          (user_p_strb            ),
    .o_user_p_addr          (user_p_addr            ),
    .o_user_p_wdata         (user_p_wdata           ),
    .o_user_p_ce            (user_p_ce              ),
    .o_user_p_we            (user_p_we              ),
    //to pcie
    .o_pcie_p_sel           (p_sel_pcie             ),
    .i_pcie_p_rdy           (p_rdy_pcie             ),
    .i_pcie_p_rdata         (p_rdata_pcie           ),
    //to dma
    .o_dma_p_sel            (p_sel_dma              ),
    .i_dma_p_rdy            (p_rdy_dma              ),
    .i_dma_p_rdata          (p_rdata_dma            ),
    //to cfg
    .o_cfg_p_sel            (p_sel_cfg              ),
    .i_cfg_p_rdy            (p_rdy_cfg              ),
    .i_cfg_p_rdata          (p_rdata_cfg            )
);

//********************************************************************
//              dma_CTRL       BASE_ADDR=0x0200_0000         UNIT 8
//********************************************************************
ips2t_pcie_dma_pio #(
    .DEVICE_TYPE            (DEVICE_TYPE            ),   //4'd0:EP,4'd1:Legacy EP,4'd4:RC
    .TEST_MODE              (TEST_MODE              )    //"DMA" for DMA TEST,"PIO" only for PIO TEST
    //parameter   integer                 AXIS_SLAVE_NUM = 3      ,
)u_pcie_dma_pio(
    .clk                     (user_clk              ),  //input    //gen1:62.5MHz,gen2:125MHz,gen3:250MHz
    .rst_n                   (user_rst_n            ),  //input
                                                    //
    .i_cfg_pbus_num          (cfg_pbus_num          ),  //input    [7:0]
    .i_cfg_pbus_dev_num      (cfg_pbus_dev_num      ),  //input    [4:0]
    .i_cfg_max_rd_req_size   (cfg_max_rd_req_size   ),  //input    [5:0]
    .i_cfg_max_payload_size  (cfg_max_payload_size  ),  //input    [5:0]
    //**********************************************************************
    //AXIS master0 interface
    .i_axis_master0_tvalid   (axis_master0_tvalid   ),  //input
    .o_axis_master0_tready   (axis_master0_tready   ),  //output  wire
    .i_axis_master0_tdata    (axis_master0_tdata    ),  //input           [255:0]
    .i_axis_master0_tkeep    (axis_master0_tkeep    ),  //input           [  7:0]
    .i_axis_master0_tlast    (axis_master0_tlast    ),  //input
    .i_axis_master0_tuser    (axis_master0_tuser    ),  //input           [ 12:0]
    .o_user_rcvd_np_ready    (user_rcvd_np_ready    ),  //output  wire
    .o_user_rcvd_p_ready     (user_rcvd_p_ready     ),  //output  wire
    //AXIS master1 interface
    .i_axis_master1_tvalid   (dma_axis_master_cpl_tvalid),  //input
    .o_axis_master1_tready   (dma_axis_master_cpl_tready),  //output  wire
    .i_axis_master1_tdata    (dma_axis_master_cpl_tdata ),  //input           [255:0]
    .i_axis_master1_tkeep    (dma_axis_master_cpl_tkeep ),  //input           [  7:0]
    .i_axis_master1_tlast    (dma_axis_master_cpl_tlast ),  //input
    .i_axis_master1_tuser    (dma_axis_master_cpl_tuser ),  //input           [ 5:0]
    //**********************************************************************
    //AXIS_Slave0 interface
    .i_axis_slave0_trdy      (axis_slave0_tready        ),//input
    .o_axis_slave0_tvld      (dma_axis_slave0_tvalid    ),//output  wire
    .o_axis_slave0_tdata     (dma_axis_slave0_tdata     ),//output  wire    [255:0]
    .o_axis_slave0_tlast     (dma_axis_slave0_tlast     ),//output  wire
    .o_axis_slave0_tuser     (dma_axis_slave0_tuser     ),//output  wire    [  5:0]
    //AXIS_Slave1 interface
    .i_axis_slave1_trdy      (axis_slave1_tready        ),//input
    .o_axis_slave1_tvld      (axis_slave1_tvalid        ),//output  wire
    .o_axis_slave1_tdata     (axis_slave1_tdata         ),//output  wire    [255:0]
    .o_axis_slave1_tlast     (axis_slave1_tlast         ),//output  wire
    .o_axis_slave1_tuser     (axis_slave1_tuser         ),//output  wire    [  5:0]
    //AXIS_Slave2 interface
    .i_axis_slave2_trdy      (axis_slave2_tready        ),//input
    .o_axis_slave2_tvld      (axis_slave2_tvalid        ),//output  wire
    .o_axis_slave2_tdata     (axis_slave2_tdata         ),//output  wire    [255:0]
    .o_axis_slave2_tlast     (axis_slave2_tlast         ),//output  wire
    .o_axis_slave2_tuser     (axis_slave2_tuser         ),//output  wire    [  5:0]
    //**********************************************************************
    //credit interface
    //from pcie
    //.i_cfg_ido_req_en        (cfg_ido_req_en),//input
    //.i_cfg_ido_cpl_en        (cfg_ido_cpl_en),//input
    //.i_xadm_ph_cdts          (xadm_ph_cdts  ),//input           [7:0]
    //.i_xadm_pd_cdts          (xadm_pd_cdts  ),//input           [11:0]
    //.i_xadm_nph_cdts         (xadm_nph_cdts ),//input           [7:0]
    //.i_xadm_npd_cdts         (xadm_npd_cdts ),//input           [11:0]
    //.i_xadm_cplh_cdts        (xadm_cplh_cdts),//input           [7:0]
    //.i_xadm_cpld_cdts        (xadm_cpld_cdts),//input           [11:0]
    //**********************************************************************
    //apb interface
    .i_apb_psel              (p_sel_dma         ),//input
    .i_apb_paddr             (user_p_addr[8:0]  ),//input           [8:0]
    .i_apb_pwdata            (user_p_wdata      ),//input           [31:0]
    .i_apb_pstrb             (user_p_strb       ),//input           [3:0]
    .i_apb_pwrite            (user_p_we         ),//input
    .i_apb_penable           (user_p_ce         ),//input
    .o_apb_prdy              (p_rdy_dma         ),//output  wire
    .o_apb_prdata            (p_rdata_dma       ),//output  wire    [31:0]
    .i_tlp_abort             (tlp_abort         ),//output  wire    [31:0]
    //cross_4kb_boundary
    .o_cross_4kb_boundary    (o_cross_4kb_boundary)//output  wire
    //debug
    //output  wire    [159:0]             o_dbg_bus
);


generate
//********************************************************************
//              CFG_CTRL       BASE_ADDR=0x0300_0000         UNIT 9
//********************************************************************
    if (DEVICE_TYPE == 4'd4)
    begin:rc
        ips2t_pcie_cfg_ctrl u_cfg_ctrl(
        //from APB                      ////from APB
            .user_clk               (user_clk               ),   //    input
            .apb_rst_n              (user_rst_n             ),   //    input
            .p_sel                  (p_sel_cfg              ),   //    input
            .p_strb                 (user_p_strb            ),   //    input    [  3:0]
            .p_addr                 (user_p_addr            ),   //    input    [ 31:0]
            .p_wdata                (user_p_wdata           ),   //    input    [ 31:0]
            .p_ce                   (user_p_ce              ),   //    input
            .p_we                   (user_p_we              ),   //    input
            .p_rdy                  (p_rdy_cfg              ),   //    output
            .p_rdata                (p_rdata_cfg            ),   //    output   [ 31:0]
            .pcie_cfg_ctrl_en       (pcie_cfg_ctrl_en       ),   //    output
        //to PCIE ctrl
            .axis_slave_tready      (axis_slave0_tready     ),   //    input
            .axis_slave_tvalid      (cfg_axis_slave_tvalid  ),   //    output
            .axis_slave_tdata       (cfg_axis_slave_tdata   ),   //    output   [255:0]
            .axis_slave_tlast       (cfg_axis_slave_tlast   ),   //    output
            .axis_slave_tuser       (cfg_axis_slave_tuser   ),   //    output   [  5:0]

            .axis_master1_tready    (axis_master_cpl_tready_cfg ),   //    output
            .axis_master1_tvalid    (axis_master_cpl_tvalid ),   //    input
            .axis_master1_tdata     (axis_master_cpl_tdata  ),   //    input    [255:0]
            .axis_master1_tkeep     (axis_master_cpl_tkeep  ),   //    input    [  7:0]
            .axis_master1_tuser     (axis_master_cpl_tuser  ),   //    input    [  5:0]
            .axis_master1_tlast     (axis_master_cpl_tlast  )    //    input
        );

        //********************************************************************
        //             AXIS INTERFACE MUX
        //********************************************************************
        assign axis_slave0_tvalid = pcie_cfg_ctrl_en ? cfg_axis_slave_tvalid : dma_axis_slave0_tvalid ;
        assign axis_slave0_tdata  = pcie_cfg_ctrl_en ? cfg_axis_slave_tdata  : dma_axis_slave0_tdata  ;
        assign axis_slave0_tlast  = pcie_cfg_ctrl_en ? cfg_axis_slave_tlast  : dma_axis_slave0_tlast  ;
        assign axis_slave0_tuser  = pcie_cfg_ctrl_en ? cfg_axis_slave_tuser  : dma_axis_slave0_tuser  ;

        assign dma_axis_master_cpl_tvalid = pcie_cfg_ctrl_en ? 1'b0   : axis_master_cpl_tvalid ;
        assign dma_axis_master_cpl_tdata  = pcie_cfg_ctrl_en ? 256'd0 : axis_master_cpl_tdata  ;
        assign dma_axis_master_cpl_tkeep  = pcie_cfg_ctrl_en ? 8'd0   : axis_master_cpl_tkeep  ;
        assign dma_axis_master_cpl_tuser  = pcie_cfg_ctrl_en ? 6'd0   : axis_master_cpl_tuser  ;
        assign dma_axis_master_cpl_tlast  = pcie_cfg_ctrl_en ? 1'd0   : axis_master_cpl_tlast  ;

        assign axis_master_cpl_tready   = pcie_cfg_ctrl_en ? axis_master_cpl_tready_cfg  : dma_axis_master_cpl_tready;
    end
    else
    begin:ep
        assign p_rdy_cfg               = 1'b0;
        assign p_rdata_cfg             = 32'b0;

        assign axis_slave0_tvalid      = dma_axis_slave0_tvalid;
        assign axis_slave0_tdata       = dma_axis_slave0_tdata;
        assign axis_slave0_tlast       = dma_axis_slave0_tlast;
        assign axis_slave0_tuser       = dma_axis_slave0_tuser;

        assign dma_axis_master_cpl_tvalid  = axis_master_cpl_tvalid;
        assign dma_axis_master_cpl_tdata   = axis_master_cpl_tdata ;
        assign dma_axis_master_cpl_tkeep   = axis_master_cpl_tkeep ;
        assign dma_axis_master_cpl_tuser   = axis_master_cpl_tuser ;
        assign dma_axis_master_cpl_tlast   = axis_master_cpl_tlast ;
        assign axis_master_cpl_tready      = dma_axis_master_cpl_tready;
    end
endgenerate
//********************************************************************
//              completion interface instance
//********************************************************************
ips2t_pcie_cpl_intf #(
    .TAG_NUM                    (0                      ),
    .MAX_PAYLOAD_SIZE           (3'd0                   ),
    .MAX_RAED_REQ_SIZE          (3'd0                   )
) u_cpl_intf(
    .clk                        (user_clk               ),
    .rst_n                      (user_rst_n             ),
    //from pcie
    .axis_master1_tvalid        (axis_master1_tvalid    ),
    .axis_master1_tdata         (axis_master1_tdata     ),
    .axis_master1_tkeep         (axis_master1_tkeep     ),
    .axis_master1_tuser         (axis_master1_tuser     ),
    //to user
    .axis_master_cpl_tready     (axis_master_cpl_tready ),
    .axis_master_cpl_tvalid     (axis_master_cpl_tvalid ),
    .axis_master_cpl_tdata      (axis_master_cpl_tdata  ),
    .axis_master_cpl_tkeep      (axis_master_cpl_tkeep  ),
    .axis_master_cpl_tuser      (axis_master_cpl_tuser  ),
    .axis_master_cpl_tlast      (axis_master_cpl_tlast  ),
    //abort flag
    .tlp_abort                  (tlp_abort              ),
    .fifo_space                 (fifo_space             )
);


//********************************************************************
//              pcie_top instance
//********************************************************************

assign power_up_rst_n = sync_perst_n & p_calib_done[1];
bdma_pcie_ip
u_pcie_wrap (
    //clk and rst
    .power_up_rst_n             (power_up_rst_n         ),  //input
    .button_rst_n               (sync_button_rst_n      ),  //input
    .perst_n                    (sync_perst_n           ),  //input
    .user_rst_n                 (user_rst_n             ),  //output
    .user_clk                   (user_clk               ),  //input
    .ref_clk                    (ref_clk                ),  //output
    .pclk_div2                  (pclk_div2              ),  //output
    .pclk                       (pclk                   ),  //output
    .user_pll_lock              (user_pll_lock          ),
    .p_calib_done               (p_calib_done           ),  //output
    //the input ref_clk pair
    .ref_clk_n                  (ref_clk_n              ),  //input
    .ref_clk_p                  (ref_clk_p              ),  //input

    //apb
    .p_clk                      (ref_clk                ),//input
    .p_rst_n                    (sync_button_rst_n      ),//input
    .p_sel                      (p_sel_pcie             ),//input
    .p_strb                     (uart_p_strb            ),//input  [ 3:0]
    .p_addr                     (uart_p_addr            ),//input  [31:0]
    .p_wdata                    (uart_p_wdata           ),//input  [31:0]
    .p_ce                       (uart_p_ce              ),//input
    .p_we                       (uart_p_we              ),//input
    .p_rdy                      (p_rdy_pcie             ),//output
    .p_rdata                    (p_rdata_pcie           ),//output [31:0]
    
    //AXIS master interface : master0 for remote request
    .axis_master0_tvalid        (axis_master0_tvalid    ),  //output
    .axis_master0_tready        (axis_master0_tready    ),  //input
    .axis_master0_tdata         (axis_master0_tdata     ),  //output  [255:0]
    .axis_master0_tkeep         (axis_master0_tkeep     ),  //output  [7:0]
    .axis_master0_tlast         (axis_master0_tlast     ),  //output
    .axis_master0_tuser         (axis_master0_tuser     ),  //output  [12:0]                   //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                            //   function number                vf number , vf active }
    .user_rcvd_np_ready         (user_rcvd_np_ready     ),  //input
    .core_avl_np_cnt            (core_avl_np_cnt        ),  //output [5:0]
    .user_rcvd_p_ready          (user_rcvd_p_ready      ),  //input
    .core_avl_p_cnt             (core_avl_p_cnt         ),  //output [5:0]
    //AXIS master interface : master1 for remote completion
    .axis_master1_tvalid        (axis_master1_tvalid    ),  //output
    .axis_master1_tdata         (axis_master1_tdata     ),  //output  [255:0]
    .axis_master1_tkeep         (axis_master1_tkeep     ),  //output  [7:0]
    .axis_master1_tuser         (axis_master1_tuser     ),  //output  [33:0]                   //{rom_in_range , mem_in_range , cpl_last,ecrc_error,tlp_abort,dllp_abort
                                                            //   function number                vf number , vf active}
    //**********************************************************************
    //axis slave 0 interface
    .axis_slave0_tready         (axis_slave0_tready     ),  //output
    .axis_slave0_tvalid         (axis_slave0_tvalid     ),  //input
    .axis_slave0_tdata          (axis_slave0_tdata      ),  //input   [255:0]
    .axis_slave0_tlast          (axis_slave0_tlast      ),  //input
    .axis_slave0_tuser          (axis_slave0_tuser      ),  //input   [5:0]                   //{bad eot , function number  , vf number , vf active}


    //axis slave 1 interface
    .axis_slave1_tready         (axis_slave1_tready     ),  //output
    .axis_slave1_tvalid         (axis_slave1_tvalid     ),  //input
    .axis_slave1_tdata          (axis_slave1_tdata      ),  //input   [255:0]
    .axis_slave1_tlast          (axis_slave1_tlast      ),  //input
    .axis_slave1_tuser          (axis_slave1_tuser      ),  //input   [5:0]
    //axis slave 2 interface
    .axis_slave2_tready         (axis_slave2_tready     ),  //output
    .axis_slave2_tvalid         (axis_slave2_tvalid     ),  //input
    .axis_slave2_tdata          (axis_slave2_tdata      ),  //input   [255:0]
    .axis_slave2_tlast          (axis_slave2_tlast      ),  //input
    .axis_slave2_tuser          (axis_slave2_tuser      ),  //input   [5:0]

    .cfg_int_disable            (                       ),  //output  [2-1:0]
    .sys_int                    (2'b0                   ),  //input [1:0]
    .int_grt                    (                       ),  //output

    .ven_msi_vector             (5'b0                   ),  //input [4:0]
    .cfg_msi_pending            (64'b0                  ),  //input [63:0]
    .cfg_msi_en                 (                       ),  //output [1:0]
    .ven_msi_func_num           (1'b0                   ),  //input
    .ven_msi_vfunc_num          (2'b0                   ),  //input [2:0]
    .ven_msi_vfunc_active       (1'b0                   ),  //input
    .cfg_msi_mask_update        (                       ),  //output
    .cfg_vf_msi_pending         (192'b0                 ),  //input [191:0]

    .ven_msi_req                (1'b0                   ),  //input
    .ven_msi_tc                 (3'b0                   ),  //input [2:0]
    .ven_msi_grant              (                       ),  //output



    .radm_cpl_timeout           (                       ),  //output  [1:0]
    .radm_timeout_func_num      (                       ),  //output  [1:0]
    .radm_timeout_vfunc_num     (                       ),  //output  [5:0]
    .radm_timeout_vfunc_active  (                       ),  //output  [1:0]
    .radm_timeout_cpl_tc        (                       ),  //output  [5:0]
    .radm_timeout_cpl_attr      (                       ),  //output  [3:0]
    .radm_timeout_cpl_len       (                       ),  //output  [21:0]
    .radm_timeout_cpl_tag       (                       ),  //output  [15:0]

    .rdlh_link_up               (rdlh_link_up           ),  //output
    .smlh_ltssm_state           (smlh_ltssm_state       ),  //output  [5:0]
    .smlh_link_up               (smlh_link_up           ),  //output
    .smlh_req_rst_not           (                       ),  //output

    //Configuration reg output interface
    .cfg_vf_bme                 (                       ),  //output [6-1:0]
    .cfg_vf_en                  (                       ),  //output [2-1:0]
    .cfg_num_vf                 (                       ),  //output [16*2-1:0]
    .cfg_start_vfi              (                       ),  //output [6-1:0]
    .cfg_tph_req_en             (                       ),  //output [(1*8)-1:0]
    .cfg_pf_tph_st_mode         (                       ),  //output [(3*8)-1:0]
    .cfg_vf_tph_st_mode         (                       ),  //output  [(3*6)-1:0]
    .cfg_vf_tph_req_en          (                       ),  //output  [(1*6)-1:0]
    .dpa_substate_update        (                       ),  //output [2-1:0]
    .cfg_atomic_req_en          (                       ),  //output [2-1:0]
    .cfg_atomic_egress_block    (                       ),  //output [2-1:0]
    .cfg_ari_fwd_en             (                       ),  //output  [2-1:0]
    .cfg_send_cor_err           (                       ),  //output  [2-1:0]
    .cfg_send_nf_err            (                       ),  //output  [2-1:0]
    .cfg_send_f_err             (                       ),  //output  [2-1:0]
    .cfg_no_snoop_en            (                       ),  //output  [2-1:0]
    .cfg_relax_order_en         (                       ),  //output  [2-1:0]
    .cfg_link_auto_bw_int       (                       ),  //output
    .cfg_link_auto_bw_msi       (                       ),  //output
    .cfg_bw_mgt_int             (                       ),  //output
    .cfg_bw_mgt_msi             (                       ),  //output
    .cfg_link_eq_req_int        (                       ),  //output
    .rbar_ctrl_update           (                       ),  //output  [2-1:0]
    .cfg_ido_req_en             (                       ),  //output  [2-1:0]
    .cfg_ido_cpl_en             (                       ),  //output  [2-1:0]
    .cfg_sys_err_rc             (                       ),  //output  [2-1:0]
    .cfg_aer_rc_err_int         (                       ),  //output  [2-1:0]
    .cfg_aer_rc_err_msi         (                       ),  //output  [2-1:0]
    .cfg_pme_int                (                       ),  //output  [2-1:0]
    .cfg_pme_msi                (                       ),  //output  [2-1:0]
    .cfg_crs_sw_vis_en          (                       ),  //output  [2-1:0]
    .radm_q_not_empty           (                       ),  //output  [1-1:0]
    .radm_qoverflow             (                       ),  //output  [1-1:0]
    .cfg_bus_master_en          (cfg_bus_master_en      ),  //output  [2-1:0]
    .cfg_2nd_reset              (                       ),  //output
    .cfg_max_payload_size       (cfg_max_payload_size   ),  //output  [6-1:0]
    .cfg_rcb                    (cfg_rcb                ),  //output  [2-1:0]
    .cfg_tc_enable              (                       ),  //output  [8-1:0]
    .cfg_mem_space_en           (cfg_mem_space_en       ),  //output  [2-1:0]
    .cfg_max_rd_req_size        (cfg_max_rd_req_size    ),  //output  [6-1:0]
    .cfg_ext_tag_en             (cfg_ext_tag_en         ),  //output  [2-1:0]
    .cfg_reg_serren             (                       ),  //output  [2-1:0]
    .cfg_cor_err_rpt_en         (                       ),  //output  [2-1:0]
    .cfg_nf_err_rpt_en          (                       ),  //output  [2-1:0]
    .cfg_f_err_rpt_en           (                       ),  //output  [2-1:0]
    .cfg_pbus_num               (cfg_pbus_num           ),  //output  [8-1:0]
    .cfg_pbus_dev_num           (cfg_pbus_dev_num       ),  //output  [5-1:0]
    .cfg_obff_en                (                       ),  //output  [1:0]

    //debug interface
    .dyn_debug_info_sel         (6'b0                   ),  //input   [6-1 :0]
    .app_ras_des_sd_hold_ltssm  (1'b0                   ),  //input
    .debug_info_mux             (                       ),  //output  [142:0]

    // START_IO:FLR Signal Descriptions
    .cfg_flr_pf_active          (                       ),  //output  [2-1:0]
    .app_flr_pf_done            (2'd0                   ),  //input   [2-1:0]

    // END_IO:FLR Signal Descriptions.

    // PHY inside device_top (or inside core)           export serial lines, import ref_clk

    .rxp                        (rxp                    ),//input  [7:0]
    .rxn                        (rxn                    ),//input  [7:0]
    .txp                        (txp                    ),//output [7:0]
    .txn                        (txn                    ),//output [7:0]

    .pcs_nearend_loop           ({8{1'b0}}              ),//input  [7:0]
    .pma_nearend_ploop          ({8{1'b0}}              ),//input  [7:0]
    .pma_nearend_sloop          ({8{1'b0}}              ) //input  [7:0]


);

endmodule
