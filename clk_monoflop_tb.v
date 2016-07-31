`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module clk_monoflop_tb;

	parameter MASTER_PERIOD = 10;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg trigger;
	reg enable;

	// Outputs
	wire q;

	// Instantiate the Unit Under Test (UUT)
	clk_monoflop uut (
		.clk(clk), 
		.trigger(trigger), 
		.enable(enable),
		.q(q)
	);

	initial begin
		// Initialize Inputs
		trigger = 0;
		enable = 1;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		trigger = 1;
		#100;
		
		trigger = 0;
		#10;
		
		trigger = 1;
		#10;
		
		trigger = 0;
		enable = 0;
		#200;
		trigger = 1;
		#100;
		
		trigger = 0;
		#10;
		
		trigger = 1;
		#10;
		trigger = 0;
		
		#50;
		enable = 1;
		trigger = 1;
		#10;
		enable = 0;
		#30;
		trigger = 0;
		#30;
		
		trigger = 1;
		#10;
		enable = 1;
		#10;
		trigger = 0;
		#10;
		enable = 0;
		
	end
      
endmodule

