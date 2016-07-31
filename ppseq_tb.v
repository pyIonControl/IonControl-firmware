`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module ppseq_tb;

	parameter MASTER_PERIOD = 4;
	// clocks
	wire really_fast_clk;
	clock_gen #(20) mclka(clka);
	clock_gen #(20) mclkb(clkb);
	clock_gen #(10) mfastclk(fastclk);
	clock_gen #(5) ffastclk(really_fast_clk);

	// Inputs
	wire clk_i = clka;
	wire usb_clk = clka;
	reg reset_i;
	reg start_i;
	reg stop_i;
	reg [7:0] count_i;
	reg dacready_i;
	reg [3:0] lvttl_i;
	reg fifo_full;
	reg [63:0] data_fifo_data;
	reg data_fifo_empty;
	reg [63:0] pp_ram_data;
	reg pp_ram_valid;
	reg [7:0] trigger_in;
	reg [15:0] write_active;

	// Outputs
	wire pp_active_o;
	wire [11:0] pp_addr_o;
	wire pp_we_o;
	wire [63:0] pp_dout_o;
	wire [11:0] cmd_addr_o;
	wire [63:0] ddsdata_o;
	wire [7:0] ddscmd_o;
	wire ddscmd_trig_o;
	wire [31:0] shutter_o;
	wire [31:0] trigger_o;
	wire [63:0] fifo_data;
	wire fifo_data_ready;
	wire data_fifo_read;
	wire pp_ram_read;
	wire pp_ram_set_address;
	wire [31:0] pp_ram_address;
	wire [3:0] state_debug;
	wire [31:0] counter_mask_out;

	//  Command Memory
	// Inputs
	reg [0:0] cmdwea;
	reg [12:0] cmdaddra;
	reg [15:0] cmddina;
	reg [0:0] cmdweb;
	reg [31:0] cmddinb;

	// Outputs
	wire [15:0] cmddouta;
	wire [31:0] cmd_in;

	// Instantiate the Unit Under Test (UUT)
	ppcmdmem ppcmdmemuut (
		.clka(fastclk), 
		.wea(cmdwea), 
		.addra(cmdaddra), 
		.dina(cmddina), 
		.douta(cmddouta), 
		.clkb(fastclk), 
		.web(cmdweb), 
		.addrb(cmd_addr_o), 
		.dinb(cmddinb), 
		.doutb(cmd_in)
	);
	
	
	// Data Memory
	// Inputs
	reg [0:0] wea;
	reg [13:0] addra;
	reg [15:0] dina;

	// Outputs
	wire [15:0] douta;
	wire [63:0] pp_din_i;

	// Instantiate the Unit Under Test (UUT)
	ppmem6 ppmem6uut (
		.clka(fastclk), 
		.wea(wea), 
		.addra(addra), 
		.dina(dina), 
		.douta(douta), 
		.clkb(fastclk), 
		.web(pp_we_o), 
		.addrb(pp_addr_o), 
		.dinb(pp_dout_o), 
		.doutb(pp_din_i)
	);




	// Instantiate the Unit Under Test (UUT)
	ppseq uut (
	   .fast_clk(really_fast_clk),
		.memory_clk(fastclk),
		.clk_i(clka), 
		.usb_clk(usb_clk), 
		.reset_i(reset_i), 
		.start_i(start_i), 
		.stop_i(stop_i), 
		.pp_active_o(pp_active_o), 
		.pp_addr_o(pp_addr_o), 
		.pp_din_i(pp_din_i), 
		.pp_we_o(pp_we_o), 
		.pp_dout_o(pp_dout_o), 
		.count_i(count_i), 
		.cmd_addr_o(cmd_addr_o), 
		.cmd_in(cmd_in), 
		.ddsdata_o(ddsdata_o), 
		.ddscmd_o(ddscmd_o), 
		.ddscmd_trig_o(ddscmd_trig_o), 
		.shutter_o(shutter_o), 
		.PC_o(PC_o), 
		.write_active( write_active ),
		.trigger_o(trigger_o), 
		.fifo_data(fifo_data), 
		.fifo_data_ready(fifo_data_ready), 
		.fifo_full(fifo_full), 
		.data_fifo_read(data_fifo_read), 
		.data_fifo_data(data_fifo_data), 
		.data_fifo_empty(data_fifo_empty), 
		.pp_ram_data(pp_ram_data), 
		.pp_ram_read(pp_ram_read), 
		.pp_ram_set_address(pp_ram_set_address), 
		.pp_ram_address(pp_ram_address), 
		.pp_ram_valid(pp_ram_valid), 
		.state_debug(state_debug), 
		.counter_mask_out(counter_mask_out), 
		.trigger_in(trigger_in)
	);

	initial begin
		// Initialize Inputs
		reset_i = 0;
		start_i = 0;
		stop_i = 0;
		count_i = 0;
		dacready_i = 0;
		write_active = 0;
		lvttl_i = 0;
		fifo_full = 0;
		data_fifo_data = 0;
		data_fifo_empty = 0;
		pp_ram_data = 0;
		pp_ram_valid = 0;
		trigger_in = 0;

		// Command
		cmdwea = 0;
		cmdaddra = 0;
		cmddina = 0;
		cmdweb = 0;
		cmddinb = 0;

		// Data
		wea = 0;
		addra = 0;
		dina = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		start_i = 1;
		#20;
		start_i = 0;
		
		#3000;
		data_fifo_empty = 1;

	end
      
endmodule

