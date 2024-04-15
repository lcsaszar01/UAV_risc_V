module instr_mem (
    input logic [31:0] addr,
    output logic [31:0] data
);

    logic [31:0] mem [255:0];

    initial begin
        // Initialize all memory locations to zero
        for (int i = 0; i < 256; i++) begin
            mem[i] = 32'h00000000;
        end
        // Load specific instructions
        mem[0] = 32'h00100093; // addi x1, x0, 1
        mem[1] = 32'h00200113; // addi x2, x0, 2
        mem[2] = 32'h002081b3; // add x3, x1, x2
        mem[3] = 32'h40308233; // sub x4, x1, x3
    end

    assign data = mem[addr[31:2]];

endmodule

module data_mem (
    input logic clk,
    input logic [31:0] addr,
    input logic [31:0] wdata,
    input logic we,
    output logic [31:0] rdata
);

    logic [31:0] mem [255:0];

    initial begin
        // Initialize all memory locations to zero
        for (int i = 0; i < 256; i++) begin
            mem[i] = 32'h00000000;
        end
    end

    always_ff @(posedge clk) begin
        if (we) begin
            mem[addr[31:2]] <= wdata;
        end
    end

    assign rdata = mem[addr[31:2]];

endmodule

