//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////


`timescale 1ns/1ps
//`default_nettype none

module ddr2_test
	(
	input  wire          clk,
	input  wire          reset,
	input  wire          writes_en,
	input  wire          reads_en,
	input	 wire				reads2_en,
	input  wire          calib_done, 
	//DDR Input Buffer (ib_)
	output reg           ib_re,
	input  wire [63:0]   ib_data,
	input  wire [8:0]    ib_count,
	input  wire          ib_valid,
	input  wire          ib_empty,
	input  wire 			ib_set_write_address,
	//DDR Output Buffer (ob_)
	output reg           ob_we,
	output reg  [63:0]   ob_data,
	input  wire [8:0]    ob_count,
	input  wire 			ob_set_read_address,
	//DDR Output Buffer (ob2_)
	output reg           ob2_we = 0,
	output reg  [63:0]   ob2_data = 0,
	input  wire [8:0]    ob2_count,
	input  wire [29:0]	ob2_read_address,
	input  wire          ob2_set_read_address,
	output reg				ob2_fifo_reset,
	output reg				ob_fifo_reset,
	output reg				ib_fifo_reset,
	input  wire [31:0] 	io_address,
	
	output reg           p0_rd_en_o, 
	input  wire          p0_rd_empty,
	input  wire [31:0]   p0_rd_data,
   input  wire [6:0]    p0_rd_count,
 	
	input  wire          p0_cmd_full,
	output reg           p0_cmd_en,
	output reg  [2:0]    p0_cmd_instr,
	output reg  [29:0]   p0_cmd_byte_addr,
	output wire [5:0]    p0_cmd_bl_o, 
	input  wire          p0_wr_full,
	output reg           p0_wr_en,
	output reg  [31:0]   p0_wr_data,
	output wire [3:0]    p0_wr_mask
	);

localparam BURST_LEN      = 28'd32;  // Number of 32bit user words per command 
                                 // Must be multipleof two for this example                

wire        rd_fifo_afull;
reg  [29:0] cmd_byte_addr_wr, cmd_byte_addr_rd, cmd_byte_addr_rd2;
reg  [5:0]  burst_cnt;

reg         write_mode;
reg         read_mode, read2_mode;
reg         reset_d;
wire 			ob2_set_read_address_d;
reg			ob2_set_read_address_ack = 0;
wire 			ob_set_read_address_d;
reg			ob_set_read_address_ack = 0;
wire 			ib_set_write_address_d;
reg			ib_set_write_address_ack = 0;
reg  [31:0] ob2_data_buffer = 0;
reg  [31:0] ob_data_buffer = 0;
reg  [31:0] ib_data_buffer = 0;
reg         last_p0_rd_empty = 0;


assign p0_cmd_bl_o = BURST_LEN - 1;
assign p0_wr_mask = 4'b0000;

always @(posedge clk) write_mode <= writes_en;
always @(posedge clk) read_mode <= reads_en;
always @(posedge clk) read2_mode <= reads2_en;
always @(posedge clk) reset_d <= reset;
set_reset set_read2_address_buffer( .clock(clk), .set(ob2_set_read_address), .reset(ob2_set_read_address_ack), .q(ob2_set_read_address_d) );
set_reset set_read_address_buffer( .clock(clk), .set(ob_set_read_address), .reset(ob_set_read_address_ack), .q(ob_set_read_address_d) );
set_reset set_write_address_buffer( .clock(clk), .set(ib_set_write_address), .reset(ib_set_write_address_ack), .q(ib_set_write_address_d) );


integer state;
localparam s_idle  = 0,
			  s_waitinit = 1,
			  s_wait = 2,
           s_write1 = 4,
           s_write2 = 5,
           s_write3 = 6,
           s_write4 = 7,
           s_read1 = 8,
			  s_read1a = 3,
           s_read2 = 9,
           s_read3 = 10,
			  s_read2_1 = 12,
			  s_read2_1a = 13,
           s_read2_2 = 14,
           s_read2_3 = 15;
			  
reg [7:0] waitcount = 0;

