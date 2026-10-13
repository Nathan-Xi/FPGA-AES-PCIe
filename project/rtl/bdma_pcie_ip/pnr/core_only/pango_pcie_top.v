
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
    //clk and rst
    input                   user_clk            ,
    input                   ref_clk_n           ,      //100 Mhz
    input                   ref_clk_p           ,      //100 Mhz
    input                   power_up_rst_n      ,
    input                   button_rst_n        ,
    input                   perst_n
);

//*********************************************************************
//              internal signals define
//*********************************************************************

//clk and rst
wire                           pclk                ;
wire                           pclk_div2           ;
wire                           ref_clk             ;
wire                           user_clk            ;
wire                           ref_clk_n           ;
wire                           ref_clk_p           ;
wire                           button_rst_n        ;
wire                           power_up_rst_n      ;
wire                           perst_n             ;
wire                           user_rst_n          ;
wire                           user_pll_lock       ;
wire           [ 1:0]          p_calib_done        ;


//apb interface to  dbi cfg
wire                           p_clk               ;
wire                           p_rst_n             ;
wire                           p_sel               ;
wire           [ 3:0]          p_strb              ;
wire           [31:0]          p_addr              ;
wire           [31:0]          p_wdata             ;
wire                           p_ce                ;
wire                           p_we                ;
wire                           p_rdy               ;
wire           [31:0]          p_rdata             ;


//axis master interface : master0 for remote request
wire                           axis_master0_tvalid ;
wire                           axis_master0_tready ;
wire            [255:0]        axis_master0_tdata  ;
wire            [7:0]          axis_master0_tkeep  ;
wire                           axis_master0_tlast  ;
wire            [12:0]         axis_master0_tuser  ; //{rom_in_range ; mem_in_range ; cpl_last;ecrc_error;tlp_abort;dllp_abort
                                                    //   function number  ; vf number ; vf active }
wire                           user_rcvd_np_ready  ;
wire            [5:0]          core_avl_np_cnt     ;
wire                           user_rcvd_p_ready   ;
wire            [5:0]          core_avl_p_cnt      ;

//axis master interface : master1 for remote completion
wire                           axis_master1_tvalid ;
wire            [255:0]        axis_master1_tdata  ;
wire            [7:0]          axis_master1_tkeep  ;
wire            [33:0]         axis_master1_tuser  ; //{rom_in_range ; mem_in_range ; cpl_last;ecrc_error;tlp_abort;dllp_abort
                                                    //   function number  ; vf number ; vf active spill_cpl_data }
//**********************************************************************
//axis slave 0 interface
wire                           axis_slave0_tready  ;
wire                           axis_slave0_tvalid  ;
wire           [255:0]         axis_slave0_tdata   ;
wire                           axis_slave0_tlast   ;
wire           [5:0]           axis_slave0_tuser   ;//{bad eot ; function number  ; vf number ; vf active}


//axis slave 1 interface
wire                           axis_slave1_tready  ;
wire                           axis_slave1_tvalid  ;
wire           [255:0]         axis_slave1_tdata   ;
wire                           axis_slave1_tlast   ;
wire           [5:0]           axis_slave1_tuser   ;
//axis slave 2 interface
wire                           axis_slave2_tready  ;
wire                           axis_slave2_tvalid  ;
wire           [255:0]         axis_slave2_tdata   ;
wire                           axis_slave2_tlast   ;
wire           [5:0]           axis_slave2_tuser   ;

//legacy interrupt
wire           [1:0]           cfg_int_disable     ;
wire           [1:0]           sys_int             ;
wire                           int_grt             ;

wire           [4:0]           ven_msi_vector      ;
wire           [63:0]          cfg_msi_pending     ;
wire           [1:0]           cfg_msi_en          ;
wire                           ven_msi_func_num    ;
wire           [2:0]           ven_msi_vfunc_num   ;
wire                           ven_msi_vfunc_active;
wire                           cfg_msi_mask_update ;
wire           [191:0]         cfg_vf_msi_pending  ;

wire                           ven_msi_req         ;
wire           [2:0]           ven_msi_tc          ;
wire                           ven_msi_grant       ;


//radm timeout
wire           [1:0]           radm_cpl_timeout           ;
wire           [1:0]           radm_timeout_func_num      ;
wire           [5:0]           radm_timeout_vfunc_num     ;
wire           [1:0]           radm_timeout_vfunc_active  ;
wire           [5:0]           radm_timeout_cpl_tc        ;
wire           [3:0]           radm_timeout_cpl_attr      ;
wire           [21:0]          radm_timeout_cpl_len       ;
wire           [15:0]          radm_timeout_cpl_tag       ;

