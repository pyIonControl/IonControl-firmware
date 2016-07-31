//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module MP9910(
	input wire clk,
	input wire sclk_in,
	input wire [3:0] dds_cmd,
	input wire [63:0] dds_data,
	input wire dds_ready,
	input wire  pulser_chan,
	output wire [2:0] dds_out,
	output wire ndone );

	wire SDIO, CSB;

	reg [15:0] cmd_word = 16'h0;
	reg wr_en = 1'b0, rd_en = 1'b0;
	wire empty, full;
	wire [67:0] dout;
	reg [64:0] data_to_send = 65'h0;
	reg [7:0] bits_to_send = 8'h0;
	reg csb = 1'b0;
	wire [3:0] pulser_chan_code = {2'b01, pulser_chan, 1'b0};
	wire done;
	assign ndone = ~done;

	dds_fifo fifo( .wr_clk(clk), .rd_clk(~sclk_in), .rst(1'b0), .din({dds_cmd, dds_data}), .dout(dout), .wr_en(wr_en), .rd_en(rd_en), .full(full), .empty(empty) );

	/// writing to fifo
	reg write_state = 1'b0;	
	always @(posedge clk) begin
		case (write_state)
		1'b0: begin
			if (dds_ready) begin
				wr_en <= 1'b1;
				write_state <= 1'b1;
			end
		end
		1'b1: begin
			wr_en <= 1'b0;
			if (~dds_ready) write_state <= 1'b0;
		end
		endcase
	end

	assign SDIO = data_to_send[64]; 
	assign CSB = ~csb; 
	assign dds_out[2:0] = { csb, CSB, SDIO };
	reg dds_done_sending = 0;
	set_reset #(1'b1) done_ff( .clock(clk), .set(dds_done_sending), .reset(dds_ready & empty), .q(done) );

	// reading from fifo
	localparam INITSETCFR2		= 4'h0;
	localparam INITSETCFR3		= 4'h1;
	localparam INITSETAUXDAC	= 4'h2;
	localparam RAMPSTEP			= 4'h3;
	localparam RAMPTIMESTEP 	= 4'h4;
	localparam RAMPLIMITS		= 4'h5;
	localparam CFR2RAMP 			= 4'h6;
	localparam STPROFILE0		= 4'h7;
	localparam SETEXTERNALCLK	= 4'h8;
	localparam IOUPDATE			= 4'h9;
	localparam RAMPDIRECTION	= 4'hA;
	// extra states needed for 3'h4 read state when writing only 32 bits at a time to pulser:
	localparam RAMPSTEP2		= 4'h0;
	localparam RAMPLIMITS2	= 4'h1;
	localparam STPROFILE02	= 4'h2;
	localparam AUTOIOUPDATE	= 4'h3;
	
	reg [3:0] additional_write_state; // No default
	reg additional_write_flag = 1'b0;
	reg [31:0] dout_store = 32'h0;
	
	reg [2:0] read_state = 3'h0;
	always @(negedge sclk_in) begin
		dds_done_sending <= 1'b0;
		case (read_state)
			3'h0: if (~empty) begin
					rd_en <= 1'b1;
					read_state <= 3'h1;
				end
			3'h1: begin
				read_state <= 3'h2;
				rd_en <= 1'b0;
			end
			3'h2: begin
				case (dout[67:64])
					INITSETCFR2: begin // On initialization set CFR registers for single tone profiles. CFR2 will be overwritten if ramps are programmed.
						// Magiq pulser card: 1'b1 = SPI Write, 32-bit address, 32-bit data (always)
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h04, 8'h01, 8'h00, 8'h08, 8'h00 }; 
						bits_to_send <= 8'd65; // AD9910 0x01: 32-bit register
						additional_write_flag <= 1'b1; 
						additional_write_state <= 4'h3; //IO_UPDATE
					end
					INITSETCFR3: begin // On initialization set CFR registers for single tone profiles. 
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h08, 8'h1F, 8'h3F, 8'hC0, 8'h0 }; 
						bits_to_send <= 8'd65; // AD9910 0x02: 32-bit register
						additional_write_flag <= 1'b0;
					end
					INITSETAUXDAC: begin // On initialization set AUX DAC to enable full amplitude range.
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h0C, 8'h00, 8'h00, 8'h00, 8'hFF }; 
						bits_to_send <= 8'd65; // AD9910 0x03: 32-bit register
						additional_write_flag <= 1'b0;
					end
					RAMPSTEP: begin // For AD9910 digital ramping feature
						// Magiq send low bits then high bits
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h2C, dout[31:0] }; // 32-bit increment 
						bits_to_send <= 8'd65; // AD9910 0x0C: 64-bit register
						dout_store <= dout[63:32];
						additional_write_flag <= 1'b1;
						additional_write_state <= 4'h0; //goes to RAMPSTEP2
					end 
					
					RAMPTIMESTEP: begin
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h34, dout[31:0]};// 16-bit neg slope rate, 16-bit pos slope rate.
						bits_to_send <= 8'd65; // AD9910 0x0D: 32-bit register
						additional_write_flag <= 1'b0;
					end
					RAMPLIMITS: begin // For AD9910 digital ramping feature
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h24, dout[31:0] }; // 32-bit Lower limit
						bits_to_send <= 8'd65; // AD9910 0x0B: 64-bit register
						dout_store <= dout[63:32];
						additional_write_flag <= 1'b1;
						additional_write_state <= 4'h1; //goes to RAMPLIMITS2
					end
					
					CFR2RAMP: begin // set DR destination, DR enable, DR no-dwell High and Low
						//{ 8'h01, 8'h01, 2'b0, [2-bit DR destination: 1X = amplitude], [1-bit DR enable], [1-bit DR no-dwell High and 1-bit no-dwell Low], 1'b0, 8'b00001000(x08), 8'b00010100 };
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h04, 8'h01, 2'b0, dout[4:0], 1'b0, 8'h08, 8'h00 }; 
						bits_to_send <= 8'd65; // AD9910 0x01: 32-bit register
						additional_write_flag <= 1'b1; //IO_UPDATE (will start ramp) // sets the ramp direction to negative slope.
						additional_write_state <= 4'h3;
					end
					// Ramping is applied on io_update.
					STPROFILE0: begin // set Single Tone Profile (for normal non-ramping behavior)
						//Profile 0 { 8'h0E, 2'hXX, 14-bit amplitude, 16-bit phase, 32-bit frequency };
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h38, dout[31:0]}; 
						bits_to_send <= 8'd65; // AD9910 0x0E: 64-bit register Single Tone Profile 0
						dout_store <= dout[63:32];
						additional_write_flag <= 1'b1;
						additional_write_state <= 4'h2; // goes to STPROFILE02
					end
					SETEXTERNALCLK: begin // set the Pulser card to take external clock (0dBm or higher signal, 10MHz. Gets scaled internally to 1GHz for DDS.)
						// As per emails from Steven Naboicheck 11/17/2014 -Rachel Noek
						// This sets the board control register. Default state is 9A06 to use internal clock.
						// The setting for external clock is 9A2E for no reproduction on the RefClk Out, and 9A6E for reproducing the clock to RefClk Out.
						data_to_send <= { 1'b1, 16'h0002, 16'h0000, 16'h0000, 16'h9A2E}; 
						bits_to_send <= 8'd65; 
						additional_write_flag <= 1'b1; //IO_UPDATE ... This may not be useful here b/c I think that is local to Magiq FPGA.
						additional_write_state <= 4'h3; 
					end
					IOUPDATE: begin // Magiq pulser IO_UPDATE goes through Magiq FPGA
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 16'h0004, 18'h0, 1'b1, 12'h0, 1'b1};//31'h0, 1'b1 }; // per Jonathan Young's email 11/26/2014
						bits_to_send <= 8'd65; 
						additional_write_flag <= 1'b0;
					end
					RAMPDIRECTION: begin // Magiq pulser ramp direction control
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 16'h0004, 18'h0, 1'b1, 8'h0, dout[0], 3'b000, 1'b1};//27'h0, dout[0], 4'h0 }; 
						bits_to_send <= 8'd65; 
						additional_write_flag <= 1'b0;
					end
				endcase
				read_state <= 3'h3;
				csb <= 1'b1;
			end
			3'h3: begin
				if (bits_to_send>1) begin
					data_to_send <= { data_to_send[63:0], 1'b0 };
					bits_to_send <= bits_to_send - 1'b1;
				end else begin
					csb <= 1'b0;
					data_to_send[64] <= 1'b0;
					if (additional_write_flag==1'b1) begin // if more to write, move to 3'h4
						read_state <= 3'h4;
					end else begin // otherwise return to beginning and get next request
						dds_done_sending <= 1'b1;
						read_state <= 3'h0;
					end
					
				end
			end
			3'h4: begin
				// buy some time to make sure no write overlap.
				read_state <= 3'h5;
			end
			3'h5: begin
				// buy some more time to make sure no write overlap.
				read_state <= 3'h6;
			end
			3'h6: begin
				case( additional_write_state )
					RAMPSTEP2: begin // For AD9910 digital ramping feature
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h30, dout_store[31:0] }; //  32-bit decrement
						bits_to_send <= 8'd65; // AD9910 0x0C: 64-bit register
						dout_store <= 32'h0;
						additional_write_flag <= 1'b0;
					end
					RAMPLIMITS2: begin // For AD9910 digital ramping feature
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h28, dout_store[31:0] }; // 32-bit Upper limit
						bits_to_send <= 8'd65; // AD9910 0x0B: 64-bit register
						dout_store <= 32'h0;
						additional_write_flag <= 1'b0;
					end
					STPROFILE02: begin // set Single Tone Profile (for normal non-ramping behavior)
						//Profile 0 { 8'h0E, 2'hXX, 14-bit amplitude, 16-bit phase, 32-bit frequency };
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 8'h01, 8'h3C, 2'h0, dout_store[29:0] }; 
						bits_to_send <= 8'd65; // AD9910 0x0E: 64-bit register Single Tone Profile 0
						dout_store <= 32'h0;
						additional_write_flag <= 1'b1; // Do IO_UPDATE
						additional_write_state <= 4'h3;
					end
					AUTOIOUPDATE: begin
						data_to_send <= { 1'b1, 12'h000, pulser_chan_code[3:0], 16'h0004, 18'h0, 1'b1, 12'h0, 1'b1};//31'h0, 1'b1 }; 
						bits_to_send <= 8'd65; 
						additional_write_flag <= 1'b0;
					end
				endcase
			
				read_state <= 3'h3;
				csb <= 1'b1;
			end
			
		endcase
	end


endmodule 