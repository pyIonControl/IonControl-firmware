`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AD9912_tb;
	parameter MASTER_PERIOD = 5;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	
	wire sclk_in;
	clock_gen #(25) sclk(sclk_in);
	
	reg [3:0] dds_cmd;
	reg [63:0] dds_data;
	reg dds_ready;
	reg lock_ready;

	// Outputs
	wire [2:0] dds_out;
	wire done;

	// Instantiate the Unit Under Test (UUT)
	AD9912 uut (
		.clk(clk), 
		.sclk_in(sclk_in), 
		.dds_cmd(dds_cmd), 
		.dds_data(dds_data), 
		.dds_ready(dds_ready), 
		.dds_out(dds_out),
		.done(done),
		.lock_data(dds_data),
		.lock_cmd(dds_cmd),
		.lock_ready(lock_ready)
	);

	initial begin
		// Initialize Inputs
		dds_cmd = 0;
		dds_data = 0;
		dds_ready = 0;
		lock_ready = 0;

		// Wait 100 ns for global reset to finish
		#110;
		// Add stimulus here
      dds_cmd = 0;
		dds_data = 64'h123456789abd;
		dds_ready = 1'b1;
		#(MASTER_PERIOD)
		
		dds_ready = 1'b0;
		#2500
		dds_cmd = 1;
		dds_data = 64'h1234;
		dds_ready = 1'b1;
		#(MASTER_PERIOD)
		
		dds_ready = 1'b0;
		#3000;
		lock_ready <= 1;
		#20;
		lock_ready = 0;
		
	end
      
endmodule

