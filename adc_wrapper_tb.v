`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module adc_wrapper_tb;

	parameter MASTER_PERIOD = 20;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg [15:0] adc_data;
	reg adc_ready;
	reg adc_gate;
	reg result_ack;
	reg [7:0] counter_id;

	// Outputs
	wire [39:0] result;
	wire result_ready;
	wire [7:0] counter_id_out;

	// Instantiate the Unit Under Test (UUT)
	adc_wrapper uut (
		.clk(clk), 
		.adc_data(adc_data), 
		.adc_ready(adc_ready), 
		.adc_gate(adc_gate), 
		.result(result), 
		.result_ready(result_ready), 
		.result_ack(result_ack), 
		.counter_id(counter_id), 
		.counter_id_out(counter_id_out)
	);

	initial begin
		// Initialize Inputs
		adc_data = 0;
		adc_ready = 0;
		adc_gate = 0;
		result_ack = 0;
		counter_id = 14;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		adc_data = 12;
		adc_gate = 1;
		#20;
		#20;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		adc_gate = 0;

		#200;
		adc_gate = 1;
		#20;
		#20;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1; 
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		adc_gate = 0;

		#200;
		adc_gate = 1;
		#20;
		#20;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1; 
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		adc_gate = 0;

		#200;
		adc_gate = 1;
		#20;
		#20;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1; 
		#20;
		adc_ready = 0;
		#200;
		adc_ready = 1;
		#20;
		adc_ready = 0;
		adc_gate = 0;

	end
	
	always @(posedge clk) begin
		if (result_ready)
			result_ack <= 1'b1;
		else
			result_ack <= 1'b0;
	end
      
endmodule

