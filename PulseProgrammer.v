`timescale 1ns / 1ps
`include "Configuration.v"

//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module PulseProgrammer #(
	parameter C3_NUM_DQ_PINS            = 16,       
	parameter C3_MEM_ADDR_WIDTH         = 13,       
	parameter C3_MEM_BANKADDR_WIDTH     = 3        
	)
	(
	input wire fast_clk,
	input wire ramclk,
	input wire memoryclk,
	input wire clk,
	input wire sync_locked,
	
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,

	output wire			hi_muxsel,
	output wire			i2c_sda,
	output wire			i2c_scl,
	
	//RAM interface
	inout  wire [C3_NUM_DQ_PINS-1:0]         mcb3_dram_dq,
	output wire [C3_MEM_ADDR_WIDTH-1:0]      mcb3_dram_a,
	output wire [C3_MEM_BANKADDR_WIDTH-1:0]  mcb3_dram_ba,
	output wire                              mcb3_dram_ras_n,
	output wire                              mcb3_dram_cas_n,
	output wire                              mcb3_dram_we_n,
	output wire                              mcb3_dram_odt,
	output wire                              mcb3_dram_cke,
	output wire                              mcb3_dram_dm,
	inout  wire                              mcb3_dram_udqs,
	inout  wire                              mcb3_dram_udqs_n,
	inout  wire                              mcb3_rzq,
	inout  wire                              mcb3_zio,
	output wire                              mcb3_dram_udm,
	inout  wire                              mcb3_dram_dqs,
	inout  wire                              mcb3_dram_dqs_n,
	output wire                              mcb3_dram_ck,
	output wire                              mcb3_dram_ck_n,
	output wire                              mcb3_dram_cs_n,
	//
	output reg [63:0] trigger,
	output reg [63:0] shutter,
	//
	output wire [63:0] DDSData,
	output wire [3:0] DDSCmd,
	output wire [7:0] DDSAddress,
	output reg [15:0] DDSReset,
	output reg [15:0] DDSResetMask,
	input wire [15:0] write_active,
	output wire dds_cmd_trig,
	output wire dac_cmd_trig,
	output wire serial_cmd_trig,
	output wire parameter_trig,
	input wire [63:0] auxAnalyzerData,
	//
	input wire [16*16-1:0] ADCData,
	input wire [15:0] ADCReady,
	//
	input wire [15:0] count_in,
	input wire [7:0] trigger_in,
	input wire [7:0] level_in,
	//
	output wire pp_active,
	output wire [3:0] state_debug,
	//
	output wire [15:0] extended_address,
	output wire [63:0] extended_data,
	output wire extended_update,
	output wire usb_clk,
	//
	input wire [31:0] externalStatus,
	output wire pp_update,
	output wire extended_wire_apply_immediately
    );


	// OK required assigns
	assign hi_muxsel = 1'b0;
	assign i2c_sda = 1'bz;
	assign i2c_scl = 1'bz;

	/////////////////////////////////////////////////////////////////////////
	// Global defs
	/////////////////////////////////////////////////////////////////////////
	wire		ti_clk;
	assign usb_clk = ti_clk;

	wire [15:0] extended_wire_data;
	wire extended_wire_write;

	//////////////////////////////////////////////////////////////////////////////////
	// Global wires
	wire [30:0]		ok1;
	wire [16:0]		ok2;
	wire [15:0]		WireIn00;  //Extra WireIn03 CWC 07112012 Extra WireIn04 and WireIn05 CWC 08132012, 06 and 07 RMN 2014-06-24
	wire [15:0]		TrigIn40, TrigIn41;
	wire [63:0]    HostTriggerMask, HostShutter;
	reg [63:0] HostTrigger = 0;
	wire [31:0]			counter_mask;  // from pp to be traced by logic analyzer
	wire				power_on_reset, host_reset, reset, ti_reset, host_trigger_activate;
	wire [8*64-1:0]    output_delay;
	wire [63:0] pp_shutter_delayed;
	wire [15:0] HostDDSReset;
	wire [15:0] HostDDSResetMask;
	wire [63:0] auxAnalyzerEnableMask;

	// Power on reset
	SRL16 #(.INIT(16'hFFFF)) reset_sr (.D(1'b0), .CLK(clk), .Q(power_on_reset),
									   .A0(1'b1), .A1(1'b1), .A2(1'b1), .A3(1'b1));

	assign	reset = power_on_reset | host_reset;
	monoflop ti_reset_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[0]), .q(ti_reset) );
	monoflop host_reset_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn40[0]), .q(host_reset) );
	monoflop host_trigger_activate_mf(.clock(clk), .enable(1'b1), .trigger(TrigIn41[2]), .q(host_trigger_activate) );
	
	always @(posedge clk) begin
		HostTrigger[63:0] = host_trigger_activate ? HostTriggerMask[63:0] : 64'h0;
	end

	genvar i;
	generate
	for (i=0; i<49; i=i+1) begin : loop_gen_block
		shift_ram shift( .clk(fast_clk), .d(pp_shutter[i]), .a( output_delay[i*8 +: 8] ), .q(pp_shutter_delayed[i]) );
	end
	endgenerate

	assign pp_shutter_delayed[63:49] = pp_shutter[63:49];

	always @(posedge fast_clk) begin
		trigger <= pp_active ? pp_trigger : HostTrigger;
		shutter <= pp_active ? pp_shutter_delayed : HostShutter;
		DDSReset <= pp_active ? {15'h0, |pp_trigger[31:24]} : HostDDSReset;
		DDSResetMask <= pp_active ? { pp_trigger[39:24]} : HostDDSResetMask;
	end

	// AD9912&AD9910 DDS boards
	wire [63:0] HostDDSData;
	wire [15:0] HostDDSCmd;
	wire host_command_trig;
	wire  host_ddstrig, host_dactrig;
	assign DDSData = pp_active ? pp_ddsdata : HostDDSData;
	assign DDSCmd = pp_active ? { pp_ddscmd[3:0]} : { HostDDSCmd[3:0] };
	assign DDSAddress = pp_active ? pp_ddscmd[11:4] : HostDDSCmd[11:4];
	
	monoflop host_ddstrig_mf(.clock(clk), .enable(HostDDSCmd[15]), .trigger(host_command_trig), .q(host_ddstrig) );
	monoflop host_dactrig_mf(.clock(clk), .enable(HostDDSCmd[14]), .trigger(host_command_trig), .q(host_dactrig) );
	assign dds_cmd_trig = pp_active ? pp_ddstrig : host_ddstrig;
	assign dac_cmd_trig = pp_active ? pp_dactrig : host_dactrig;

	/////////////////////////////////////////////////////////////////////////
	// Data Input FIFO
	//
	/////////////////////////////////////////////////////////////////////////
	wire [15:0]		DataPipeInData;
	wire			   DataPipeInWrite;
	wire [63:0]    DataFIFOData;
	wire				DataFIFORead, DataFIFOEmpty, DataPipeInFull;
	wire [12:0]    DataPipeWrCount;
	monoflop resetDataInputFIFO_mf(.clock(clk), .enable(1'b1), .trigger(TrigIn41[3]), .q(resetDataInputFIFO) );
	data_fifo my_data_fifo( .rst(resetDataInputFIFO), .wr_clk(ti_clk), .rd_clk(clk), .din(DataPipeInData), .wr_en(DataPipeInWrite), 
							      .rd_en(DataFIFORead), .dout({DataFIFOData[15:0],DataFIFOData[31:16],DataFIFOData[47:32],DataFIFOData[63:48]}), 
									.full(DataPipeInFull), .empty(DataFIFOEmpty), .wr_data_count(DataPipeWrCount) );

	/////////////////////////////////////////////////////////////////////////
	// Data output FIFO from FPGA to computer
	// The data output fifo is shared between the pulse programmer and the
	// continuously running counter and ADC. Each has its own small fifo, then these fifos are combined.
	/////////////////////////////////////////////////////////////////////////

	// output wires of the second level fifo
	wire        pipe_out_read;
	wire [15:0] pipe_out_data;
	wire [12:0] pipe_out_available;
	wire fifo_empty;

	// input wires for the first level pp fifo
	wire [63:0] fifo_din ;
	wire fifo_wr_en;
	wire fifo_full;
	
	// input wires for the first level ADC and counter fifo
	wire [63:0] adc_fifo_din;
	wire adc_fifo_wr_en, adc_fifo_full;
	
	wire resetDataOutputFifo;
	wire outputfifoFull;
	wire outputfifoOverrun;
	wire outputfifoOverrunClear;
	monoflop resetDataOutputFIFO_mf(.clock(clk), .enable(1'b1), .trigger(TrigIn41[4]), .q(resetDataOutputFifo) );
	// fifo multiplexer, copies data from the two first level fifos into the second level fifo
	FifoMultiplexer fifo_multiplexer( .rst(resetDataOutputFifo), .wr_clk(clk), .rd_clk(ti_clk), 
												 .din_1({fifo_din[15:0], fifo_din[31:16], fifo_din[47:32], fifo_din[63:48]}), .wr_en_1(fifo_wr_en), .full_1(fifo_full),
												 .din_2({adc_fifo_din[15:0], adc_fifo_din[31:16], adc_fifo_din[47:32], adc_fifo_din[63:48]}), .wr_en_2(adc_fifo_wr_en), .full_2(adc_fifo_full),
												 .dout(pipe_out_data), .rd_en(pipe_out_read), .empty(fifo_empty), .rd_data_count(pipe_out_available),
												 .full(outputfifoFull) );
												 
	monoflop outputfifoOverrunClear_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[9]), .q(outputfifoOverrunClear) );
	set_reset fifoOverrunFF( .clock(clk), .set(outputfifoFull | adc_fifo_full), .reset(outputfifoOverrunClear), .q(outputfifoOverrun) );
												 
	/////////////////////////////////////////////////////////////////////////
	// Wires for RAM access from pp
	/////////////////////////////////////////////////////////////////////////
	wire [63:0] pp_ram_data;
	wire pp_ram_valid, pp_ram_set_address, pp_ram_read;
	wire [31:0] pp_ram_address;
												 

	////////r/////////////////////////////////////////////////////////////////
	// PP memory
	// 
	// Memory is 32bits wide, 4000 deep // UPDATED to 64 bits wide RN 2014-06-30
	// Pipes connect it to the FPGA
	/////////////////////////////////////////////////////////////////////////
	wire [15:0]		pp_addr, pp_cmd_addr;
	reg  [15:0]		host_addr;
	reg  [15:0]    cmd_host_addr;
	wire [63:0]		pp_dout, pp_din;
	wire [31:0]    pp_cmd_dout;
	wire			   pp_web, host_wea;

	// Host read and write wires
	wire [15:0]		PipeInData, PipeOutData, CmdPipeInData, CmdPipeOutData;
	wire				PipeInWrite, PipeOutRead, set_host_addr, CmdPipeInWrite, CmdPipeOutRead, set_cmd_host_addr;

	monoflop set_host_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[1]), .q(set_host_addr) );
	monoflop cmd_set_host_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[10]), .q(set_cmd_host_addr) );
	  
	always @(posedge ti_clk)
		if (ti_reset) begin
			host_addr <= 14'b0;
			cmd_host_addr <= 13'h0;
		end
		else begin
			if (set_host_addr) begin
				host_addr <= WireIn00[13:0];
			end
			else 
				if ( PipeOutRead | PipeInWrite ) begin
					host_addr <= host_addr + 14'h1;
				end
			if (set_cmd_host_addr) begin
				cmd_host_addr[15:0] <= WireIn00[15:0];
			end
			else 
				if ( CmdPipeOutRead | CmdPipeInWrite ) begin
					cmd_host_addr[15:0] <= cmd_host_addr[15:0] + 1'h1;
				end
		end
			
	// Data Memory: port a is connected to computer, port b connected tot pulse programmer
	ppmem6 ppmem6(.addra(host_addr), .addrb(pp_addr), .clka(ti_clk), .clkb(memoryclk), 
				.dina(PipeInData), .dinb(pp_din), .douta(PipeOutData), .doutb(pp_dout),
				.wea(PipeInWrite), .web(pp_web) );

	// Command Memory: port a is connected to computer, port b connected tot pulse programmer			
	ppcmdmem ppcmdmem(.addra(cmd_host_addr), .addrb(pp_cmd_addr), .clka(ti_clk), .clkb(memoryclk), 
				.dina(CmdPipeInData), .dinb(32'h0), .douta(CmdPipeOutData), .doutb(pp_cmd_dout),
				.wea(CmdPipeInWrite), .web(1'b0));

	/////////////////////////////////////////////////////////////////////////
	// Pulse Programmer
	//
	// 
	/////////////////////////////////////////////////////////////////////////
	wire			pp_start_trig = TrigIn40[2];
	wire			pp_stop_trig = TrigIn40[3];
	wire			pp_interrupt = TrigIn40[14];
	

	wire [63:0]		pp_shutter; // changed to 32 bits //Change # of shutters from 4 to 12 CWC 08132012
										// 8MSB, routed to rf switches, 24LSB routed to output
	wire [63:0]    pp_trigger; // trigger lines will give a one clock cycle trigger out
	wire [63:0]		pp_ddsdata;
	wire [11:0]		pp_ddscmd;
	wire 			   pp_ddstrig, pp_dactrig;


	wire pp_debug;
	wire timestamp_counter_reset;
	wire [39:0] tdc_count;
	monoflop timestamp_reset_mf( .clock(clk), .trigger(TrigIn40[15]), .enable(1'b1), .q(timestamp_counter_reset) );
	ppseq ppseq(.fast_clk(fast_clk), .memory_clk(memoryclk), .clk_i(clk), .usb_clk(ti_clk), .reset_i(reset), .start_i(pp_start_trig), .stop_i(pp_stop_trig), .pp_active_o(pp_active),
				.pp_interrupt(pp_interrupt),
				.pp_addr_o(pp_addr), .pp_din_i(pp_dout), .pp_we_o(pp_web), .pp_dout_o(pp_din), 
				.cmd_addr_o(pp_cmd_addr), .cmd_in(pp_cmd_dout),
				.count_i(count_in), .ddsdata_o(pp_ddsdata), .ddscmd_o(pp_ddscmd), .ddscmd_trig_o(pp_ddstrig), .daccmd_trig_o(pp_dactrig),
				.serialcmd_trig_o(serial_cmd_trig), .parameter_trig_o(parameter_trig),
				.write_active(write_active), .shutter_o(pp_shutter), .trigger_o(pp_trigger),
				.fifo_data(fifo_din), .fifo_data_ready(fifo_wr_en), .fifo_full(fifo_full), .fifo_rst(resetDataOutputFifo),
				.data_fifo_read(DataFIFORead), .data_fifo_data(DataFIFOData), .data_fifo_empty(DataFIFOEmpty),
				.pp_ram_data(pp_ram_data), .pp_ram_read(pp_ram_read), .pp_ram_set_address(pp_ram_set_address), .pp_ram_address(pp_ram_address), .pp_ram_valid(pp_ram_valid),
				.state_debug(state_debug), .counter_mask_out( counter_mask ), .trigger_in({trigger_in}), .level_in(level_in), .adc_data(ADCData), .adc_update(ADCReady),
				.timestamp_counter_reset(timestamp_counter_reset), .tdc_count(tdc_count), .pp_update(pp_update), .staticShutter(HostShutter) );      // Data FIFO input


	////////////////////////////////////////////////////////////////////////////
	// Dedicated counters and ADC inputs
	//
	///////////////////////////////////////////////////////////////////////////
	wire [15:0] dedicated_countermask;
	wire [15:0] adc_enable;
	wire [47:0] dedicated_integration;
	wire dedicated_integration_update;
	wire [15:0] adc1data, adc2data, adc3data, adc4data;
	wire adc1ready, adc2ready, adc3ready, adc4ready;
	
	DedicatedCounterADC counter_adc( .clk(clk), .count_input( count_in ), .count_enable( dedicated_countermask ), .adc_enable(adc_enable), 
												.data_out(adc_fifo_din), .data_available( adc_fifo_wr_en ), .fifo_full( adc_fifo_full ),
												.update_time(dedicated_integration),
												.adcdata(ADCData), .adcready(ADCReady), .tdc_count(tdc_count),
												.integration_update(dedicated_integration_update) );

	///////////////////////////////////////////////////////////////////////////
	// Logic Analyzer
	///////////////////////////////////////////////////////////////////////////
	wire [15:0] logic_analyzer_control;
	wire [15:0] logic_analyzer_status;
	wire [15:0] LogicAnalyzerData;
	wire LogicAnalyzerRead;
	logic_analyzer_wrapper logic_analyzer_wrapp_inst( .clk(clk),
					  .ti_clk(ti_clk),
					  .control(logic_analyzer_control), 
					  .triggers(TrigIn40[12:10]),
					  .status_data(logic_analyzer_status),
					  .LogicAnalyzerData(LogicAnalyzerData),
					  .LogicAnalyzerRead(LogicAnalyzerRead),
					  .data_in( shutter[63:0] ),
					  .trigger_data_in({ pp_ram_set_address, pp_trigger[62:0]} ),     // pp_ram_set_address
					  .aux_data_in(auxAnalyzerEnableMask & {auxAnalyzerData[59:0], pp_ram_valid, DataFIFOEmpty, fifo_full, dds_write_done } ),   // pp_ram_valid,
					  .gate_data_in( counter_mask ),
					  .pp_active(pp_active)
							);

	/////////////////////////////////////////////////////////////////////////
	// OK interface
	okHost okHI(.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa), .ti_clk(ti_clk), .ok1(ok1), .ok2(ok2));

	// Config interface
	wire [31:0] RamAddress;
	okWireIn ep00(.ok1(ok1), .ep_addr(8'h00), .ep_dataout(WireIn00)); // { 12'host_write_address }
	okWireIn ep01(.ok1(ok1), .ep_addr(8'h01), .ep_dataout(RamAddress[15:0])); 
	okWireIn ep02(.ok1(ok1), .ep_addr(8'h02), .ep_dataout(RamAddress[31:16])); 
	//okWireIn ep03(.ok1(ok1), .ep_addr(8'h03), .ep_dataout(HostDDSCmd[11:0] )); // { 8' test_in, 8' dds_data MSB }
	okWireIn ep0d(.ok1(ok1), .ep_addr(8'h0d), .ep_dataout(logic_analyzer_control[15:0]) );
	okWireIn ep04(.ok1(ok1), .ep_addr(8'h04), .ep_dataout(HostDDSResetMask[15:0]) );
		
	// Triggers
	okTriggerIn ep40 (.ok1(ok1),.ep_addr(8'h40), .ep_clk(clk), .ep_trigger(TrigIn40)); //{ host_dactrig, pp_stop_trig, pp_start_trig, host_ddstrig, host_reset}
	//{ LogicAnalyzerReset, LogicAnalyzerOverrunAck, outputfifoOverrunClear, memory_reset, ram_set_read_addr, ram_set_write_addr, ram_read_reset,
	//                       ram_write_reset, resetDataInputFIFO, activate_triggers, set_host_addr, ti_reset }
	okTriggerIn ep41 (.ok1(ok1),.ep_addr(8'h41), .ep_clk(clk), .ep_trigger(TrigIn41)); 
	okTriggerIn ep42 (.ok1(ok1),.ep_addr(8'h42), .ep_clk(clk), .ep_trigger(HostDDSReset));   // dds Reset
		
	//WireOR
	wire [17*17-1:0]  ok2x;  
	okWireOR # (.N(17)) wireOR (ok2, ok2x);

	// Triggers Out
	wire host_in_fifo_full;
	okTriggerOut trigOut60 (.ok1(ok1), .ok2(ok2x[ 0*17 +: 17 ]), .ep_addr(8'h60), .ep_clk(clk), .ep_trigger({13'h0,host_in_fifo_full,DataPipeInFull,outputfifoFull}));

	// Input pipe. Internal code has to read fast enough not to overflow
	okPipeIn  ep80 (.ok1(ok1), .ok2(ok2x[ 1*17 +: 17 ]),.ep_addr(8'h80), .ep_write(PipeInWrite), .ep_dataout(PipeInData));

	// Output pipe. Internal code has to feed it fast enough for the fifo not to starve on readout
	okPipeOut epa0 (.ok1(ok1), .ok2(ok2x[ 2*17 +: 17 ]), .ep_addr(8'hA0), .ep_read(PipeOutRead), .ep_datain(PipeOutData));
	
	// Logic Analyzer Pipe
	okPipeOut epa1 (.ok1(ok1), .ok2(ok2x[ 3*17 +: 17 ]), .ep_addr(8'hA1), .ep_read(LogicAnalyzerRead), .ep_datain(LogicAnalyzerData));

	// Check Wires
	okWireOut FIFOSizeWire(.ok1(ok1), .ok2(ok2x[ 4*17 +: 17 ]), .ep_addr(8'h25), .ep_datain({fifo_empty, outputfifoOverrun, 1'h0, pipe_out_available[12:0]}));
	okWireOut wire25(.ok1(ok1), .ok2(ok2x[ 5*17 +: 17 ]), .ep_addr(8'h26), .ep_datain({3'h0, DataPipeWrCount[12:0]}));  
	okWireOut logicAnalyzerWire(.ok1(ok1), .ok2(ok2x[ 6*17 +: 17 ]), .ep_addr(8'h27), .ep_datain(logic_analyzer_status));
	okWireOut ExternalStatusWire1( .ok1(ok1), .ok2(ok2x[ 7*17 +: 17]), .ep_addr(8'h30), .ep_datain( externalStatus[15:0] ) );
	okWireOut ExternalStatusWire2( .ok1(ok1), .ok2(ok2x[ 8*17 +: 17]), .ep_addr(8'h31), .ep_datain( externalStatus[31:16] ) );
	
	// DataPipe used from the sequencer to send results back to the computer
	okPipeOut  DataPipeOut(.ok1(ok1), .ok2(ok2x[ 9*17 +: 17 ]), .ep_addr(8'ha2), .ep_read(pipe_out_read), .ep_datain(pipe_out_data));
	
	// Input pipe for data stream buffer, used to supply serial data. Internal code has to read fast enough not to overflow
	okPipeIn  DataPipeIn(.ok1(ok1), .ok2(ok2x[ 10*17 +: 17 ]),.ep_addr(8'h81), .ep_write(DataPipeInWrite), .ep_dataout(DataPipeInData));
	
	// Ram access Pipes
	wire [15:0] ram_out_data, ram_in_data;
	wire ram_out_read, ram_in_write;
	okPipeOut RamPipeOut(.ok1(ok1), .ok2(ok2x[ 11*17 +: 17 ]), .ep_addr(8'ha3), .ep_read(ram_out_read), .ep_datain(ram_out_data));
	okPipeIn  RamPipeIn(.ok1(ok1), .ok2(ok2x[ 12*17 +: 17 ]),.ep_addr(8'h82), .ep_write(ram_in_write), .ep_dataout(ram_in_data));
	
	// Cmd Memory Access Pipes
	okPipeIn  ep83 (.ok1(ok1), .ok2(ok2x[ 13*17 +: 17 ]),.ep_addr(8'h83), .ep_write(CmdPipeInWrite), .ep_dataout(CmdPipeInData));
	okPipeOut epa4 (.ok1(ok1), .ok2(ok2x[ 14*17 +: 17 ]), .ep_addr(8'hA4), .ep_read(CmdPipeOutRead), .ep_datain(CmdPipeOutData));

	// Extended wires
	okPipeIn  ep84(.ok1(ok1), .ok2(ok2x[ 15*17 +: 17 ]),.ep_addr(8'h84), .ep_write(extended_wire_write), .ep_dataout(extended_wire_data));
	
	ExtendedWireToParallel ExtendedWireToParallel ( .data_in(extended_wire_data), .clk_in(ti_clk), .write(extended_wire_write), 
		.address(extended_address), .data_out(extended_data), .data_available(extended_update), .wide_in(DDSData), .wide_address(DDSAddress),
      .wide_update(parameter_trig), .wide_clk(clk), .apply_immediately(extended_wire_apply_immediately) );

	ExtendedWireBuffer ExtendedWireInHostShutter( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h10), .data_out(HostShutter), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInHostTrigger( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h11), .data_out(HostTriggerMask), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInHostDDSData( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h12), .data_out(HostDDSData), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h13), .data_out(output_delay[0*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h14), .data_out(output_delay[1*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h15), .data_out(output_delay[2*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h16), .data_out(output_delay[3*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h17), .data_out(output_delay[4*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h18), .data_out(output_delay[5*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h19), .data_out(output_delay[6*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay8( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h1a), .data_out(output_delay[7*64 +: 64]), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay9( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h1b), .data_out(dedicated_integration), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately), .update(dedicated_integration_update) );
	ExtendedWireBuffer ExtendedWireInDelay10( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h1c), .data_out(adc_enable), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay11( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h1d), .data_out(dedicated_countermask), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInDelay70( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address),  .my_address(16'h70), .data_out(auxAnalyzerEnableMask), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer #(1'b1) ExtendedWireInDelay12( .update(host_command_trig), .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h1e), .data_out(HostDDSCmd), .apply_immediately(extended_wire_apply_immediately) );
	
	okWireOut HardwareConfigurationIdWire( .ok1(ok1), .ok2(ok2x[ 16*17 +: 17]), .ep_addr(8'h32), .ep_datain( HardwareConfigurationId ) );

	///////////////////////////////////////////////////////////////////////////////////////////////////
	// Ram Interface
	///////////////////////////////////////////////////////////////////////////////////////////////////
	wire ram_read_reset, ram_write_reset, ram_set_write_address, ram_set_read_address, ram_system_reset;
	monoflop ram_read_reset_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[5]), .q(ram_read_reset) );
	monoflop ram_write_reset_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[4]), .q(ram_write_reset) );
	monoflop ram_set_read_address_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[7]), .q(ram_set_read_address) );
	monoflop ram_set_write_address_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[6]), .q(ram_set_write_address) );
	monoflop ram_system_reset_mf(.clock(ti_clk), .enable(1'b1), .trigger(TrigIn41[8]), .q(ram_system_reset) );

	RamInterface RamInterface_inst( 
		.clk1(ramclk), // CY22393 CLKA @ 100MHz
		.pp_clk(clk),
		// Ram interface
		.mcb3_dram_dq(mcb3_dram_dq), .mcb3_dram_a(mcb3_dram_a), .mcb3_dram_ba(mcb3_dram_ba), .mcb3_dram_ras_n(mcb3_dram_ras_n),
		.mcb3_dram_cas_n(mcb3_dram_cas_n), .mcb3_dram_we_n(mcb3_dram_we_n), .mcb3_dram_odt(mcb3_dram_odt), .mcb3_dram_cke(mcb3_dram_cke),
		.mcb3_dram_dm(mcb3_dram_dm), .mcb3_dram_udqs(mcb3_dram_udqs), .mcb3_dram_udqs_n(mcb3_dram_udqs_n), .mcb3_rzq(mcb3_rzq),
		.mcb3_zio(mcb3_zio), .mcb3_dram_udm(mcb3_dram_udm), .mcb3_dram_dqs(mcb3_dram_dqs), .mcb3_dram_dqs_n(mcb3_dram_dqs_n), 
		.mcb3_dram_ck(mcb3_dram_ck), .mcb3_dram_ck_n(mcb3_dram_ck_n), .mcb3_dram_cs_n(mcb3_dram_cs_n), 
		// access to fifos write for host interface
		.pipe_clk(ti_clk), 
		// pipe acess to host
		.host_in_data(ram_in_data), .host_in_fifo_full(host_in_fifo_full), .host_in_write(ram_in_write), .host_write_reset(ram_write_reset),
		.host_out_data(ram_out_data), .host_out_read(ram_out_read), .host_read_reset(ram_read_reset),
		.host_address(RamAddress), .host_set_write_address(ram_set_write_address), .host_set_read_address(ram_set_read_address),
		// pp memory access
		.ppseq_out_data({pp_ram_data[15:0], pp_ram_data[31:16], pp_ram_data[47:32], pp_ram_data[63:48]}), .ppseq_out_read(pp_ram_read), .ppseq_address(pp_ram_address), .ppseq_set_address(pp_ram_set_address),
		.ppseq_valid(pp_ram_valid), .ppseq_read_enable(pp_active),
		.system_reset(ram_system_reset) );

endmodule
