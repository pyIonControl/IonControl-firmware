`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module adc_wrapper(
	input wire clk,
	input wire [15:0] adc_data,
	input wire adc_ready,
	input wire adc_gate,
	output reg [39:0] result = 0,
	output reg result_ready = 0,
	input wire result_ack,
	input wire [7:0] counter_id,
   output reg [7:0] counter_id_out = 0	);

	wire [39:0] q;
	reg sclr = 0;
	
	reg [15:0] adc_data_buffer = 16'h0;
	reg adc_ready_buffer = 1'h0;

	Accumulator32 accum( .clk(clk), .b(adc_data_buffer), .sclr(sclr), .ce(adc_gate & adc_ready_buffer), .q(q[27:0]) );
	Counter16 mycount( .clk(clk), .ce(adc_gate & adc_ready_buffer), .sclr(sclr), .q(q[39:28]) );	
	
	reg [1:0] state = 2'h0;
	
	always @(posedge clk) begin
		adc_data_buffer <= adc_data;
		adc_ready_buffer <= adc_ready;
		
		case (state)
			2'h0: begin
				sclr <= 1'b0;
				if (adc_gate) begin
					state <= 2'h1;
					counter_id_out <= counter_id;
				end
				if (result_ready & result_ack) result_ready <= 1'b0;
			end
			2'h1: begin
				if ((~adc_gate)) state <= 2'h2;
				if (result_ready & result_ack) result_ready <= 1'b0;
				if (q[39:28]==12'hfff) begin
					result <= q;
					result_ready <= 1'b1;
					sclr <= 1'b1;
				end else begin
					result_ready <= 1'b0;
					sclr <= 1'b0;
				end
			end
			2'h2: begin
				result <= q;
				result_ready <= 1'b1;
				state <= 2'h3;
			end
			2'h3: begin
				sclr <= 1'b1;
				state <= 2'h0;
			end
		endcase
	end


endmodule
