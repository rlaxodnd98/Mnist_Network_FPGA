module buffer #(
    parameter ASCIIBIT = 8,
    parameter COUNT = 99 )(
    
    input clk, reset_b,
    input [ASCIIBIT-1:0] data,
    input receive_done, //from receiver
    
    output [3:0] label_out,
    output [783:0] pixel_out,
    output enable
);

//1st buffer  
reg [6:0] counter;    // num 99 = 64 + 32 + 2 + 1 = 1100011
reg [1:0] state;

localparam HOLD = 2'b00,
           SEND1 = 2'b01,
           SEND2 = 2'b10;


reg [7:0] label_reg;
reg [783:0] pixel_reg;



//2nd buffer
reg [3:0] label_out_reg;
reg [783:0] pixel_out_reg;
reg enable_reg;

assign label_out = label_out_reg;
assign pixel_out = pixel_out_reg;
assign enable = enable_reg;


always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        counter <= 0;
		  state <= HOLD;
	 end else if (state == HOLD) begin
	     enable_reg <= 1'b0;
		  if (receive_done) begin
		      if (counter == 7'b0) begin
				    label_reg <= data;    // label input
				end else begin
				    pixel_reg <= {data, pixel_reg[783-8:783-16]};
				end
				if (counter == COUNT - 1) begin
				    counter <= 7'b0;
					 state <= SEND1;
				end else begin
				    counter <= counter + 7'd1;
				end
		  end
	 end else if (state == SEND1) begin
	     state <= SEND2;
		  pixel_out_reg <= pixel_reg;
		  label_out_reg <= label_reg[3:0];
    end else if (state == SEND2) begin
	     enable_reg <= 1'b1;
		  state <= HOLD;
	 end
end



/* 
always @(posedge clk or negedge reset_b)
begin : DATA_RECEIVE
    if (~reset_b) begin
        counter <= 0;
        label_reg <= 0;
        pixel_reg <= 0;
        enable_reg <= 0;
        state <= HOLD;
		  pixel_out_reg <= 0;
		  label_out_reg <= 0;
    end else if (state == SEND1) begin
        counter <= 0;
        state <= SEND2;
        pixel_out_reg <= pixel_reg;
        label_out_reg <= label_reg[3:0];
    end else if (state == SEND2) begin
        enable_reg <= 1'b1;
        state <= HOLD;
    end else if (state == HOLD) begin
	     enable_reg <= 0;
        if (receive_done == 1'b1) begin
            counter <= counter + 7'd1;
            if (counter == 0) begin
                label_reg <= data;
            end else if (counter < COUNT) begin
                pixel_reg <= pixel_reg>>8;
                pixel_reg[783:776] <= data;
                if (counter == COUNT-1) begin
                    state <= SEND1;
                end
            end
		  end
    end 
end

*/

endmodule


