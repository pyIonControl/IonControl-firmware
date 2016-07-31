`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module divider_wrapper(
		input wire clk,
		input wire [63:0] dividend,
		input wire [63:0] divisor,
		input wire start,
		output wire [127:0] result,
		output wire result_valid
    );
	 
wire start_pulse; 
clk_monoflop cmf( .clk(clk), .enable(1'b1), .trigger(start), .q(start_pulse) );

//	wire s_axis_divisor_tvalid;
//	wire s_axis_dividend_tvalid;
	wire s_axis_divisor_tready;
	wire s_axis_dividend_tready;
//	set_reset divisor_sr( .clock(clk), .set(start_pulse), .reset(s_axis_divisor_tready), .q(s_axis_divisor_tvalid) );
//	set_reset dividend_sr( .clock(clk), .set(start_pulse), .reset(s_axis_dividend_tready), .q(s_axis_dividend_tvalid) );
	
	// Instantiate the Unit Under Test (UUT)
	divider_64bit uut (
		.aclk(clk), 
		.s_axis_divisor_tvalid(start_pulse), 
		.s_axis_dividend_tvalid(start_pulse), 
		.s_axis_divisor_tready(s_axis_divisor_tready), 
		.s_axis_dividend_tready(s_axis_dividend_tready), 
		.m_axis_dout_tvalid(result_valid), 
		.s_axis_divisor_tdata(divisor), 
		.s_axis_dividend_tdata(dividend), 
		.m_axis_dout_tdata(result)
	);


endmodule
