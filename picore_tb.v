`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module picore_tb;

	parameter MASTER_PERIOD = 20;
	wire clk;
	wire update_proto, update;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	clock_gen #(500) update_clk(update_proto);
	// Inputs
	reg [31:0] pCoeff;
	reg [31:0] iCoeff;
	reg enable;
	reg sclr;
	reg [15:0] inputOffset;
	reg set_output_offset;
	reg [15:0] output_offset;
	reg set_output_clk;

	// Outputs
	wire [15:0] regOut;
	wire regOutUpdate;
	reg [15:0] errorsig;
	wire underflow;
	wire overflow;

	// Instantiate the Unit Under Test (UUT)
	picore uut (
		.clk(clk), 
		.update(update), 
		.errorsig(errorsig), 
		.pCoeff(pCoeff), 
		.iCoeff(iCoeff), 
		.enable(enable), 
		.sclr(sclr), 
		.regOut(regOut), 
		.regOutUpdate(regOutUpdate), 
		.inputOffset(inputOffset), 
		.underflow(underflow),
		.overflow(overflow),
		.output_offset(output_offset),
		.set_output_offset(set_output_offset),
		.set_output_clk(set_output_clk)
	);

reg use_output = 0;
always @(posedge clk) begin
	if (use_output)
		errorsig <= regOut;
	else
		errorsig <= 16'h250;
end

clk_monoflop mf( .clk(clk), .enable(1), .trigger(update_proto), .q(update) );

	initial begin
		// Initialize Inputs
		pCoeff = 0;
		iCoeff = 0;
		enable = 0;
		sclr = 0;
		inputOffset = 0;
		use_output = 0;
		output_offset = 0;
		set_output_offset = 0;
		set_output_clk = 0;
		
		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		//pCoeff = 1000;
		iCoeff = 10000;
		enable = 0;
		inputOffset = 1000;
		
		set_output_offset = 1;
		output_offset = 16'h100;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;		
		#100
		output_offset = 16'h200;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;		
		#100
		output_offset = 16'h300;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;		
		#100
		output_offset = 16'h400;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;		
		#100
		output_offset = 16'h500;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;		
		#100
		output_offset = 16'h600;
		set_output_clk = 1'b1;
		#20
		set_output_clk = 1'b0;	
		set_output_offset = 0;
		enable = 1;
		pCoeff = -64;
		iCoeff = -1024;
		
	end
      
endmodule

