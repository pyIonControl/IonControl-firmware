`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCControl_tb;

	// Inputs
	wire clk;
	clock_gen #(20) mclk(clk);
	reg [31:0] update_time;
	reg [255:0] adcdata;
	reg [15:0] adcready;

	// Outputs
	wire [31:0] adc0data;
	wire [31:0] adc1data;
	wire [31:0] adc2data;
	wire [31:0] adc3data;
	wire [31:0] adc4data;
	wire [31:0] adc5data;
	wire [31:0] adc6data;
	wire [31:0] adc7data;
	wire [31:0] adc8data;
	wire [31:0] adc9data;
	wire [31:0] adcadata;
	wire [31:0] adcbdata;
	wire [31:0] adccdata;
	wire [31:0] adcddata;
	wire [31:0] adcedata;
	wire [31:0] adcfdata;

	// Instantiate the Unit Under Test (UUT)
	ADCControl uut (
		.clk(clk), 
		.update_time(update_time), 
		.adcdata(adcdata), 
		.adcready(adcready), 
		.adc0data(adc0data), 
		.adc1data(adc1data), 
		.adc2data(adc2data), 
		.adc3data(adc3data), 
		.adc4data(adc4data), 
		.adc5data(adc5data), 
		.adc6data(adc6data), 
		.adc7data(adc7data), 
		.adc8data(adc8data), 
		.adc9data(adc9data), 
		.adcadata(adcadata), 
		.adcbdata(adcbdata), 
		.adccdata(adccdata), 
		.adcddata(adcddata), 
		.adcedata(adcedata), 
		.adcfdata(adcfdata)
	);

	always begin 
		#(20) adcready = ~adcready; 
		#(80) adcready = ~adcready; 
	end

	initial begin
		// Initialize Inputs
		update_time = 0;
		adcdata = 0;
		adcready = 16'hffff;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		adcdata = { 16'h28ee, -16'h200, 16'h020, -16'h030, 16'h040, -16'h050, 16'h060, -16'h070,
						16'h080, -16'h090, 16'h0a0, -16'h0b0, 16'h0c0, -16'h0e0, 16'h0f0, -16'h010 };
	
		
	end
      
endmodule

