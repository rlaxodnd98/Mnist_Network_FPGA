module uart_tx #(
    parameter D_BIT = 8,
    parameter SB_TICK = 16) (
    input clk,                  // external clk
    input reset_b,              //
    input tx_start,             // transmitter start signal
    input sampling_tick,               // baud rate generator signal
    input [7:0] d_in,           // data input
    output reg tx_done_tick,    // transmit done
    output tx_data              // single bit data
);
//////////////////////////////////////////////////
//   symbolic state declaration
//////////////////////////////////////////////////
localparam [1:0]
    IDLE  = 2'b00,
    START = 2'b01,
    DATA  = 2'b10,
    STOP  = 2'b11;


//////////////////////////////////////////////////
//  signal declaration
//////////////////////////////////////////////////
reg [1:0] state_reg, state_next;
reg [3:0] s_reg, s_next;    // signal tick count(0 ~ 15)
reg [2:0] n_reg, n_next;    // data count(0 ~ 7)
reg [7:0] b_reg, b_next;    // data storage(8bit)
reg tx_reg, tx_next;        // transmitter 1bit data


// FSMD state & data
always @(posedge clk, negedge reset_b) begin
	if (!reset_b) begin
		state_reg <= IDLE;
		s_reg <= 0;
		n_reg <= 0;
		b_reg <= 0;
		tx_reg <= 1'b1;
	end else begin    // normally executed
		state_reg <= state_next;
		s_reg <= s_next;
		n_reg <= n_next;
		b_reg <= b_next;
		tx_reg <= tx_next;
	end
end


always @(*) begin
    state_next = state_reg;
    tx_done_tick = 1'b0;
    s_next = s_reg;
    n_next = n_reg;
    b_next = b_reg;
    tx_next = tx_reg;
	
    case (state_reg)
        IDLE: begin
        	tx_next = 1'b1;  // IDLE bit
        	if (tx_start) begin
        		state_next = START;
        		s_next = 0;
        		b_next = d_in;
        	end
        end
        START: begin
        	tx_next = 1'b0;  // START bit
        	if (sampling_tick) begin
        		if (s_reg == 4'd15) begin
        			state_next = DATA;
        			s_next = 0;
        			n_next = 0;
        		end else begin
        			s_next = s_reg + 4'd1;
        		end
        	end
        end
        DATA: begin
        	tx_next = b_reg[0];
        	if (sampling_tick) begin
        		if (s_reg == 4'd15) begin
        			s_next = 0;
        			b_next = b_reg >> 1;
        			if (n_reg == D_BIT - 1) begin
        				state_next = STOP;
        			end else begin
        				n_next = n_reg + 3'd1;
        			end
        		end else begin
        		    s_next = s_reg + 4'd1;
         	    end
         	end 
        end
        STOP: begin
        	tx_next = 1'b1;
        	if (sampling_tick) begin
        		if (s_reg == SB_TICK - 1) begin
        			state_next = IDLE;
        			tx_done_tick = 1'b1;
        		end else begin
        			s_next = s_reg + 4'd1;
        		end
        	end
        end
	endcase
end

// output
assign tx_data = tx_reg;

endmodule