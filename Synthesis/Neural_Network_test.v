`timescale 1ns/1ps

module Neural_Network_tb;

parameter NWBITS = 16;             // weight bits 
parameter NHIDDEN = 256;           // number of hidden neuron
parameter NPIXEL = 784;            // 28 * 28 data array
parameter COUNT_BIT1 = 10;         // int(log2(NPIXEL)) + 1
parameter COUNT_BIT2 = 8;          // int(log2(NHIDDEN)) 
parameter NOUT = 10;               // number of output neuron
parameter NHBITS = NWBITS + COUNT_BIT1;    // number of hidden_neuron bits
parameter OUT_BIT = NHBITS + NWBITS + COUNT_BIT2;  // output_neuron bit      
parameter NTEST = 10000;

// timing constant for simulation
localparam clock_period      = 20;
localparam half_clock_period = clock_period / 2;
localparam minimum_period    = 1;


// signals on which logic values will be assigned 
reg clk;                 // external clk 
reg reset_b;               // asynchronous reset
reg start_train_sw;        // start_training (start_state1)
reg [783:0] pixel;         // currently 784 number of pixel
reg [3:0] target_label;    // pixel label data(0~9)

// clock signal generator
always begin
    #(half_clock_period) clk = ~clk;
end

// signals which will be observed.
wire end_system;           // Neural_Network is terminated


// variables for test_process
reg [3:0] label [0:NTEST-1];
reg [NPIXEL-1:0] pixel_memory [0:NTEST-1];
reg expected;
integer fo;
integer char;
integer code;
integer error_count;
integer i, j, loop, loop2;     // for loop variable
integer Yes, No;

reg signed [OUT_BIT-1:0] max_expected, max_value;


/* ----------initialization of the design-----------------------------------
 *
 *
 *------------------------------------------------------------------------*/
/*
 * definition of state diagram constant(7 state)
 *
 * [0] WAIT                : waiting for 'start_train_sw' (train switch) 
 *
 * [1] FIRST_LAYER         : compute weighted sum of first_layer and   
 *                           calculate hidden_neuron(NHIDDEN)
 *
 * [2] SECOND_LAYER        : compute weighted sum of second_layer and
 *                           calculate output_neuron(NOUT)
 *
 * [3] COMPARE             : transfer our output_neuron to one_hot vector
 *                           and compare target_label.
 *                           if expectation is matched for target_label,
 *                           Go to [0]WAIT, else Go to [4]UPDATE_SECOND_LAYER
 *
 * [4] UPDATE_SECOND_LAYER : find delta_weight2 and delta_bias2 and update
 *                           its value. (learning rate is 1/8192)
 *
 * [5] DERIVATIVE_HIDDEN   : to calculate [6], find derivative of 
 *                           hidden neuron (error * weight2 )
 * 
 * [6] UPDATE_FIRST_LAYER  : find delta_weight1 and delta_bias1 and update
 *                           its value. (learning rate is 1/8192)
 * 
 *------------------------------------------------------------------------*/
localparam [2:0] WAIT                = 3'b000,
                 FIRST_LAYER         = 3'b001,  
                 SECOND_LAYER        = 3'b010,   
                 COMPARE             = 3'b011,   
                 UPDATE_SECOND_LAYER = 3'b100,
                 DERIVATIVE_HIDDEN   = 3'b101,
                 UPDATE_FIRST_LAYER  = 3'b110;

reg [2:0] state;                // state diagram variable
reg [COUNT_BIT1-1:0] counter;  // counter for state diagram(0 ~ NPIXEL)

/**-----------------------------------------------
 *  definition of operting signal
 * 
 * NOTE : all modules for [1] ~ [6] states only operate only when
 *        start_state(n) signal arrives and all modules complete their 
 *        operation, they output an next start signal(end_state(n)).
 *            
 * EXAMPLE : start_state1 : operate state1(FIRST_LAYER)
 *           start_state5 : operate state5(DERIVATIVE_HIDDEN)
 *           end_state4   : completed state4(UPDATE_SECOND_LAYER)
 * 
 * 
 * EXCEPTION : 1. start_state1 is named "start_train_sw"
 *             (external FPGA switch)
 *             
 *             2. start_state4 is named "matched"
 *             (whether expectation is matched or not)
 *
 **----------------------------------------------*/
// input start_train_sw;             // module Neural_Network input
wire start_state2;                   // starts state2                        
wire start_state3;                   // starts state3                        
wire matched;                        // our expectation is matched or not 
wire start_state5;                   // starts state5                        
wire start_state6;                   // starts state6                        


wire end_state1 [NHIDDEN-1:0];       // state1 is ended,                     
wire end_state2 [NOUT-1:0];          // state2 is ended,                     
wire end_state3;                     // state3 is ended,         
wire end_state4 [NOUT-1:0];          // state4 is ended,                     
reg end_state5;                      // state5 is ended,                     
wire end_state6 [NHIDDEN-1:0];       // state6 is ended,                     
// output end_system

// to make start_state5, or signal for all end_state4 
wire a, b, c;
assign a = end_state4[0] || end_state4[1] || end_state4[2] || end_state4[3];
assign b = end_state4[4] || end_state4[5] || end_state4[6] || end_state4[7];
assign c = end_state4[8] || end_state4[9];

/* connects start signal and end signal */
assign start_state2 = end_state1[0];    // end_state1 is same as start_state2
assign start_state3 = end_state2[0];    // end_state2 is same as start_state3
assign start_state5 = a || b || c;      // end_state4 is same as start_state5
assign start_state6 = end_state5;    // state5 end is same as start state6
assign end_system = matched | end_state6[0];  // system is terminated


/*--------------------------------------------------------------------------
 * [1] variables for FIRST_LAYER
 *
 * hidden_neuron  : calculated hidden_neuron value(with ReLu activation func)
 * 
 * pixel_multiply : multipling pixel when calculate weighted sum.
 *                  it selected with counter at state1
 * 
 **--------------------------------------------------------------------------*/
wire signed [NHBITS-1:0] hidden_neuron [NHIDDEN-1:0]; 
reg pixel_multiply;

/*--------------------------------------------------------------------------- 
 * [2] variables for SECOND_LAYER
 * output_neuron : calculated output_neuron value
 * 
 * hidden_multiply : multipling hidden_neuron when calculate weighted sum.
 *                   it selected with counter at state2
 *
 **-------------------------------------------------------------------------*/
wire signed [OUT_BIT-1:0] output_neuron [NOUT-1:0];
reg signed [NHBITS-1:0] hidden_multiply;

/*--------------------------------------------------------------------------- 
 * [3] variables for COMPARE
 * output_neuron_onehot : one_hot vector for output neuron
 * 
 * target_label_onehot  : one_hot vector for target label
 * 
 * output_index         : output_neuron maximum index number
 **-------------------------------------------------------------------------*/
wire [NOUT-1:0] output_neuron_onehot;
wire [NOUT-1:0] target_label_onehot;
wire [3:0] output_index;
/*--------------------------------------------------------------------------- 
 * [4] variables for UPDATE_SECOND_LAYER
 * hidden_multiply :  multipling hidden_neuron when calculate delta_weight2.
 *                    it selected with counter at state4 
 *                    this variable is reused variable of [2] 
 *
 * start_pos     :  when this signal is high, operates
 *                  "delta_weight2_and_bias2" modules (positive delta_weight2)                  
 *                  in [4], start_pos <= output_neuron_onehot;  on 1clk period
 * 
 * start_neg     :  when this signal is high, operates 
 *                  "delta_weight2_and_bias2" modules (negative delta_weight2)               
 *                  in [4], start_neg <= target_label_onehot;   on 1clk period
 * 
 * update_second_layer : when this signal is high, 
 *                       update second_layer weight and bias,
 *  in [4], update_second_layer <= target_label_onehot | output_neuron_onehot;
 *                    on 1clk period
 **-------------------------------------------------------------------------*/
reg [NOUT-1:0] start_pos;     
reg [NOUT-1:0] start_neg;
reg [NOUT-1:0] update_second_layer;
wire signed [NWBITS-1:0] delta_weight2 [NOUT-1:0];
wire signed [NWBITS-1:0] delta_bias2 [NOUT-1:0];

/*--------------------------------------------------------------------------- 
 * [5] variables for DERIVATIVE_HIDDEN_NEURON
 * 
 * start_backprop : start signal when take out weight in second_layer.
 *                  when start_state5 arrives, start_backprop signal 
 *                  operate weight_memory2 in second_layer.
 *
 * second_layer_weight : second_layer take out its own weight value, 
 *                       and this variable contains its output weight
 *
 * weight_pos     :  when compute derivative of hidden neuron, we need
 *                   subtract two weights. it is positive side weight
 *                                    
 * weight_neg     :  when compute derivative of hidden neuron, we need
 *                   subtract two weights. it is negative side weight
 *
 * hidden_neuron_isneg : check, hidden_neuron is negative or positive
 *
 * enable_neuron  :  when calculate neuron, we should store it's value.
 *                   "derivative_hidden_neuron" cell stores only enable_neuron
 *                   is high
 **-------------------------------------------------------------------------*/
reg [NOUT-1:0] start_backprop;
wire signed [NWBITS-1:0] second_layer_weight [NOUT-1:0];
wire signed [NWBITS-1:0] weight_pos, weight_neg;
wire hidden_neuron_isneg;
wire signed [NWBITS:0] derivative_hidden_neuron [NHIDDEN-1:0];
reg [NHIDDEN-1:0] enable_neuron;

/*--------------------------------------------------------------------------- 
 * [6] variables for UPDATE_FIRST_LAYER
 * 
 * delta_weight1      : calculated delta_weight1(delta_weight1 module output)
 *
 * delta_bias1        : calculated delta_bias1 (delta_bias1 module output)
 * 
 * update_first_layer : when this signal is high,
 *                      update first_layer weight and bias,
 *
 **-------------------------------------------------------------------------*/
wire signed [NWBITS-1:0] delta_weight1 [NHIDDEN-1:0];
wire signed [NWBITS-1:0] delta_bias1 [NHIDDEN-1:0];
reg update_first_layer;

/* function declaration part */
/* (1) convert one_hot vector */
function [NOUT-1:0] one_hot(
    input [3:0] max
);
begin
    case (max)
        0: one_hot = 10'b0000000001; 
        1: one_hot = 10'b0000000010;
        2: one_hot = 10'b0000000100;
        3: one_hot = 10'b0000001000;
        4: one_hot = 10'b0000010000;
        5: one_hot = 10'b0000100000;
        6: one_hot = 10'b0001000000;
        7: one_hot = 10'b0010000000;
        8: one_hot = 10'b0100000000;
        9: one_hot = 10'b1000000000;
        default: one_hot = 10'b0000000000;
    endcase
end
endfunction


/** 
 * state [1] Generate statement for first layer
 **/
genvar layer1;
generate                     
for (layer1 = 0 ; layer1 < NHIDDEN ; layer1 = layer1 + 1)
begin: gen_loop1
/**
 * state [1] calculate weighted sum, add bias, and take relu function
 * this modules contains weight memory and bias memory.
 * 
 */
first_layer_cell #(
    .NWBITS(NWBITS), 
    .NPIXEL(NPIXEL), 
    .COUNT_BIT1(COUNT_BIT1), 
    .NUM(layer1)) FIRST (            // parameter NUM : memory initial num
    .clk(clk),                                // input: external clk
    .reset_b(reset_b),                        // input: asynchronous reset
    .update_first_layer(update_first_layer),  // input: enable for update weight
    .start_state1(start_train_sw),            // input: start_train_sw signal
    .pixel_multiply(pixel_multiply),    // input: proper pixel data weighted_sum
    .delta_weight(delta_weight1[layer1]),   // input: delta_weight data array
    .delta_bias(delta_bias1[layer1]),       // input: delta_bias data array
    .hidden_neuron(hidden_neuron[layer1]),  // output: hidden_neuron data
    .end_state1(end_state1[layer1]),        // output: enable_out for next block
    .end_state6(end_state6[layer1])                 // output: state6 is ended
);
/**
 * state [5] derivative_hidden_neuron
 * 
 * Implementation : This module cacluate derivative hidden_neuron
 *                  to find delta_weight1 and delta_bias.
 *                  We are using relu function as activation function,
 *                  hidden_neuron_isneg is needed.
 *                
 */
derivative_hidden_neuron #(
    .NWBITS(NWBITS)) DERIVATIVE_HIDDEN_NEURON (    // parameter
    .clk(clk),                                     // input:  external clk
    .reset_b(reset_b),                             // input:  asynchronous reset
    .enable_neuron(enable_neuron[layer1]),         // input:  enable_neuron
    .weight_pos(weight_pos),                       // input:  positive weight
    .weight_neg(weight_neg),                       // input:  negative weight
    .hidden_neuron_isneg(hidden_neuron_isneg),     // input:  is hidden neuron value neg?
    .derivative_hidden_neuron(derivative_hidden_neuron[layer1])   // output
);

/**
 * state [6] CALCULATE delta_weight1 and delta_bias1, and update
 * 
 * 
 */
delta_weight1 #(
    .NWBITS(NWBITS),                           // parameter 
    .NPIXEL(NPIXEL),                           // parameter
    .COUNT_BIT1(COUNT_BIT1)) DELTA_WEIGHT1 (   // parameter
    .clk(clk),                                 // input:  external clk
    .reset_b(reset_b),                         // input:  asynchronous reset
    .start_state6(start_state6),               // input:  calculate delta_weight1
    .pixel(pixel_multiply),                    // input:  pixel_multiply         
    .derivative_hidden_neuron(derivative_hidden_neuron[layer1]),
    .delta_weight(delta_weight1[layer1])               // output:  update_delta_weight
);

delta_bias1 #(
    .NWBITS(NWBITS)) DELTA_BIAS1 (
    .clk(clk),
    .reset_b(reset_b),
    .start_state6(start_state6),
    .derivative_hidden_neuron(derivative_hidden_neuron[layer1]),
    .delta_bias(delta_bias1[layer1])
);

end
endgenerate


genvar layer2;
generate
for (layer2 = 0 ; layer2 < NOUT ; layer2 = layer2 + 1)
begin: gen_loop2

 /**
  * state [2] Generate statement for second layer
  **/
second_layer_cell #(
    .NWBITS(NWBITS),                    // parameter
    .NHIDDEN(NHIDDEN),                  // parameter 
    .COUNT_BIT1(COUNT_BIT1),          // parameter
    .COUNT_BIT2(COUNT_BIT2),          // parameter
    .NUM(layer2)) SECOND (              // parameter NUM : memeory initial num
    .clk(clk),                          // input:  external clk
    .reset_b(reset_b),                  // input:  asynchronous reset
    .update_second_layer(update_second_layer[layer2]), // input:  change bias and weight
    .start_state2(start_state2),        // input:  start state2
    .start_backprop(start_backprop[layer2]),          // input:  weight_out for backprop
    .hidden_multiply(hidden_multiply),  // input:  first_layer output data 
    .delta_weight(delta_weight2[layer2]),  // input:  10 new_weight data array
    .delta_bias(delta_bias2[layer2]),      // input:  10 new_bias data array
    .output_neuron(output_neuron[layer2]), // output: data for weight and bias multiply
    .second_layer_weight(second_layer_weight[layer2]),  // output: weight value
    .end_state2(end_state2[layer2]),  // output: calculate outputneuron end 
    .end_state4(end_state4[layer2])             // output: update_memory is ended
);

/* [4] backpropagation process module for weight_memory2 */
delta_weight2 #(
    .NWBITS(NWBITS),                    // parameter
    .NHIDDEN(NHIDDEN),                  // parameter
    .NHBITS(NHBITS),                        // parameter
    .COUNT_BIT2(COUNT_BIT2)) DELTA_WEIGHT2 (        // parameter
    .clk(clk),                          // input:  external clk
    .reset_b(reset_b),                  // input:  asynchronous reset
    .start_pos(start_pos[layer2]),      // input:  expected value of forward prop
    .start_neg(start_neg[layer2]),      // input:  one_hot encoding for label
    .hidden_multiply(hidden_multiply),  // input:  hidden_multiply data for delta_weight2
    .delta_weight(delta_weight2[layer2])   // output: new_weight_for second layer
);
/* [4] backpropagation process module for bias_memory2 */
delta_bias2 #(.NWBITS(NWBITS)) DELTA_BIAS2 (
    .clk(clk),                          // input:  external clk
    .reset_b(reset_b),                  // input:  asynchronous reset
    .start_pos(start_pos[layer2]),            // input:  positive calculation
    .start_neg(start_neg[layer2]),            // input:  negative calculation
    .delta_bias(delta_bias2[layer2])       // output: new_bias for second layer
);


end 
endgenerate

/**
 * state [3] COMPARE module
 * 
 * Implementation : this module transfer output_neuron to output_neuron_onehot
 *                  and compare with target_label_onehot.
 *                  If output_neuron is equal to target_label, matched signal
 *                  is 1'b1, otherwise, matched signal is 1'b0
 **/
transfer_onehot_and_compare #(          
    .OUT_BIT(OUT_BIT),                 // parameter : output_neuron bit
    .NOUT(NOUT)) ONE_HOT (             // parameter
    .clk(clk),                         // input:  external clk
    .reset_b(reset_b),                 // input:  asynchronous reset
    .start_state3(start_state3),                // input:  second_layer output 
    .target_label_onehot(target_label_onehot),  // input
    .output_neuron0(output_neuron[0]),   // input:  output_neuron data0
    .output_neuron1(output_neuron[1]),   // input:  output_neuron data1
    .output_neuron2(output_neuron[2]),   // input:  output_neuron data2
    .output_neuron3(output_neuron[3]),   // input:  output_neuron data3
    .output_neuron4(output_neuron[4]),   // input:  output_neuron data4
    .output_neuron5(output_neuron[5]),   // input:  output_neuron data5
    .output_neuron6(output_neuron[6]),   // input:  output_neuron data6
    .output_neuron7(output_neuron[7]),   // input:  output_neuron data7
    .output_neuron8(output_neuron[8]),   // input:  output_neuron data8
    .output_neuron9(output_neuron[9]),   // input:  output_neuron data9
    .output_neuron_onehot(output_neuron_onehot),  // output:
    .output_index(output_index),         // output:  onehot index number
    .matched(matched),              // output: our expect matched target_label?
    .end_state3(end_state3)         // output: compare is ended
);


/* always block [0] : state_machine for Neural Network */
always @(posedge clk, negedge reset_b) begin
    if (!reset_b) begin
        state <= WAIT;
        counter <= 10'd0;
    
    /* [0] WAIT state */
    end else if (state == WAIT) begin  // [0] WAIT state
        counter <= 10'd0;
        if (start_train_sw) begin
            state <= FIRST_LAYER;
            pixel_multiply <= pixel[0];
            counter <= 10'd1;
        end
    /* [1] FIRST_LAYER state */
    end else if (state == FIRST_LAYER) begin 
        pixel_multiply <= pixel[counter];
        if (counter < NPIXEL) begin
            counter <= counter + 10'd1;
        end
        if (start_state2) begin
            state <= SECOND_LAYER;
            hidden_multiply <= hidden_neuron[0];
            counter <= 10'd1;
        end
    
    /* [2] SECOND_LAYER STATE */
    end else if (state == SECOND_LAYER) begin

        hidden_multiply <= hidden_neuron[counter];
        if (counter < NHIDDEN) begin
            counter <= counter + 10'd1;
        end
        if (start_state3) begin   // next_state
            state <= COMPARE;
            counter <= 10'd0;
        end
    
    /* [3] COMPARE STATE */
    end else if (state == COMPARE) begin
        if (end_state3) begin
            if (!matched) begin
                state <= UPDATE_SECOND_LAYER;  
                counter <= 10'd1;

                // hidden_multiply for delta_weight2 and delta_bias2 module
                hidden_multiply <= hidden_neuron[counter];
                
                // to update new_weight, enable second_layer_cell
                start_pos <= output_neuron_onehot;   // one_hot output_layer     
                start_neg <= target_label_onehot;    // one_hot target_label
            end

            if (matched) begin
                state <= WAIT;
                counter <= 10'd0;
            end
        end
    
    /* [4] UPDATE_SECOND_LAYER */
    end else if (state == UPDATE_SECOND_LAYER) begin  
        
        hidden_multiply <= hidden_neuron[counter];
        if (counter < NHIDDEN) begin
            counter <= counter + 10'd1;
        end

        if (counter == 10'd1) begin
            // UPDATE weight and bias enable signal
            update_second_layer <= output_neuron_onehot | target_label_onehot;
            start_pos <= 10'd0;    // start_pos signal is only 1clk period high
            start_neg <= 10'd0;    // start_neg signal is only 1clk period high
        end else begin
            update_second_layer <= 10'd0;  // only 1clk period high.
        end 
        if (start_state5) begin   // next_state
            state <= DERIVATIVE_HIDDEN;

            // to backpropagation first_layer weight,
            // take out weight of second_layer. 
            // start_backprop is enable signal for second_layer_cell
            start_backprop <= output_neuron_onehot | target_label_onehot;
            counter <= 10'd0;
        end

    /* [5] DERIVATIVE_HIDDEN */
    end else if (state == DERIVATIVE_HIDDEN) begin    // [5] state
        start_backprop <= 10'd0;  // only one-clock period high
        counter <= counter + 10'd1;
        if (counter > 10'd0) begin
            enable_neuron[counter-1] <= 1'b0;  // disable previous DERIVATIVE_HIDDEN 
        end
        
        if (counter == NHIDDEN) begin            
            state <= UPDATE_FIRST_LAYER;    // goto next_state
            pixel_multiply <= pixel[0];     
            counter <= 1'd1;
            end_state5 <= 1'b1;
        end else begin
            counter <= counter + 10'd1;
            enable_neuron[counter] <= 1'b1;  // enable next DERIVATIVE_HIDDEN
        end
    
    /* [6] UPDATE_FIRST_LAYER */
    end else if (state == UPDATE_FIRST_LAYER) begin   // [6] state
        end_state5 <= 1'b0;

        pixel_multiply <= pixel[counter];
        if (counter == 10'd1) begin
            update_first_layer <= 1'b1;    // enable_first_layer
        end else begin
            update_first_layer <= 1'b0;    // disable_first_layer
        end

        if (counter < NPIXEL) begin
            counter <= counter + 10'd1;
        end
        if (end_state6[0]) begin    // UPDATE FIRST_LAYER is end
            state <= WAIT;
            counter <= 10'd0;
        end
    end
end

// continuous assignment for state [5] DERIVATIVE_HIDDEN
assign weight_pos = second_layer_weight[output_index];
assign weight_neg = second_layer_weight[target_label];
assign hidden_neuron_isneg = hidden_neuron[counter-1] == 0 ? 1'b1 : 1'b0;

// continuous assignment for state [3] COMPARE
assign target_label_onehot = one_hot(target_label);




/* ------------------Module Instanciation end ----------------------------- */


/* function for test */
function signed [NWBITS-1:0] w_bit (
    input signed [NWBITS:0] x
);
    if (x < 0) begin
        w_bit = {12'b111111111111, x[NWBITS:NWBITS-3]} + 1; 
    end else begin
        w_bit = {12'b000000000000, x[NWBITS:NWBITS-3]};
    end 
endfunction 



initial 
begin: TEST_PROGRAM
    // parameters for timeformat is : unit (-9 means ns), digits after dot,
    // string after $time, minimum string length
    $timeformat(-9, 0, " ns", 5);

    // initail value of TEST_PROGRAM
    clk = 1'b0;
    reset_b = 1'b1;
    start_train_sw = 1'b0;
    pixel = 0;
    target_label = 0;
    error_count = 0;
    Yes = 0;
    No = 0;
    
    /* number of epochs */
    for (loop2 = 0 ; loop2 < 5 ; loop2 = loop2 + 1) begin

    // [0.0] read file pointer 
    fo = $fopen("mnist_test.csv", "r");
    
    for (j = 0 ; j < NTEST ; j = j + 1) begin
        
        // reading label of MNIST
        code = $fscanf(fo, "%d", char);
        label[j] = char;
        // code = $fscanf(fo, "%c", char);
        char = $fgetc(fo);
        for (i = 0 ; i < NPIXEL ; i = i + 1) begin 
            
            // reading data of MNIST
            code = $fscanf(fo, "%d", char);  // can do read digit, but It can't read comma(,)   
            pixel_memory[j][i] = char; 
            char = $fgetc(fo);
        end
    end
    
    $fclose(fo);

    // [0.5] : activate asynchronous reset.
    # minimum_period;
    reset_b = 1'b0;         // activate reset of active low
    # clock_period;
    @ (posedge clk);
    # (2*minimum_period);
    reset_b = 1'b1;         // back to normal state
    @ (posedge clk);        // simulation begins at rising edge
    $display("--------------------------------------------------------------");
    $display("Check, state is WAIT and counter is 0 at %0t", $time);
    expected = (state === WAIT);
    if (!expected) begin
        $error("state is not WAIT at %0t", $time);
        error_count = error_count + 1;
    end else begin
        $display("state is reset correctly");
    end
    
    /*-----------------------------------------------------------------------
     * state [1] Inserting first_pixel data
     *--------------------------------------------------------------------*/
    for (loop = 0 ; loop < NTEST ; loop = loop + 1)
    begin : continue_loop 

    $display("begin Inserting first pixel data and target_label at %0t", $time);

    @ (negedge clk);
    pixel = pixel_memory[loop];
    target_label = label[loop];

    start_train_sw = 1'b1;
    # clock_period;
    start_train_sw = 1'b0;

    $display("--------------------------------------------------------------");
    $display("start_train_sw is high, let's check pixel data");
    
    for (i = 0 ; i < NPIXEL ; i = i + 1) begin
        expected = (pixel_multiply === pixel[i]);
        if (!expected) begin
            $error("pixel_multiply is not matched at  pixel[i]");
            error_count = error_count + 1;
        end

        # clock_period;
    end
    
    // 1clk delay for weighted sum and bias function
    # clock_period;

    $display("--------------------------------------------------------------");
    $display("[1.1] first_layer process is ended, and check end_state1");
    expected = (end_state1[0] === 1'b1);
    if (!expected) begin
        $error("end_state1 signal is not detected at %0t", $time);
        error_count = error_count + 1;
        $display("end_state1 signal = %1d", end_state1[0]);
    end else begin
        $display("end_state1 signal is detected!");
    end
    
    $display("--------------------------------------------------------------");
    $display("[1.2] check state is FIRST_LAYER at %0t", $time);
    expected = (state === FIRST_LAYER);
    if (!expected) begin
        $error("state is not FIRST_LAYER, state is %3d", state);
        error_count = error_count + 1;
    end else begin
        $display("Yes!, state is FIRST_LAYER!");
    end
    
    $display("--------------------------------------------------------------");
    $display("[1.3] check hidden_neuron value at %0t", $time);
    
    for (i = 0 ; i < NHIDDEN ; i = i + 1) begin
        expected = (hidden_neuron[i] > 0 || hidden_neuron[i] == 0);
        if (!expected) begin
            $error("hidden_neuron[i] value have error = %d", hidden_neuron[i]);
            error_count = error_count + 1;
        end 
    end
    /*-----------------------------------------------------------------------
     * state [2] Calculated second weighted sum
     *--------------------------------------------------------------------*/
    # clock_period;  // waiting for second_layer
    $display("--------------------------------------------------------------");
    $display("[2.0]check state is SECOND_LAYER at %0t", $time);
    expected = (state === SECOND_LAYER);
    if (!expected) begin
        $error("state is not SECOND_LAYER, state is %3d", state);
        error_count = error_count + 1;
    end else begin
        $display("Yes!, state is SECOND_LAYER!");
    end
    
    $display("--------------------------------------------------------------");
    $display("[2.1] check hidden_multiply value of SECOND_LAYER");
    for (i = 0 ; i < NHIDDEN ; i = i + 1) begin
        expected = (hidden_multiply === hidden_neuron[i]);
        if (!expected) begin
            $error("hidden_multiply is not matched at  pixel[i]");
            error_count = error_count + 1;
        end
        # clock_period;
    end
    
    // 1clk delay for weighted sum and bias function
    # clock_period;
    $display("--------------------------------------------------------------");
    $display("[2.2] state2 is ended, check end_state2 signal at %0t", $time);
    expected = (end_state2[0] === 1'b1);
    if (!expected) begin
        $error("end_state2 is not detected. end_state2 = %d", end_state2[0]);
        error_count = error_count + 1;
    end else begin
        $display("Yes!, end_state2 signal is detected");
    end
    
    $display("--------------------------------------------------------------");
    $display("[2.3] check output_neuron value of SECOND_LAYER state");
    for (i = 0 ; i < NOUT ; i = i + 1) begin
        $display("output_neuron[%2d] = %2d", i, output_neuron[i]);
    end
    
    /*-----------------------------------------------------------------------
     * state [3] translate one_hot and compare state
     *--------------------------------------------------------------------*/
    # clock_period;
    $display("--------------------------------------------------------------");
    $display("[3.0] let's check current state is COMPARE at %0t", $time);
    expected = (state === COMPARE);
    if (!expected) begin
        $error("current state is not COMPARE, state = %2d", state);
        error_count = error_count + 1;
    end else begin
        $display("Nice!! Current state is COMPARE");
    end
    
    
    // waiting for COMPARE module ended
    for (i = 0 ; i < 8 ; i = i + 1) begin
        # clock_period;
    end
    $display("--------------------------------------------------------------");
    $display("[3.1] check end_state3 signal is detected at %0t", $time);
    expected = (end_state3 === 1'b1);
    if (!expected) begin
        $error("end_state3 is not detected. end_state3 = %2d", end_state3);
        error_count = error_count + 1;
    end else begin
        $display("Yes!, end_state3 signal is detected");
    end
    
    // calculate output_neuron_onehot
    max_expected = 0;
    max_value = output_neuron[0];
    for (i = 1 ; i < NOUT ; i = i + 1) begin
        if (output_neuron[i] > max_value) begin
            max_value = output_neuron[i];
            max_expected = i;
        end
    end

    $display("--------------------------------------------------------------");
    $display("[3.2] check output_neuron value and one_hot at %0t", $time);
    expected = (output_neuron_onehot === one_hot(max_expected));
    if (!expected) begin
        $error("output_neuron_onehot have an error");
        $display("output_neuron_onehot = %3d", output_neuron_onehot);
        error_count = error_count + 1;
    end else begin
        $display("output_neuron_onehot value is correct");
    end

    $display("--------------------------------------------------------------");
    $display("[3.3] check matched signal for COMPARE module");
    char = (output_neuron_onehot === target_label_onehot);
    expected = (matched === char);
    if (!expected) begin
        $error("matched signal is wrong, matched = %3d", matched);
        $display("expected matched signal = %3d", expected);
        error_count = error_count + 1;
    end else begin
        $display("Yes! matched signal is correct");
    end
    
    // waiting for match signal is applied in Neural Network
    # minimum_period;
    
    /* if our expectation is matched, continue for-loop */
    if (matched) begin
        $display("");
        Yes = Yes + 1;
        $display("loop = %1d data is matched, go to next data", loop);
        disable continue_loop;
    end else begin
        $display("loop = %1d data is not matched, so backpropagation process", loop);
        No = No + 1;
    end
    
    // this block is matched signal is 1'b0
    /*-----------------------------------------------------------------------
     * state [4] UPDATE_SECOND_LAYER
     *--------------------------------------------------------------------*/    
    
    // delay for state4
    # clock_period; 
    
    $display("--------------------------------------------------------------");
    $display("[4.0] check current state is UPDATE_SECOND_LAYER");
    expected = (state === UPDATE_SECOND_LAYER);
    if (!expected) begin
        $error("state error, expected = 4, state = %2d", state);
        error_count = error_count + 1;
    end else begin
        $display("Yep!, current state is UPDATE_SECOND_LAYER");
    end
    
    $display("--------------------------------------------------------------");
    $display("[4.1] Check, start_pos and start_neg signal at %0t", $time);
    $write("start_pos : %2d,", start_pos);
    $display("output_neuron_onehot = %2d", output_neuron_onehot);
    $write("start_neg : %2d", start_pos);
    $display("target_label_onehot = %2d", target_label_onehot);
    
    // delay for update signal
    # clock_period;
    
    $display("--------------------------------------------------------------");
    $display("[4.2] Check 'update_second_layer signal");
    char = (output_neuron_onehot | target_label_onehot);
    expected = (update_second_layer === char);
    if (!expected) begin
        $error("update_second_layer signal is wrong!");
        $display("expected signal = %1d", expected);
        $display("update_second_layer = %1d", update_second_layer);
        error_count = error_count + 1;
    end else begin
        $display("update_second_layer is good!");
    end

    $display("--------------------------------------------------------------");
    $display("[4.3] delta_bias2 data check");

    expected = (delta_bias2[output_index] === 16'sd2);
    if (!expected) begin
        $error("delta_bias2 pos have an error,");
        $display("delta_bias2 : %3d", delta_bias2[output_index]);
        error_count = error_count + 1;
    end else begin
        $display("delta_bias pos data has no error, ");
    end

    expected = (delta_bias2[target_label] === -16'sd2);
    if (!expected) begin
        $error("delta_bias2 neg have an error, ");
        $display("delta_bias2 : %3d", delta_bias2[target_label]);
        error_count = error_count + 1;
    end else begin
        $display("delta_bias neg data has no error, ");
    end

    $display("--------------------------------------------------------------");
    $display("[4.4] delta_weight2 data check");

    for (i = 1 ; i < NHIDDEN ; i = i + 1) begin
        
        // delta_weight2[output_index] check
        expected = (delta_weight2[output_index] === hidden_neuron[i-1] / 8192);
        if (!expected) begin
            $error("%3dth delta_weight2[output_index] has an error", i);
            $display("delta_weight2 = %5d", delta_weight2[output_index]);
            $display("expected value = %5d", hidden_neuron[i-1] / 8192);
            error_count = error_count + 1;
        end
        
        // delta_weight2[target_label] check
        expected = (delta_weight2[target_label] === -hidden_neuron[i-1] / 8192);
        if (!expected) begin
            $error("%3dth delta_weight2[target_label] has an error", i);
            $display("delta_weight2 = %5d", delta_weight2[target_label]);
            $display("expected value = %5d", -hidden_neuron[i-1] / 8192);
            error_count = error_count + 1;
        end
        
        // clock delay;
        # clock_period;
    end

    // last delta_weight2[output_index] check
    expected = (delta_weight2[output_index] === hidden_neuron[i-1] / 8192);
    if (!expected) begin
        $error("%3dth delta_weight2[output_index] has an error", i);
        $display("delta_weight2 = %5d", delta_weight2[output_index]);
        $display("expected value = %5d", hidden_neuron[i-1] / 8192);
        error_count = error_count + 1;
    end
    
    // last delta_weight2[target_label] check
    expected = (delta_weight2[target_label] === -hidden_neuron[i-1] / 8192);
    if (!expected) begin
        $error("%3dth delta_weight2[target_label] has an error", i);
        $display("delta_weight2 = %5d", delta_weight2[target_label]);
        $display("expected value = %5d", -hidden_neuron[i-1] / 8192);
        error_count = error_count + 1;
    end
    
    // waiting for update final data 
    # clock_period;

    $display("--------------------------------------------------------------");
    $display("[4.5] Check start_state5 signal detect");

    expected = (start_state5 === 1'b1);
    if (!expected) begin
        $error("start_state5 signal is not detected");
        $display("start_state5 = %3d", start_state5);
        error_count = error_count + 1;
    end else begin
        $display("Success! start_state5 signal is detected!");
    end

    // waiting for [5] DERIVATIVE_HIDDEN
    # clock_period;

    $display("--------------------------------------------------------------");
    $display("[5.0] Check state is [5]DERIVATIVE_HIDDEN");
    
    expected = (state === DERIVATIVE_HIDDEN);
    if (!expected) begin
        $error("state is not DERIVATIVE_HIDDEN");
        $display("state == %3d", state);
        error_count = error_count + 1;
    end else begin
        $display("state is correct");
    end

    $display("--------------------------------------------------------------");
    $display("[5.1] Check start_backprop signal");
    
 
    // expected = (start_backprop === output_neuron_onehot | target_label_onehot);
    $display("start_backprop = %b", start_backprop);
    # clock_period;

    for (i = 0 ; i < NHIDDEN ; i = i + 1) begin
        expected = (enable_neuron[i] === 1'b1);
        if (!expected) begin
            $error("enable_neuron signal is not correct");
            $display("enable_neuron[%2d] = %d", i, enable_neuron[i]);
            error_count = error_count + 1;
        end 

        # clock_period;
    end

    $display("[5.2] state5 is ended at %0t", $time - clock_period);

    $display("--------------------------------------------------------------");
    $display("[6.0] Check state is [6] UPDATE_FIRST_LAYER at %0t", $time);

    expected = (state === UPDATE_FIRST_LAYER);
    if (!expected) begin
        $error("Current state is not UPDATE_FIRST_LAYER");
        $display("state = %2d", state);
        error_count = error_count + 1;
    end else begin
        $display("current state is UPDATE_FIRST_LAYER");
    end

    # clock_period;

    $display("--------------------------------------------------------------");
    $display("[6.1] Check update_first_layer is 1'b1 at %0t", $time);

    expected = (update_first_layer === 1'b1);
    if (!expected) begin
        $error("update_first_layer signal is %3d", update_first_layer);
        error_count = error_count + 1;
    end else begin
        $display("update_first_layer signal is correct");
    end

    $display("--------------------------------------------------------------");
    $display("[6.2] delta_bias1 value checking");

    for (i = 0 ; i < NHIDDEN ; i = i + 1) begin
        expected = (delta_bias1[i] === w_bit(derivative_hidden_neuron[i]));
        if (!expected) begin
            $error("delta_bias1 value is wrong");
            $display("delta_bias1[%1d] = %1d", i, delta_bias1[i]);
            $display("expected value = %1d", w_bit(derivative_hidden_neuron[i]));
            error_count = error_count + 1;
        end
    end
    
    $display("--------------------------------------------------------------");
    $display("[6.3] delta_weight1 value checking");

    for (i = 1 ; i < NPIXEL ; i = i + 1) begin
        char = w_bit(derivative_hidden_neuron[0] * pixel[i-1]);
        expected = (delta_weight1[0] === char);
        if (!expected) begin
            $error("delta_weight1 value have an error");
            $display("delta_weight1 value = %1d", delta_weight1[0]);
            $display("expected value = %1d", char);
            error_count = error_count + 1;
        end

        # clock_period;
    end
    
    // last delta_weight1 data check
    char = w_bit(derivative_hidden_neuron[0] * pixel[i-1]);
    expected = (delta_weight1[0] === char);
    if (!expected) begin
        $error("delta_weight1 value have an error");
        $display("delta_weight1 value = %d", delta_weight1[0]);
        error_count = error_count + 1;
    end

    // waiting for end_state6 signal
    # clock_period;

    $display("--------------------------------------------------------------");
    $display("[6.4] end_state6 signal checking");

    expected = (end_state6[0] === 1'b1);
    if (!expected) begin
        $error("end_state6 data is not 1'b1");
        $display("end_state6 = %1d", end_state6[0]);
        error_count = error_count + 1;
    end else begin
        $display("end_state6 is high");
    end
    
    // you don't care about this statement. It is just avoid an error
    # minimum_period; 

    /* continue loop end */
    end
    
    /* epoch loop end*/
    end
    $display("SIMULATION TERMINATED at %0t", $time);
    $display("total error count : %2d", error_count);
    $display("matched = %2d, mismatched = %2d", Yes, No);
    $stop(2);



end




endmodule