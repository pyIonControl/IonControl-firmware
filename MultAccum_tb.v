`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module MultAccum_tb;

	parameter MASTER_PERIOD = 5;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg ce;
	reg sclr;
	reg [15:0] a;
	reg [15:0] b;

	// Outputs
	wire [31:0] q;
	wire underflow;
	wire overflow;

	// Instantiate the Unit Under Test (UUT)
	MultAccum_limited uut (
		.clk(clk), 
		.ce(ce), 
		.sclr(sclr), 
		.a(a), 
		.b(b), 
		.q(q),
		.overflow(overflow),
		.underflow(underflow)
	);

	initial begin
		// Initialize Inputs
		ce = 0;
		sclr = 0;
		a = 16'h4000;
		b = 16'h2000;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		ce = 1;
		#300;
		b = -16'h2000;
		
		#400;
		b = 16'h2000;
	end
      
endmodule

