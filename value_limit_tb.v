//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module value_limit_tb;

	parameter MASTER_PERIOD = 5;
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg [15:0] value;
	wire [9:0] out;
	wire clipped;

	// Instantiate the Unit Under Test (UUT)
	value_limit uut (
		.clk(clk), 
		.value(value),
		.out(out),
		.clipped(clipped)
	);

	initial begin
		// Initialize Inputs
		value = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		value = 255;
		#20;
		value = 0;
		#20;
		value = -255;
		#20;
		value = 0;
	end
      
endmodule

