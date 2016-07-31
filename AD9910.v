//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AD9910(
	input wire clk,
	input wire sclk_in,
	input wire [3:0] dds_cmd,
	input wire [63:0] dds_data,
	input wire dds_ready,
	output wire [2:0] dds_out,
	output wire ndone );

	wire SDIO, CSB;

	reg [15:0] cmd_word = 16'h0;
	reg wr_en = 1'b0, rd_en = 1'b0;
	wire empty, full;
	wire [67:0] dout;
	reg [71:0] data_to_send = 72'h0;
	reg [7:0] bits_to_send = 8'h0;
	reg csb = 1'b0;
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

	assign SDIO = data_to_send[71]; 
	assign CSB = ~csb;
	assign dds_out[2:0] = { csb, CSB, SDIO };
	reg dds_done_sending = 0;
	set_reset #(1'b1) done_ff( .clock(clk), .set(dds_done_sending), .reset(dds_ready & empty), .q(done) );

	// reading from fifo
	localparam INITSETCFR2	= 4'h0;
	localparam INITSETCFR3	= 4'h1;
	localparam INITSETAUXDAC= 4'h2;
	localparam RAMPSTEP		= 4'h3;
	localparam RAMPTIMESTEP = 4'h4;
	localparam RAMPLIMITS	= 4'h5;
	localparam CFR2RAMP 		= 4'h6;
	localparam STPROFILE0	= 4'h7;
	//localparam
	
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
						data_to_send <= { 8'h01, 8'h01, 8'h00, 8'h08, 8'h00, 32'h0 }; 
						bits_to_send <= 8'd40; // AD9910 0x01: 32-bit register
					end
					INITSETCFR3: begin // On initialization set CFR registers for single tone profiles. 
						data_to_send <= { 8'h02, 8'h1F, 8'h3F, 8'hC0, 8'h0, 32'h0 }; 
						bits_to_send <= 8'd40; // AD9910 0x02: 32-bit register
					end
					INITSETAUXDAC: begin // On initialization set AUX DAC to enable full amplitude range.
						data_to_send <= { 8'h03, 8'h00, 8'h00, 8'h00, 8'hFF, 32'h0 }; 
						bits_to_send <= 8'd40; // AD9910 0x03: 32-bit register
					end
					RAMPSTEP: begin // For AD9910 digital ramping feature
						data_to_send <= { 8'h0C, dout[63:0] }; // 32-bit decrement, 32-bit increment
						bits_to_send <= 8'd72; // AD9910 0x0C: 64-bit register
					end
					RAMPTIMESTEP: begin
						data_to_send <= { 8'h0D, dout[31:0], 32'h0 };// 16-bit neg slope rate, 16-bit pos slope rate.
						bits_to_send <= 8'd40; // AD9910 0x0D: 32-bit register
					end
					RAMPLIMITS: begin // For AD9910 digital ramping feature
						data_to_send <= { 8'h0B, dout[63:0] }; // 32-bit Upper limit, 32-bit Lower limit
						bits_to_send <= 8'd72; // AD9910 0x0B: 64-bit register
					end
					// Add CFR1REG to control power state
					//CFR1REG: begin // Set power states
					//	data_to_send <= { 8'h00, 32'h0 }; // Default 32'h0, everything on.
					//	bits_to_send <= 8'd40; // AD9910 0x00: 32-bit register
					//end
					CFR2RAMP: begin // set DR destination, DR enable, DR no-dwell High and Low
						//{ 8'h01, 8'h01, 2'b0, [2-bit DR destination: 1X = amplitude], [1-bit DR enable], [1-bit DR no-dwell High and 1-bit no-dwell Low], 1'b0, 8'b00001000, 8'b00010100 };
						data_to_send <= { 8'h01, 8'h01, 2'b0, dout[4:0], 1'b0, 8'h08, 8'h00, 32'h0 }; 
						bits_to_send <= 8'd40; // AD9910 0x01: 32-bit register
					end
					// Ramping is applied on io_update.
					STPROFILE0: begin // set Single Tone Profile (for normal non-ramping behavior)
						//Profile 0 { 8'h0E, 2'hXX, 14-bit amplitude, 16-bit phase, 32-bit frequency };
						data_to_send <= { 8'h0E, 2'h0, dout[61:0]}; 
						bits_to_send <= 8'd72; // AD9910 0x0E: 64-bit register Single Tone Profile 0
					end
					
					
				endcase
				read_state <= 3'h3;
				csb <= 1'b1;
			end
			3'h3: begin
				if (bits_to_send>1) begin
					data_to_send <= { data_to_send[70:0], 1'b0 };
					bits_to_send <= bits_to_send - 1'b1;
				end else begin
					csb <= 1'b0;
					read_state <= 3'h0;
					dds_done_sending <= 1'b1;
					//data_to_send[71] <= 1'b0; // A couple versions ago - does not bring Serial low at the end, so do it manually.
				end
			end
			//3'h4: begin
			//	read_state <= 3'h0;
			//	csb <= 1'b0; // newest version CSB=~csb seems to be going high too early.
			//end
		endcase
	end


endmodule 