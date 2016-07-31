//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps
module VarScanGenerator(
	input wire clk,
	input wire [15:0] increment,
	input wire sinit,
	input wire [15:0] scan_min,
	input wire [15:0] scan_max,
	input wire scan_enable,
	output reg [15:0] q = 0,
	output wire output_upd
    );
	 
	 
	wire [23:0] accum_q;
	reg direction = 1'b0;
	
	always @(posedge clk) begin
		if (~accum_q[23]) q <= accum_q[22:7];
	end
	
	wire invert_direction = accum_q[23:7]>scan_max || accum_q[23:7]<scan_min;
	reg overflow = 1'b0;
	always @(posedge clk) begin
		if (|state) begin
			direction <= 1'b0;
			overflow <= 1'b0;
		end
		else begin
			if (overflow) begin
				if (~invert_direction) overflow <= 1'b0;
			end else begin
				if (invert_direction) begin
					direction <= ~direction;
					overflow <= 1'b1;
				end
			end
		end
	end
	
	reg [1:0] state = 2'h0;
	reg accum_sclr = 1'b0;
	always @(posedge clk) begin
		case (state)
			2'h0: begin
				if (sinit) begin
					state <= 1'b1;
					accum_sclr <= 1'b1;
				end
			end
			2'h1: begin
				state <= 2'h2;
			end
			2'h2: begin
				state <= 2'h3;
			end
			2'h3: begin
				state <= 2'h0;
				accum_sclr <= 1'b0;
			end
		endcase
	end

	wire [15:0] slow_clk_bundle;
	clock_division_debug_counter div_count( .clk(clk), .q(slow_clk_bundle) );
	ScanAccumulator ScanAccum( .clk(slow_clk_bundle[4]), .add(~direction), .ce(scan_enable), .bypass(accum_sclr),
										.b(increment), .q(accum_q) );
	delay_generator_no_retrigger dg1( .clk(clk), .delay(4'h5), .trigger(slow_clk_bundle[4]), .q(output_upd), .ce(scan_enable) );

endmodule
