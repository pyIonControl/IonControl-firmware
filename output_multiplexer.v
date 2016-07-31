`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module output_multiplexer(
	input wire clk,
	input wire update,
	input wire pp_active,
	input wire pulse_mode,
	input wire wait_expired,
	input wire [63:0] shutter_in,
	input wire [63:0] pulse_end_shutter,
	output reg [63:0] shutter_out = 0,
	input wire [63:0] counter_in,
	output reg [63:0] counter_out = 0,
	input wire enable
    );
	 
reg pulse_mode_active = 0;
wire update_pulse;
clk_monoflop update_mf( .clk(clk), .enable(1'b1), .trigger(update), .q(update_pulse) );

always @(posedge clk) begin
	if (update_pulse) begin
		if (pulse_mode) begin
			if (enable) begin
				shutter_out <= shutter_in;
				counter_out <= counter_in;
				pulse_mode_active <= pulse_mode;				
			end
		end else begin
			shutter_out <= shutter_in;
			counter_out <= counter_in;
		end
	end 
	else if (wait_expired & pulse_mode_active) begin
		shutter_out <= pulse_end_shutter;
		counter_out <= 64'h0;
		pulse_mode_active <= 1'b0;
	end
	else if (~pp_active) begin
			counter_out <= 64'h0;		
	end
end



endmodule
