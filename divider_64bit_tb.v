`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module divider_64bit_tb;

	parameter MASTER_PERIOD = 10;
	// Inputs
	wire aclk;
	clock_gen #(MASTER_PERIOD) mclk(aclk);

	// Inputs
	reg s_axis_divisor_tvalid;
	reg s_axis_dividend_tvalid;
	reg [63:0] s_axis_divisor_tdata;
	reg [63:0] s_axis_dividend_tdata;

	// Outputs
	wire s_axis_divisor_tready;
	wire s_axis_dividend_tready;
	wire m_axis_dout_tvalid;
	wire [127:0] m_axis_dout_tdata;

	// Instantiate the Unit Under Test (UUT)
	divider_64bit uut (
		.aclk(aclk), 
		.s_axis_divisor_tvalid(s_axis_divisor_tvalid), 
		.s_axis_dividend_tvalid(s_axis_dividend_tvalid), 
		.s_axis_divisor_tready(s_axis_divisor_tready), 
		.s_axis_dividend_tready(s_axis_dividend_tready), 
		.m_axis_dout_tvalid(m_axis_dout_tvalid), 
		.s_axis_divisor_tdata(s_axis_divisor_tdata), 
		.s_axis_dividend_tdata(s_axis_dividend_tdata), 
		.m_axis_dout_tdata(m_axis_dout_tdata)
	);

	initial begin
		// Initialize Inputs
		s_axis_divisor_tvalid = 0;
		s_axis_dividend_tvalid = 0;
		s_axis_divisor_tdata = 0;
		s_axis_dividend_tdata = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		s_axis_divisor_tvalid = 1;
		s_axis_dividend_tvalid = 1;
		s_axis_divisor_tdata = 64'd1000;
		s_axis_dividend_tdata = 64'd10;
		
		
	end
	
	always @(posedge aclk) begin
		if (s_axis_divisor_tready) s_axis_divisor_tvalid = 0;
		if (s_axis_dividend_tready) s_axis_dividend_tvalid = 0;
	end
      
endmodule

