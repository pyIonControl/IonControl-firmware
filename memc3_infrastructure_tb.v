`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module memc3_infrastructure_tb;

	wire sys_clk_p;
	clock_gen #(10) mclk(sys_clk_p);

	parameter C3_MEMCLK_PERIOD          = 3200;      
	parameter C3_RST_ACT_LOW            = 0;    
	parameter C3_INPUT_CLK_TYPE         = "DIFFERENTIAL";
	
	// Inputs
	reg sys_clk;
	reg sys_rst_n;

	// Outputs
	wire clk0;
	wire rst0;
	wire async_rst;
	wire sysclk_2x;
	wire sysclk_2x_180;
	wire mcb_drp_clk;
	wire pll_ce_0;
	wire pll_ce_90;
	wire pll_lock;

	// Instantiate the Unit Under Test (UUT)
	memc3_infrastructure #
	(
   .C_MEMCLK_PERIOD                  (C3_MEMCLK_PERIOD),
   .C_RST_ACT_LOW                    (C3_RST_ACT_LOW),
   .C_INPUT_CLK_TYPE                 (C3_INPUT_CLK_TYPE) )
	uut (
		.sys_clk_p(sys_clk_p), 
		.sys_clk(sys_clk), 
		.sys_rst_n(sys_rst_n), 
		.clk0(clk0), 
		.rst0(rst0), 
		.async_rst(async_rst), 
		.sysclk_2x(sysclk_2x), 
		.sysclk_2x_180(sysclk_2x_180), 
		.mcb_drp_clk(mcb_drp_clk), 
		.pll_ce_0(pll_ce_0), 
		.pll_ce_90(pll_ce_90), 
		.pll_lock(pll_lock)
	);

	initial begin
		// Initialize Inputs
		sys_clk = 0;
		sys_rst_n = 0;

		// Wait 100 ns for global reset to finish
		#100;
      sys_rst_n = 1;
		#100;
		sys_rst_n = 0;
		// Add stimulus here

	end
      
endmodule

