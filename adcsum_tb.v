`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module adcsum_tb;

	wire clk;
	clock_gen #(10) mclk(clk);
	
	// Inputs
	reg [15:0] data;
	reg data_ready;
	reg sclr;

	// Outputs
	wire [31:0] q;
	wire [15:0] count;

	// Instantiate the Unit Under Test (UUT)
	adcsum uut (
		.clk(clk), 
		.data(data), 
		.data_ready(data_ready), 
		.sclr(sclr), 
		.q(q), 
		.count(count)
	);

	initial begin
		// Initialize Inputs
		data = 0;
		data_ready = 0;
		sclr = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		data = 2;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 3;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 4;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 5;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 6;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		sclr = 1;
		#10
		sclr = 0;
		
		data = 2;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 3;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 4;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 16'hfff8;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
		
		data = 6;
		data_ready = 1;
		#10;
		data_ready = 0;
		#100;
	end
      
endmodule

