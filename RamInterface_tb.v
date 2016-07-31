`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


module RamInterface_tb;

	parameter MASTER_PERIOD = 5;
	// Inputs
	wire clk1;
	wire pp_clk;
	clock_gen #(MASTER_PERIOD) mclk(clk1);
	clock_gen #(MASTER_PERIOD*2) ppclk_gen(pp_clk);

	// Inputs
	reg pipe_clk;
	reg [15:0] host_in_data;
	reg host_in_write;
	reg host_out_read;
	reg host_write_reset;
	reg host_read_reset;
	reg [31:0] host_address;
	reg host_set_write_address;
	reg host_set_read_address;
	reg ppseq_out_read;
	reg [29:0] ppseq_address;
	reg ppseq_set_address;
	reg ppseq_read_enable;
	reg system_reset;

	// Outputs
	wire [12:0] mcb3_dram_a;
	wire [2:0] mcb3_dram_ba;
	wire mcb3_dram_ras_n;
	wire mcb3_dram_cas_n;
	wire mcb3_dram_we_n;
	wire mcb3_dram_odt;
	wire mcb3_dram_cke;
	wire mcb3_dram_dm;
	wire mcb3_dram_udm;
	wire mcb3_dram_ck;
	wire mcb3_dram_ck_n;
	wire mcb3_dram_cs_n;
	wire host_in_fifo_full;
	wire [15:0] host_out_data;
	wire [31:0] ppseq_out_data;
	wire ppseq_valid;

	// Bidirs
	wire [15:0] mcb3_dram_dq;
	wire mcb3_dram_udqs;
	wire mcb3_dram_udqs_n;
	wire mcb3_rzq;
	wire mcb3_zio;
	wire mcb3_dram_dqs;
	wire mcb3_dram_dqs_n;
	
	// Instantiate memory simulator
	ddr2 memorySim(
		.ck(mcb3_dram_ck),
		.ck_n(mcb3_dram_ck_n),
		.cke(mcb3_dram_cke),
		.cs_n(mcb3_dram_cs_n),
		.ras_n(mcb3_dram_ras_n),
		.cas_n(mcb3_dram_cas_n),
		.we_n(mcb3_dram_we_n),
		.dm_rdqs(mcb3_dram_dm),
		.ba(mcb3_dram_ba),
		.addr(mcb3_dram_a),
		.dq(mcb3_dram_dq),
		.dqs(mcb3_dram_dqs),
		.dqs_n(mcb3_dram_dqs_n),
		.rdqs_n(mcb3_dram_udqs_n),
		.odt(mcb3_dram_odt)
);
	

	// Instantiate the Unit Under Test (UUT)
	RamInterface uut (
		.clk1(clk1), 
		.mcb3_dram_dq(mcb3_dram_dq), 
		.mcb3_dram_a(mcb3_dram_a), 
		.mcb3_dram_ba(mcb3_dram_ba), 
		.mcb3_dram_ras_n(mcb3_dram_ras_n), 
		.mcb3_dram_cas_n(mcb3_dram_cas_n), 
		.mcb3_dram_we_n(mcb3_dram_we_n), 
		.mcb3_dram_odt(mcb3_dram_odt), 
		.mcb3_dram_cke(mcb3_dram_cke), 
		.mcb3_dram_dm(mcb3_dram_dm), 
		.mcb3_dram_udqs(mcb3_dram_udqs), 
		.mcb3_dram_udqs_n(mcb3_dram_udqs_n), 
		.mcb3_rzq(mcb3_rzq), 
		.mcb3_zio(mcb3_zio), 
		.mcb3_dram_udm(mcb3_dram_udm), 
		.mcb3_dram_dqs(mcb3_dram_dqs), 
		.mcb3_dram_dqs_n(mcb3_dram_dqs_n), 
		.mcb3_dram_ck(mcb3_dram_ck), 
		.mcb3_dram_ck_n(mcb3_dram_ck_n), 
		.mcb3_dram_cs_n(mcb3_dram_cs_n), 
		.pipe_clk(pipe_clk), 
		.host_in_data(host_in_data), 
		.host_in_write(host_in_write), 
		.host_in_fifo_full(host_in_fifo_full), 
		.host_out_data(host_out_data), 
		.host_out_read(host_out_read), 
		.host_write_reset(host_write_reset), 
		.host_read_reset(host_read_reset), 
		.host_address(host_address), 
		.host_set_write_address(host_set_write_address), 
		.host_set_read_address(host_set_read_address), 
		.pp_clk(pp_clk), 
		.ppseq_out_data(ppseq_out_data), 
		.ppseq_out_read(ppseq_out_read), 
		.ppseq_address(ppseq_address), 
		.ppseq_set_address(ppseq_set_address), 
		.ppseq_valid(ppseq_valid), 
		.ppseq_read_enable(ppseq_read_enable), 
		.system_reset(system_reset)
	);

	initial begin
		// Initialize Inputs
		pipe_clk = 0;
		host_in_data = 0;
		host_in_write = 0;
		host_out_read = 0;
		host_write_reset = 0;
		host_read_reset = 0;
		host_address = 0;
		host_set_write_address = 0;
		host_set_read_address = 0;
		ppseq_out_read = 0;
		ppseq_address = 0;
		ppseq_set_address = 0;
		ppseq_read_enable = 0;
		system_reset = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here
		ppseq_read_enable = 1;
		
		#1000;
		ppseq_set_address = 1;
		#20;
		ppseq_set_address = 0;


	end
      
endmodule

