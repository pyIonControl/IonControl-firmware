//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

`timescale 1ns / 1ps

module clock_gen (masterclk); 
   parameter PERIOD = 20; 
	output masterclk; 
	reg    masterclk; 
	initial masterclk = 1; 
	always begin 
		#(PERIOD/2.0) masterclk = ~masterclk; 
	end
endmodule
