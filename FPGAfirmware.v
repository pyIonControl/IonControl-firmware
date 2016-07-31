`timescale 1ns / 1ps
`include "Configuration.v"
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


//////////////////////////////////////////////////////////////////////////////////
// Interface to pulse sequencer:
//
// TrigIn40[2] = start pulse sequence
// TrigIn40[3] = force stop of pulse sequence
//	 ep20[0] = pp_active
//
// Interface to ddss:
//
//	data2dds = {ep02,ep01} 
//	cmd2dds  = ep00[7:0]
//	cmd_trig = TrigIn40[1](perform dds command)
//	profile  = ep00[13:8]
// 
// Interface to DAC:
// host_dactrig= TrigIn40[4];
// host_LDACtrig = TrigIn40[5];
// host_dacdata = {WireIn05,WireIn04[15:8]};

module FPGAfirmware #(
	parameter C3_NUM_DQ_PINS            = 16,       
	parameter C3_MEM_ADDR_WIDTH         = 13,       
	parameter C3_MEM_BANKADDR_WIDTH     = 3        
	)
	(
	input  wire [7:0]  hi_in,
	output wire [1:0]  hi_out,
	inout  wire [15:0] hi_inout,
	inout  wire        hi_aa,

	output wire			hi_muxsel,
	output wire			i2c_sda,
	output wire			i2c_scl,
	
	input wire clk1, clk2,               // external clocks
	output wire [7:0] led,

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


// Breakout board specific 
`ifdef BreakoutDukeADCDAC
	output wire DAC_LDAC,
	output wire DAC_SYNC,
	output wire DAC_DIN,
	output wire DAC_SCLK,
	
	output wire [2:0] ADC_OS,
	output wire ADC_CS,
	input wire ADC_BUSY,
	output wire ADC_CONVST,
	output wire ADC_RESET,
	output wire ADC_SCLK,
	input wire [1:0] ADC_DOUT,
`endif

`ifdef BreakoutDuke
	inout  wire [7:0] out1, out2, out3, out4, out5, out6, out7,
`ifdef ExternalClock
		output wire [7:0] sma,
		input wire ext_clk,
`else
		output wire [8:0] sma,
`endif
	output wire buffer_enable,	
	
	input  wire [7:0] in1,in2,in3,in4,in5
`endif

`ifdef BreakoutDuke3b
	inout  wire [7:0] out1, out2, out3, out4, out5, out6, out7, out8, out9,
	output wire [8:0] sma,
	output wire buffer_enable,	
	input  wire [7:0] in1,in2,in3
`endif

`ifdef BreakoutSandiaOrig	
	output wire [7:0] out1, out2, out3,out4, out5, //
	output wire [4:0] out6,
	output wire [7:0] sma, // three pins are missing :(

	input wire [7:0] in1,
	input wire [5:0] in2,	

	output wire [2:0] adc1out, adc2out,  // adc interfaces, each is  { din, sclk, cs }
	input wire adc1dout, adc2dout        // these are input wires named after the ADC chip output
`endif

`ifdef BreakoutSandia2	
	output wire [7:0] out1, out2, out3,out4, out5, out6, //
	output wire [7:0] sma, 

	input wire [7:0] in1,
	input wire [5:0] in2,	

	output wire [2:0] adc1out, adc2out,  // adc interfaces, each is  { din, sclk, cs }
	input wire adc1dout, adc2dout        // these are input wires named after the ADC chip output
`endif
 
);
	
parameter DDSChannels = 12;

	/////////////////////////////////////////////////////////////////////////
	// Clocks
	wire	 clk, sync_locked;   // main clk wire
	wire   ad9912wr_clk;			// write clock for AD9912s & AD9910s
	wire	 ramclk;					// 100MHz clock for ram access
	wire   slowclk;            // 25MHz clock unused
	wire   clk12p5MHz;				// 4 MHz clock for scan
	wire   clk_40_MHz;
	
	wire mux_clk, clk_switching;
`ifdef ExternalClockImplementation
	BUFG mux( .I(ext_clk), .O(mux_clk) );
	wire ext_clk_present;
	assign ext_clk_present = 1'b1;
`else
	assign clk_switching = 1'b0;
	BUFG nonmuxbuffer( .I(clk1), .O(mux_clk) );
`endif	
	
	// clocking pll
	clocking pll(.CLK_IN1(mux_clk), .CLK_OUT1(clk200), .CLK_OUT2(ramclk), .CLK_OUT3(clk), .CLK_OUT4(clk_40_MHz), 
					 .CLK_OUT5(clk_20_MHz), .CLK_OUT6(clk12p5MHz), .LOCKED(sync_locked), .RESET(clk_switching) ); // 200, 100, 50, 40, 10 MHz
`ifdef SlowDDSClk
	assign ad9912wr_clk = clk_20_MHz;
`else
	assign ad9912wr_clk = clk_40_MHz;
`endif
	assign slowclk = clk_20_MHz;
	
`ifdef Debug
	wire [15:0] divided_clock;
   clock_division_debug_counter cddc1( .clk(ad9912wr_clk), .q(divided_clock) );
`endif
	/////////////////////////////////////////////////////////////////////////
	// photon counter signal input conditioning
	// generate single cycle clock pulse when photon trigger is input
	/////////////////////////////////////////////////////////////////////////
	wire [15:0] count_raw; // raw counts inputs
	wire [15:0] count_in;  // synchronized counts
	wire [7:0] trigger_raw;
	wire [7:0] trigger_in;
	reg [7:0] level_in;
	
`ifdef IndependentInputs
	assign count_raw[15:0] = { in2[7:0], in1[7:0]};
	assign trigger_raw[7:0] = { in3[7:0]};
	always @(posedge clk) begin
		level_in[7:0] <= { in3[7:0] };
	end
`else
	assign count_raw[15:0] = { in1[7:0], in1[7:0]};
	assign trigger_raw[7:0] = {2'h0, in2[5:0]};
	always @(posedge clk) begin
		level_in[7:0] <= { 2'h0, in2[5:0] };
	end
`endif

	monoflop MF0(.clock(clk), .enable(1'b1), .trigger(count_raw[0]), .q(count_in[0]));
	monoflop MF1(.clock(clk), .enable(1'b1), .trigger(count_raw[1]), .q(count_in[1]));
	monoflop MF2(.clock(clk), .enable(1'b1), .trigger(count_raw[2]), .q(count_in[2]));
	monoflop MF3(.clock(clk), .enable(1'b1), .trigger(count_raw[3]), .q(count_in[3]));
	monoflop MF4(.clock(clk), .enable(1'b1), .trigger(count_raw[4]), .q(count_in[4]));
	monoflop MF5(.clock(clk), .enable(1'b1), .trigger(count_raw[5]), .q(count_in[5]));
	monoflop MF6(.clock(clk), .enable(1'b1), .trigger(count_raw[6]), .q(count_in[6]));
	monoflop MF7(.clock(clk), .enable(1'b1), .trigger(count_raw[7]), .q(count_in[7]));
	monoflop MF8(.clock(clk), .enable(1'b1), .trigger(count_raw[8]), .q(count_in[8]));
	monoflop MF9(.clock(clk), .enable(1'b1), .trigger(count_raw[9]), .q(count_in[9]));
	monoflop MFa(.clock(clk), .enable(1'b1), .trigger(count_raw[10]), .q(count_in[10]));
	monoflop MFb(.clock(clk), .enable(1'b1), .trigger(count_raw[11]), .q(count_in[11]));
	monoflop MFc(.clock(clk), .enable(1'b1), .trigger(count_raw[12]), .q(count_in[12]));
	monoflop MFd(.clock(clk), .enable(1'b1), .trigger(count_raw[13]), .q(count_in[13]));
	monoflop MFe(.clock(clk), .enable(1'b1), .trigger(count_raw[14]), .q(count_in[14]));
	monoflop MFf(.clock(clk), .enable(1'b1), .trigger(count_raw[15]), .q(count_in[15]));	
	
	monoflop tMF0(.clock(clk), .enable(1'b1), .trigger(trigger_raw[0]), .q(trigger_in[0]));
	monoflop tMF1(.clock(clk), .enable(1'b1), .trigger(trigger_raw[1]), .q(trigger_in[1]));
	monoflop tMF2(.clock(clk), .enable(1'b1), .trigger(trigger_raw[2]), .q(trigger_in[2]));
	monoflop tMF3(.clock(clk), .enable(1'b1), .trigger(trigger_raw[3]), .q(trigger_in[3]));
	monoflop tMF4(.clock(clk), .enable(1'b1), .trigger(trigger_raw[4]), .q(trigger_in[4]));
	monoflop tMF5(.clock(clk), .enable(1'b1), .trigger(trigger_raw[5]), .q(trigger_in[5]));
	monoflop tMF6(.clock(clk), .enable(1'b1), .trigger(trigger_raw[6]), .q(trigger_in[6]));
	monoflop tMF7(.clock(clk), .enable(1'b1), .trigger(trigger_raw[7]), .q(trigger_in[7]));

	/////////////////////////////////////////////////////////////////////////
	// Pulse Programmer Kernel
	/////////////////////////////////////////////////////////////////////////
	wire [63:0] trigger;    // trigger lines from Host or PulseProgram
	wire [63:0]	shutter;    // shutter lines from Host or PulseProgram
	wire [63:0] DDSData;    // DDS Data from Host or PulseProgram, DDS values are valid for at least one clock cycle and meant to be inserted into a FIFO for delivery to the hardware
	wire [3:0] DDSCmd;      // DDS Command from Host or PulseProgram
	wire [7:0] DDSAddress;  // DDS Address
	wire [15:0] DDSReset;   // DDS Reset
	wire [15:0] DDSResetMask; 
	
	wire [15:0] extended_address;
	wire [63:0] extended_data;
	wire extended_update;
	
	wire clk_enable[9:0];   // SCLK enable for DDS channels
	wire [DDSChannels-1:0] dds_write_done_bundle;  // DDS write done line for the different channels
	
	wire [16*16-1:0] ADCData;  // 8*16 bit data from the 8 ADCs
	wire [15:0]      ADCReady; // Ready lines for the ADC data
	wire pp_active;
	wire [3:0] state_debug;
	wire usb_clk;
	wire ddscmd_trig, serial_cmd_trig, daccmd_trig, parameter_trig;
	wire [31:0] externalStatus;
	wire pp_update;
	wire extended_wire_apply_immediately;
	wire [63:0] auxAnalyzerData = {56'h0, clk_enable[6], clk_enable[7], clk_enable[4], clk_enable[5], clk_enable[2], clk_enable[3], clk_enable[0], clk_enable[1]};
	PulseProgrammer PulseProgrammer( .fast_clk(clk200), .ramclk(ramclk), .memoryclk(ramclk), .clk(clk), .sync_locked(sync_locked),
												// Opal Kelly Interface
												.hi_in(hi_in), .hi_out(hi_out), .hi_inout(hi_inout), .hi_aa(hi_aa),
												.hi_muxsel(hi_muxsel), .i2c_sda(i2c_sda), .i2c_scl(i2c_scl),
												// Memory Interface
												.mcb3_dram_dq(mcb3_dram_dq), .mcb3_dram_a(mcb3_dram_a), .mcb3_dram_ba(mcb3_dram_ba), .mcb3_dram_ras_n(mcb3_dram_ras_n),
												.mcb3_dram_cas_n(mcb3_dram_cas_n), .mcb3_dram_we_n(mcb3_dram_we_n), .mcb3_dram_odt(mcb3_dram_odt), .mcb3_dram_cke(mcb3_dram_cke),
												.mcb3_dram_dm(mcb3_dram_dm), .mcb3_dram_udqs(mcb3_dram_udqs), .mcb3_dram_udqs_n(mcb3_dram_udqs_n), .mcb3_rzq(mcb3_rzq),
												.mcb3_zio(mcb3_zio),.mcb3_dram_udm(mcb3_dram_udm), .mcb3_dram_dqs(mcb3_dram_dqs), .mcb3_dram_dqs_n(mcb3_dram_dqs_n),
												.mcb3_dram_ck(mcb3_dram_ck), .mcb3_dram_ck_n(mcb3_dram_ck_n), .mcb3_dram_cs_n(mcb3_dram_cs_n),
												// PulseProgram
												.trigger(trigger), .shutter(shutter),
												.DDSData(DDSData), .DDSCmd(DDSCmd), .DDSAddress(DDSAddress), .DDSReset(DDSReset), .DDSResetMask(DDSResetMask), 
												.write_active(dds_write_done_bundle),
												.dds_cmd_trig(ddscmd_trig), .serial_cmd_trig(serial_cmd_trig), .parameter_trig(parameter_trig),
												.dac_cmd_trig(daccmd_trig),
												.auxAnalyzerData( auxAnalyzerData ),
												.ADCData(ADCData), .ADCReady(ADCReady),
												.count_in(count_in), .trigger_in(trigger_in), .level_in(level_in),
												.pp_active(pp_active), .state_debug(state_debug),
												.extended_data( extended_data), .extended_update(extended_update), .extended_address(extended_address), .usb_clk(usb_clk),
									         .externalStatus(externalStatus),
												.pp_update(pp_update), .extended_wire_apply_immediately(extended_wire_apply_immediately) );


	
	/////////////////////////////////////////////////////////////////////////
	// Output connections
	/////////////////////////////////////////////////////////////////////////	
	
	assign out1[7:0] = shutter[7:0];
	
`ifdef BreakoutSandia2
	`ifndef WiggelyLineBox
		assign out2[5:0] = shutter[13:8];
		`ifdef InvertSma
			assign sma[7:0] =  ~shutter[31:24];
		`else
			assign sma[7:0] =  shutter[31:24];
		`endif
	`else
		assign out2[6:0] = shutter[14:8];
		assign out2[7] = in1[0];
		assign sma[7:0] =  {shutter[31:30], shutter[27], shutter[24], shutter[28], shutter[25], shutter[29], shutter[26] };
	`endif
`endif	

`ifdef BreakoutSandiaOrig
	`ifndef WiggelyLineBox
		assign out2[7:0] = shutter[15:8];
		`ifdef InvertSma
			assign sma[7:0] =  ~shutter[31:24];
		`else
			assign sma[7:0] =  shutter[31:24];
		`endif
	`else
		assign out2[6:0] = shutter[14:8];
		assign out2[7] = in1[0];
		assign sma[7:0] =  {shutter[31:30], shutter[27], shutter[24], shutter[28], shutter[25], shutter[29], shutter[26] };
	`endif
`endif	

`ifdef BreakoutDuke
	assign out2[5:0] = shutter[13:8];
	`ifdef InvertSma
		assign sma[7:0] =  ~shutter[31:24];
	`else
		assign sma[7:0] =  shutter[31:24];
	`endif
	`ifndef ExternalClock
		`ifdef SMA8IsClock
			ODDR2 oddr_sma(.D0(1'b1), .D1(1'b0), .C0(clk), .C1(~clk), .CE(1'b1), .Q(sma[8]), .R(1'b0), .S(1'b0) );
		`else
			assign sma[8] = 1'b0; // static for now.
		`endif
	`endif
	assign buffer_enable = 1'b0;
`endif 

`ifdef BreakoutDuke3b
	assign out2[5:0] = shutter[13:8];
	assign out8[7:0] = shutter[23:16];
	`ifdef InvertSma
		assign sma[8:0] =  ~shutter[32:24];
		assign out9[0] = ~shutter[33];
	`else
		assign sma[8:0] =  shutter[32:24];
		assign out9[0] = shutter[33];
	`endif
	assign buffer_enable = 1'b0;
	assign out9[7:1] = 7'h0;
`endif 

`ifdef BreakoutSandiaOrig
	// SandiaBreakout2 normally used out6 as follows instead of extra DDS channels.
	assign out6[4:1] = shutter[21:17];   // bit one is echo of count input channel 0
	assign out6[0] = in1[0];  
	// bit one is echo of count input channel 0
`endif
	
	wire [15:0] long_trigger;  // IO Update triggers to DDS
	wire [15:0] long_trigger_oddr;

	clk_timed_monoflop trig_mf_0(.clk(clk), .enable(1'b1), .trigger(trigger[0]), .q(long_trigger_oddr[0]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_1(.clk(clk), .enable(1'b1), .trigger(trigger[1]), .q(long_trigger_oddr[1]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_2(.clk(clk), .enable(1'b1), .trigger(trigger[2]), .q(long_trigger_oddr[2]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_3(.clk(clk), .enable(1'b1), .trigger(trigger[3]), .q(long_trigger_oddr[3]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_4(.clk(clk), .enable(1'b1), .trigger(trigger[4]), .q(long_trigger_oddr[4]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_5(.clk(clk), .enable(1'b1), .trigger(trigger[5]), .q(long_trigger_oddr[5]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_6(.clk(clk), .enable(1'b1), .trigger(trigger[6]), .q(long_trigger_oddr[6]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_7(.clk(clk), .enable(1'b1), .trigger(trigger[7]), .q(long_trigger_oddr[7]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_8(.clk(clk), .enable(1'b1), .trigger(trigger[8]), .q(long_trigger_oddr[8]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_9(.clk(clk), .enable(1'b1), .trigger(trigger[9]), .q(long_trigger_oddr[9]), .pulselength(4'h5));
	clk_timed_monoflop trig_mf_a(.clk(clk), .enable(1'b1), .trigger(trigger[16]), .q(long_trigger[10]), .pulselength(4'h5));
	
	genvar pin_iter;
	generate for (pin_iter = 0; pin_iter < 8; pin_iter = pin_iter + 1) begin: oddr2loop
		ODDR2 #(.DDR_ALIGNMENT("C0"),
				  .INIT(0),
				  .SRTYPE("ASYNC"))
				outddr( .D0(long_trigger_oddr[pin_iter]), 
						  .D1(long_trigger_oddr[pin_iter]), 
						  .C0(clk), 
						  .C1(1'b0), 
						  .CE(1'b1), 
						  .Q(long_trigger[pin_iter]), 
						  .R(1'b0), 
						  .S(1'b0) );
				 end //oddr2loop
	endgenerate
	
	// The following delay_out instantiations are used to synchronize IOUPDATE pulses for the DDSs
   // The input parameter is the number of "taps" that specify the delay where each tap is roughly
	// 35 ps on the LX150 board. Final delays are still subject to variations in Place & Route.
	delay_out #(13) delay_out_0(.DATA_OUT_FROM_DEVICE(long_trigger[0]),.DATA_OUT_TO_PINS(out3[5]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(7) delay_out_1(.DATA_OUT_FROM_DEVICE(long_trigger[1]),.DATA_OUT_TO_PINS(out3[0]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(0) delay_out_2(.DATA_OUT_FROM_DEVICE(long_trigger[2]),.DATA_OUT_TO_PINS(out4[5]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(8) delay_out_3(.DATA_OUT_FROM_DEVICE(long_trigger[3]),.DATA_OUT_TO_PINS(out4[0]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(0) delay_out_4(.DATA_OUT_FROM_DEVICE(long_trigger[4]),.DATA_OUT_TO_PINS(out5[5]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(9) delay_out_5(.DATA_OUT_FROM_DEVICE(long_trigger[5]),.DATA_OUT_TO_PINS(out5[0]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );

	wire [8*16-1:0] regulatorData;
	wire [7:0] regulatorUpdate;


	wire [7:0] PIChannelDDS0, PIChannelDDS1, PIChannelDDS2, PIChannelDDS3, PIChannelDDS4, PIChannelDDS5, PIChannelDDS6, PIChannelDDS7, PIChannelDDS8, PIChannelDDS9;
	wire [7:0] PIChannelDAC0, PIChannelDAC1, PIChannelDAC2, PIChannelDAC3, PIChannelDAC4, PIChannelDAC5, PIChannelDAC6, PIChannelDAC7;

	/////////////////////////////////////////////////////////////////////////
	// DDS Channels
	/////////////////////////////////////////////////////////////////////////
	// SIO clock
	ODDR2 oddr_1(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[0]|clk_enable[1]), .Q(out3[4]), .R(1'b0), .S(1'b0) );
	ODDR2 oddr_2(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[2]|clk_enable[3]), .Q(out4[4]), .R(1'b0), .S(1'b0) );
	ODDR2 oddr_3(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[4]|clk_enable[5]), .Q(out5[4]), .R(1'b0), .S(1'b0) );
	
	wire [7:0] rst_ddrbuf;
	
	clk_timed_monoflop #(10) dds_reset_mf_0(.clk(clk), .enable(|DDSResetMask[1:0]), .trigger(DDSReset[0]), .q(rst_ddrbuf[0]), .pulselength(10'd500));
	clk_timed_monoflop #(10) dds_reset_mf_1(.clk(clk), .enable(|DDSResetMask[3:2]), .trigger(DDSReset[0]), .q(rst_ddrbuf[1]), .pulselength(10'd500));
	clk_timed_monoflop #(10) dds_reset_mf_2(.clk(clk), .enable(|DDSResetMask[5:4]), .trigger(DDSReset[0]), .q(rst_ddrbuf[2]), .pulselength(10'd500));
	
	ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		   outddr1(.D0(rst_ddrbuf[0]), .D1(rst_ddrbuf[0]), .C0(clk), .C1(1'b0), .CE(1'b1), .Q(out3[3]), .R(1'b0), .S(1'b0));
	ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		   outddr2(.D0(rst_ddrbuf[1]), .D1(rst_ddrbuf[1]), .C0(clk), .C1(1'b0), .CE(1'b1), .Q(out4[3]), .R(1'b0), .S(1'b0));
	ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		   outddr3(.D0(rst_ddrbuf[2]), .D1(rst_ddrbuf[2]), .C0(clk), .C1(1'b0), .CE(1'b1), .Q(out5[3]), .R(1'b0), .S(1'b0));
	
	// PI output selects
	wire [15:0] regDDS0, regDDS1, regDDS2, regDDS3, regDDS4, regDDS5;
	wire [15:0] updRegDDS;
	SignalSelect pi_output_select_dss0( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS0), .signal_out(regDDS0), .available_out(updRegDDS[0]) );
	SignalSelect pi_output_select_dss1( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS1), .signal_out(regDDS1), .available_out(updRegDDS[1]) );
	SignalSelect pi_output_select_dss2( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS2), .signal_out(regDDS2), .available_out(updRegDDS[2]) );
	SignalSelect pi_output_select_dss3( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS3), .signal_out(regDDS3), .available_out(updRegDDS[3]) );
	SignalSelect pi_output_select_dss4( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS4), .signal_out(regDDS4), .available_out(updRegDDS[4]) );
	SignalSelect pi_output_select_dss5( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS5), .signal_out(regDDS5), .available_out(updRegDDS[5]) );

	// for backwards compatibility the dds_cmd is 1bit don't care, 1bit MSB of cmd, 2bits LSB cmd
	AD9912 ad9912dds0(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h1)), 
							.dds_out({ clk_enable[0], out3[2:1]}), .ndone(dds_write_done_bundle[0]),
							.lock_data( {54'h0, regDDS1[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[1])	);
	AD9912 ad9912dds1(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h0)), 
							.dds_out({ clk_enable[1], out3[7:6]}), .ndone(dds_write_done_bundle[1]), 
							.lock_data( {54'h0, regDDS0[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[0]) 	);
	AD9912 ad9912dds2(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h3)), 
							.dds_out({ clk_enable[2], out4[2:1]}), .ndone(dds_write_done_bundle[2]),
							.lock_data( {54'h0, regDDS3[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[3])  );
	AD9912 ad9912dds3(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h2)), 
							.dds_out({ clk_enable[3], out4[7:6]}), .ndone(dds_write_done_bundle[3]),
							.lock_data( {54'h0, regDDS2[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[2]) );
	AD9912 ad9912dds4(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h5)), 
							.dds_out({ clk_enable[4], out5[2:1]}), .ndone(dds_write_done_bundle[4]), 
							.lock_data( {54'h0, regDDS5[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[5]) );
	AD9912 ad9912dds5(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h4)), 
							.dds_out({ clk_enable[5], out5[7:6]}), .ndone(dds_write_done_bundle[5]), 
							.lock_data( {54'h0, regDDS4[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[4]) );
							
`ifdef Out6IsMagiq
	// last one for talking to Magiq pulser card:
	ODDR2 oddr_5(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[8]|clk_enable[9]), .Q(out6[4]), .R(1'b0), .S(1'b0) );
	// And Magiq Pulser card, two AD9910 chips controlled by their FPGA (unfortunately 32-bit fifo on their end)
	MP9910 mp9910dds0(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h9 | DDSAddress==8'h8)), 
							.dds_out({ clk_enable[8], out6[1], out6[2]}), .ndone(dds_write_done_bundle[6]), .pulser_chan(DDSAddress==8'h9)  );	
	assign dds_write_done_bundle[7] = 1'b0;
`else
`ifdef Out6IsAD9912

	delay_out #(3) delay_out_6(.DATA_OUT_FROM_DEVICE(long_trigger[6]),.DATA_OUT_TO_PINS(out6[5]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(3) delay_out_7(.DATA_OUT_FROM_DEVICE(long_trigger[7]),.DATA_OUT_TO_PINS(out6[0]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );

	wire [15:0] regDDS6, regDDS7;
	SignalSelect pi_output_select_dss6( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS6), .signal_out(regDDS6), .available_out(updRegDDS[6]) );
	SignalSelect pi_output_select_dss7( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS7), .signal_out(regDDS7), .available_out(updRegDDS[7]) );

	ODDR2 oddr_4(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[6]|clk_enable[7]), .Q(out6[4]), .R(1'b0), .S(1'b0) );
	clk_timed_monoflop #(10) dds_reset_mf_3(.clk(clk), .enable(|DDSResetMask[7:6]), .trigger(DDSReset[0]), .q(rst_ddrbuf[3]), .pulselength(10'd500));

	ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		   outddr4(.D0(rst_ddrbuf[3]), .D1(rst_ddrbuf[3]), .C0(clk), .C1(1'b0), .CE(1'b1), .Q(out6[3]), .R(1'b0), .S(1'b0));

	AD9912 ad9912dds6(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h7)), 
							.dds_out({ clk_enable[6], out6[2:1]}), .ndone(dds_write_done_bundle[6]), 
							.lock_data( {54'h0, regDDS7[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[7]) );
	AD9912 ad9912dds7(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h6)), 
							.dds_out({ clk_enable[7], out6[7:6]}), .ndone(dds_write_done_bundle[7]), 
							.lock_data( {54'h0, regDDS6[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[6]) );
`else
	assign dds_write_done_bundle[7:6] = 2'b00;	
`endif
`endif

`ifdef Out7IsAD9910
	assign out7[5] = long_trigger[6]; //AD9910
	assign out7[0] = long_trigger[7]; //AD9910

	ODDR2 oddr_5(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[8]|clk_enable[9]), .Q(out7[4]), .R(1'b0), .S(1'b0) );

	clk_timed_monoflop dds_reset_mf_4(.clk(clk), .enable(1'b1), .trigger(DDSReset[3]), .q(out7[3]), .pulselength(4'hf));

	// Analog Devices evaluations boards for AD9910 chips (1 chip/board, I split ribbon cable to similarly share lines as with custom AD9912 boards) -RN
	AD9910 ad9910dds0(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h7)), 
							.dds_out({ clk_enable[8], out7[2:1]}), .ndone(dds_write_done_bundle[8])  );
	AD9910 ad9910dds1(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h6)), 
							.dds_out({ clk_enable[9], out7[7:6]}), .ndone(dds_write_done_bundle[9])  );		
`else
`ifdef Out7IsAD9912
	delay_out #(3) delay_out_8(.DATA_OUT_FROM_DEVICE(long_trigger[8]),.DATA_OUT_TO_PINS(out7[5]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );
	delay_out #(3) delay_out_9(.DATA_OUT_FROM_DEVICE(long_trigger[9]),.DATA_OUT_TO_PINS(out7[0]),
										.CLK_IN(clk), .CLK_OUT(), .IO_RESET(1'b0) );

	genvar pin_iter2;
	generate for (pin_iter2 = 8; pin_iter2 < 10; pin_iter2 = pin_iter2 + 1) begin: oddr2loop2
		ODDR2 #(.DDR_ALIGNMENT("C0"),
				  .INIT(0),
				  .SRTYPE("ASYNC"))
				outddr( .D0(long_trigger_oddr[pin_iter2]), 
						  .D1(long_trigger_oddr[pin_iter2]), 
						  .C0(clk), 
						  .C1(1'b0), 
						  .CE(1'b1), 
						  .Q(long_trigger[pin_iter2]), 
						  .R(1'b0), 
						  .S(1'b0) );
				 end //oddr2loop2
	endgenerate

	wire [15:0] regDDS8, regDDS9;
	SignalSelect pi_output_select_dss8( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS8), .signal_out(regDDS8), .available_out(updRegDDS[8]) );
	SignalSelect pi_output_select_dss9( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDDS9), .signal_out(regDDS9), .available_out(updRegDDS[9]) );

	ODDR2 oddr_5(.D0(1'b1), .D1(1'b0), .C0(ad9912wr_clk), .C1(~ad9912wr_clk), .CE(clk_enable[8]|clk_enable[9]), .Q(out7[4]), .R(1'b0), .S(1'b0) );
	clk_timed_monoflop #(10) dds_reset_mf_4(.clk(clk), .enable(|DDSResetMask[9:8]), .trigger(DDSReset[0]), .q(rst_ddrbuf[4]), .pulselength(10'd500));

	ODDR2 #(.DDR_ALIGNMENT("C0"), .INIT(0), .SRTYPE("ASYNC"))
		   outddr5(.D0(rst_ddrbuf[4]), .D1(rst_ddrbuf[4]), .C0(clk), .C1(1'b0), .CE(1'b1), .Q(out7[3]), .R(1'b0), .S(1'b0));

	AD9912 ad9912dds8(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h9)), 
							.dds_out({ clk_enable[8], out7[2:1]}), .ndone(dds_write_done_bundle[9]), 
							.lock_data( {54'h0, regDDS9[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[9]) );
	AD9912 ad9912dds9(.clk(clk), .sclk_in(ad9912wr_clk), .dds_cmd(DDSCmd), .dds_data(DDSData), .dds_ready(ddscmd_trig & (DDSAddress==8'h8)), 
							.dds_out({ clk_enable[9], out7[7:6]}), .ndone(dds_write_done_bundle[8]), 
							.lock_data( {54'h0, regDDS8[15:6]} ), .lock_cmd(4'h2), .lock_ready(updRegDDS[8]) );

`else 
	assign dds_write_done_bundle[9:8] = 2'b00;
	`ifdef Out7IsShutters
		assign out7[7:0] = shutter[23:16];
	`endif
`endif
`endif



`ifdef SerialOutputOut2_7
	wire serial_out;
	wire [3:0] serial_out_debug;
	assign out2[7] = serial_out;
	AsyncTransmitter SerialTrans(.clk(clk), .command(DDSAddress), .data(DDSData), .ready(serial_cmd_trig), .TxD(serial_out), .ndone(dds_write_done_bundle[10]),
											.debug(serial_out_debug) );
	wire serial_long_trigger;
	timed_monoflop #(8) trig_17(.clock(clk), .enable(1'b1), .trigger(trigger[17]), .q(serial_long_trigger), .pulselength(8'd100));

	assign out2[6] = serial_long_trigger;
`else
	assign dds_write_done_bundle[10] = 1'b0;
	`ifndef WiggelyLineBox
		assign out2[7:6] = shutter[15:14];
	`endif
`endif


	/////////////////////////////////////////////////////////////////////////
	// LED
	wire blinker;
	ledblink ledblink( .clk(clk), .trigger(|ADCReady), .q(blinker) );
	assign led[3:0] = ~state_debug;
	assign led[4] = ~shutter[0];
	assign led[6] = ~pp_active;
	assign led[7] = 0;
`ifdef ExternalClockImplementation
	assign led[5] = ~ext_clk_present;
`else
	assign led[5] = ~blinker;
`endif

   /////////////////////////////////////////////////////////////////////////////
	// PID regulator
	/////////////////////////////////////////////////////////////////////////////
	wire [63:0] pCoeff0, iCoeff0, enable_delay0, input_offset0;
	ExtendedWireBuffer ExtendedWireInpCoeff0( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h20), .data_out(pCoeff0), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately));
	ExtendedWireBuffer ExtendedWireIniCoeff0( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h21), .data_out(iCoeff0), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay0( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h22), .data_out(enable_delay0), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset0( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h23), .data_out(input_offset0), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff1, iCoeff1, enable_delay1, input_offset1;
	ExtendedWireBuffer ExtendedWireInpCoeff1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h24), .data_out(pCoeff1), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h25), .data_out(iCoeff1), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h26), .data_out(enable_delay1), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h27), .data_out(input_offset1), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff2, iCoeff2, enable_delay2, input_offset2;
	ExtendedWireBuffer ExtendedWireInpCoeff2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h28), .data_out(pCoeff2), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h29), .data_out(iCoeff2), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2a), .data_out(enable_delay2), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2b), .data_out(input_offset2), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff3, iCoeff3, enable_delay3, input_offset3;
	ExtendedWireBuffer ExtendedWireInpCoeff3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2c), .data_out(pCoeff3), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2d), .data_out(iCoeff3), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2e), .data_out(enable_delay3), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h2f), .data_out(input_offset3), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff4, iCoeff4, enable_delay4, input_offset4;
	ExtendedWireBuffer ExtendedWireInpCoeff4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h30), .data_out(pCoeff4), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h31), .data_out(iCoeff4), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h32), .data_out(enable_delay4), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h33), .data_out(input_offset4), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff5, iCoeff5, enable_delay5, input_offset5;
	ExtendedWireBuffer ExtendedWireInpCoeff5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h34), .data_out(pCoeff5), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h35), .data_out(iCoeff5), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h36), .data_out(enable_delay5), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h37), .data_out(input_offset5), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff6, iCoeff6, enable_delay6, input_offset6;
	ExtendedWireBuffer ExtendedWireInpCoeff6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h38), .data_out(pCoeff6), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h39), .data_out(iCoeff6), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3a), .data_out(enable_delay6), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3b), .data_out(input_offset6), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [63:0] pCoeff7, iCoeff7, enable_delay7, input_offset7;
	ExtendedWireBuffer ExtendedWireInpCoeff7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3c), .data_out(pCoeff7), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIniCoeff7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3d), .data_out(iCoeff7), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireInenable_delay7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3e), .data_out(enable_delay7), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireIninput_offset7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h3f), .data_out(input_offset7), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	ExtendedWireBuffer ExtendedWirePIChannelDDS( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h40), 
																      .data_out({PIChannelDDS7, PIChannelDDS6, PIChannelDDS5, PIChannelDDS4, PIChannelDDS3, PIChannelDDS2, PIChannelDDS1, PIChannelDDS0}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWirePIChannelDDS2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h42), 
																      .data_out({PIChannelDDS9, PIChannelDDS8}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWirePIChannelDAC( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h41), 
																      .data_out({PIChannelDAC7, PIChannelDAC6, PIChannelDAC5, PIChannelDAC4, PIChannelDAC3, PIChannelDAC2, PIChannelDAC1, PIChannelDAC0}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
																		
`ifdef DACScanning
	wire [15:0] scan_min_0, scan_max_0, scan_increment_0;
	wire [15:0] scan_min_1, scan_max_1, scan_increment_1;
	wire [15:0] scan_min_2, scan_max_2, scan_increment_2;
	wire [15:0] scan_min_3, scan_max_3, scan_increment_3;
	wire [15:0] scan_min_4, scan_max_4, scan_increment_4;
	wire [15:0] scan_min_5, scan_max_5, scan_increment_5;
	wire [15:0] scan_min_6, scan_max_6, scan_increment_6;
	wire [15:0] scan_min_7, scan_max_7, scan_increment_7;
	ExtendedWireBuffer ExtendedWireScanDAC0( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h50), 
																      .data_out({scan_min_0, scan_max_0, scan_increment_0}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC1( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h51), 
																      .data_out({scan_min_1, scan_max_1, scan_increment_1}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC2( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h52), 
																      .data_out({scan_min_2, scan_max_2, scan_increment_2}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC3( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h53), 
																      .data_out({scan_min_3, scan_max_3, scan_increment_3}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC4( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h54), 
																      .data_out({scan_min_4, scan_max_4, scan_increment_4}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC5( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h55), 
																      .data_out({scan_min_5, scan_max_5, scan_increment_5}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC6( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h56), 
																      .data_out({scan_min_6, scan_max_6, scan_increment_6}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
	ExtendedWireBuffer ExtendedWireScanDAC7( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h57), 
																      .data_out({scan_min_7, scan_max_7, scan_increment_7}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );
`endif

`ifdef PILoops
	wire pi_gate_0;

`ifdef PDHAutoLock
	wire [15:0] autolock_threshold;
	wire [31:0] autolock_timeout;
	ExtendedWireBuffer ExtendedWireAutolock( .data_in(extended_data), .update_in(extended_update), .clk(clk), .address(extended_address), .my_address(16'h58), 
																      .data_out({autolock_threshold, autolock_timeout}), .pp_update(pp_update), .apply_immediately(extended_wire_apply_immediately) );

	wire [15:0] autolock_offset;
	wire autolock_bypass;
	wire autolock_lock_enable;
	wire [15:0] lockScan;
	wire lockScanEnable, scan_upd;
   delayed_on_gate delayed_on_gate_0( .clk(clk), .gate(shutter[32] | autolock_lock_enable), .delay(enable_delay0[31:2]), .q(pi_gate_0) );
	picore ampl_piCore0( .clk(clk), .update(ADCReady[0]), .errorsig(ADCData[0*16+:16]), 
		.pCoeff(pCoeff0[31:0]), .iCoeff(iCoeff0[31:0]), 
		.enable(pi_gate_0), .sclr(trigger[8]), 
		.regOut(regulatorData[0*16 +: 16]), .regOutUpdate(regulatorUpdate[0]), 
		.inputOffset(input_offset0[15:0]), .underflow(externalStatus[0]), .overflow(externalStatus[1]), 
		.output_offset(lockScan), .set_output_offset(lockScanEnable), .set_output_clk(scan_upd)  );
		
	AutoLock Autolock0( .clk(clk), .update(ADCReady[0]), .errorsig(ADCData[0*16+:16]), .discriminator(ADCData[1*16+:16]),
							  .threshold(autolock_threshold), 
							  .enable( shutter[48] ),
							  .enable_lock_out(autolock_lock_enable), 
							  .scanEnable(lockScanEnable),
							  .timeout( autolock_timeout) );
							  
	VarScanGenerator scanGenLock( .clk(clk), .increment(scan_increment_0), .sinit(1'b0), .scan_min(scan_min_0), .scan_max(scan_max_0), 
											.scan_enable(lockScanEnable), .q(lockScan), .output_upd(scan_upd) );

`else
   delayed_on_gate delayed_on_gate_0( .clk(clk), .gate(shutter[32]), .delay(enable_delay0[31:2]), .q(pi_gate_0) );
	picore ampl_piCore0( .clk(clk), .update(ADCReady[0]), .errorsig(ADCData[0*16+:16]), 
		.pCoeff(pCoeff0[31:0]), .iCoeff(iCoeff0[31:0]), 
		.enable(pi_gate_0), .sclr(trigger[8]), 
		.regOut(regulatorData[0*16 +: 16]), .regOutUpdate(regulatorUpdate[0]), 
		.inputOffset(input_offset0[15:0]), .underflow(externalStatus[0]), .overflow(externalStatus[1]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'h8 & ~pi_gate_0), .set_output_clk(daccmd_trig)  );
`endif
		
	wire pi_gate_1;
   delayed_on_gate delayed_on_gate_1( .clk(clk), .gate(shutter[33]), .delay(enable_delay1[31:2]), .q(pi_gate_1) );
	picore ampl_piCore1( .clk(clk), .update(ADCReady[1]), .errorsig(ADCData[1*16+:16]), 
		.pCoeff(pCoeff1[31:0]), .iCoeff(iCoeff1[31:0]), 
		.enable(pi_gate_1), .sclr(trigger[9]), 
		.regOut(regulatorData[1*16 +: 16]), .regOutUpdate(regulatorUpdate[1]), 
		.inputOffset(input_offset1[15:0]), .underflow(externalStatus[2]), .overflow(externalStatus[3]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'h9 & ~pi_gate_1), .set_output_clk(daccmd_trig)  );

	wire pi_gate_2;
   delayed_on_gate delayed_on_gate_2( .clk(clk), .gate(shutter[34]), .delay(enable_delay2[31:2]), .q(pi_gate_2) );
	picore ampl_piCore2( .clk(clk), .update(ADCReady[2]), .errorsig(ADCData[2*16+:16]), 
		.pCoeff(pCoeff2[31:0]), .iCoeff(iCoeff2[31:0]), 
		.enable(pi_gate_2), .sclr(trigger[10]), 
		.regOut(regulatorData[2*16 +: 16]), .regOutUpdate(regulatorUpdate[2]), 
		.inputOffset(input_offset2[15:0]), .underflow(externalStatus[4]), .overflow(externalStatus[5]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'ha & ~pi_gate_2), .set_output_clk(daccmd_trig)  );

	wire pi_gate_3;
   delayed_on_gate delayed_on_gate_3( .clk(clk), .gate(shutter[35]), .delay(enable_delay3[31:2]), .q(pi_gate_3) );
	picore ampl_piCore3( .clk(clk), .update(ADCReady[3]), .errorsig(ADCData[3*16+:16]), 
		.pCoeff(pCoeff3[31:0]), .iCoeff(iCoeff3[31:0]), 
		.enable(pi_gate_3), .sclr(trigger[11]), 
		.regOut(regulatorData[3*16 +: 16]), .regOutUpdate(regulatorUpdate[3]), 
		.inputOffset(input_offset3[15:0]), .underflow(externalStatus[6]), .overflow(externalStatus[7]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'hb & ~pi_gate_3), .set_output_clk(daccmd_trig)  );

	wire pi_gate_4;
   delayed_on_gate delayed_on_gate_4( .clk(clk), .gate(shutter[36]), .delay(enable_delay4[31:2]), .q(pi_gate_4) );
	picore ampl_piCore4( .clk(clk), .update(ADCReady[4]), .errorsig(ADCData[4*16+:16]), 
		.pCoeff(pCoeff4[31:0]), .iCoeff(iCoeff4[31:0]), 
		.enable(pi_gate_4), .sclr(trigger[12]), 
		.regOut(regulatorData[4*16 +: 16]), .regOutUpdate(regulatorUpdate[4]), 
		.inputOffset(input_offset4[15:0]), .underflow(externalStatus[8]), .overflow(externalStatus[9]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'hc & ~pi_gate_4), .set_output_clk(daccmd_trig)  );
		
	wire pi_gate_5;
   delayed_on_gate delayed_on_gate_5( .clk(clk), .gate(shutter[37]), .delay(enable_delay5[31:2]), .q(pi_gate_5) );
	picore ampl_piCore5( .clk(clk), .update(ADCReady[5]), .errorsig(ADCData[5*16+:16]), 
		.pCoeff(pCoeff5[31:0]), .iCoeff(iCoeff5[31:0]), 
		.enable(pi_gate_5), .sclr(trigger[13]), 
		.regOut(regulatorData[5*16 +: 16]), .regOutUpdate(regulatorUpdate[5]), 
		.inputOffset(input_offset5[15:0]), .underflow(externalStatus[10]), .overflow(externalStatus[11]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'hd & ~pi_gate_5), .set_output_clk(daccmd_trig)  );

	wire pi_gate_6;
   delayed_on_gate delayed_on_gate_6( .clk(clk), .gate(shutter[38]), .delay(enable_delay6[31:2]), .q(pi_gate_6) );
	picore ampl_piCore6( .clk(clk), .update(ADCReady[6]), .errorsig(ADCData[6*16+:16]), 
		.pCoeff(pCoeff6[31:0]), .iCoeff(iCoeff6[31:0]), 
		.enable(pi_gate_6), .sclr(trigger[14]), 
		.regOut(regulatorData[6*16 +: 16]), .regOutUpdate(regulatorUpdate[6]), 
		.inputOffset(input_offset6[15:0]), .underflow(externalStatus[12]), .overflow(externalStatus[13]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'he & ~pi_gate_6), .set_output_clk(daccmd_trig)  );

	wire pi_gate_7;
   delayed_on_gate delayed_on_gate_7( .clk(clk), .gate(shutter[39]), .delay(enable_delay7[31:2]), .q(pi_gate_7) );
	picore ampl_piCore7( .clk(clk), .update(ADCReady[7]), .errorsig(ADCData[7*16+:16]), 
		.pCoeff(pCoeff7[31:0]), .iCoeff(iCoeff7[31:0]), 
		.enable(pi_gate_7), .sclr(trigger[15]), 
		.regOut(regulatorData[7*16 +: 16]), .regOutUpdate(regulatorUpdate[7]), 
		.inputOffset(input_offset7[15:0]), .underflow(externalStatus[14]), .overflow(externalStatus[15]), 
		.output_offset(DDSData[15:0]), .set_output_offset(~DDSCmd[3] & DDSAddress==8'hf & ~pi_gate_7), .set_output_clk(daccmd_trig)  );
		
		
	assign ADCData[8*16 +: 16] = regulatorData[0*16 +: 16];
	assign ADCData[9*16 +: 16] = regulatorData[1*16 +: 16];
	assign ADCData[10*16 +: 16] = regulatorData[2*16 +: 16];
	assign ADCData[11*16 +: 16] = regulatorData[3*16 +: 16];
	assign ADCData[12*16 +: 16] = regulatorData[4*16 +: 16];
	assign ADCData[13*16 +: 16] = regulatorData[5*16 +: 16];
	assign ADCData[14*16 +: 16] = regulatorData[6*16 +: 16];
	assign ADCData[15*16 +: 16] = regulatorData[7*16 +: 16];
	assign ADCReady[15:8] = regulatorUpdate[7:0];
	assign externalStatus[23:17] = 15'h0;
	assign externalStatus[31:24] = level_in[7:0];
`else
	assign externalStatus[23:17] = 15'h0;
	assign externalStatus[31:24] = level_in[7:0];
`endif

`ifdef ExternalClockImplementation
	assign externalStatus[16] = ext_clk_present;
`else
	assign externalStatus[16] = 1'b0;
`endif
	
	///////////////////////////////////////////////////////////////////////////////////
	//  ADC control
	///////////////////////////////////////////////////////////////////////////////////
`ifdef BreakoutSandia2
	ADCReaderBoardV1 ADCReaderBoardV1( .clk(clk), .adc_enable(4'hf), 
												  .adc1out(adc1out),  .adc1dout(adc1dout), .adc2out(adc2out), .adc2dout(adc2dout),
												  .adcdata( ADCData[4*16-1:0] ), .adcready( ADCReady[3:0] )    );
`endif
`ifdef BreakoutSandiaOrig
	ADCReaderBoardV1 ADCReaderBoardV1( .clk(clk), .adc_enable(4'hf), 
												  .adc1out(adc1out),  .adc1dout(adc1dout), .adc2out(adc2out), .adc2dout(adc2dout),
												  .adcdata( ADCData[4*16-1:0] ), .adcready( ADCReady[3:0] )    );
`endif

`ifdef BreakoutDukeADCDAC
	assign DAC_LDAC = ~long_trigger[10];
	
	assign ADC_OS = 2'h0;
	assign ADC_RESET = 0;
	wire ADC_sclk_enable;
	wire [7:0] ADCReady_slow;
	ODDR2 oddr_adc(.D0(1'b1), .D1(1'b0), .C0(clk12p5MHz), .C1(~clk12p5MHz), .CE(ADC_sclk_enable), .Q(ADC_SCLK), .R(1'b0), .S(1'b0) );
   ADCReaderAD7608 ADCReaderAD7608( .clk(clk12p5MHz), .adc_enable( 8'hff ), 
												.adcdata( ADCData[8*16-1:0] ), .adcready( ADCReady_slow[7:0] ),
												.cs(ADC_CS), .convst(ADC_CONVST), .sclk_enable(ADC_sclk_enable), .adc_dout(ADC_DOUT), .adc_busy(ADC_BUSY) );
	genvar i;
	generate
	for (i=0; i<8; i=i+1) begin : loop_gen_block
		monoflop adc_mf( .clock(clk), .trigger(ADCReady_slow[i]), .enable(1'b1), .q(ADCReady[i]) ); 
	end
	endgenerate
	
												
	// DAC output selects
	wire [15:0] regDAC0, regDAC1, regDAC2, regDAC3, regDAC4, regDAC5, regDAC6, regDAC7;
	wire [15:0] scanDAC0, scanDAC1, scanDAC2, scanDAC3, scanDAC4, scanDAC5, scanDAC6, scanDAC7;
	wire [7:0] updRegDAC;
	SignalSelect pi_output_select_dac0( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC0), .signal_out(regDAC0), .available_out(updRegDAC[0]) );
	SignalSelect pi_output_select_dac1( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC1), .signal_out(regDAC1), .available_out(updRegDAC[1]) );
	SignalSelect pi_output_select_dac2( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC2), .signal_out(regDAC2), .available_out(updRegDAC[2]) );
	SignalSelect pi_output_select_dac3( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC3), .signal_out(regDAC3), .available_out(updRegDAC[3]) );
	SignalSelect pi_output_select_dac4( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC4), .signal_out(regDAC4), .available_out(updRegDAC[4]) );
	SignalSelect pi_output_select_dac5( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC5), .signal_out(regDAC5), .available_out(updRegDAC[5]) );
	SignalSelect pi_output_select_dac6( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC6), .signal_out(regDAC6), .available_out(updRegDAC[6]) );
	SignalSelect pi_output_select_dac7( .clk(clk), .signal_in(regulatorData), .available_in(regulatorUpdate), .channel_select(PIChannelDAC7), .signal_out(regDAC7), .available_out(updRegDAC[7]) );

`ifdef DACScanning
	VarScanGenerator scanGen0( .clk(clk), .increment(scan_increment_0), .sinit(1'b0), .scan_min(scan_min_0), .scan_max(scan_max_0), .scan_enable(shutter[40]), .q(scanDAC0) );
	VarScanGenerator scanGen1( .clk(clk), .increment(scan_increment_1), .sinit(1'b0), .scan_min(scan_min_1), .scan_max(scan_max_1), .scan_enable(shutter[41]), .q(scanDAC1) );
	VarScanGenerator scanGen2( .clk(clk), .increment(scan_increment_2), .sinit(1'b0), .scan_min(scan_min_2), .scan_max(scan_max_2), .scan_enable(shutter[42]), .q(scanDAC2) );
	VarScanGenerator scanGen3( .clk(clk), .increment(scan_increment_3), .sinit(1'b0), .scan_min(scan_min_3), .scan_max(scan_max_3), .scan_enable(shutter[43]), .q(scanDAC3) );
	VarScanGenerator scanGen4( .clk(clk), .increment(scan_increment_4), .sinit(1'b0), .scan_min(scan_min_4), .scan_max(scan_max_4), .scan_enable(shutter[44]), .q(scanDAC4) );
	VarScanGenerator scanGen5( .clk(clk), .increment(scan_increment_5), .sinit(1'b0), .scan_min(scan_min_5), .scan_max(scan_max_5), .scan_enable(shutter[45]), .q(scanDAC5) );
	VarScanGenerator scanGen6( .clk(clk), .increment(scan_increment_6), .sinit(1'b0), .scan_min(scan_min_6), .scan_max(scan_max_6), .scan_enable(shutter[46]), .q(scanDAC6) );
	VarScanGenerator scanGen7( .clk(clk), .increment(scan_increment_7), .sinit(1'b0), .scan_min(scan_min_7), .scan_max(scan_max_7), .scan_enable(shutter[47]), .q(scanDAC7) ); 
`endif

	wire dac_clk_enable;
	ODDR2 oddr_dac(.D0(1'b1), .D1(1'b0), .C0(clk), .C1(~clk), .CE(dac_clk_enable), .Q(DAC_SCLK), .R(1'b0), .S(1'b0) );
	DAC8568 DAC0(.clk(clk), .sclk_in(clk), .cmd(DDSCmd), .data(DDSData[15:0]), .ready(daccmd_trig), .address(DDSAddress & 16'hf), 
					 .dac_clk_enable(dac_clk_enable), .dac_din(DAC_DIN), .dac_sync(DAC_SYNC), .ndone(dds_write_done_bundle[11]), 
`ifdef DACScanning
					 .lock_data0(shutter[40] ? scanDAC0 : regDAC0), .lock_ready0(shutter[40] ? 1'b1 : updRegDAC[0]), 
					 .lock_data1(shutter[41] ? scanDAC1 : regDAC1), .lock_ready1(shutter[41] ? 1'b1 : updRegDAC[1]), 
					 .lock_data2(shutter[42] ? scanDAC2 : regDAC2), .lock_ready2(shutter[42] ? 1'b1 : updRegDAC[2]), 
					 .lock_data3(shutter[43] ? scanDAC3 : regDAC3), .lock_ready3(shutter[43] ? 1'b1 : updRegDAC[3]), 
					 .lock_data4(shutter[44] ? scanDAC4 : regDAC4), .lock_ready4(shutter[44] ? 1'b1 : updRegDAC[4]), 
					 .lock_data5(shutter[45] ? scanDAC5 : regDAC5), .lock_ready5(shutter[45] ? 1'b1 : updRegDAC[5]), 
					 .lock_data6(shutter[46] ? scanDAC6 : regDAC6), .lock_ready6(shutter[46] ? 1'b1 : updRegDAC[6]), 
					 .lock_data7(shutter[47] ? scanDAC7 : regDAC7), .lock_ready7(shutter[47] ? 1'b1 : updRegDAC[7])
`else
					 .lock_data0(regDAC0), .lock_ready0(updRegDAC[0]), 
					 .lock_data1(regDAC1), .lock_ready1(updRegDAC[1]), 
					 .lock_data2(regDAC2), .lock_ready2(updRegDAC[2]), 
					 .lock_data3(regDAC3), .lock_ready3(updRegDAC[3]), 
					 .lock_data4(regDAC4), .lock_ready4(updRegDAC[4]), 
					 .lock_data5(regDAC5), .lock_ready5(updRegDAC[5]), 
					 .lock_data6(regDAC6), .lock_ready6(updRegDAC[6]), 
					 .lock_data7(regDAC7), .lock_ready7(updRegDAC[7]) 
`endif
	);
	
	
	
`else
	assign dds_write_done_bundle[11] = 1'b0;
`endif

endmodule


