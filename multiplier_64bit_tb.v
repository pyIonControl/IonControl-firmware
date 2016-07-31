`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module multiplier_64bit_tb;

	parameter MASTER_PERIOD = 5;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);

	reg ce;
	reg [63:0] a;
	reg [63:0] b;

	// Outputs
	wire [63:0] p;

	// Instantiate the Unit Under Test (UUT)
	multiplier_64bit uut (
		.clk(clk), 
		.ce(ce), 
		.a(a), 
		.b(b), 
		.p(p)
	);

	initial begin
		// Initialize Inputs
		ce = 0;
		a = 0;
		b = 0;

		// Wait 100 ns for global reset to finish
		#100;
		a = 8;
		b = 8;
		ce = 1;
        
		// Add stimulus here

	end
      
endmodule

