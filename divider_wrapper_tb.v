`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module divider_wrapper_tb;

	parameter MASTER_PERIOD = 10;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);

	reg [63:0] dividend;
	reg [63:0] divisor;
	reg start;

	// Outputs
	wire [127:0] result;
	wire result_valid;

	// Instantiate the Unit Under Test (UUT)
	divider_wrapper uut (
		.clk(clk), 
		.dividend(dividend), 
		.divisor(divisor), 
		.start(start), 
		.result(result), 
		.result_valid(result_valid)
	);

	initial begin
		// Initialize Inputs
		dividend = 0;
		divisor = 0;
		start = 0;

		// Wait 100 ns for global reset to finish
		#100;
      dividend = 8;
		divisor = 2;
		start = 1;
		// Add stimulus here
		#850;
		start = 0;
		#20;
		start = 1;
		dividend = 16;
		
	end
      
endmodule