//link status interface
wire                           rdlh_link_up               ;
wire           [5:0]           smlh_ltssm_state           ;
wire                           smlh_link_up               ;
wire                           link_req_rst_not           ;
wire                           smlh_req_rst_not           ;


//Configuration reg output interface
wire           [6-1:0]         cfg_vf_bme                 ;
wire           [2-1:0]         cfg_vf_en                  ;
wire           [16*2-1:0]      cfg_num_vf                 ;
wire           [6-1:0]         cfg_start_vfi              ;
wire           [(1*2)-1:0]     cfg_tph_req_en             ;
wire           [(3*2)-1:0]     cfg_pf_tph_st_mode         ;
wire           [(3*6)-1:0]     cfg_vf_tph_st_mode         ;
wire           [(1*6)-1:0]     cfg_vf_tph_req_en          ;
wire           [2-1:0]         dpa_substate_update        ;
wire           [2-1:0]         cfg_atomic_req_en          ;
wire           [2-1:0]         cfg_atomic_egress_block    ;
wire           [2-1:0]         cfg_ari_fwd_en             ;
wire           [2-1:0]         cfg_send_cor_err           ;
wire           [2-1:0]         cfg_send_nf_err            ;
wire           [2-1:0]         cfg_send_f_err             ;
wire           [2-1:0]         cfg_no_snoop_en            ;
wire           [2-1:0]         cfg_relax_order_en         ;
wire                           cfg_link_auto_bw_int       ;
wire                           cfg_link_auto_bw_msi       ;
wire                           cfg_bw_mgt_int             ;
wire                           cfg_bw_mgt_msi             ;
wire                           cfg_link_eq_req_int        ;
wire           [2-1:0]         rbar_ctrl_update           ;
wire           [2-1:0]         cfg_ido_req_en             ;
wire           [2-1:0]         cfg_ido_cpl_en             ;
wire           [2-1:0]         cfg_sys_err_rc             ;
wire           [2-1:0]         cfg_aer_rc_err_int         ;
wire           [2-1:0]         cfg_aer_rc_err_msi         ;
wire           [2-1:0]         cfg_pme_int                ;
wire           [2-1:0]         cfg_pme_msi                ;
wire           [2-1:0]         cfg_crs_sw_vis_en          ;
wire           [1-1:0]         radm_q_not_empty           ;
wire           [1-1:0]         radm_qoverflow             ;
wire           [2-1:0]         cfg_bus_master_en          ;
wire                           cfg_2nd_reset              ;
wire           [6-1:0]         cfg_max_payload_size       ;
wire           [2-1:0]         cfg_rcb                    ;
wire           [8-1:0]         cfg_tc_enable              ;
wire           [2-1:0]         cfg_mem_space_en           ;
wire           [6-1:0]         cfg_max_rd_req_size        ;
wire           [2-1:0]         cfg_ext_tag_en             ;
wire           [2-1:0]         cfg_reg_serren             ;
wire           [2-1:0]         cfg_cor_err_rpt_en         ;
wire           [2-1:0]         cfg_nf_err_rpt_en          ;
wire           [2-1:0]         cfg_f_err_rpt_en           ;
wire           [8-1:0]         cfg_pbus_num               ;
wire           [5-1:0]         cfg_pbus_dev_num           ;
wire           [1:0]           cfg_obff_en                ;

//debug interface
wire           [6-1 :0]        dyn_debug_info_sel         ;
wire                           app_ras_des_sd_hold_ltssm  ;
wire           [142:0]         debug_info_mux             ;

// START_IO:FLR Signal Descriptions
wire           [2-1:0]         cfg_flr_pf_active          ;
wire           [2-1:0]         app_flr_pf_done            ;



//phy diff signals

wire          [7:0]           rxp                         ;
wire          [7:0]           rxn                         ;
wire          [7:0]           txp                         ;
wire          [7:0]           txn                         ;
              
wire           [7:0]           pcs_nearend_loop           ;
wire           [7:0]           pma_nearend_ploop          ;
wire           [7:0]           pma_nearend_sloop          ;

//********************************************************************
//              pcie_top instance
//********************************************************************

