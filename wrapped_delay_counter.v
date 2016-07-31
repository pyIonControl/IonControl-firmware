//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module wrapped_delay_counter(
	input wire clk,
	input wire load,
	input wire [47:0] l,
	input wire rst,
	output wire expired,
	output wire threshold,
	output wire expired_pulse );
	
parameter threshold_offset = 12;
parameter pulsed_threshold_offset = 2;

	wire [47:0] count;
	wire thresh;
	
	wire load_pulse;
	clk_monoflop load_mf( .clk(clk), .enable(1'b1), .trigger(load), .q(load_pulse) );
	
	
	delay_counter my_delay_counter( .clk(clk), .load(load_pulse), .l(l), .q(count), .thresh0(thresh) );
	set_reset_pulse #(1'b1) my_set_reset( .clock(clk), .set(thresh | rst), .reset(load_pulse & l>=pulsed_threshold_offset), .q(expired), .q_pulse(expired_pulse) );
	set_reset #(1'b1) thresh_set_reset( .clock(clk), .set(count==threshold_offset | rst), .reset(load_pulse & l>threshold_offset), .q(threshold) );
	
endmodule