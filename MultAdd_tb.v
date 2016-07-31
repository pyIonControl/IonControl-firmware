`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module MultAdd_tb;

	// Inputs
	reg subtract;
	reg [15:0] a;
	reg [15:0] b;
	reg [31:0] c;

	// Outputs
	wire [31:0] p;
	wire [47:0] pcout;

	// Instantiate the Unit Under Test (UUT)
	MultAdd_16_24_40_40 uut (
		.subtract(subtract), 
		.a(a), 
		.b(b), 
		.c(c), 
		.p(p), 
		.pcout(pcout)
	);

	initial begin
		// Initialize Inputs
		subtract = 0;
		a = 0;
		b = 0;
		c = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		a = 16'h4fff;
		b = 16'h4fff;
		c = 32'h4fffffff;
		
		#100;
		a = -16'h10;
		b = 16'h4000;
		c = 32'h0;

	end
      
endmodule

