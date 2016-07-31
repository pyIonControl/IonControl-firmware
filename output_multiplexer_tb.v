`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module output_multiplexer_tb;

	wire clk;
	clock_gen #(5) myclk(clk);
	// Inputs
	reg update;
	reg pulse_mode;
	reg wait_expired;
	reg [63:0] shutter_in;
	reg [63:0] pulse_end_shutter;

	// Outputs
	wire [63:0] shutter_out;

	// Instantiate the Unit Under Test (UUT)
	output_multiplexer uut (
		.clk(clk), 
		.update(update), 
		.pulse_mode(pulse_mode), 
		.wait_expired(wait_expired), 
		.shutter_in(shutter_in), 
		.pulse_end_shutter(pulse_end_shutter), 
		.shutter_out(shutter_out)
	);

	initial begin
		// Initialize Inputs
		update = 0;
		pulse_mode = 0;
		wait_expired = 0;
		shutter_in = 0;
		pulse_end_shutter = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		shutter_in = 64'h123456789abcdeff;
		pulse_end_shutter = 64'hffedcba987654321;
		wait_expired = 1;
		update = 1;
		#10;
		wait_expired = 0;
		#10;
		update = 0;
		shutter_in = 0;
		#200;
		wait_expired = 1;
		#20;
		update = 1;
		#20;
		update = 0;
		#40;
		
		shutter_in = 64'h123456789abcdeff;
		pulse_end_shutter = 64'hffedcba987654321;
		pulse_mode = 1;
		wait_expired = 1;
		update = 1;
		#10;
		wait_expired = 0;
		#10;
		pulse_mode = 0;
		update = 0;
		shutter_in = 0;
		#200;
		wait_expired = 1;
		#20;
		wait_expired = 0;

		shutter_in = 64'hffedcba987654321;
		pulse_end_shutter = 64'h0;
		pulse_mode = 0;
		update = 1;
		#20;
		update = 0;
		
	end
      
endmodule

