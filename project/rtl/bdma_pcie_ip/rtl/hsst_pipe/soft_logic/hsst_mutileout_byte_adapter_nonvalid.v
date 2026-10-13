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
//common adapter module for pulse input only signals, where signal is from user logic to usr
//please note this sigal's latency is not critical
`timescale  1ns/10ps
module hsst_mutileout_byte_adapter_nonvalid #( 
parameter DW = 2
)(
input                   sc_pcie_hard_en,
input                   user_clk,
input                   user_rst_n,
//input                   data_valid,
input                   ctrl_clk,
input                   ctrl_rst_n,
//
input       [DW-1:0]    dout_core,
//output reg    		data_valid_usr,
output      [DW-1:0]    dout_usr_o
);

parameter DFT_VALUE  = {DW{1'b0}};

reg [1:0] update_ack_dly;
reg [DW-1:0] data_buf;
reg update_ack;
reg update_strobe;

reg [DW-1:0] dout_usr_r;

assign dout_usr_o = sc_pcie_hard_en ? dout_usr_r : {DW{1'b1}};

//*****************************************************************************************

//source clk domain
always @(posedge ctrl_clk or negedge ctrl_rst_n)
   if (!ctrl_rst_n) begin
      update_ack_dly <= 2'b0;
      update_strobe  <= 1'b0;
      data_buf       <= DFT_VALUE;
   end
   else begin
      update_ack_dly <= {update_ack_dly[0], update_ack};

      //latch new data
      if (update_strobe == update_ack_dly[1]) begin
         data_buf <= dout_core; 
         update_strobe <= ~ update_strobe;
      end
   end

//**********************************************************************
//destination clk domain
reg  [1:0] update_strobe_dly;

always @(posedge user_clk or negedge user_rst_n)
   if (!user_rst_n) begin
      update_strobe_dly <= 2'b0;
      update_ack        <= 1'b0;
      dout_usr_r          <= DFT_VALUE;
   end
   else begin
      update_strobe_dly <= {update_strobe_dly[0], update_strobe};
      
      if (update_strobe_dly[1] !=  update_ack) begin
         dout_usr_r   <= data_buf;
         update_ack <= ~ update_ack;
      end
   end


//***************************************************************************************** 

endmodule
