module uart_rx #(
	parameter D_BIT = 8,
	parameter SB_TICK = 16) (
	input clk,                        // external clk
	input reset_b,                    // asynchronous reset
	input rx_data,                    // recieved data
	input sampling_tick,              // UART sampling tick(16 times baud rate)
	output reg rx_done_tick,          // recieve done tick signal
	output [D_BIT-1:0] d_out          // example 8bit data
); 


// symbolic state declaration (assume there is no parity bit)
localparam [1:0]
    IDLE  = 2'b00,   // IDLE mode (waiting for start_bit)
    START = 2'b01,   // reading start bit
    DATA  = 2'b10,   // reading data bit
    STOP  = 2'b11;   // reading stop bit


// signal declaration
reg [1:0] state_reg, state_next;
reg [3:0] tick_counter_reg, tick_counter_next;
reg [2:0] data_counter_reg, data_counter_next;
reg [D_BIT-1:0] data_reg, data_next;


// Finite State Machine register
always @(posedge clk, negedge reset_b) begin
	if (!reset_b) begin
		state_reg <= IDLE;
		tick_counter_reg <= 0;
		data_counter_reg <= 0;
      data_reg <= 0;
	end else begin
		state_reg <= state_next;
		tick_counter_reg <= tick_counter_next;
		data_counter_reg <= data_counter_next;
		data_reg <= data_next;
	end
end

// Finite State Machine Next-state logic
always @(*) begin
    // default value (hold)
    state_next = state_reg;
    rx_done_tick = 1'b0;
    tick_counter_next = tick_counter_reg;
    data_counter_next = data_counter_reg;
    data_next = data_reg;

    case (state_reg)
        IDLE: begin
            if (~rx_data) begin  // ~rx_data is given asynchronously
            	state_next = START;
            	tick_counter_next = 0; 
            end
        end
        
        START: begin
            if (sampling_tick) begin  // baud_rate_generator signal
                if (tick_counter_reg == 7) begin  // middle of startbit
                	  state_next = DATA;          // read for next_data
                	  tick_counter_next = 0;
                	  data_counter_next = 0;
                end else begin
            	     tick_counter_next = tick_counter_reg + 4'd1;
                end
            end 
		  end
		  
        DATA: begin
            if (sampling_tick) begin
                if (tick_counter_reg == 15) begin
                    tick_counter_next = 0;
                    data_next = {rx_data, data_reg[D_BIT-1:1]};  // shift right
                    if (data_counter_reg == D_BIT - 1) begin
                        state_next = STOP;
                    end else begin
                        data_counter_next = data_counter_reg + 3'd1;
                    end
            	 end else begin
                    tick_counter_next = tick_counter_reg + 4'd1;
            	 end
            end
		  end
		  
        STOP: begin
            if (sampling_tick) begin
                if (tick_counter_reg == (SB_TICK - 1)) begin
                    state_next = IDLE;
                    rx_done_tick = 1'b1;
                end else begin
                    tick_counter_next = tick_counter_reg + 4'd1;
					 end
            end
		  end
    endcase
end

assign d_out = data_reg;

endmodule


module clock_frequency_divider #(
    parameter MOD = 163,    // CLK = 50MHz, Baudrate = 19,200Bps 
    parameter N_COUNT_BIT = 8 ) (
    input clk,
    input reset_b,
    output reg clk_divide
);

reg [N_COUNT_BIT-1:0] counter;

always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        counter <= 0;
    end else if (counter == MOD - 1) begin
        counter <= 0;
        clk_divide <= 1'b1;
    end else begin
        counter <= counter + 8'd1;
        clk_divide <= 1'b0;
    end
end 

endmodule
