`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module counters_tb;

	// Inputs
	wire clk;
	wire usb_clk;
	wire fast_clk;
	parameter MASTER_PERIOD = 10;
	// clocks
	clock_gen #(MASTER_PERIOD) mclk(clk);
	clock_gen #(22) sclk(usb_clk);
	clock_gen #(5) fast_clk_gen(fast_clk);

	reg [15:0] count_in;
	reg [23:0] count_enable;
	reg [7:0] timestamp_enable;
	reg [129:0] output_data = 0;
	reg output_data_ready = 0;
	reg [7:0] counter_id = 0;

	// Outputs
	wire [63:0] fifo_data;
	wire fifo_data_ready;
	reg fifo_full = 0;

	// Instantiate the Unit Under Test (UUT)
	counters uut (
		.clk(clk), 
		.usb_clk(usb_clk), 
		.fifo_data(fifo_data), 
		.fifo_data_ready(fifo_data_ready), 
		.fifo_full(fifo_full), 
		.fifo_rst( 1'b0 ),
		.count_in(count_in), 
		.count_enable(count_enable), 
		.timestamp_enable(timestamp_enable),
		.output_data(output_data),
		.output_data_ready(output_data_ready),
		.counter_id( counter_id ),
		.fast_clk( fast_clk),
		.send_timestamp(0),
		.timestamp_counter_reset(0),
		.tdc_marker(8'h0),
		.adc_data(256'h0),
		.adc_ready(0),
		.adc_gate(0)
	);

	initial begin
		// Initialize Inputs
		count_in = 0;
		count_enable = 0;
		timestamp_enable = 0;
		counter_id = 0;

		// Wait 100 ns for global reset to finish
		#110;
        
		// Add stimulus here
		count_enable[2] = 1'b1;
		counter_id = 4;
		
		#(10*MASTER_PERIOD) count_in[2] = 1'b1;
		#(MASTER_PERIOD) count_in[2] = 1'b0;
		#(10*MASTER_PERIOD) count_enable[8] = 1'b0;
		
		#(10*MASTER_PERIOD) timestamp_enable[2] = 1'b1;
		#(10*MASTER_PERIOD) count_in[2] = 1'b1;
		#(MASTER_PERIOD) count_in[2] = 1'b0;
		#(10*MASTER_PERIOD) count_in[2] = 1'b1;
		#(MASTER_PERIOD) count_in[2] = 1'b0;
		
		#(10*MASTER_PERIOD) output_data = 32'h01020304;
		output_data_ready = 1'b1;
		#(MASTER_PERIOD) output_data_ready = 1'b0;
		#(MASTER_PERIOD) output_data_ready = 1'b1;
		#(MASTER_PERIOD) output_data_ready = 1'b0;
		
		#100;
		count_enable[2] = 0;
		
	end
      
endmodule