always @(posedge clk) begin
	if (reset_d) begin
		state           <= s_waitinit;
		burst_cnt       <= 3'b000;
		cmd_byte_addr_wr  <= 0;
		cmd_byte_addr_rd  <= 0;
		cmd_byte_addr_rd2 <= 0;
		p0_cmd_instr <= 3'b0;
		p0_cmd_byte_addr <= 30'b0;
		ob2_fifo_reset <= 1'b1;
		ob_fifo_reset <= 1'b1;
		ib_fifo_reset <= 1'b1;
	end else begin
		p0_cmd_en  <= 1'b0;
		p0_wr_en <= 1'b0;
		ib_re <= 1'b0;
		p0_rd_en_o   <= 1'b1;
		ob_we <= 1'b0;
		ob2_we <= 1'b0;
		ob_set_read_address_ack <= 1'b0;
		ob2_set_read_address_ack <= 1'b0;
		ob_fifo_reset <= 1'b0;
		ob2_fifo_reset <= 1'b0;
		ib_set_write_address_ack <= 1'b0;
		ib_fifo_reset <= 1'b0;

		case (state)
			s_waitinit: begin
				waitcount <= 8'h20;
				state <= s_wait;
			end
			s_wait: begin
				if (waitcount==8'h0)
					state <= s_idle;
				else
					waitcount <= waitcount - 8'h1;
			end
			s_idle: begin
				burst_cnt <= BURST_LEN;

				// only start writing when initialization done
				if (calib_done==1 && ob2_set_read_address_d) begin
					cmd_byte_addr_rd2 <= ob2_read_address;
					ob2_set_read_address_ack <= 1'b1;
					ob2_fifo_reset <= 1'b1;
					state <= s_waitinit;
				end else if (calib_done==1 && ob_set_read_address_d) begin
					cmd_byte_addr_rd <= {io_address[29:2], 2'h0};
					ob_set_read_address_ack <= 1'b1;
					ob_fifo_reset <= 1'b1;
					state <= s_waitinit;
				end else if (calib_done==1 && ib_set_write_address_d) begin
					cmd_byte_addr_wr[29:0] <= {io_address[29:2], 2'h0};
					ib_set_write_address_ack <= 1'b1;
					ib_fifo_reset <= 1'b1;
					state <= s_waitinit;
				end else if (calib_done==1 && write_mode==1 && (ib_count >= BURST_LEN/2)) begin
					state <= s_write1;
					ib_re <= 1'b1;
				end else if (calib_done==1 && read_mode==1 && (ob_count<511-BURST_LEN/2) ) begin
					state <= s_read1;
				end else if (calib_done==1'b1 && read2_mode==1'b1 && (ob2_count<511-BURST_LEN/2) ) begin
					state <= s_read2_1;
				end 
			end

			s_write1: begin
				state <= s_write2;
			end

			s_write2: begin
				if(ib_valid==1) begin
					p0_wr_data <= ib_data[63:32];
					ib_data_buffer <= ib_data[31:0];
					p0_wr_en   <= 1'b1;
					burst_cnt <= burst_cnt - 6'h2;
					state <= s_write3;
				end
			end
			
			s_write3: begin
				p0_wr_data <= ib_data_buffer;
				p0_wr_en   <= 1'b1;
				if (burst_cnt == 3'd0) begin
					state <= s_write4;
				end else begin
					state <= s_write1;
					ib_re <= 1'b1;
				end
			end
			
			s_write4: begin
				p0_cmd_en    <= 1'b1;
				p0_cmd_byte_addr    <= cmd_byte_addr_wr;
				cmd_byte_addr_wr <= cmd_byte_addr_wr + 4*BURST_LEN;
				p0_cmd_instr     <= 3'b000;
				state <= s_idle;
			end
	
			s_read2_1: begin
				p0_cmd_byte_addr    <= cmd_byte_addr_rd2;
				cmd_byte_addr_rd2 <= cmd_byte_addr_rd2 + 4*BURST_LEN;
				p0_cmd_instr     <= 3'b001;
				p0_cmd_en    <= 1'b1;
				state <= s_read2_1a;
				p0_rd_en_o <= 1'b0;
			end

			s_read2_1a: begin
				p0_rd_en_o <= 1'b0;
				if (p0_rd_count==BURST_LEN) begin
					p0_rd_en_o <= 1'b1;
					state <= s_read2_2;
				end 
			end
			
			s_read2_2: begin
					state <= s_read2_3;
					ob2_data_buffer <= p0_rd_data;   // buffering to make sure ob2_data is maintained for two clock cycles
					burst_cnt <= burst_cnt - 6'h2;
			end
						
			s_read2_3: begin
					ob2_data[31:0] <= p0_rd_data;
					ob2_data[63:32] <= ob2_data_buffer;
					ob2_we <= 1'b1;
					if (burst_cnt == 3'd0) begin
						state <= s_idle;
					end else begin
						state <= s_read2_2;
					end
			end

			s_read1: begin
				p0_cmd_byte_addr    <= cmd_byte_addr_rd;
				cmd_byte_addr_rd <= cmd_byte_addr_rd + 4*BURST_LEN;
				p0_cmd_instr     <= 3'b001;
				p0_cmd_en    <= 1'b1;
				state <= s_read1a;
			end
			
			s_read1a: begin
				p0_rd_en_o <= 1'b0;
				if (p0_rd_count==6'h20) begin
					p0_rd_en_o <= 1'b1;
					state <= s_read2;
				end 
			end

			s_read2: begin
					ob_data_buffer <= p0_rd_data;
					burst_cnt <= burst_cnt - 6'h2;
					state <= s_read3;
			end
			
			s_read3: begin
					ob_data[63:32] <= ob_data_buffer;
					ob_data[31:0] <= p0_rd_data;
					ob_we <= 1'b1;
					if (burst_cnt == 3'd0) begin
						state <= s_idle;
					end else begin
						state <= s_read2;
					end
			end							
		endcase
	end
end


endmodule
