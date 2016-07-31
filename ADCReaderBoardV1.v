`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCReaderBoardV1(
		input wire clk,
		input wire [3:0] adc_enable,
		output wire [2:0] adc1out, 
		input wire adc1dout,
		output wire [2:0] adc2out,
		input wire adc2dout,
		output reg [4*16-1:0] adcdata = 0,
		output wire [3:0] adcready
    );

/////////////////////////////////////////////////////////////////
// ADC logic
/////////////////////////////////////////////////////////////////

reg [3:0] adcReadyInternal = 0;
assign adcready[3:0] = adc_enable & adcReadyInternal;
wire [11:0] ADCData1, ADCData2;
wire ADCDataReady1, ADCDataReady2;
reg [7:0] ADCControl1 = 0, ADCControl2 = 0;
reg ADCRead1 = 0, ADCRead2 = 0;

ADC122S101 adc1( .clk(clk), .adcs( adc1out[0] ), .adclk( adc1out[1] ), .addin( adc1out[2] ), .addout( adc1dout ), 
					  .ADCRead(ADCRead1),  .ADCControl( ADCControl1 ), .ADCData( ADCData1 ), .ADCDataReady( ADCDataReady1 ) );

ADC122S101 adc2( .clk(clk), .adcs( adc2out[0] ), .adclk( adc2out[1] ), .addin( adc2out[2] ), .addout( adc2dout ), 
					  .ADCRead(ADCRead2),  .ADCControl( ADCControl2 ), .ADCData( ADCData2 ), .ADCDataReady( ADCDataReady2 ) );


////////////////////////////////////////////////////////////////////
//  State machines reading ADCs and triggering buffer ins
reg [2:0] ADCState1 = 0;
always @ (posedge clk)
begin
	if (|adcReadyInternal[1:0]) begin
		adcReadyInternal[1:0] <= 2'h0;
	end
	else if (ADCRead1)
		ADCRead1 <= 1'b0;
	else begin
		case (ADCState1)
		default: ADCState1 <= 3'h0;
		3'h0: begin
				ADCState1 <= 3'h1;
			end
		3'h1: begin
				ADCRead1 <= 1'b1;
				ADCControl1 <= 8'h0;
				ADCState1 <= 3'h2;
			end
		3'h2:
			if (ADCDataReady1) begin
				adcdata[15:0] <= { 4'h0, ADCData1[11:0] };
				adcReadyInternal[0] <= 1'b1;
				ADCState1 <= 3'h3;
				end
		3'h3: begin
				ADCRead1 <= 1'b1;
				ADCControl1 <= 8'h8;
				ADCState1 <= 3'h4;
			end
		3'h4: if (ADCDataReady1) begin
				adcdata[31:16] <= { 4'h0, ADCData1[11:0] };
				ADCState1 <= 3'h0;
				adcReadyInternal[1] <= 1'b1;
			end	
		endcase
	end
end

////////////////////////////////////////////////////////////////////
//  State machines reading ADCs and triggering buffer ins
reg [2:0] ADCState2 = 0;
always @ (posedge clk)
begin
	if (|adcReadyInternal[3:2]) begin
		adcReadyInternal[3:2] <= 2'h0;
	end
	else if (ADCRead2)
		ADCRead2 <= 1'b0;
	else begin
		case (ADCState2)
		default: ADCState2 <= 3'h0;
		3'h0: begin
				ADCState2 <= 3'h1;
			end
		3'h1: begin
				ADCRead2 <= 1'b1;
				ADCControl2 <= 8'h0;
				ADCState2 <= 3'h2;
			end
		3'h2:
			if (ADCDataReady2) begin
				adcdata[47:32] <= { 4'h0, ADCData2[11:0] };
				adcReadyInternal[2] <= 1'b1;
				ADCState2 <= 3'h3;
				end
		3'h3: begin
				ADCRead2 <= 1'b1;
				ADCControl2 <= 8'h8;
				ADCState2 <= 3'h4;
			end
		3'h4: if (ADCDataReady2) begin
				adcdata[63:48] <= { 4'h0, ADCData2[11:0] };
				ADCState2 <= 3'h0;
				adcReadyInternal[3] <= 1'b1;
			end	
		endcase
	end
end

endmodule
