module riscv_pipeline #(
    parameter int DATA_WIDTH = 32
) (
    input logic clk,
    input logic reset,
    
    // DO WE NEDD A INSTRUCITON IMPUT LOGIC FUNC HERE?????

    // Instruction memory interface
    output logic [DATA_WIDTH-1:0] instr_addr,
    input logic [DATA_WIDTH-1:0] instr_data,    // Data memory interface
    output logic [DATA_WIDTH-1:0] data_addr,
    output logic [DATA_WIDTH-1:0] data_wdata,
    input logic [DATA_WIDTH-1:0] data_rdata,
    output logic data_we
);

    // Instruction types
    typedef enum logic [6:0] {
        OPCODE_LOAD   = 7'b0000011,
        OPCODE_STORE  = 7'b0100011,
        OPCODE_BRANCH = 7'b1100011,
        OPCODE_JALR   = 7'b1100111,
        OPCODE_JAL    = 7'b1101111,
        OPCODE_OP_IMM = 7'b0010011,
        OPCODE_OP     = 7'b0110011
    } opcode_t;

    // ALU operations
    typedef enum logic [3:0] {
        ALU_ADD  = 4'b0000,
        ALU_SUB  = 4'b0001,
        ALU_SLT  = 4'b0010,
        ALU_SLTU = 4'b0011,
        ALU_XOR  = 4'b0100,
        ALU_OR   = 4'b0101,
        ALU_AND  = 4'b0110,
        ALU_SLL  = 4'b0111,
        ALU_SRL  = 4'b1000,
        ALU_SRA  = 4'b1001
    } alu_op_t;

    // ALU source B selection
    typedef enum logic {
        ALU_SRC_RS2 = 1'b0,
        ALU_SRC_IMM = 1'b1
    } alu_src_b_t;

    // Pipeline registers
    logic [DATA_WIDTH-1:0] IF_ID_pc, IF_ID_instr;
    logic [DATA_WIDTH-1:0] ID_EX_pc, ID_EX_rs1_data, ID_EX_rs2_data, ID_EX_imm;
    logic [4:0] ID_EX_rd, ID_EX_rs1, ID_EX_rs2;
    alu_op_t ID_EX_alu_op;
    alu_src_b_t ID_EX_alu_src;
    logic ID_EX_mem_read, ID_EX_mem_write, ID_EX_reg_write;
    logic [DATA_WIDTH-1:0] EX_MEM_alu_result, EX_MEM_rs2_data;
    logic [4:0] EX_MEM_rd;
    logic EX_MEM_mem_read, EX_MEM_mem_write, EX_MEM_reg_write;
    logic [DATA_WIDTH-1:0] MEM_WB_alu_result, MEM_WB_mem_data;
    logic [4:0] MEM_WB_rd;
    logic MEM_WB_reg_write;

    // Register file
    logic [DATA_WIDTH-1:0] reg_file [31:0];

    // Control signals
    opcode_t opcode;
    logic [2:0] funct3;
    logic [6:0] funct7;
    alu_op_t alu_op;
    alu_src_b_t alu_src;
    logic mem_read, mem_write, reg_write;
    logic [DATA_WIDTH-1:0] imm_gen_out;

    // IF stage
    logic [DATA_WIDTH-1:0] pc_reg, pc_next;
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= '0;
        end else begin
            pc_reg <= pc_next;
        end
    end
    assign pc_next = pc_reg + 4;
    assign instr_addr = pc_reg;

    // IF/ID pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            IF_ID_pc <= '0;
            IF_ID_instr <= '0;
        end else begin
            IF_ID_pc <= pc_reg;
            IF_ID_instr <= instr_data;
        end
    end

    // ID stage
    assign opcode = opcode_t'(IF_ID_instr[6:0]);
    assign funct3 = IF_ID_instr[14:12];
    assign funct7 = IF_ID_instr[31:25];

    // Control unit
    always_comb begin
        case (opcode)
            OPCODE_OP: begin
                alu_src = ALU_SRC_RS2;
                mem_read = 1'b0;
                mem_write = 1'b0;
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_op = (funct7[5] ? ALU_SUB : ALU_ADD);
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = (funct7[5] ? ALU_SRA : ALU_SRL);
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                endcase
            end
            OPCODE_OP_IMM: begin
                alu_src = ALU_SRC_IMM;
                mem_read = 1'b0;
                mem_write = 1'b0;
                reg_write = 1'b1;
                case (funct3)
                    3'b000: alu_op = ALU_ADD;
                    3'b001: alu_op = ALU_SLL;
                    3'b010: alu_op = ALU_SLT;
                    3'b011: alu_op = ALU_SLTU;
                    3'b100: alu_op = ALU_XOR;
                    3'b101: alu_op = (funct7[5] ? ALU_SRA : ALU_SRL);
                    3'b110: alu_op = ALU_OR;
                    3'b111: alu_op = ALU_AND;
                endcase
            end
            OPCODE_LOAD: begin
                alu_src = ALU_SRC_IMM;
                mem_read = 1'b1;
                mem_write = 1'b0;
                reg_write = 1'b1;
                alu_op = ALU_ADD;
            end
            OPCODE_STORE: begin
                alu_src = ALU_SRC_IMM;
                mem_read = 1'b0;
                mem_write = 1'b1;
                reg_write = 1'b0;
                alu_op = ALU_ADD;
            end
            default: begin
                alu_src = ALU_SRC_RS2;
                mem_read = 1'b0;
                mem_write = 1'b0;
                reg_write = 1'b0;
                alu_op = ALU_ADD;
            end
        endcase
    end

    // Instruction Decode Stage with Hazard Detection
    HazardDetectionUnit hazard_unit (
        .opcode1(instr[6:0]), // Opcode of the current instruction
        .opcode2(instr[6:0]), // Opcode of the next instruction
        .rd1(instr[11:7]),    // Destination register of the current instruction
        .rs2(instr[24:20]),   // Source register of the next instruction
        .hazard(hazard)       // Hazard signal
    );

    // Immediate generator
    always_comb begin
        begin
        if(hazard) //stall if hazard is detected
            rs1Data = 0; // Set inputs to ALU to 0
            rs2Data = 0;
        end
        else // Proceed normally
        begin
        case (opcode)
            OPCODE_OP_IMM: imm_gen_out = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:20]};
            OPCODE_LOAD  : imm_gen_out = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:20]};
            OPCODE_STORE : imm_gen_out = {{20{IF_ID_instr[31]}}, IF_ID_instr[31:25], IF_ID_instr[11:7]};
            default      : imm_gen_out = '0;
        endcase
        end
    end

    // ID/EX pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            ID_EX_pc <= '0;
            ID_EX_rs1_data <= '0;
            ID_EX_rs2_data <= '0;
            ID_EX_imm <= '0;
            ID_EX_rd <= '0;
            ID_EX_rs1 <= '0;
            ID_EX_rs2 <= '0;
            ID_EX_alu_op <= ALU_ADD;
            ID_EX_alu_src <= ALU_SRC_RS2;
            ID_EX_mem_read <= '0;
            ID_EX_mem_write <= '0;
            ID_EX_reg_write <= '0;
        end else begin
            ID_EX_pc <= IF_ID_pc;
            ID_EX_rs1_data <= reg_file[ID_EX_rs1];
            ID_EX_rs2_data <= reg_file[ID_EX_rs2];
            ID_EX_imm <= imm_gen_out;
            ID_EX_rd <= IF_ID_instr[11:7];
            ID_EX_rs1 <= IF_ID_instr[19:15];
            ID_EX_rs2 <= IF_ID_instr[24:20];
            ID_EX_alu_op <= alu_op;
            ID_EX_alu_src <= alu_src;
            ID_EX_mem_read <= mem_read;
            ID_EX_mem_write <= mem_write;
            ID_EX_reg_write <= reg_write;
        end
    end


    // EX stage
    logic [DATA_WIDTH-1:0] alu_result;
    always_comb begin
        case (ID_EX_alu_op)
            ALU_ADD : alu_result = ID_EX_rs1_data + (ID_EX_alu_src == ALU_SRC_IMM ? ID_EX_imm : ID_EX_rs2_data);
            ALU_SUB : alu_result = ID_EX_rs1_data - ID_EX_rs2_data;
            ALU_SLT : alu_result = $signed(ID_EX_rs1_data) < $signed(ID_EX_imm) ? 1 : 0;
            ALU_SLTU: alu_result = ID_EX_rs1_data < ID_EX_imm ? 1 : 0;
            ALU_XOR : alu_result = ID_EX_rs1_data ^ (ID_EX_alu_src == ALU_SRC_IMM ? ID_EX_imm : ID_EX_rs2_data);
            ALU_OR  : alu_result = ID_EX_rs1_data | (ID_EX_alu_src == ALU_SRC_IMM ? ID_EX_imm : ID_EX_rs2_data);
            ALU_AND : alu_result = ID_EX_rs1_data & (ID_EX_alu_src == ALU_SRC_IMM ? ID_EX_imm : ID_EX_rs2_data);
            ALU_SLL : alu_result = ID_EX_rs1_data << ID_EX_rs2_data[4:0];
            ALU_SRL : alu_result = ID_EX_rs1_data >> ID_EX_rs2_data[4:0];
            ALU_SRA : alu_result = $signed(ID_EX_rs1_data) >>> ID_EX_rs2_data[4:0];
            default: alu_result = '0;
        endcase
    end

    // EX/MEM pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            EX_MEM_alu_result <= '0;
            EX_MEM_rs2_data <= '0;
            EX_MEM_rd <= '0;
            EX_MEM_mem_read <= '0;
            EX_MEM_mem_write <= '0;
            EX_MEM_reg_write <= '0;
        end else begin
            EX_MEM_alu_result <= alu_result;
            EX_MEM_rs2_data <= ID_EX_rs2_data;
            EX_MEM_rd <= ID_EX_rd;
            EX_MEM_mem_read <= ID_EX_mem_read;
            EX_MEM_mem_write <= ID_EX_mem_write;
            EX_MEM_reg_write <= ID_EX_reg_write;
        end
    end

    // MEM stage
    assign data_addr = EX_MEM_alu_result;
    assign data_wdata = EX_MEM_rs2_data;
    assign data_we = EX_MEM_mem_write;

    // MEM/WB pipeline register
    always_ff @(posedge clk or posedge reset) begin
        if (reset) begin
            MEM_WB_alu_result <= '0;
            MEM_WB_mem_data <= '0;
            MEM_WB_rd <= '0;
            MEM_WB_reg_write <= '0;
        end else begin
            MEM_WB_alu_result <= EX_MEM_alu_result;
            MEM_WB_mem_data <= data_rdata;
            MEM_WB_rd <= EX_MEM_rd;
            MEM_WB_reg_write <= EX_MEM_reg_write;
        end
    end

    // WB stage
    always_ff @(posedge clk) begin
        if (MEM_WB_reg_write) begin
            reg_file[MEM_WB_rd] <= MEM_WB_mem_data;
        end
    end

endmodule


// Hazard Detection Unit Module
// Produced by chatGPT, modifed by team
module HazardDetectionUnit (
    input logic [6:0] opcode1, // Opcode of the first instruction
    input logic [6:0] opcode2, // Opcode of the second instruction
    input logic [4:0] rd1,     // Destination register of the first instruction
    input logic [4:0] rs2,     // Source register of the second instruction
    output logic hazard         // Hazard signal indicating a hazard
);
    // Data Hazard Detection Logic
    always_comb begin
        // Check for read-after-write (RAW) hazard
        if (opcode1 != 7'b0000011 && opcode2 != 7'b0000011) begin // Exclude load instructions
            if (rd1 != 5'b00000 && rd1 == rs2) begin // Check if destination register of first instruction matches source register of second instruction
                hazard = 1'b1; // Hazard detected
            end else begin
                hazard = 1'b0; // No hazard
            end
        end else begin
            hazard = 1'b0; // No hazard for load instructions
        end
    end
endmodule
