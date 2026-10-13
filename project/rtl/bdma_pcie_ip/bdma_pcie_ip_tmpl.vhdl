-- Created by IP Generator (Version 2024.2-dev1 build 165593)
-- Instantiation Template
--
-- Insert the following codes into your VHDL file.
--   * Change the_instance_name to your own instance name.
--   * Change the net names in the port map.


COMPONENT bdma_pcie_ip
  PORT (
    pclk : OUT STD_LOGIC;
    pclk_div2 : OUT STD_LOGIC;
    ref_clk : OUT STD_LOGIC;
    user_clk : IN STD_LOGIC;
    ref_clk_n : IN STD_LOGIC;
    ref_clk_p : IN STD_LOGIC;
    button_rst_n : IN STD_LOGIC;
    power_up_rst_n : IN STD_LOGIC;
    perst_n : IN STD_LOGIC;
    user_rst_n : OUT STD_LOGIC;
    user_pll_lock : IN STD_LOGIC;
    p_calib_done : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    axis_master1_tvalid : OUT STD_LOGIC;
    axis_master1_tdata : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    axis_master1_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axis_master1_tuser : OUT STD_LOGIC_VECTOR(33 DOWNTO 0);
    axis_master0_tvalid : OUT STD_LOGIC;
    axis_master0_tready : IN STD_LOGIC;
    axis_master0_tdata : OUT STD_LOGIC_VECTOR(255 DOWNTO 0);
    axis_master0_tkeep : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    axis_master0_tlast : OUT STD_LOGIC;
    axis_master0_tuser : OUT STD_LOGIC_VECTOR(12 DOWNTO 0);
    user_rcvd_np_ready : IN STD_LOGIC;
    core_avl_np_cnt : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    user_rcvd_p_ready : IN STD_LOGIC;
    core_avl_p_cnt : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    axis_slave0_tready : OUT STD_LOGIC;
    axis_slave0_tvalid : IN STD_LOGIC;
    axis_slave0_tdata : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    axis_slave0_tlast : IN STD_LOGIC;
    axis_slave0_tuser : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    axis_slave1_tready : OUT STD_LOGIC;
    axis_slave1_tvalid : IN STD_LOGIC;
    axis_slave1_tdata : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    axis_slave1_tlast : IN STD_LOGIC;
    axis_slave1_tuser : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    axis_slave2_tready : OUT STD_LOGIC;
    axis_slave2_tvalid : IN STD_LOGIC;
    axis_slave2_tdata : IN STD_LOGIC_VECTOR(255 DOWNTO 0);
    axis_slave2_tlast : IN STD_LOGIC;
    axis_slave2_tuser : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    p_sel : IN STD_LOGIC;
    p_strb : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    p_addr : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    p_wdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    p_ce : IN STD_LOGIC;
    p_we : IN STD_LOGIC;
    p_rdy : OUT STD_LOGIC;
    p_rdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    ven_msi_req : IN STD_LOGIC;
    ven_msi_tc : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    ven_msi_grant : OUT STD_LOGIC;
    sys_int : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    int_grt : OUT STD_LOGIC;
    rdlh_link_up : OUT STD_LOGIC;
    smlh_ltssm_state : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    smlh_link_up : OUT STD_LOGIC;
    smlh_req_rst_not : OUT STD_LOGIC;
    cfg_vf_bme : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    cfg_vf_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_num_vf : OUT STD_LOGIC;
    cfg_start_vfi : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    cfg_tph_req_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_pf_tph_st_mode : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    cfg_vf_tph_st_mode : OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
    cfg_vf_tph_req_en : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    dpa_substate_update : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_atomic_req_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_atomic_egress_block : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_ari_fwd_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_send_cor_err : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_send_nf_err : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_send_f_err : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_int_disable : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_no_snoop_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_relax_order_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_link_auto_bw_int : OUT STD_LOGIC;
    cfg_link_auto_bw_msi : OUT STD_LOGIC;
    cfg_bw_mgt_msi : OUT STD_LOGIC;
    cfg_link_eq_req_int : OUT STD_LOGIC;
    rbar_ctrl_update : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_sys_err_rc : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_aer_rc_err_int : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_aer_rc_err_msi : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_pme_int : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_pme_msi : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_crs_sw_vis_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    radm_q_not_empty : OUT STD_LOGIC;
    radm_qoverflow : OUT STD_LOGIC;
    cfg_bus_master_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_2nd_reset : OUT STD_LOGIC;
    cfg_max_payload_size : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    cfg_rcb : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_tc_enable : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_mem_space_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_max_rd_req_size : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    cfg_ext_tag_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_reg_serren : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_cor_err_rpt_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_nf_err_rpt_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_f_err_rpt_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    cfg_pbus_num : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    cfg_pbus_dev_num : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
    cfg_obff_en : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    dyn_debug_info_sel : IN STD_LOGIC_VECTOR(5 DOWNTO 0);
    app_ras_des_sd_hold_ltssm : IN STD_LOGIC;
    debug_info_mux : OUT STD_LOGIC_VECTOR(142 DOWNTO 0);
    cfg_flr_pf_active : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
    app_flr_pf_done : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    rxn : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    rxp : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    txn : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    txp : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
    pcs_nearend_loop : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    pma_nearend_ploop : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    pma_nearend_sloop : IN STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
END COMPONENT;


the_instance_name : bdma_pcie_ip
  PORT MAP (
    pclk => pclk,
    pclk_div2 => pclk_div2,
    ref_clk => ref_clk,
    user_clk => user_clk,
    ref_clk_n => ref_clk_n,
    ref_clk_p => ref_clk_p,
    button_rst_n => button_rst_n,
    power_up_rst_n => power_up_rst_n,
    perst_n => perst_n,
    user_rst_n => user_rst_n,
    user_pll_lock => user_pll_lock,
    p_calib_done => p_calib_done,
    axis_master1_tvalid => axis_master1_tvalid,
    axis_master1_tdata => axis_master1_tdata,
    axis_master1_tkeep => axis_master1_tkeep,
    axis_master1_tuser => axis_master1_tuser,
    axis_master0_tvalid => axis_master0_tvalid,
    axis_master0_tready => axis_master0_tready,
    axis_master0_tdata => axis_master0_tdata,
    axis_master0_tkeep => axis_master0_tkeep,
    axis_master0_tlast => axis_master0_tlast,
    axis_master0_tuser => axis_master0_tuser,
    user_rcvd_np_ready => user_rcvd_np_ready,
    core_avl_np_cnt => core_avl_np_cnt,
    user_rcvd_p_ready => user_rcvd_p_ready,
    core_avl_p_cnt => core_avl_p_cnt,
    axis_slave0_tready => axis_slave0_tready,
    axis_slave0_tvalid => axis_slave0_tvalid,
    axis_slave0_tdata => axis_slave0_tdata,
    axis_slave0_tlast => axis_slave0_tlast,
    axis_slave0_tuser => axis_slave0_tuser,
    axis_slave1_tready => axis_slave1_tready,
    axis_slave1_tvalid => axis_slave1_tvalid,
    axis_slave1_tdata => axis_slave1_tdata,
    axis_slave1_tlast => axis_slave1_tlast,
    axis_slave1_tuser => axis_slave1_tuser,
    axis_slave2_tready => axis_slave2_tready,
    axis_slave2_tvalid => axis_slave2_tvalid,
    axis_slave2_tdata => axis_slave2_tdata,
    axis_slave2_tlast => axis_slave2_tlast,
    axis_slave2_tuser => axis_slave2_tuser,
    p_sel => p_sel,
    p_strb => p_strb,
    p_addr => p_addr,
    p_wdata => p_wdata,
    p_ce => p_ce,
    p_we => p_we,
    p_rdy => p_rdy,
    p_rdata => p_rdata,
    ven_msi_req => ven_msi_req,
    ven_msi_tc => ven_msi_tc,
    ven_msi_grant => ven_msi_grant,
    sys_int => sys_int,
    int_grt => int_grt,
    rdlh_link_up => rdlh_link_up,
    smlh_ltssm_state => smlh_ltssm_state,
    smlh_link_up => smlh_link_up,
    smlh_req_rst_not => smlh_req_rst_not,
    cfg_vf_bme => cfg_vf_bme,
    cfg_vf_en => cfg_vf_en,
    cfg_num_vf => cfg_num_vf,
    cfg_start_vfi => cfg_start_vfi,
    cfg_tph_req_en => cfg_tph_req_en,
    cfg_pf_tph_st_mode => cfg_pf_tph_st_mode,
    cfg_vf_tph_st_mode => cfg_vf_tph_st_mode,
    cfg_vf_tph_req_en => cfg_vf_tph_req_en,
    dpa_substate_update => dpa_substate_update,
    cfg_atomic_req_en => cfg_atomic_req_en,
    cfg_atomic_egress_block => cfg_atomic_egress_block,
    cfg_ari_fwd_en => cfg_ari_fwd_en,
    cfg_send_cor_err => cfg_send_cor_err,
    cfg_send_nf_err => cfg_send_nf_err,
    cfg_send_f_err => cfg_send_f_err,
    cfg_int_disable => cfg_int_disable,
    cfg_no_snoop_en => cfg_no_snoop_en,
    cfg_relax_order_en => cfg_relax_order_en,
    cfg_link_auto_bw_int => cfg_link_auto_bw_int,
    cfg_link_auto_bw_msi => cfg_link_auto_bw_msi,
    cfg_bw_mgt_msi => cfg_bw_mgt_msi,
    cfg_link_eq_req_int => cfg_link_eq_req_int,
    rbar_ctrl_update => rbar_ctrl_update,
    cfg_sys_err_rc => cfg_sys_err_rc,
    cfg_aer_rc_err_int => cfg_aer_rc_err_int,
    cfg_aer_rc_err_msi => cfg_aer_rc_err_msi,
    cfg_pme_int => cfg_pme_int,
    cfg_pme_msi => cfg_pme_msi,
    cfg_crs_sw_vis_en => cfg_crs_sw_vis_en,
    radm_q_not_empty => radm_q_not_empty,
    radm_qoverflow => radm_qoverflow,
    cfg_bus_master_en => cfg_bus_master_en,
    cfg_2nd_reset => cfg_2nd_reset,
    cfg_max_payload_size => cfg_max_payload_size,
    cfg_rcb => cfg_rcb,
    cfg_tc_enable => cfg_tc_enable,
    cfg_mem_space_en => cfg_mem_space_en,
    cfg_max_rd_req_size => cfg_max_rd_req_size,
    cfg_ext_tag_en => cfg_ext_tag_en,
    cfg_reg_serren => cfg_reg_serren,
    cfg_cor_err_rpt_en => cfg_cor_err_rpt_en,
    cfg_nf_err_rpt_en => cfg_nf_err_rpt_en,
    cfg_f_err_rpt_en => cfg_f_err_rpt_en,
    cfg_pbus_num => cfg_pbus_num,
    cfg_pbus_dev_num => cfg_pbus_dev_num,
    cfg_obff_en => cfg_obff_en,
    dyn_debug_info_sel => dyn_debug_info_sel,
    app_ras_des_sd_hold_ltssm => app_ras_des_sd_hold_ltssm,
    debug_info_mux => debug_info_mux,
    cfg_flr_pf_active => cfg_flr_pf_active,
    app_flr_pf_done => app_flr_pf_done,
    rxn => rxn,
    rxp => rxp,
    txn => txn,
    txp => txp,
    pcs_nearend_loop => pcs_nearend_loop,
    pma_nearend_ploop => pma_nearend_ploop,
    pma_nearend_sloop => pma_nearend_sloop
  );
