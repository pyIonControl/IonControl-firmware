//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module AD9912(
	input wire clk,
	input wire sclk_in,
	input wire [3:0] dds_cmd,
	input wire [63:0] dds_data,
	input wire dds_ready,
	output wire [2:0] dds_out,
	output wire ndone,
	input wire [63:0] lock_data,
	input wire [3:0] lock_cmd,
	input wire lock_ready );

	wire SDIO, CSB;

	reg [15:0] cmd_word = 16'h0;
	reg wr_en = 1'b0, rd_en = 1'b0;
	wire empty, full;
	wire [67:0] dout;
	reg [63:0] data_to_send = 64'h0;
	reg [7:0] bits_to_send = 8'h0;
	reg csb = 1'b0;
	reg [3:0] dds_cmd_buffer = 0;
	reg [63:0] dds_data_buffer = 0;
	wire done;
	assign ndone = ~done;

	dds_fifo fifo( .wr_clk(clk), .rd_clk(~sclk_in), .rst(1'b0), .din({dds_cmd_buffer, dds_data_buffer}), .dout(dout), .wr_en(wr_en), .rd_en(rd_en), .full(full), .empty(empty) );

	/// writing to fifo
	reg write_state = 1'b0;	
	always @(posedge clk) begin
		case (write_state)
		1'b0: begin
			if (dds_ready) begin
				wr_en <= 1'b1;
				write_state <= 1'b1;
				dds_cmd_buffer <= dds_cmd;
				dds_data_buffer <= dds_data;
			end else if (lock_ready & empty) begin
				wr_en <= 1'b1;
				write_state <= 1'b1;
				dds_cmd_buffer <= lock_cmd;
				dds_data_buffer <= lock_data;				
			end
		end
		1'b1: begin
			wr_en <= 1'b0;
			if (~dds_ready) write_state <= 1'b0;
		end
		endcase
	end

	assign SDIO = data_to_send[63];
	assign CSB = ~csb;
	assign dds_out[2:0] = { csb, CSB, SDIO };
	reg dds_done_sending = 0;
	set_reset #(1'b1) done_ff( .clock(clk), .set(dds_done_sending & empty), .reset(dds_ready), .q(done) );

	// reading from fifo
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
					4'h0: begin  // Frequency all 48 bits, RN 2014-07-02
						data_to_send <= { 3'b011, 13'h1AB, dout[47:0]};
						bits_to_send <= 8'd64;
					end
					4'h1: begin // Phase
						data_to_send <= { 3'b001, 13'h1AD, 2'h0, dout[13:0], 32'h0 };
						bits_to_send <= 8'd32; //was 6'd32  RN 2014-07			
					end
					4'h2: begin // Amplitude
						data_to_send <= { 3'b001, 13'h40C, 6'h0, dout[9:0], 32'h0 };
						bits_to_send <= 8'd32; // was 6'd32; RN 2014-07				
					end
					4'h3: begin // Enable square output
						data_to_send <= { 3'b000, 13'h010, ~dout[0], 7'h50, 40'h0 };
						bits_to_send <= 8'd24; 			
					end
				endcase
				read_state <= 3'h3;
				csb <= 1'b1;
			end
			3'h3: begin
				if (bits_to_send>1) begin
					data_to_send <= { data_to_send[62:0], 1'b0 };
					bits_to_send <= bits_to_send - 1'b1;
				end else begin
					csb <= 1'b0;
					read_state <= 3'h0;
					dds_done_sending <= 1'b1;
					data_to_send[63] <= 1'b0;
				end
			end
		endcase
	end


endmodule 