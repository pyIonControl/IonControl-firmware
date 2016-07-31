`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module DedicatedCounterADC_tb;

	parameter MASTER_PERIOD = 5;
	// clocks
	clock_gen #(MASTER_PERIOD) mclk(clk);

	// Inputs
	reg [15:0] count_input;
	reg [15:0] count_enable;
	reg [15:0] adc_enable;
	reg [47:0] update_time;
	reg [255:0] adcdata;
	reg [15:0] adcready;
	reg [39:0] tdc_count;
	reg fifo_full;

	// Outputs
	wire [63:0] data_out;
	wire data_available;
	wire [15:0] dout;
	wire empty;
	wire [11:0] rd_data_count;

	// Instantiate the Unit Under Test (UUT)
	DedicatedCounterADC uut (
		.clk(clk), 
		.count_input(count_input), 
		.count_enable(count_enable), 
		.adc_enable(adc_enable), 
		.adcdata(adcdata), 
		.adcready(adcready), 
		.tdc_count(tdc_count), 
		.data_out(data_out), 
		.data_available(data_available), 
		.fifo_full(fifo_full), 
		.update_time(update_time)
	);
		
			
	FifoMultiplexer fmm(
		.rst(1'b0),
		.wr_clk(clk),
		.rd_clk(clk),
		.din_1(data_out),
		.din_2(data_out),
		.wr_en_1(data_available),
		.wr_en_2(data_available),
		.full_1(),
		.full_2(fifo_full),
		.dout(dout),
		.rd_en(1'b0),
		.empty(empty),
		.rd_data_count(rd_data_count) );


	initial begin
		// Initialize Inputs
		count_input = 0;
		count_enable = 0;
		adc_enable = 0;
		update_time = 30;
		adcdata = 0;
		adcready = 0;
		tdc_count = 5;
		fifo_full = 0;

		// Wait 100 ns for global reset to finish
		#100;
		adcdata = 256'h42;
        
		// Add stimulus here
		update_time = 32'h20;
		
		#200;
		count_enable = 8'h01;
		adc_enable = 1;
		
		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

		#40 count_input = 1;
		adcready = 1;
		#(MASTER_PERIOD) count_input = 0;		adcready = 0;

	end
      
endmodule

