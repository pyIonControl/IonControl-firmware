`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module random_tb;

	wire clk;
	clock_gen #(20) mclk(clk);
	// Inputs
	reg read_ack;
	reg [62:0] seed;
	reg set_seed;

	// Outputs
	wire [63:0] random;
	wire valid;
	reg rst;

	// Instantiate the Unit Under Test (UUT)
	random uut (
		.int_clk(clk), 
		.rd_clk(clk),
		.random(random), 
		.read_ack(read_ack), 
		.seed(seed), 
		.set_seed(set_seed), 
		.valid(valid),
		.rst(rst)
	);

	initial begin
		// Initialize Inputs
		read_ack = 0;
		seed = 0;
		set_seed = 0;
		rst = 1;

		// Wait 100 ns for global reset to finish
		#100;
		rst = 0;
        
		// Add stimulus here

	end
      
endmodule

