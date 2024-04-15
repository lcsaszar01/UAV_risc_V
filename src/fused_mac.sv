module fused_mac #(
    parameter DATA_WIDTH   = 8,
    parameter ACC_WIDTH    = 20,
    parameter OVFLW_BITS   = 3,
    parameter VECTOR_SIZE  = 4           // Length of vectors for MAC
) (
    input clk,
    input reset,
    input  [VECTOR_SIZE-1:0][DATA_WIDTH-1:0] a_in,
    input  [VECTOR_SIZE-1:0][DATA_WIDTH-1:0] b_in,
    input  start,                       // Signal to initiate MAC
    output [ACC_WIDTH-1:0] mac_result,
    output done                         // Signal completion
);

logic [VECTOR_SIZE-1:0][DATA_WIDTH-1:0] a_reg, b_reg;
logic [ACC_WIDTH-1:0] acc_reg;
logic [ACC_WIDTH-1:0] temp_result;
logic calculating;
logic done_int;


// let's set up some adder tree intermediates 
logic [ACC_WIDTH-1:0] mult_results [VECTOR_SIZE];
logic [ACC_WIDTH-1:0] mac_result_int;
logic [ACC_WIDTH-1:0] tree_adder_result;


/*****    let's set up outputs               ******/
assign mac_result = mac_result_int;
assign done = done_int;
/*****    let's set up control signals       ******/

always_ff @(posedge clk or posedge reset) begin
    if (reset) begin
        a_reg       <= '0;
        b_reg       <= '0;
        acc_reg     <= '0;
        calculating <= 1'b0; // set everything to 0 first
        done_int    <= 1'b0;
    end else if (start) begin
        a_reg       <= a_in;
        b_reg       <= b_in; 
        acc_reg     <= '0;
        
        // control flags

        calculating <= 1'b1;  
        done_int    <= 1'b0;
    end else if (calculating) begin
        if (acc_reg[ACC_WIDTH-1:ACC_WIDTH-OVFLW_BITS] == '0 || &acc_reg[ACC_WIDTH-1:ACC_WIDTH-OVFLW_BITS]) begin
            acc_reg     <= acc_reg + tree_adder_result;
            calculating <= 1'b0;
            done_int    <= 1'b1;
        end else begin
            calculating <= 1'b0;
            done_int    <= 1'b1;
        end
    end
end


/*****    this now contains the main datapath       ******/

genvar i;

// use generate here to in parallel do operand multiplication 
generate 
    for (i=0; i < VECTOR_SIZE; i++) begin
        always_comb begin
            mult_results[i] = a_reg[i] * b_reg[i];
        end
    end
endgenerate

// let's set up our adder tree
localparam LEVELS = $clog2(VECTOR_SIZE)+1;
logic [ACC_WIDTH-1:0] adder_stage [LEVELS][VECTOR_SIZE];

// now, the first stage of the adder tree is just the multiplication results
always_comb begin
    adder_stage[0] = mult_results;
end


// now let's generate the rest of the tree
genvar level, j;

// add up the values in pairs for our tree (remember it's binary) 
generate 
    for (level = 1; level < LEVELS; level++) begin    // set up outer loop
        for (j=0; j< VECTOR_SIZE >> level; j++) begin // set up inner loop
        
            always_comb begin
                adder_stage[level][j] = adder_stage[level-1][2*j] + adder_stage[level-1][2*j+1];
            end

        end
    end
endgenerate

// let's now add in the final odd vector

always_comb begin
    if (VECTOR_SIZE == 1) begin
        mac_result_int = mult_results[0];
    end else begin
        mac_result_int = adder_stage[LEVELS-1][0];
        if (VECTOR_SIZE[0]) begin
            mac_result_int = mac_result_int + adder_stage[LEVELS-1][1];
        end 
        else begin
            mac_result_int = mac_result_int; 
        end
    end
end


endmodule

