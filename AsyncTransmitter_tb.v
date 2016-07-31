`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AsyncTransmitter_tb;

	// Inputs
	wire clk;
	clock_gen #(10) mclk(clk);

	reg [7:0] command;
	reg [63:0] data;
	reg ready;
	reg rd_en;

	// Outputs
	wire data_line;
	wire ndone;
	
	wire [7:0] rec_command;
	wire [63:0] rec_data;
	wire valid;
	wire [63:0] raw_data;
	wire raw_data_write;

	// Instantiate the Unit Under Test (UUT)
	AsyncTransmitter uut (
		.clk(clk), 
		.command(command), 
		.data(data), 
		.ready(ready), 
		.TxD(data_line), 
		.ndone(ndone)
	);
	
	AsyncReceiver uut2(
	    .clk(clk),
	    .command(rec_command),
	    .data(rec_data),
	    .rd_en(rd_en),
	    .RxD(data_line),
	    .valid(valid),
		 .raw_data(raw_data),
		 .raw_data_write(raw_data_write) );

	initial begin
		// Initialize Inputs
		command = 0;
		data = 0;
		ready = 0;
		rd_en = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		command = 8'h42;
		data = 64'h123456789abcdeff;
		ready = 1;
		#20
		ready = 0;
		#20
		ready = 1;
		#20
		ready = 0;
	end
      
endmodule

