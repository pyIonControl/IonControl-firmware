`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`unconnected_drive pull0
module picore(
	input wire clk,
	input wire update,
	input wire signed [15:0] errorsig,
	input wire [31:0] pCoeff,
	input wire [31:0] iCoeff,
	input wire enable,
	input wire sclr,
	output reg [15:0] regOut = 0,
	output reg regOutUpdate = 0,
	input wire [15:0] inputOffset,
	output wire overflow,
	output wire underflow,
	input wire [15:0] output_offset,
	input wire set_output_offset,
	input wire set_output_clk
   );

	wire [31:0] accumOut;
	wire accumUpdate;
	wire regUpdateInternal;
	wire [15:0] centeredErrorsigInternal;
	wire [33:0] pIOutInternal;
	wire int_overflow;
	wire int_underflow;
	wire internal_sclr, long_sclr;
	
	timed_monoflop tm( .clock(clk), .enable(1'b1), .pulselength(4'h3), .trigger(sclr), .q(long_sclr) );
	set_reset clr_sr( .clock(clk), .set(long_sclr), .reset(accumUpdate), .q(internal_sclr) );
	

	delay_generator dg1( .clk(clk), .delay(4'h7), .trigger(update & enable), .q(accumUpdate) );
	delay_generator dg2( .clk(clk), .delay(4'h7), .trigger(accumUpdate), .q(regUpdateInternal) );

	AddSub_16_16 inputOffsetCalc( .b(errorsig), .a( inputOffset ), .s(centeredErrorsigInternal) );
	MultAccum_limited PI( .clk(clk), .ce( (enable & accumUpdate) ), 
	              .a(centeredErrorsigInternal), .b(iCoeff[31:0]), .s(accumOut[31:0]), .sclr(internal_sclr), .overflow(int_overflow), .underflow(int_underflow),
					  .output_offset(output_offset), .set_output_offset(set_output_offset), .set_output_clk(set_output_clk) );
	MultAdd_16_24_40_40 P(   .a(centeredErrorsigInternal), .b( enable?pCoeff[31:0]:32'h0 ), .c(accumOut[31:0]), .subtract(1'b0), .p(pIOutInternal) );
	
	assign overflow = int_overflow | (pIOutInternal[32] & ~pIOutInternal[33]);
	assign underflow = int_underflow | pIOutInternal[33];

	always @(posedge clk) begin
		regOut <= overflow ? 16'hffff : ( underflow ? 16'h0 : pIOutInternal[31:16] );
		regOutUpdate <= (regUpdateInternal & enable) | (set_output_offset & set_output_clk);
	end
endmodule
`nounconnected_drive 