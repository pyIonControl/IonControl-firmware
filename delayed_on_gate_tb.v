`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module delayed_on_gate_tb;

	parameter MASTER_PERIOD = 20;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg gate;
	reg [31:0] delay;

	// Outputs
	wire q;

	// Instantiate the Unit Under Test (UUT)
	delayed_on_gate uut (
		.clk(clk), 
		.gate(gate), 
		.delay(delay), 
		.q(q)
	);

	initial begin
		// Initialize Inputs
		gate = 0;
		delay = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		gate = 1;
		delay = 10;
		
		#400;
		gate = 0;
		
		#20;
		gate = 1;
		#60;
		gate = 0;
	end
      
endmodule

