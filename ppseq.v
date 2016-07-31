`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

//////////////////////////////////////////////////////////////////////////////////
// Pulse Programmer Core
//
//
//////////////////////////////////////////////////////////////////////////////////
module ppseq(fast_clk, memory_clk, clk_i, usb_clk, reset_i, start_i, stop_i, pp_active_o,
			 pp_addr_o, pp_din_i, pp_we_o, pp_dout_o, count_i, 
			 cmd_addr_o, cmd_in, 
			 ddsdata_o, ddscmd_o, ddscmd_trig_o, daccmd_trig_o, serialcmd_trig_o, parameter_trig_o, write_active,
			 shutter_o, PC_o, trigger_o,
			 fifo_data, fifo_data_ready, fifo_full, fifo_rst,
			 data_fifo_read, data_fifo_data, data_fifo_empty,
			 pp_ram_data, pp_ram_read, pp_ram_set_address, pp_ram_address, pp_ram_valid,   // access to onboard RAM
			 state_debug, counter_mask_out, trigger_in, level_in, adc_data, adc_update, timestamp_counter_reset, tdc_count,
			 pp_update, pp_interrupt, staticShutter ); 
			 
	input wire 					fast_clk;
	input wire					memory_clk;
	input wire					clk_i;
	input wire					reset_i;
	input wire					start_i;		// start trigger (one cycle high)
	input wire					stop_i;			// stop trigger (one cycle high)
	input wire 					usb_clk;
	input wire					pp_interrupt;  // signal that the pp should stop at a convenient location

	output reg [15:0]		pp_addr_o=0;	  // pp memory address
	input  wire signed [63:0]	pp_din_i;		// pp memory output
	output reg					   pp_we_o=0;		// pp memory we
	output wire [63:0]			pp_dout_o;	  // pp memory input
	
	output wire [15:0]      cmd_addr_o;   // cmd memory address
	input wire [31:0]       cmd_in;       // command memory data
		  
	input wire [15:0]				count_i;		// PMT signal (single clk cycle high) 
		  
	output reg [63:0]			ddsdata_o;
	output reg [11:0]			ddscmd_o;
	output reg					ddscmd_trig_o;
	output reg					daccmd_trig_o;
	output reg              serialcmd_trig_o = 0;   // serial reuses ddsdata_o, ddscmd_o, dds_write_done
	output reg              parameter_trig_o = 0;
	input wire [15:0]			write_active;
	
	output wire [63:0]			shutter_o;		// BNC shutter outputs. Increase # of shutters from 4 to 12 CWC 08132012
	output reg [63:0]			trigger_o;     // to be used for update triggers for DDS and DAC, are 0 by default
	output wire [63:0]		counter_mask_out;  // copy of counter_mask to be traced by logic analyzer
	
	output reg					pp_active_o = 0;		// 1=active, 0=idle
		  
	// status outputs:
	output wire [15:0]			PC_o;		// program counter
		
	output wire [63:0]     fifo_data;
	output wire            fifo_data_ready;
	input wire 				  fifo_full;
	input wire				  fifo_rst;

	// Data FIFO Interface FIFO is first word fall through
	input wire [63:0] data_fifo_data;
	input wire data_fifo_empty;
	output reg data_fifo_read = 0;

	// Access to the onboard RAM
	input wire [63:0] pp_ram_data;
	output reg pp_ram_read  = 0, pp_ram_set_address = 0;
	output reg [31:0] pp_ram_address = 0;
	input wire pp_ram_valid;
	input wire [7:0] trigger_in;
	input wire [7:0] level_in;
	
	// ADC interface
	input wire [16*16-1:0] adc_data;
	input wire [15:0] adc_update;
	
	input wire timestamp_counter_reset;
	output wire [39:0]  tdc_count;
	
	// debug
	output wire [3:0] state_debug;
	output wire pp_update;
	input wire [63:0] staticShutter;

	// counter wires
	wire [575:0] all_counts;
	wire [447:0] adc_sum;
	wire [191:0] adc_counts;
	reg  [575:0] all_counts_buffer;
	
	reg [63:0] counter_mask_proto = 0;
	wire [63:0] counter_mask;
	reg [39:0] tdc_count_buffer = 0;
	
//// Interrupt buffering
	reg pp_interrupt_reset = 0;
	wire pp_interrupt_buffer;
	set_reset interrupt_set_reset( .clock(memory_clk), .set(pp_interrupt), .reset(pp_interrupt_reset), .q(pp_interrupt_buffer) );
	
	
////////////////////////////////////////
// pulse sequencer instruction definitions

	localparam			PP_NOP		= 8'h00;	// no operation
	
	localparam			PP_DDSFRQ	= 8'h01; // set dds frequency
	localparam			PP_DDSAMP	= 8'h02;	// set dds amplitude
	localparam			PP_DDSPHS	= 8'h03;	// set dds phase
	
	localparam			PP_LDWR		= 8'h08;	// W <= *REG
	localparam			PP_LDWI		= 8'h09;	// W <= *INDF (store *INDF into W)
	localparam			PP_STWR		= 8'h0A;	// *REG <= W
	localparam			PP_STWI		= 8'h0B;	// *INDF <= W (store W into location at INDF)
	localparam			PP_LDINDF	= 8'h0C;	// INDF <= *REG
	localparam			PP_ANDW		= 8'h0D;	// W = W & *REG
	localparam			PP_ADDW		= 8'h0E;	// W = W + *REG
	localparam			PP_INC		= 8'h0F;	// W = W + 1
	localparam			PP_DEC		= 8'h10;	// W = W - 1
	localparam			PP_CLRW		= 8'h11; // W = 0
	localparam			PP_CMP		= 8'h12;	// (W > *REG) ? W = W : W = 0
	localparam			PP_JMP		= 8'h13;	// Jump
	localparam			PP_JMPZ		= 8'h14;	// Jump to specified location if W = 0
	localparam			PP_JMPNZ		= 8'h15;	// Jump to specified location if W != 0
	localparam			PP_SHL		= 8'h16; // Shift left bits given in cmd bits 23:16
	localparam			PP_SHR		= 8'h17; // Shift right bits given by cmd bit 23:16
	
	// AD9910 ramping DDS functionality:
   localparam 	PP_DDS9910_SAVEAMP            = 8'h19;
   localparam 	PP_DDS9910_SAVEPHS            = 8'h20;
   localparam 	PP_DDS9910_SAVEFRQ            = 8'h21; 
   localparam 	PP_DDS9910_SETAPF             = 8'h22;
   localparam 	PP_DDS9910_SAVERAMPSTEPDOWN   = 8'h23;
   localparam 	PP_DDS9910_SAVERAMPSTEPUP   	= 8'h24;
   localparam 	PP_DDS9910_SETRAMPSTEPS       = 8'h25;
   localparam 	PP_DDS9910_SAVERAMPTIMESTEPDOWN   = 8'h26;
   localparam 	PP_DDS9910_SAVERAMPTIMESTEPUP		 = 8'h27;
   localparam 	PP_DDS9910_SETRAMPTIMESTEPS       = 8'h28;
   localparam 	PP_DDS9910_SAVERAMPMAX            = 8'h29;
   localparam 	PP_DDS9910_SAVERAMPMIN            = 8'h2A;
   localparam 	PP_DDS9910_SETRAMPLIMITS          = 8'h2B;
   localparam 	PP_DDS9910_SAVENODWELLHIGH        = 8'h2C;
   localparam 	PP_DDS9910_SAVENODWELLLOW         = 8'h2D;
   localparam 	PP_DDS9910_SAVERAMPTYPE           = 8'h2E;
   localparam 	PP_DDS9910_SETCFR2RAMPPARAMS      = 8'h2F;

	///// Additions to allow for fixed timing
	localparam			PP_SHUTTERMASK = 8'h30;  // set the register shutter mask, defining which shutter channels will be set by a shutter command
	localparam			PP_ASYNCSHUTTER= 8'h31;  // set the SHUTTER outputs, will only become effective on UPDATE
	localparam			PP_COUNTERMASK	= 8'h32;  // set counter mask MS 16 bit are mask, LS 16 bit are enable, of each MS 8 bit are for timestamping, LS 8 bit for counting
	localparam			PP_TRIGGER		= 8'h33;  // set trigger bits, will update on UPDATE
	localparam			PP_UPDATE		= 8'h34;  // UPDATE all of the above and set the wait counter
	localparam			PP_WAIT			= 8'h35;	 // WAIT for the last wait counter to expire, typically called before UPDATE
	localparam			PP_LDCOUNT		= 8'h37;  // Load the last counter value into W, the 3 LSB give the counter number
	localparam			PP_WRITEPIPE   = 8'h38;  // Write the contents of the W register to the BTPipe to the host computer
	localparam			PP_READPIPE    = 8'h39;  // Read one word from the input pipe to the W register
	localparam			PP_LDTDCCOUNT	= 8'h3a;  // load current tdc count value into W
	localparam			PP_CMPEQUAL		= 8'h3b;  // reg_cmp = (W == *REG)
	localparam			PP_JMPCMP		= 8'h3c;  // JMP if CMP
	localparam			PP_JMPNCMP		= 8'h3d;  // JMP if not CMP
	localparam			PP_JMPPIPEAVAIL = 8'h3e; // JMP if input pipe available
	localparam			PP_JMPPIPEEMPTY = 8'h3f; // JMP if pipe not available
	localparam			PP_READPIPEINDF = 8'h40; // Read INDF from pipe bit 15 is also copied into reg_cmp
	localparam			PP_WRITEPIPEINDF = 8'h41; // Write INDF to pipe
	localparam			PP_SETRAMADDR   = 8'h42; // Set address of onboard RAM
	localparam			PP_RAMREADINDF  = 8'h43;  // Read word from RAM into indirect register
	localparam		   PP_RAMREAD      = 8'h44;  // Read word from RAM into W register
	localparam			PP_JMPRAMVALID  = 8'h45;  // jmp if ram input is valid
	localparam			PP_JMPRAMINVALID = 8'h46; // jmp if ram input is invalid
	localparam			PP_CMPGE        = 8'h47;  // reg_cmp = (W>= *REG)
	localparam			PP_CMPLE        = 8'h48;  // reg_cmp = (W<= *REG)
	localparam        PP_CMPGREATER   = 8'h4a;  // reg_cmp = (W> *REG)
	localparam			PP_ORW			 = 8'h4b;  // W = W | *REG
	localparam			PP_MULTW			 = 8'h4c;  // W = W * *REG  // non-functional
	localparam			PP_UPDATEINDF   = 8'h4d;  // like update only use the register pointed to by INDF
	localparam			PP_WAITDDSWRITEDONE = 8'h4e;  // wait until dds_write_done is true
	localparam			PP_CMPLESS      = 8'h4f;   // reg_cmp = (W< *REG)
	localparam			PP_ASYNCINVSHUTTER = 8'h50; // set the SHUTTER outputs to the inverse, will only become effective on UPDATE
	localparam			PP_CMPNOTEQUAL  = 8'h51;
	localparam			PP_SUBW   	    = 8'h52;
	localparam			PP_WAITFORTRIGGER = 8'h53;   // wait for trigger
	localparam			PP_WRITERESULTTOPIPE	= 8'h54;
	localparam        PP_SERIALWRITE = 8'h55;
	localparam			PP_DIVW = 8'h56;
	localparam			PP_SETPARAMETER = 8'h57;
	localparam			PP_MP9910_RAMPDIR = 8'h5a;
	localparam 			PP_DACOUT        = 8'h5b;
	localparam			PP_LDACTIVE       = 8'h5c;
	localparam			PP_JMPNINTERRUPT  = 8'h5d;
	localparam			PP_LDADCCOUNT = 8'h5e;
	localparam			PP_LDADCSUM = 8'h5f;
	localparam			PP_RAND = 8'h60;
	localparam			PP_RANDSEED = 8'h61;
	localparam			PP_STOP		= 8'hFF;	// end program
			
	// command words used in ddssys.v and dds_ad9858_serial.v, ad9912.v, AD9910.v, and MP9910.v
	localparam			ACMD_FRQ	= 4'h0;
	localparam			ACMD_PHS	= 4'h1;
	localparam			ACMD_AMP	= 4'h2;
	localparam 			AD9910_RAMPSTEPS		= 4'h3;
	localparam 			AD9910_RAMPTIMESTEPS	= 4'h4;
	localparam 			AD9910_RAMPLIMITS		= 4'h5;
	localparam			AD9910_CFR2RAMP 		= 4'h6;
	localparam			AD9910_STPROFILE		= 4'h7;
	localparam			MP9910_RAMPDIR			= 4'ha;
	
	// registers for AD9910 writes
	reg [63:0] DDS9910_apf = 64'h0; // 14bit amplitude, 16bit phase, 32bit frequency that all must be written together.
	reg [63:0] DDS9910_rampsteps = 64'h0; // 32bit decrement, 32bit increment
	reg [63:0] DDS9910_ramptimesteps = 64'h0; // 16bit negative, 16bit positive
	reg [63:0] DDS9910_ramplimits = 64'h0; // 32bit upper, 32bit lower
	reg [63:0] DDS9910_CFR2_rampparams = 64'h0; // [4:0] = [2-bit DR destination], [1-bit DR enable], [1-bit DR no-dwell High and 1-bit no-dwell Low]
	
// Register definitions
	//
	reg signed [63:0]	W = 0; 
	reg [15:0]			PC = 0;
	reg [15:0]			LastPC = 0;
	reg [15:0]        INDF = 0;
	reg					reg_cmp = 0;
	
	//// new registers for advanced commands
	reg [63:0]		shutter_mask = 64'hffffffffffffffff;    // bitmask of bits being affected by the next shutter command
	reg [63:0]		shutter_reg = 0;	  // buffer to hold next value of shutter register, copied to shutter_o on UPDATE
	reg [63:0]     shutter_reg_buffer = 0;
	reg [63:0]		pulse_end_shutter_reg = 0;
	reg [63:0]		trigger_reg = 0;	  // buffer to hold next value of trigger register, copied to trigger_o on UPDATE
	reg [63:0]		counter_mask_reg = 0;
	reg [7:0]      counter_id_reg = 0;
	reg [63:0]		timed_delay = 0;     // value to initialize the delay counter
	reg				timed_delay_greater_1 = 0;
	reg				timed_delay_start = 0; // trigger to start timed delay
	wire				timed_wait_expired; // high while timed wait counter running
	wire			   pulsed_timed_wait_expired;
	reg				output_data_available = 0;
	reg [31:0]		trigger_in_mask = 32'h000000ff;
	reg [129:0]		output_data = 0;
	reg [7:0]      calc_wait_count = 0;
	reg [63:0]		data_buffer = 0;
	wire [63:0]    mult_result;
	wire [127:0]   div_result;
	wire				div_result_valid;
	wire				div_result_valid_buffered;
	reg				div_result_ack = 0;
	wire [63:0]    random;
	wire				rand_valid;
	reg				set_rand_seed = 0;
	reg				rand_read_ack = 0;

// synthesis attribute INIT of state_f is "R"
	reg [3:0]			state_f = 0;

	localparam			STATE_STOP		=  4'h0;
	localparam			STATE_SETUP	  	=  4'h1;
	localparam        STATE_POSTSETUP    = 4'h2;
	localparam			STATE_EXEC		=  4'h3;
	localparam			STATE_TIMEDWAIT = 4'h4;
	localparam			STATE_DDSWRITEWAIT = 4'h5;
	localparam			STATE_TRIGGERWAIT = 4'h6;
	localparam			STATE_MULTWAIT    = 4'h7;
	localparam			STATE_DIVWAIT     = 4'h8;
	localparam        STATE_POSTEXEC    = 4'h9;

	localparam			START_VECT		= 12'h0;
	
	wire				   delay;
	reg				   wait_counter_rst;
	reg [7:0]			cmd_code_buffer;
	reg [23:0]			cmd_data_buffer;
	wire [7:0] 			cmd_code_in  = cmd_in[31:24];
	wire [7:0] 			cmd_data_in  = cmd_in[23:0];
	reg [8:0]			cmd_is_jmp = 8'b0;
	reg 					data_fifo_empty_buffer = 1'b0;
	reg 					pp_ram_valid_buffer = 1'b0;
	reg [15:0]			UpdateAddress = 0;
	
	always @(posedge memory_clk) begin
		wait_counter_rst <= state_f==STATE_STOP;
	end
	
	// Memory address control
	assign 				need_indf_addr = (cmd_code_in == PP_LDWI) | (cmd_code_in == PP_STWI) | (cmd_code_in == PP_UPDATEINDF);
	//assign 				pp_addr_o = (need_indf_addr) ? INDF[15:0] : cmd_in[15:0];
	//assign 				pp_we_o = (cmd_in[31:24]==PP_STWR) | (cmd_in[31:24]==PP_STWI) ;
	assign            cmd_addr_o = PC;

	// Memory write control
	assign				pp_dout_o = W; 

	always @(posedge memory_clk) begin
	   pp_addr_o <= (need_indf_addr) ? INDF[15:0] : cmd_in[15:0];
		div_result_ack <= 1'b1;
		pp_interrupt_reset <= 1'b0;  // default
		rand_read_ack <= 1'b0;  // default
		set_rand_seed <= 1'b0;  // default
		if (reset_i) begin
			cmd_code_buffer <= PP_NOP;
			cmd_data_buffer <= 24'h0;
			state_f <= STATE_STOP;
			W <= 64'h0;
			ddscmd_trig_o <= 1'b0;
			daccmd_trig_o <= 1'b0;
			serialcmd_trig_o <= 1'b0;
			parameter_trig_o <= 1'b0;
			ddscmd_o <= 12'h0;
			INDF <= 16'h0;
			pp_active_o <= 1'b0;
			UpdateAddress <= 16'h0;
			//pp_we_o <= 1'b0;
			trigger_in_mask <= 32'h000000ff;
		end else if (stop_i) begin
			state_f <= STATE_STOP;
		end else begin
			 begin
				case (state_f)
				STATE_STOP: begin
					pp_interrupt_reset <= 1'b1;  // default
					pp_active_o <= 1'b0;
					//pp_we_o <= 1'b0;
					cmd_code_buffer <= PP_NOP;
					cmd_data_buffer <= 24'h0;
					PC <= START_VECT;
					W <= 64'h0;
					ddscmd_trig_o <= 1'b0;
					daccmd_trig_o <= 1'b0;
					serialcmd_trig_o <= 1'b0;
					parameter_trig_o <= 1'b0;
					INDF <= 16'h0;
					output_data_available <= 1'b0;
					data_fifo_read <= 1'b0;
					pp_ram_read <= 1'b0;
					pp_ram_set_address <= 1'b0;
					timed_delay_start <= 1'b0;
					trigger_o <= 64'h0;
					counter_mask_proto[63:0] <= 64'h0;
					trigger_in_mask <= 32'h000000ff;
					UpdateAddress <= 16'h0;
					shutter_reg_buffer <= staticShutter;
					// State
					if (start_i) state_f <= STATE_SETUP;
				end
				STATE_SETUP: begin
					pp_active_o <= 1'b1;
					ddscmd_trig_o <= 1'b0;  
					daccmd_trig_o <= 1'b0;
					serialcmd_trig_o <= 1'b0;
					parameter_trig_o <= 1'b0;
					LastPC <= PC;
					if (((cmd_code_in == PP_JMPZ) & (~|W)) | ((cmd_code_in == PP_JMPNZ) & (|W)) | (cmd_code_in == PP_JMP) 
							| ((cmd_code_in == PP_JMPCMP) & reg_cmp) | ((cmd_code_in == PP_JMPNCMP) & ~reg_cmp )
							| ((cmd_code_in == PP_JMPNINTERRUPT ) & ~pp_interrupt_buffer )
							| ((cmd_code_in == PP_JMPPIPEEMPTY) & data_fifo_empty) | ((cmd_code_in == PP_JMPPIPEAVAIL) & ~data_fifo_empty) 
							| ((cmd_code_in == PP_JMPRAMVALID) & pp_ram_valid) | ((cmd_code_in == PP_JMPRAMINVALID) & (~pp_ram_valid)) )
						PC <= cmd_in[15:0];
					else
						PC <= PC + 1;

					cmd_code_buffer <= cmd_in[31:24]; // Is it still in the first 8 bits [63:56], or is it here? RN
					cmd_data_buffer <= cmd_in[23:0];
					output_data_available <= 1'b0;
					data_fifo_read <= 1'b0;
					pp_ram_read <= 1'b0;
					pp_ram_set_address <= 1'b0;
					timed_delay_start <= 1'b0;
					trigger_o <= 64'h0;
					trigger_in_mask <= 32'h000000ff;
					//pp_we_o <= 1'b0;
					// State
					if (stop_i | (cmd_code_in == PP_STOP)) state_f <= STATE_STOP;
					else state_f <= STATE_POSTSETUP;
					pp_we_o <= (cmd_in[31:24]==PP_STWR) | (cmd_in[31:24]==PP_STWI) ;
					pp_ram_valid_buffer <= pp_ram_valid;
					data_fifo_empty_buffer <= data_fifo_empty;
					all_counts_buffer <= all_counts;
				end // case: STATE_SETUP
				STATE_POSTSETUP: begin
					state_f <= STATE_EXEC;
					tdc_count_buffer <= tdc_count;
				   end
				STATE_EXEC: begin				
					state_f <= STATE_POSTEXEC;     // default
					pp_active_o <= 1'b1;
					case (cmd_code_buffer)
					// dds commands
					PP_SERIALWRITE: begin
					   ddscmd_o <= {cmd_data_buffer[23:16], 4'h0};
						ddsdata_o <= pp_din_i;
						serialcmd_trig_o <= 1'b1;
					end
					PP_SETPARAMETER: begin
					   ddscmd_o <= {cmd_data_buffer[23:16], 4'h0};
						ddsdata_o <= pp_din_i;
						parameter_trig_o <= 1'b1;
					end
					PP_DDSFRQ: begin
						ddscmd_o <= {cmd_data_buffer[23:16], ACMD_FRQ};
						ddsdata_o <= pp_din_i;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DDSAMP: begin
						ddscmd_o <= {cmd_data_buffer[23:16], ACMD_AMP};
						ddsdata_o <= pp_din_i;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DDSPHS: begin
						ddscmd_o <= {cmd_data_buffer[23:16], ACMD_PHS};
						ddsdata_o <= pp_din_i;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DACOUT: begin
						ddscmd_o <= {cmd_data_buffer[23:16],pp_din_i[63:60] };
						ddsdata_o <= pp_din_i;
						daccmd_trig_o <= 1'b1;
					end
					// AD9910 commands
					PP_DDS9910_SAVEAMP: begin
						DDS9910_apf[61:48] <= pp_din_i[13:0];
					end
					PP_DDS9910_SAVEPHS: begin
						DDS9910_apf[47:32] <= pp_din_i[15:0];
					end
					PP_DDS9910_SAVEFRQ: begin
						DDS9910_apf[31:0] <= pp_din_i[31:0];
					end
					PP_DDS9910_SETAPF: begin
						ddscmd_o <= {cmd_data_buffer[23:16], AD9910_STPROFILE};
						ddsdata_o <= DDS9910_apf;
						ddscmd_trig_o <= 1'b1;
						DDS9910_apf <= 64'h0;
					end
					PP_DDS9910_SAVERAMPSTEPDOWN: begin
						DDS9910_rampsteps[63:32] <= pp_din_i[31:0];
					end
					PP_DDS9910_SAVERAMPSTEPUP: begin
						DDS9910_rampsteps[31:0] <= pp_din_i[31:0];
					end
					PP_DDS9910_SETRAMPSTEPS: begin
						ddscmd_o <= {cmd_data_buffer[23:16], AD9910_RAMPSTEPS};
						ddsdata_o <= DDS9910_rampsteps;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DDS9910_SAVERAMPTIMESTEPDOWN: begin
						DDS9910_ramptimesteps[31:16] <= pp_din_i[15:0];
					end
					PP_DDS9910_SAVERAMPTIMESTEPUP: begin
						DDS9910_ramptimesteps[15:0] <= pp_din_i[15:0];
					end
					PP_DDS9910_SETRAMPTIMESTEPS: begin
						ddscmd_o <= {cmd_data_buffer[23:16], AD9910_RAMPTIMESTEPS};
						ddsdata_o <= DDS9910_ramptimesteps;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DDS9910_SAVERAMPMAX: begin
						DDS9910_ramplimits[63:32] <= pp_din_i[31:0];
					end
					PP_DDS9910_SAVERAMPMIN: begin
						DDS9910_ramplimits[31:0] <= pp_din_i[31:0];
					end
					PP_DDS9910_SETRAMPLIMITS: begin
						ddscmd_o <= {cmd_data_buffer[23:16], AD9910_RAMPLIMITS};
						ddsdata_o <= DDS9910_ramplimits;
						ddscmd_trig_o <= 1'b1;
					end
					PP_DDS9910_SAVERAMPTYPE: begin
						DDS9910_CFR2_rampparams[4:2] <= {pp_din_i[1:0], 1'b1}; // 1'b1 digital ramp enable
					end
					PP_DDS9910_SAVENODWELLHIGH: begin
						DDS9910_CFR2_rampparams[1] <= pp_din_i[0];
					end
					PP_DDS9910_SAVENODWELLLOW: begin
						DDS9910_CFR2_rampparams[0] <= pp_din_i[0];
					end
					PP_DDS9910_SETCFR2RAMPPARAMS: begin
						ddscmd_o <= {cmd_data_buffer[23:16], AD9910_CFR2RAMP};
						ddsdata_o <= DDS9910_CFR2_rampparams;
						ddscmd_trig_o <= 1'b1;
					end
					PP_MP9910_RAMPDIR: begin
						ddscmd_o <= {cmd_data_buffer[23:16], MP9910_RAMPDIR};
						ddsdata_o <= pp_din_i;
						ddscmd_trig_o <= 1'b1;
					end
					// Logic commands
					PP_LDWR: W <= pp_din_i;
					PP_LDWI: W <= pp_din_i;
					PP_LDINDF:  INDF <= pp_din_i[15:0];
					PP_ANDW: W <= W & pp_din_i;
					PP_ORW: W <= W | pp_din_i;
					PP_MULTW: begin
						calc_wait_count <= 8'd26;
						data_buffer <= pp_din_i;
						state_f <= STATE_MULTWAIT;
					end
					PP_DIVW: begin
						data_buffer <= pp_din_i;
						state_f <= STATE_DIVWAIT;
						div_result_ack <= 1'b0;
					end
					PP_CLRW: W <= 64'h0;
					// commands added
					PP_LDCOUNT:
						case (cmd_data_buffer[4:0])
							5'h0: W[63:0] <= {40'h0, all_counts_buffer[0*24 +: 24]};
							5'h1: W[63:0] <= {40'h0, all_counts_buffer[1*24 +: 24]};
							5'h2: W[63:0] <= {40'h0, all_counts_buffer[2*24 +: 24]};
							5'h3: W[63:0] <= {40'h0, all_counts_buffer[3*24 +: 24]};
							5'h4: W[63:0] <= {40'h0, all_counts_buffer[4*24 +: 24]};
							5'h5: W[63:0] <= {40'h0, all_counts_buffer[5*24 +: 24]};
							5'h6: W[63:0] <= {40'h0, all_counts_buffer[6*24 +: 24]};
							5'h7: W[63:0] <= {40'h0, all_counts_buffer[7*24 +: 24]};
							5'h8: W[63:0] <= {40'h0, all_counts_buffer[8*24 +: 24]};
							5'h9: W[63:0] <= {40'h0, all_counts_buffer[9*24 +: 24]};
							5'ha: W[63:0] <= {40'h0, all_counts_buffer[10*24 +: 24]};
							5'hb: W[63:0] <= {40'h0, all_counts_buffer[11*24 +: 24]};
							5'hc: W[63:0] <= {40'h0, all_counts_buffer[12*24 +: 24]};
							5'hd: W[63:0] <= {40'h0, all_counts_buffer[13*24 +: 24]};
							5'he: W[63:0] <= {40'h0, all_counts_buffer[14*24 +: 24]};
							5'hf: W[63:0] <= {40'h0, all_counts_buffer[15*24 +: 24]};
							5'h10: W[63:0] <= {40'h0, all_counts_buffer[16*24 +: 24]};
							5'h11: W[63:0] <= {40'h0, all_counts_buffer[17*24 +: 24]};
							5'h12: W[63:0] <= {40'h0, all_counts_buffer[18*24 +: 24]};
							5'h13: W[63:0] <= {40'h0, all_counts_buffer[19*24 +: 24]};
							5'h14: W[63:0] <= {40'h0, all_counts_buffer[20*24 +: 24]};
							5'h15: W[63:0] <= {40'h0, all_counts_buffer[21*24 +: 24]};
							5'h16: W[63:0] <= {40'h0, all_counts_buffer[22*24 +: 24]};
							5'h17: W[63:0] <= {40'h0, all_counts_buffer[23*24 +: 24]};
						endcase
					PP_LDADCCOUNT:
						case (cmd_data_buffer[4:0])
							5'h0: W[63:0] <= {52'h0, adc_counts[0*12 +: 12]};
							5'h1: W[63:0] <= {52'h0, adc_counts[1*12 +: 12]};
							5'h2: W[63:0] <= {52'h0, adc_counts[2*12 +: 12]};
							5'h3: W[63:0] <= {52'h0, adc_counts[3*12 +: 12]};
							5'h4: W[63:0] <= {52'h0, adc_counts[4*12 +: 12]};
							5'h5: W[63:0] <= {52'h0, adc_counts[5*12 +: 12]};
							5'h6: W[63:0] <= {52'h0, adc_counts[6*12 +: 12]};
							5'h7: W[63:0] <= {52'h0, adc_counts[7*12 +: 12]};
							5'h8: W[63:0] <= {52'h0, adc_counts[8*12 +: 12]};
							5'h9: W[63:0] <= {52'h0, adc_counts[9*12 +: 12]};
							5'ha: W[63:0] <= {52'h0, adc_counts[10*12 +: 12]};
							5'hb: W[63:0] <= {52'h0, adc_counts[11*12 +: 12]};
							5'hc: W[63:0] <= {52'h0, adc_counts[12*12 +: 12]};
							5'hd: W[63:0] <= {52'h0, adc_counts[13*12 +: 12]};
							5'he: W[63:0] <= {52'h0, adc_counts[14*12 +: 12]};
							5'hf: W[63:0] <= {52'h0, adc_counts[15*12 +: 12]};
						endcase
					PP_LDADCSUM:
						case (cmd_data_buffer[4:0])
							5'h0: W[63:0] <= {36'h0, adc_sum[0*28 +: 28]};
							5'h1: W[63:0] <= {36'h0, adc_sum[1*28 +: 28]};
							5'h2: W[63:0] <= {36'h0, adc_sum[2*28 +: 28]};
							5'h3: W[63:0] <= {36'h0, adc_sum[3*28 +: 28]};
							5'h4: W[63:0] <= {36'h0, adc_sum[4*28 +: 28]};
							5'h5: W[63:0] <= {36'h0, adc_sum[5*28 +: 28]};
							5'h6: W[63:0] <= {36'h0, adc_sum[6*28 +: 28]};
							5'h7: W[63:0] <= {36'h0, adc_sum[7*28 +: 28]};
							5'h8: W[63:0] <= {36'h0, adc_sum[8*28 +: 28]};
							5'h9: W[63:0] <= {36'h0, adc_sum[9*28 +: 28]};
							5'ha: W[63:0] <= {36'h0, adc_sum[10*28 +: 28]};
							5'hb: W[63:0] <= {36'h0, adc_sum[11*28 +: 28]};
							5'hc: W[63:0] <= {36'h0, adc_sum[12*28 +: 28]};
							5'hd: W[63:0] <= {36'h0, adc_sum[13*28 +: 28]};
							5'he: W[63:0] <= {36'h0, adc_sum[14*28 +: 28]};
							5'hf: W[63:0] <= {36'h0, adc_sum[15*28 +: 28]};
						endcase							
					PP_LDACTIVE: begin
							W[63:0] <= {48'h0, write_active[15:0] };
						end
					PP_RAND: begin
							W[63:0] <= random[63:0];
							rand_read_ack <= 1'b1;
						end
					PP_RANDSEED: begin
							set_rand_seed <= 1'b1;
						end
					PP_SHUTTERMASK: shutter_mask[63:0] <= pp_din_i[63:0];
					PP_ASYNCSHUTTER: begin
							shutter_reg[63:0] <= (shutter_mask[63:0] & pp_din_i[63:0]) | (~shutter_mask[63:0] & shutter_reg[63:0]);
							pulse_end_shutter_reg[63:0] <= (shutter_mask[63:0] & ~pp_din_i[63:0]) | (~shutter_mask[63:0] & shutter_reg[63:0]);
						end
					PP_ASYNCINVSHUTTER: shutter_reg[63:0] <= (shutter_mask[63:0] & ~pp_din_i[63:0]) | (~shutter_mask[63:0] & shutter_reg[63:0]);
					PP_COUNTERMASK: begin
							counter_mask_reg[63:0]	<= pp_din_i[63:0];
							counter_id_reg[7:0] <= cmd_data_buffer[23:16];
						end
					PP_TRIGGER: trigger_reg[63:0] <= trigger_reg[63:0] | pp_din_i[63:0];
					PP_UPDATE: begin
						trigger_o[63:0] <= trigger_reg[63:0];
						trigger_reg[63:0] <= 64'h0;
						counter_mask_proto[63:0] <= counter_mask_reg[63:0];
						timed_delay <= pp_din_i[63:0];
						timed_delay_start <= 1'b1;
						shutter_reg_buffer <= shutter_reg;
						if (cmd_data_buffer[16]) shutter_reg <= pulse_end_shutter_reg[63:0];
						if (~cmd_data_buffer[16] & |pp_din_i[63:0]) begin
							UpdateAddress <= LastPC;
						end else begin
							UpdateAddress <= 16'h0;
						end
					end
					PP_UPDATEINDF: begin
						trigger_o[63:0] <= trigger_reg[63:0];
						trigger_reg[63:0] <= 64'h0;
						counter_mask_proto[63:0] <= counter_mask_reg[63:0];
						timed_delay <= pp_din_i[63:0];
						timed_delay_start <= 1'b1;
						shutter_reg_buffer <= shutter_reg;
						if (cmd_data_buffer[16]) shutter_reg <= pulse_end_shutter_reg[63:0];
					end
					PP_WAIT: begin
						state_f <= STATE_TIMEDWAIT;
						if (|UpdateAddress & timed_wait_expired) begin
							output_data_available <= 1'b1;
							output_data <= { 1'b1, 16'hfffb, 32'h0, UpdateAddress, 1'b0, 64'h0 };						
						end
					end
					PP_WRITEPIPE: begin
						output_data_available <= 1'b1;
						output_data <= { 1'b1, W, 65'h0 };
					end
					PP_WRITERESULTTOPIPE: begin
						output_data_available <= 1'b1;
						output_data <= { 1'b1, 8'h51, cmd_data_buffer[23:16], pp_din_i[47:0], |(pp_din_i[63:48]) ,8'h50, cmd_data_buffer[23:16], 32'h0, pp_din_i[63:48] };						
					end
					PP_WRITEPIPEINDF: begin
						output_data_available <= 1'b1;
						output_data <= { 1'b1, 48'hfffc00000000, INDF[15:0], 65'h0 }; //RN changed from INDF[11:0] as I think it should be.
					end
					PP_READPIPE: begin
						data_fifo_read <= 1'b1;
						W <= data_fifo_data;
					end
					PP_READPIPEINDF: begin
						data_fifo_read <= 1'b1;
						INDF[15:0] <= data_fifo_data[15:0];
						reg_cmp <= data_fifo_data[15];
					end
					PP_LDTDCCOUNT: W <= {24'h0, tdc_count_buffer[39:0] };
					PP_SETRAMADDR: begin
						pp_ram_address <= pp_din_i[31:0]; // Set address of onboard RAM
						pp_ram_set_address <= 1'b1;
					end
					PP_RAMREADINDF: begin
						pp_ram_read <= 1'b1;
						INDF[15:0] <= pp_ram_data[15:0];
					end
					PP_RAMREAD: begin
						pp_ram_read <= 1'b1;
						W <= pp_ram_data;
					end		
					PP_WAITFORTRIGGER: begin
						trigger_in_mask <= pp_din_i[31:0];
						state_f <= STATE_TRIGGERWAIT;
					end
					PP_WAITDDSWRITEDONE: begin
						state_f  <= STATE_DDSWRITEWAIT;
					end
					PP_JMPNINTERRUPT: begin
						pp_interrupt_reset <= 1'b1;
					end
					endcase
				end // case: STATE_EXEC
				STATE_POSTEXEC: begin
				    state_f <= STATE_SETUP;
					 pp_we_o <= 1'b0;
					 case (cmd_code_buffer)
							PP_ADDW: W <= W + pp_din_i;
							PP_SUBW: W <= W - pp_din_i;
							//PP_CMP:  W <= (W > pp_din_i) ? W : 64'h0;
							PP_CMP: W <= { 63'h0, W > pp_din_i };
							PP_CMPEQUAL: reg_cmp <= ( W == pp_din_i );
							PP_CMPGE: reg_cmp <= ( W>= pp_din_i );
							PP_CMPLE: reg_cmp <= ~( W> pp_din_i );
							PP_CMPGREATER:  reg_cmp <= ( W> pp_din_i );
							PP_CMPLESS: reg_cmp <= (W< pp_din_i);
							PP_SHL: W <= W <<< pp_din_i[5:0];
							PP_SHR: W <= W >>> pp_din_i[5:0];  // sign extended bitshift
							PP_INC:  W <= pp_din_i + 64'h1;
							PP_DEC:  W <= pp_din_i - 64'h1;
					 endcase
				    end
				STATE_TIMEDWAIT: begin
					pp_active_o <= 1'b1;
					if (timed_wait_expired) begin
						state_f <= STATE_SETUP;
					end else begin
    					state_f <= STATE_TIMEDWAIT;
   				end
					output_data_available <= 1'b0;
					data_fifo_read <= 1'b0;
					pp_ram_read <= 1'b0;
					pp_ram_set_address <= 1'b0;
					timed_delay_start <= 1'b0;
					trigger_o <= 64'h0;
					//pp_we_o <= 1'b0;
					// State
				end
				STATE_DDSWRITEWAIT: begin
					if (~(|write_active)) begin
						state_f <= STATE_POSTEXEC;
					end else state_f <= STATE_DDSWRITEWAIT;
				end
				STATE_TRIGGERWAIT: begin // trigger is asserted if either one of the pulsed lines is high
					// or trigger_in_mask[31:24] contains do care bits and trigger_mask[23:16] 
					if (|(trigger_in_mask[7:0] & trigger_in[7:0]) | 
						  (|(trigger_in_mask[31:24] & (~trigger_in_mask[23:16] ^ level_in[7:0]) )) )
						state_f <= STATE_POSTEXEC;
					else state_f <= STATE_TRIGGERWAIT;
				end
				STATE_MULTWAIT: begin
					if (calc_wait_count>0) begin
						calc_wait_count <= calc_wait_count - 1'b1;
						state_f <= STATE_MULTWAIT;
					end
					else begin
						W <= mult_result;
						state_f <= STATE_POSTEXEC;
					end
				end
				STATE_DIVWAIT: begin
					if (div_result_valid_buffered) begin
						W <= div_result[127:64];
						state_f <= STATE_POSTEXEC;
						div_result_ack <= 1'b1;
					end else begin
						div_result_ack <= 1'b0;
						state_f <= STATE_DIVWAIT;
					end
				end
				default: begin
					pp_active_o <= 1'b1;
					output_data_available <= 1'b0;
					data_fifo_read <= 1'b0;
					pp_ram_read <= 1'b0;
					pp_ram_set_address <= 1'b0;
					//pp_we_o <= 1'b0;
					timed_delay_start <= 1'b0;
					trigger_o <= 64'h0;
				end
				endcase // case(state_f)
			end // of else block
		end
		end

		// delay counter
		wrapped_delay_counter my_delay_counter( .clk(fast_clk), .load(timed_delay_start), .l(timed_delay[47:0]), 
		                                        .expired(pulsed_timed_wait_expired), .threshold(timed_wait_expired),.rst(wait_counter_rst) );
		
		
		// counters
		counters mycounters( .fast_clk(fast_clk), .clk(clk_i), .usb_clk(usb_clk), .fifo_data(fifo_data), .fifo_data_ready(fifo_data_ready), 
									.fifo_full(fifo_full), .fifo_rst(fifo_rst),
								   .count_in(count_i), .count_enable(counter_mask[23:0]), .timestamp_enable(counter_mask[31:24]), .all_counts(all_counts),
									.output_data(output_data), .output_data_ready(output_data_available), .tdc_count_out(tdc_count), 
									.counter_id( /*counter_id_reg*/ counter_mask[63:56] ),
									.adc_data(adc_data), .adc_ready(adc_update), .adc_gate(counter_mask[47:32]), .send_timestamp(counter_mask[48]),
									.timestamp_counter_reset(timestamp_counter_reset), .adc_sum(adc_sum), .adc_counts(adc_counts)	);

		wire [63:0] counter_mask_before_delay;
		output_multiplexer outmult( .clk(fast_clk), .update(timed_delay_start),	.pp_active(pp_active_o), .pulse_mode(cmd_data_buffer[16]),
										    .wait_expired(pulsed_timed_wait_expired), .shutter_in(shutter_reg_buffer), 
											 .pulse_end_shutter(pulse_end_shutter_reg), .shutter_out(shutter_o), .enable(timed_delay_greater_1),
											 .counter_in(counter_mask_proto), .counter_out(counter_mask_before_delay) );
											 
		always @(posedge fast_clk) timed_delay_greater_1 <= |timed_delay[63:1];
`ifdef DoDelayCounters											 
		counter_delay my_counter_delay( .clk(fast_clk), .d(counter_mask_before_delay), .q(counter_mask) );
`else
		assign counter_mask = counter_mask_before_delay;
`endif
	
		multiplier_64bit mult64( .a(W), .b(data_buffer), .clk(memory_clk), .ce(state_f==STATE_MULTWAIT), .p(mult_result) );

		divider_wrapper div64( .clk(clk_i), .dividend(W), .divisor(data_buffer), .start(state_f==STATE_DIVWAIT), .result(div_result), .result_valid(div_result_valid) );
		set_reset mysetrest( .clock(memory_clk), .set(div_result_valid), .reset(div_result_ack), .q(div_result_valid_buffered) );
									
		random random1( .int_clk(clk_i), .rd_clk(memory_clk), .random(random), .read_ack(rand_read_ack), .seed(pp_din_i[63:0]), .set_seed(set_rand_seed), .valid(rand_valid) );
									
		assign state_debug[3:0] = state_f[3:0];
		assign counter_mask_out[31:0] = counter_mask[31:0];
		assign pp_update = timed_delay_start;

endmodule
