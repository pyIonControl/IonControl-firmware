//////////////////////////////////////////////////////////////////
//    IonControl 1.0:  Copyright 2016 Sandia Corporation              
//    This Software is released under the GPL license detailed    
//    in the file "license.txt" in the top-level pyGSTi directory 
//////////////////////////////////////////////////////////////////

module click_counter_encaps(
	input wire clk,
	input wire count_in,
	input wire count_enable, 
	output reg [23:0] count = 0,
	output reg count_ready = 0,
	input wire count_ack,
	input wire [7:0] counter_id,
   output reg [7:0] counter_id_out = 0	);

	wire [23:0] q;
	reg sclr = 0;
	
	click_counter mycount(.clk(clk), .ce(count_enable & count_in), .sclr(sclr), .q(q) );
	
	reg [2:0] state = 3'h0;
	
	always @(posedge clk) begin
		case (state)
			3'h0: begin
				sclr <= 1'b0;
				if (count_enable) begin
					state <= 3'h1;
					counter_id_out <= counter_id;
				end
				if (count_ready & count_ack) count_ready <= 1'b0;
			end
			3'h1: begin
				if ((~count_enable)) state <= 3'h2;
				if (count_ready & count_ack) count_ready <= 1'b0;
			end
			3'h2: begin
				count <= q;
				state <= 3'h3;
			end
			3'h3: begin
				count_ready <= 1'b1;
				state <= 3'h4;
			end
			3'h4: begin
				sclr <= 1'b1;
				state <= 3'h0;
			end
		endcase
	end

endmodule