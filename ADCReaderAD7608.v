`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCReaderAD7608(
		input wire clk,
		input wire [7:0] adc_enable,
		output reg [8*16-1:0] adcdata = 128'h0,
		output reg [7:0] adcready = 8'h0,
		output reg cs = 1'b1,
		output reg convst = 1'b1,
		input wire [1:0] adc_dout,
		input wire adc_busy,
		output reg sclk_enable = 1'b0
    );
	 
	 
 reg [3:0] state = 4'h0;
 reg [4*18-1:0] data1 = 72'h0;
 reg [4*18-1:0] data2 = 72'h0;
 reg [7:0] bits_to_read = 8'h0;
 
 always @(posedge clk) begin	
	case (state)
	4'h0: begin  // initiate conversion
		adcready <= 8'h0;
		convst <= 1'b0;
		state <= 4'h1;
	end
	4'h1: begin   // wait for busy signal to go high
		convst <= 1'b1;
		if (adc_busy)
			state <= 4'h2;
		else
			state <= 4'h1;
	end
	4'h2: begin   // wait for conversion done
		if (adc_busy)
			state <= 4'h2;
		else
			state <= 4'h3;
	end
	4'h3: begin  // prepare for reading of data
		bits_to_read <= 8'd72;
		cs <= 1'b0;
		sclk_enable <= 1'b1;
		state <= 4'h4;
	end
	4'h4: begin  // read data
		if (bits_to_read>8'h1) begin
			bits_to_read <= bits_to_read - 8'h1;
		end
		else begin
			state <= 4'h5;
			sclk_enable <= 1'b0;
			cs <= 1'b1;
		end
	end
	4'h5: begin  // deliver data
		adcdata[ 4*16 +: 4*16] = { data2[0*18+2 +: 16], data2[1*18+2 +: 16], data2[2*18+2 +: 16], data2[3*18+2 +: 16] };
		adcdata[ 0*16 +: 4*16] = { data1[0*18+2 +: 16], data1[1*18+2 +: 16], data1[2*18+2 +: 16], data1[3*18+2 +: 16] };
		adcready <= adc_enable;
		state <= 4'h0;
	end
	endcase
 end

always @(negedge clk) begin
	if (~cs) begin
		data1 <= { data1[4*18-2:0], adc_dout[0] };
		data2 <= { data2[4*18-2:0], adc_dout[1] };		
	end
end

endmodule
