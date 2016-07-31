`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module logic_analyzer_tb;

	wire clk;
	clock_gen myclk(clk);

	// Inputs
	reg [31:0] data_in;
	reg [31:0] trigger_in;
	reg [31:0] gate_in;
	reg reset;
	reg fifo_full;
	reg enable;

	// Outputs
	wire fifo_wr_en;
	wire [63:0] fifo_data_out;

	// Instantiate the Unit Under Test (UUT)
	logic_analyzer uut (
		.data_in(data_in), 
		.trigger_in(trigger_in), 
		.gate_data_in( gate_in ),
		.reset(reset), 
		.clk(clk), 
		.fifo_wr_en(fifo_wr_en), 
		.fifo_data_out(fifo_data_out), 
		.fifo_full(fifo_full), 
		.enable(enable)
	);

	initial begin
		// Initialize Inputs
		data_in = 0;
		trigger_in = 0;
		reset = 0;
		fifo_full = 0;
		enable = 0;
		gate_in = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		enable = 1;
		#20;
		
		data_in = 32'h42;
		
		#100;
		data_in = 32'h43;
		trigger_in = 32'h14;
		gate_in = 32'h23;
		
		#20
		trigger_in = 32'h0;

		#200
		gate_in = 32'h44;
		
		#300
		enable = 0;
	end
      
endmodule

