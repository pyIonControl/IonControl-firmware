`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module delay_counter_tb;

	parameter MASTER_PERIOD = 5;
	// clocks
	clock_gen #(MASTER_PERIOD) mclk(clk);

	// Inputs
	reg load;
	reg [47:0] l;

	// Outputs
	wire thresh0;
	wire [47:0] q;

	// Instantiate the Unit Under Test (UUT)
	delay_counter uut (
		.clk(clk), 
		.load(load), 
		.thresh0(thresh0), 
		.l(l), 
		.q(q)//,
		//.ce(1'b1)
	);

	initial begin
		// Initialize Inputs
		load = 0;
		l = 10;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		l = 15;
		load = 1;
		
		#(MASTER_PERIOD) load = 0;

	end
      
endmodule

