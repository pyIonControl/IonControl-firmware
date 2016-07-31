`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module pulsed_mode__tb;

	// Inputs
	wire clk;
	wire fast_clk;
	clock_gen #(20) myclk(clk);
	clock_gen #(5) myfastclk(fast_clk);
	
	reg timed_delay_start;
	reg [47:0] timed_delay;
	reg wait_counter_rst;
	reg [63:0] shutter_reg_buffer;
	reg [63:0] pulse_end_shutter_reg;
	reg pulse_mode;

	// Outputs
	wire pulsed_timed_wait_expired;
	wire timed_wait_expired;
	wire [63:0] shutter_o;
	wire expired_pulse;

	// Instantiate the Unit Under Test (UUT)
   wrapped_delay_counter my_delay_counter( .clk(fast_clk), .load(timed_delay_start), .l(timed_delay), 
		                                        .expired(pulsed_timed_wait_expired), .threshold(timed_wait_expired),.rst(wait_counter_rst),
															 .expired_pulse(expired_pulse) );
		
		
	output_multiplexer outmult( .clk(fast_clk), .update(timed_delay_start),
										 .pulse_mode(pulse_mode),
										 .wait_expired(expired_pulse), .shutter_in(shutter_reg_buffer), 
										 .pulse_end_shutter(pulse_end_shutter_reg), .shutter_out(shutter_o),
										 .enable(timed_delay>1) );


	initial begin
		// Initialize Inputs
		timed_delay_start = 0;
		timed_delay = 0;
		wait_counter_rst = 0;
		shutter_reg_buffer = 0;
		pulse_end_shutter_reg = 0;
		pulse_mode = 1;

		// Wait 100 ns for global reset to finish
		#110;
        
		// Add stimulus here
		// As initiated by from PP_UPDATE
		shutter_reg_buffer = 64'h0123456789abcdef;
		pulse_end_shutter_reg = 0;
		timed_delay_start = 1;
		timed_delay = 10;
		
		#20;
		timed_delay_start = 0;
		
		#210;
		timed_delay_start = 1;
		timed_delay = 50;
		pulse_mode = 0;
		#20;
		timed_delay_start = 0;
		shutter_reg_buffer = 0;
		
	end
      
endmodule

