//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module wrapped_delay_counter_tb;

	// Inputs
	wire clk;
	clock_gen #(5) myclk(clk);
	reg load;
	reg [47:0] l;
	reg rst;

	// Outputs
	wire expired;
	wire threshold;

	// Instantiate the Unit Under Test (UUT)
	wrapped_delay_counter uut (
		.clk(clk), 
		.load(load), 
		.l(l), 
		.rst(rst),
		.expired(expired),
		.threshold(threshold)
	);

	initial begin
		// Initialize Inputs
		load = 0;
		l = 28;
		rst = 0;

		// Wait 100 ns for global reset to finish
		#110;
        
		// Add stimulus here
		l = 47'h22;
		load = 1'b1;
		
		#20;
		load = 1'b0;

		#200
		load = 1'b1;
		
		#20;
		load = 1'b0;
		
		#200
		l = 6;
		load = 1;
		
		#20
		load = 0;
		
		#500
		rst = 1;
		
		#100
		rst = 0;
		
		#200
		load = 1;
		
		#20
		load = 0;
		
		#20;
		l=2000;
		load = 1;
		
		#200;
		load = 0;
		
	end
      
endmodule

