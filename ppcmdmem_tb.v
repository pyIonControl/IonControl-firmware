`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module ppcmdmem_tb;

	parameter MASTER_PERIOD = 4;
	// clocks
	clock_gen #(10) mclka(clka);
	clock_gen #(4) mclkb(clkb);

	// Inputs
	reg [0:0] wea;
	reg [12:0] addra;
	reg [15:0] dina;
	reg [0:0] web;
	reg [11:0] addrb;
	reg [31:0] dinb;

	// Outputs
	wire [15:0] douta;
	wire [31:0] doutb;

	// Instantiate the Unit Under Test (UUT)
	ppcmdmem uut (
		.clka(clka), 
		.wea(wea), 
		.addra(addra), 
		.dina(dina), 
		.douta(douta), 
		.clkb(clkb), 
		.web(web), 
		.addrb(addrb), 
		.dinb(dinb), 
		.doutb(doutb)
	);

	initial begin
		// Initialize Inputs
		wea = 0;
		addra = 0;
		dina = 0;
		web = 0;
		addrb = 0;
		dinb = 0;

		// Wait 100 ns for global reset to finish
		#100;
		addra = 0;
      dina = 16'h0123;
		wea = 1;
		
		#40;
		wea = 0;
		
		#20;
		addra = 1;
      dina = 16'h4567;
		wea = 1;
		
		#40;
		wea = 0;
		
		#20;
	
		// Add stimulus here

	end
      
endmodule

