module riscv_stub_tb;

    parameter int DATA_WIDTH = 32;

    // Clock and reset signals
    logic clk;
    logic reset;

    // Instruction and data memory interface signals
    logic [DATA_WIDTH-1:0] instr_addr;
    logic [DATA_WIDTH-1:0] instr_data;
    logic [DATA_WIDTH-1:0] data_addr;
    logic [DATA_WIDTH-1:0] data_wdata;
    logic [DATA_WIDTH-1:0] data_rdata;
    logic data_we;


    // Instantiate the instruction memory
    instr_mem imem (
        .addr(instr_addr),
        .data(instr_data)
    );

    // Instantiate the data memory
    data_mem dmem (
        .clk(clk),
        .addr(data_addr),
        .wdata(data_wdata),
        .we(data_we),
        .rdata(data_rdata)
    );


    // Instantiate the riscv_stub module
    riscv_stub #(
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .reset(reset),
        .instr_addr(instr_addr),
        .instr_data(instr_data),
        .data_addr(data_addr),
        .data_wdata(data_wdata),
        .data_rdata(data_rdata),
        .data_we(data_we)
    );

    // Clock generation
    always begin
        clk = 1'b0;
        #5;
        clk = 1'b1;
        #5;
    end


    // Test scenario
    initial begin
        // Reset the processor
        reset = 1'b1;
        #20;
        reset = 1'b0;

        // Run the test for a certain number of cycles
        for (int i = 0; i < 10; i++) begin
            @(posedge clk);
            $display("Cycle %d:", i);
            
            // IF Stage
            $display("IF Stage:");
            $display("  PC: %h", dut.pc_reg);
            $display("  Instruction: %h", dut.instr_data);

            // ID Stage
            $display("ID Stage:");
            $display("  Opcode: %b", dut.opcode);
            $display("  Rs1 Address: %d", dut.IF_ID_instr[19:15]);
            $display("  Rs2 Address: %d", dut.IF_ID_instr[24:20]);
            $display("  Rd Address: %d", dut.IF_ID_instr[11:7]);
            $display("  Immediate: %h", dut.imm_gen_out);

            // EX Stage
            $display("EX Stage:");
            $display("  ALU Operation: %b", dut.ID_EX_alu_op);
            $display("  Rs1 Data: %h", dut.ID_EX_rs1_data);
            $display("  Rs2 Data: %h", dut.ID_EX_rs2_data);
            $display("  Immediate: %h", dut.ID_EX_imm);
            $display("  ALU Result: %h", dut.alu_result);

            // MEM Stage
            $display("MEM Stage:");
            $display("  Memory Address: %h", dut.data_addr);
            $display("  Memory Write Data: %h", dut.data_wdata);
            $display("  Memory Read Data: %h", dut.data_rdata);

            // WB Stage
            $display("WB Stage:");
            $display("  Register Write Enable: %b", dut.MEM_WB_reg_write);
            $display("  Register Write Address: %d", dut.MEM_WB_rd);
            $display("  Register Write Data: %h", dut.reg_file[dut.MEM_WB_rd]);

            $display("--------------------------------");
        end

        // Display the contents of registers after execution
        $display("Register x1: %d", dut.reg_file[1]);
        $display("Register x2: %d", dut.reg_file[2]);
        $display("Register x3: %d", dut.reg_file[3]);
        $display("Register x4: %d", dut.reg_file[4]);

        // Assertions
        assert(dut.reg_file[1] == 1) else $error("Assertion failed: x1 should be 1");
        assert(dut.reg_file[2] == 2) else $error("Assertion failed: x2 should be 2");
        assert(dut.reg_file[3] == 3) else $error("Assertion failed: x3 should be 3");
        assert(dut.reg_file[4] == -2) else $error("Assertion failed: x4 should be -2");

        // Finish the simulation
        $finish;
    end

endmodule