bdma_pcie_ip
u_pcie_wrap (
    //clk and rst
    .power_up_rst_n             (power_up_rst_n         ),  //input
    .button_rst_n               (button_rst_n           ),  //input
    .perst_n                    (perst_n                ),  //input
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
    .p_clk                      (p_clk                  ),  //input
    .p_rst_n                    (p_rst_n                ),  //input
    .p_sel                      (p_sel                  ),  //input
    .p_strb                     (p_strb                 ),  //input [3:0]
    .p_addr                     (p_addr                 ),  //input [31:0]
    .p_wdata                    (p_wdata                ),  //input [31:0]
    .p_ce                       (p_ce                   ),  //input
    .p_we                       (p_we                   ),  //input
    .p_rdy                      (p_rdy                  ),  //output
    .p_rdata                    (p_rdata                ),  //output [31:0]

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

    .cfg_int_disable            (cfg_int_disable        ),  //output  [2-1:0]
    .sys_int                    (sys_int                ),  //input [1:0]
    .int_grt                    (int_grt                ),  //output

    .ven_msi_vector             (ven_msi_vector         ),  //input [4:0]
    .cfg_msi_pending            (cfg_msi_pending        ),  //input [63:0]
    .cfg_msi_en                 (cfg_msi_en             ),  //output [1:0]
    .ven_msi_func_num           (ven_msi_func_num       ),  //input
    .ven_msi_vfunc_num          (ven_msi_vfunc_num      ),  //input [2:0]
    .ven_msi_vfunc_active       (ven_msi_vfunc_active   ),  //input
    .cfg_msi_mask_update        (cfg_msi_mask_update    ),  //output
    .cfg_vf_msi_pending         (cfg_vf_msi_pending     ),  //input [191:0]

    .ven_msi_req                (ven_msi_req            ),  //input
    .ven_msi_tc                 (ven_msi_tc             ),  //input [2:0]
    .ven_msi_grant              (ven_msi_grant          ),  //output



    .radm_cpl_timeout           (radm_cpl_timeout         ),  //output  [1:0]
    .radm_timeout_func_num      (radm_timeout_func_num    ),  //output  [1:0]
    .radm_timeout_vfunc_num     (radm_timeout_vfunc_num   ),  //output  [5:0]
    .radm_timeout_vfunc_active  (radm_timeout_vfunc_active),  //output  [1:0]
    .radm_timeout_cpl_tc        (radm_timeout_cpl_tc      ),  //output  [5:0]
    .radm_timeout_cpl_attr      (radm_timeout_cpl_attr    ),  //output  [3:0]
    .radm_timeout_cpl_len       (radm_timeout_cpl_len     ),  //output  [21:0]
    .radm_timeout_cpl_tag       (radm_timeout_cpl_tag     ),  //output  [15:0]


    //Link status interface
    .rdlh_link_up               (rdlh_link_up           ),  //output
    .smlh_ltssm_state           (smlh_ltssm_state       ),  //output  [5:0]
    .smlh_link_up               (smlh_link_up           ),  //output
    .link_req_rst_not           (link_req_rst_not       ),  //output
    .smlh_req_rst_not           (smlh_req_rst_not       ),  //output

    //Configuration reg output interface
    .cfg_vf_bme                 (cfg_vf_bme             ),  //output [6-1:0]
    .cfg_vf_en                  (cfg_vf_en              ),  //output [2-1:0]
    .cfg_num_vf                 (cfg_num_vf             ),  //output [16*2-1:0]
    .cfg_start_vfi              (cfg_start_vfi          ),  //output [6-1:0]
    .cfg_tph_req_en             (cfg_tph_req_en         ),  //output [(1*8)-1:0]
    .cfg_pf_tph_st_mode         (cfg_pf_tph_st_mode     ),  //output [(3*8)-1:0]
    .cfg_vf_tph_st_mode         (cfg_vf_tph_st_mode     ),  //output  [(3*6)-1:0]
    .cfg_vf_tph_req_en          (cfg_vf_tph_req_en      ),  //output  [(1*6)-1:0]
    .dpa_substate_update        (dpa_substate_update    ),  //output [2-1:0]
    .cfg_atomic_req_en          (cfg_atomic_req_en      ),  //output [2-1:0]
    .cfg_atomic_egress_block    (cfg_atomic_egress_block),  //output [2-1:0]
    .cfg_ari_fwd_en             (cfg_ari_fwd_en         ),  //output  [2-1:0]
    .cfg_send_cor_err           (cfg_send_cor_err       ),  //output  [2-1:0]
    .cfg_send_nf_err            (cfg_send_nf_err        ),  //output  [2-1:0]
    .cfg_send_f_err             (cfg_send_f_err         ),  //output  [2-1:0]
    .cfg_no_snoop_en            (cfg_no_snoop_en        ),  //output  [2-1:0]
    .cfg_relax_order_en         (cfg_relax_order_en     ),  //output  [2-1:0]
    .cfg_link_auto_bw_int       (cfg_link_auto_bw_int   ),  //output
    .cfg_link_auto_bw_msi       (cfg_link_auto_bw_msi   ),  //output
    .cfg_bw_mgt_int             (cfg_bw_mgt_int         ),  //output
    .cfg_bw_mgt_msi             (cfg_bw_mgt_msi         ),  //output
    .cfg_link_eq_req_int        (cfg_link_eq_req_int    ),  //output
    .rbar_ctrl_update           (rbar_ctrl_update       ),  //output  [2-1:0]
    .cfg_ido_req_en             (cfg_ido_req_en         ),  //output  [2-1:0]
    .cfg_ido_cpl_en             (cfg_ido_cpl_en         ),  //output  [2-1:0]
    .cfg_sys_err_rc             (cfg_sys_err_rc         ),  //output  [2-1:0]
    .cfg_aer_rc_err_int         (cfg_aer_rc_err_int     ),  //output  [2-1:0]
    .cfg_aer_rc_err_msi         (cfg_aer_rc_err_msi     ),  //output  [2-1:0]
    .cfg_pme_int                (cfg_pme_int            ),  //output  [2-1:0]
    .cfg_pme_msi                (cfg_pme_msi            ),  //output  [2-1:0]
    .cfg_crs_sw_vis_en          (cfg_crs_sw_vis_en      ),  //output  [2-1:0]
    .radm_q_not_empty           (radm_q_not_empty       ),  //output  [1-1:0]
    .radm_qoverflow             (radm_qoverflow         ),  //output  [1-1:0]
    .cfg_bus_master_en          (cfg_bus_master_en      ),  //output  [2-1:0]
    .cfg_2nd_reset              (cfg_2nd_reset          ),  //output
    .cfg_max_payload_size       (cfg_max_payload_size   ),  //output  [6-1:0]
    .cfg_rcb                    (cfg_rcb                ),  //output  [2-1:0]
    .cfg_tc_enable              (cfg_tc_enable          ),  //output  [8-1:0]
    .cfg_mem_space_en           (cfg_mem_space_en       ),  //output  [2-1:0]
    .cfg_max_rd_req_size        (cfg_max_rd_req_size    ),  //output  [6-1:0]
    .cfg_ext_tag_en             (cfg_ext_tag_en         ),  //output  [2-1:0]
    .cfg_reg_serren             (cfg_reg_serren         ),  //output  [2-1:0]
    .cfg_cor_err_rpt_en         (cfg_cor_err_rpt_en     ),  //output  [2-1:0]
    .cfg_nf_err_rpt_en          (cfg_nf_err_rpt_en      ),  //output  [2-1:0]
    .cfg_f_err_rpt_en           (cfg_f_err_rpt_en       ),  //output  [2-1:0]
    .cfg_pbus_num               (cfg_pbus_num           ),  //output  [8-1:0]
    .cfg_pbus_dev_num           (cfg_pbus_dev_num       ),  //output  [5-1:0]
    .cfg_obff_en                (cfg_obff_en            ),  //output  [1:0]

    //debug interface
    .dyn_debug_info_sel         (dyn_debug_info_sel       ),  //input   [6-1:0]
    .app_ras_des_sd_hold_ltssm  (app_ras_des_sd_hold_ltssm),  //input
    .debug_info_mux             (debug_info_mux           ),  //output  [142:0]

    // START_IO:FLR Signal Descriptions
    .cfg_flr_pf_active          (cfg_flr_pf_active      ),  //output  [2-1:0]
    .app_flr_pf_done            (app_flr_pf_done        ),  //input   [2-1:0]

    // END_IO:FLR Signal Descriptions.

    // PHY inside device_top (or inside core)           export serial lines, import refclk

    .rxp                        (rxp                    ),//input  [7:0]
    .rxn                        (rxn                    ),//input  [7:0]
    .txp                        (txp                    ),//output [7:0]
    .txn                        (txn                    ),//output [7:0]

    .pcs_nearend_loop           (pcs_nearend_loop       ),//input  [7:0]
    .pma_nearend_ploop          (pma_nearend_ploop      ),//input  [7:0]
    .pma_nearend_sloop          (pma_nearend_sloop      ) //input  [7:0]

);

endmodule
