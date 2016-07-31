`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AutoLock_tb;

	wire clk;
	clock_gen #(20) mclk(clk);
	// Inputs
	reg update;
	reg [15:0] errorsig;
	reg [15:0] discriminator;
	reg [15:0] threshold;
	reg enable;
	reg [31:0] pCoeff;
	reg [31:0] iCoeff;
	reg [15:0] input_offset0;
	reg lock_enable;
	reg [15:0] scan_increment_0, scan_min_0, scan_max_0;
	reg [31:0] timeout;

	// Outputs
	wire enable_lock_out;
	wire scanEnable;
	wire [15:0] regOut;
	wire regulatorUpdate;
	wire [1:0] externalStatus;
	wire [15:0] lockScan;

	// Instantiate the Unit Under Test (UUT)
	wire scan_upd, pi_gate_0;

   delayed_on_gate delayed_on_gate_0( .clk(clk), .gate(lock_enable | enable_lock_out), .delay(0), .q(pi_gate_0) );
	picore ampl_piCore0( .clk(clk), .update(update), .errorsig(errorsig), 
		.pCoeff(pCoeff[31:0]), .iCoeff(iCoeff[31:0]), 
		.enable(pi_gate_0), .sclr(0), 
		.regOut(regOut), .regOutUpdate(regulatorUpdate), 
		.inputOffset(input_offset0[15:0]), .underflow(externalStatus[0]), .overflow(externalStatus[1]), 
		.output_offset(lockScan), .set_output_offset(scanEnable), .set_output_clk(scan_upd)  );
		
	AutoLock Autolock0( .clk(clk), .update(update), .errorsig(errorsig), .discriminator(discriminator),
							  .threshold(threshold), 
							  .enable( enable ),
							  .enable_lock_out(enable_lock_out), 
							  .scanEnable(scanEnable),
							  .timeout(timeout));
							  
	VarScanGenerator scanGenLock( .clk(clk), .increment(scan_increment_0), .sinit(1'b0), .scan_min(scan_min_0), .scan_max(scan_max_0), 
											.scan_enable(scanEnable), .q(lockScan), .output_upd(scan_upd) );


	initial begin
		// Initialize Inputs
		update = 0;
		errorsig = 10;
		discriminator = -20;
		threshold = 1000;
		enable = 0;
		pCoeff = 10;
		iCoeff = 10;
		input_offset0 =0;
	   lock_enable =0;
		scan_increment_0 = 1000;
		scan_min_0 = 0;
		scan_max_0 = 10000;
		timeout = 16;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		enable = 1;
		
		#3000;
		discriminator = 12000;
		
		#8000;
		discriminator = 100;

	end
      
endmodule

