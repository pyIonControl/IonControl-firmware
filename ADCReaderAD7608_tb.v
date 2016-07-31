`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCReaderAD7608_tb;

	wire clk;
	clock_gen #(20) mclk(clk);
	// Inputs
	reg [7:0] adc_enable;
	reg [1:0] adc_dout;
	reg adc_busy;

	// Outputs
	wire [127:0] adcdata;
	wire [7:0] adcready;
	wire cs;
	wire convst;
	wire sclk_enable;
	wire ADC_SCLK;

	// Instantiate the Unit Under Test (UUT)
	ODDR2 oddr_adc(.D0(1'b1), .D1(1'b0), .C0(clk), .C1(~clk), .CE(sclk_enable), .Q(ADC_SCLK), .R(1'b0), .S(1'b0) );
	ADCReaderAD7608 uut (
		.clk(clk), 
		.adc_enable(adc_enable), 
		.adcdata(adcdata), 
		.adcready(adcready), 
		.cs(cs), 
		.convst(convst), 
		.adc_dout(adc_dout), 
		.adc_busy(adc_busy), 
		.sclk_enable(sclk_enable)
	);

	reg lastconvst = 1'b0;
	reg [4:0] delay_count = 4'h0;
	reg [1:0] state = 2'h0;
	always @(posedge clk) begin
		lastconvst <= convst;
		case (state)
			2'h0: if (lastconvst ^ convst) begin
				delay_count <= 4'hf;
				state <= 2'h1;
				adc_busy <= 1'b1;
			end else begin
				adc_busy <= 1'b0;
			end
			2'h1: if (|delay_count) begin
				delay_count <= delay_count - 4'h1;
			end else begin
				state <= 2'h0;
			end
		endcase
	end

	initial begin
		// Initialize Inputs
		adc_enable = 0;
		adc_dout = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

