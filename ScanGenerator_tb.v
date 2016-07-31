`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module ScanGenerator_tb;

	wire clk;
	clock_gen #(10) mclk(clk);
	// Inputs
	reg [15:0] increment;
	reg sclr;
	reg [15:0] scan_min, scan_max;
	reg scan_enable;
	reg [9:0] delay;

	// Outputs
	wire [15:0] q;
	wire output_upd;

	// Instantiate the Unit Under Test (UUT)
	VarScanGenerator uut (
		.clk(clk), 
		.increment(increment), 
		.scan_min(scan_min), 
		.scan_max(scan_max),
		.scan_enable(scan_enable), 
		.sinit(1'b0),
		.q(q),
		.output_upd(output_upd)
	);

	initial begin
		// Initialize Inputs
		increment = 0;
		sclr = 0;
		scan_min = 16'h0000;
		scan_max = 16'h1fff;
		scan_enable = 0;
		delay = 10'h100;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		increment = 16'h100;
		scan_enable = 1;
		sclr = 1;
		#20;
		sclr = 0;
	end
      
endmodule

