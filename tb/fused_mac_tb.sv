module fused_mac_tb;

// let's set up some simulation parameters
parameter TOGGLE=10;    // clock toggle rate
parameter TICK=10;      // one simulation step 
parameter TIMEOUT=1000; // end of simulation



localparam DATA_WIDTH = 4;
localparam ACC_WIDTH = 20;
localparam VECTOR_SIZE = 2;

// let's set up i/o

// inputs
logic clk;
logic reset;
logic [VECTOR_SIZE-1:0][DATA_WIDTH-1:0] a_in;
logic [VECTOR_SIZE-1:0][DATA_WIDTH-1:0] b_in;
logic start;

// outputs
logic [ACC_WIDTH-1:0] mac_result;
logic done;

fused_mac #(
    .DATA_WIDTH(DATA_WIDTH),
    .ACC_WIDTH(ACC_WIDTH),
    .VECTOR_SIZE(VECTOR_SIZE)
) dut (
    .clk(clk),
    .reset(reset),
    .a_in(a_in),
    .b_in(b_in),
    .start(start),
    .mac_result(mac_result),
    .done(done)
);



// now let's set up our clock and global sim behavior



always #(TOGGLE) clk = ~clk;

initial begin
    clk = 0;



// initialize inputs
        reset = 1'b1;
        a_in = '0;
        b_in = '0;


        start = 1'b0;

// apply reset
        #(TICK) reset = 1'b0;
        #(TICK);


// test case 1
        a_in = {4'd10, 4'd15}; // {8'd10, 8'd20, 8'd30, 8'd40};
        b_in = {4'd1, 4'd2};  // {8'd1, 8'd2, 8'd3, 8'd4};
        start = 1'b1;

        #(TICK);
        #(TICK);
        #(TICK);
        #(TICK);
        #(TICK);
        $display ("done:%d",done);
        #(TICK);
 //       wait(done);
        #(TICK);
        $display("Test case 1 -- Expected: %0d, Actual: %0d",40, mac_result);

        #(TIMEOUT)

        $display("Test case 1 -- Expected: %0d, Actual: %0d",40, mac_result);
 $finish;
end
endmodule
