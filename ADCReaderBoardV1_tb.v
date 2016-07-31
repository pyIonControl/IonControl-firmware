`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCReaderBoardV1_tb;

	parameter MASTER_PERIOD = 20;
	// Inputs
	wire clk;
	clock_gen #(MASTER_PERIOD) mclk(clk);
	// Inputs
	reg [3:0] adc_enable;
	reg adc1dout;
	reg adc2dout;

	// Outputs
	wire [2:0] adc1out;
	wire [2:0] adc2out;
	wire [63:0] adcdata;
	wire [3:0] adcready;

	// Instantiate the Unit Under Test (UUT)
	ADCReaderBoardV1 uut (
		.clk(clk), 
		.adc_enable(adc_enable), 
		.adc1out(adc1out), 
		.adc1dout(adc1dout), 
		.adc2out(adc2out), 
		.adc2dout(adc2dout), 
		.adcdata(adcdata), 
		.adcready(adcready)
	);

	initial begin
		// Initialize Inputs
		adc_enable = 0;
		adc1dout = 0;
		adc2dout = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		adc_enable = 15;

	end
      
endmodule

