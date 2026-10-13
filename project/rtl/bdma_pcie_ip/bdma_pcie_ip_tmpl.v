// Created by IP Generator (Version 2024.2-dev1 build 165593)
// Instantiation Template
//
// Insert the following codes into your Verilog file.
//   * Change the_instance_name to your own instance name.
//   * Change the signal names in the port associations


bdma_pcie_ip the_instance_name (
  .pclk(pclk),                                              // output
  .pclk_div2(pclk_div2),                                    // output
  .ref_clk(ref_clk),                                        // output
  .user_clk(user_clk),                                      // input
  .ref_clk_n(ref_clk_n),                                    // input
  .ref_clk_p(ref_clk_p),                                    // input
  .button_rst_n(button_rst_n),                              // input
  .power_up_rst_n(power_up_rst_n),                          // input
  .perst_n(perst_n),                                        // input
  .user_rst_n(user_rst_n),                                  // output
  .user_pll_lock(user_pll_lock),                            // input
  .p_calib_done(p_calib_done),                              // output [1:0]
  .axis_master1_tvalid(axis_master1_tvalid),                // output
  .axis_master1_tdata(axis_master1_tdata),                  // output [255:0]
  .axis_master1_tkeep(axis_master1_tkeep),                  // output [7:0]
  .axis_master1_tuser(axis_master1_tuser),                  // output [33:0]
  .axis_master0_tvalid(axis_master0_tvalid),                // output
  .axis_master0_tready(axis_master0_tready),                // input
  .axis_master0_tdata(axis_master0_tdata),                  // output [255:0]
  .axis_master0_tkeep(axis_master0_tkeep),                  // output [7:0]
  .axis_master0_tlast(axis_master0_tlast),                  // output
  .axis_master0_tuser(axis_master0_tuser),                  // output [12:0]
  .user_rcvd_np_ready(user_rcvd_np_ready),                  // input
  .core_avl_np_cnt(core_avl_np_cnt),                        // output [5:0]
  .user_rcvd_p_ready(user_rcvd_p_ready),                    // input
  .core_avl_p_cnt(core_avl_p_cnt),                          // output [5:0]
  .axis_slave0_tready(axis_slave0_tready),                  // output
  .axis_slave0_tvalid(axis_slave0_tvalid),                  // input
  .axis_slave0_tdata(axis_slave0_tdata),                    // input [255:0]
  .axis_slave0_tlast(axis_slave0_tlast),                    // input
  .axis_slave0_tuser(axis_slave0_tuser),                    // input [5:0]
  .axis_slave1_tready(axis_slave1_tready),                  // output
  .axis_slave1_tvalid(axis_slave1_tvalid),                  // input
  .axis_slave1_tdata(axis_slave1_tdata),                    // input [255:0]
  .axis_slave1_tlast(axis_slave1_tlast),                    // input
  .axis_slave1_tuser(axis_slave1_tuser),                    // input [5:0]
  .axis_slave2_tready(axis_slave2_tready),                  // output
  .axis_slave2_tvalid(axis_slave2_tvalid),                  // input
  .axis_slave2_tdata(axis_slave2_tdata),                    // input [255:0]
  .axis_slave2_tlast(axis_slave2_tlast),                    // input
  .axis_slave2_tuser(axis_slave2_tuser),                    // input [5:0]
  .p_sel(p_sel),                                            // input
  .p_strb(p_strb),                                          // input [3:0]
  .p_addr(p_addr),                                          // input [31:0]
  .p_wdata(p_wdata),                                        // input [31:0]
  .p_ce(p_ce),                                              // input
  .p_we(p_we),                                              // input
  .p_rdy(p_rdy),                                            // output
  .p_rdata(p_rdata),                                        // output [31:0]
  .ven_msi_req(ven_msi_req),                                // input
  .ven_msi_tc(ven_msi_tc),                                  // input [2:0]
  .ven_msi_grant(ven_msi_grant),                            // output
  .sys_int(sys_int),                                        // input [1:0]
  .int_grt(int_grt),                                        // output
  .rdlh_link_up(rdlh_link_up),                              // output
  .smlh_ltssm_state(smlh_ltssm_state),                      // output [5:0]
  .smlh_link_up(smlh_link_up),                              // output
  .smlh_req_rst_not(smlh_req_rst_not),                      // output
  .cfg_vf_bme(cfg_vf_bme),                                  // output [5:0]
  .cfg_vf_en(cfg_vf_en),                                    // output [1:0]
  .cfg_num_vf(cfg_num_vf),                                  // output
  .cfg_start_vfi(cfg_start_vfi),                            // output [5:0]
  .cfg_tph_req_en(cfg_tph_req_en),                          // output [1:0]
  .cfg_pf_tph_st_mode(cfg_pf_tph_st_mode),                  // output [5:0]
  .cfg_vf_tph_st_mode(cfg_vf_tph_st_mode),                  // output [17:0]
  .cfg_vf_tph_req_en(cfg_vf_tph_req_en),                    // output [5:0]
  .dpa_substate_update(dpa_substate_update),                // output [1:0]
  .cfg_atomic_req_en(cfg_atomic_req_en),                    // output [1:0]
  .cfg_atomic_egress_block(cfg_atomic_egress_block),        // output [1:0]
  .cfg_ari_fwd_en(cfg_ari_fwd_en),                          // output [1:0]
  .cfg_send_cor_err(cfg_send_cor_err),                      // output [1:0]
  .cfg_send_nf_err(cfg_send_nf_err),                        // output [1:0]
  .cfg_send_f_err(cfg_send_f_err),                          // output [1:0]
  .cfg_int_disable(cfg_int_disable),                        // output [1:0]
  .cfg_no_snoop_en(cfg_no_snoop_en),                        // output [1:0]
  .cfg_relax_order_en(cfg_relax_order_en),                  // output [1:0]
  .cfg_link_auto_bw_int(cfg_link_auto_bw_int),              // output
  .cfg_link_auto_bw_msi(cfg_link_auto_bw_msi),              // output
  .cfg_bw_mgt_msi(cfg_bw_mgt_msi),                          // output
  .cfg_link_eq_req_int(cfg_link_eq_req_int),                // output
  .rbar_ctrl_update(rbar_ctrl_update),                      // output [1:0]
  .cfg_sys_err_rc(cfg_sys_err_rc),                          // output [1:0]
  .cfg_aer_rc_err_int(cfg_aer_rc_err_int),                  // output [1:0]
  .cfg_aer_rc_err_msi(cfg_aer_rc_err_msi),                  // output [1:0]
  .cfg_pme_int(cfg_pme_int),                                // output [1:0]
  .cfg_pme_msi(cfg_pme_msi),                                // output [1:0]
  .cfg_crs_sw_vis_en(cfg_crs_sw_vis_en),                    // output [1:0]
  .radm_q_not_empty(radm_q_not_empty),                      // output
  .radm_qoverflow(radm_qoverflow),                          // output
  .cfg_bus_master_en(cfg_bus_master_en),                    // output [1:0]
  .cfg_2nd_reset(cfg_2nd_reset),                            // output
  .cfg_max_payload_size(cfg_max_payload_size),              // output [5:0]
  .cfg_rcb(cfg_rcb),                                        // output [1:0]
  .cfg_tc_enable(cfg_tc_enable),                            // output [7:0]
  .cfg_mem_space_en(cfg_mem_space_en),                      // output [1:0]
  .cfg_max_rd_req_size(cfg_max_rd_req_size),                // output [5:0]
  .cfg_ext_tag_en(cfg_ext_tag_en),                          // output [1:0]
  .cfg_reg_serren(cfg_reg_serren),                          // output [1:0]
  .cfg_cor_err_rpt_en(cfg_cor_err_rpt_en),                  // output [1:0]
  .cfg_nf_err_rpt_en(cfg_nf_err_rpt_en),                    // output [1:0]
  .cfg_f_err_rpt_en(cfg_f_err_rpt_en),                      // output [1:0]
  .cfg_pbus_num(cfg_pbus_num),                              // output [7:0]
  .cfg_pbus_dev_num(cfg_pbus_dev_num),                      // output [4:0]
  .cfg_obff_en(cfg_obff_en),                                // output [1:0]
  .dyn_debug_info_sel(dyn_debug_info_sel),                  // input [5:0]
  .app_ras_des_sd_hold_ltssm(app_ras_des_sd_hold_ltssm),    // input
  .debug_info_mux(debug_info_mux),                          // output [142:0]
  .cfg_flr_pf_active(cfg_flr_pf_active),                    // output [1:0]
  .app_flr_pf_done(app_flr_pf_done),                        // input [1:0]
  .rxn(rxn),                                                // input [7:0]
  .rxp(rxp),                                                // input [7:0]
  .txn(txn),                                                // output [7:0]
  .txp(txp),                                                // output [7:0]
  .pcs_nearend_loop(pcs_nearend_loop),                      // input [7:0]
  .pma_nearend_ploop(pma_nearend_ploop),                    // input [7:0]
  .pma_nearend_sloop(pma_nearend_sloop)                     // input [7:0]
);
