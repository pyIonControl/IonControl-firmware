`timescale 1ns / 1ps
`include "Configuration.v"
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module ADCControl(
		input wire clk,
		input wire sclr,
		input wire [16*16-1:0] adcdata,
		input wire [15:0] adcready,
		output wire [47:0] adc0data,
		output wire [47:0] adc1data,
		output wire [47:0] adc2data,
		output wire [47:0] adc3data,
		output wire [47:0] adc4data,
		output wire [47:0] adc5data,
		output wire [47:0] adc6data,
		output wire [47:0] adc7data,
		output wire [47:0] adc8data,
		output wire [47:0] adc9data,
		output wire [47:0] adcadata,
		output wire [47:0] adcbdata,
		output wire [47:0] adccdata,
		output wire [47:0] adcddata,
		output wire [47:0] adcedata,
		output wire [47:0] adcfdata
    );

/////////////////////////////////////////////////////////////////
// ADC logic
/////////////////////////////////////////////////////////////////




adcsum average0( .clk(clk), .data(adcdata[0*16 +: 16]), .data_ready(adcready[0]), .q(adc0data[31:0]), .sclr(sclr), .count(adc0data[47:32]) );
adcsum average1( .clk(clk), .data(adcdata[1*16 +: 16]), .data_ready(adcready[1]), .q(adc1data[31:0]), .sclr(sclr), .count(adc1data[47:32])  );
adcsum average2( .clk(clk), .data(adcdata[2*16 +: 16]), .data_ready(adcready[2]), .q(adc2data[31:0]), .sclr(sclr), .count(adc2data[47:32])  );
adcsum average3( .clk(clk), .data(adcdata[3*16 +: 16]), .data_ready(adcready[3]), .q(adc3data[31:0]), .sclr(sclr), .count(adc3data[47:32])  );
adcsum average4( .clk(clk), .data(adcdata[4*16 +: 16]), .data_ready(adcready[4]), .q(adc4data[31:0]), .sclr(sclr), .count(adc4data[47:32])  );
adcsum average5( .clk(clk), .data(adcdata[5*16 +: 16]), .data_ready(adcready[5]), .q(adc5data[31:0]), .sclr(sclr), .count(adc5data[47:32])  );
adcsum average6( .clk(clk), .data(adcdata[6*16 +: 16]), .data_ready(adcready[6]), .q(adc6data[31:0]), .sclr(sclr), .count(adc6data[47:32])  );
adcsum average7( .clk(clk), .data(adcdata[7*16 +: 16]), .data_ready(adcready[7]), .q(adc7data[31:0]), .sclr(sclr), .count(adc7data[47:32])  );
adcsum average8( .clk(clk), .data(adcdata[8*16 +: 16]), .data_ready(adcready[8]), .q(adc8data[31:0]), .sclr(sclr), .count(adc8data[47:32])  );
adcsum average9( .clk(clk), .data(adcdata[9*16 +: 16]), .data_ready(adcready[9]), .q(adc9data[31:0]), .sclr(sclr) , .count(adc9data[47:32]) );
adcsum averagea( .clk(clk), .data(adcdata[10*16 +: 16]), .data_ready(adcready[10]), .q(adcadata[31:0]), .sclr(sclr), .count(adcadata[47:32])  );
adcsum averageb( .clk(clk), .data(adcdata[11*16 +: 16]), .data_ready(adcready[11]), .q(adcbdata[31:0]), .sclr(sclr), .count(adcbdata[47:32])  );
adcsum averagec( .clk(clk), .data(adcdata[12*16 +: 16]), .data_ready(adcready[12]), .q(adccdata[31:0]), .sclr(sclr), .count(adccdata[47:32])  );
adcsum averaged( .clk(clk), .data(adcdata[13*16 +: 16]), .data_ready(adcready[13]), .q(adcddata[31:0]), .sclr(sclr), .count(adcddata[47:32])  );
adcsum averagee( .clk(clk), .data(adcdata[14*16 +: 16]), .data_ready(adcready[14]), .q(adcedata[31:0]), .sclr(sclr), .count(adcedata[47:32])  );
adcsum averagef( .clk(clk), .data(adcdata[15*16 +: 16]), .data_ready(adcready[15]), .q(adcfdata[31:0]), .sclr(sclr), .count(adcfdata[47:32])  );



endmodule
