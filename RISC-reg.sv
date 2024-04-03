`timsclae 1ns/ 1ps

//Adapted from fpga4student.com example of a 16bit RISC-V Memory
//SystemVerilog for register file
module GPRs(
    input clk,
    //Ports to write
    input reg_write_en,
    input [4:0] reg_write_dest,
    input [31:0]reg_write_data,
    //port 1 read
    input [5:0] reg_read_addr_1,
    input [31:0] reg_read_data_1,
    //port 2 read
    input [5:0] reg_read_addr_2,
    input [31:0] reg_read_data_2
);
    reg [31:0] reg_array [7:0];
    interger i;
    //write port
    //reg [2:0] i;

    initial begin
        for(i=0;i<8;i=i+1)
        reg_array[i] <=32'd0;
    end
    always @ (postege clk) begin
        if(reg_write_en) begin
            reg_array[reg_write_dest] <= reg_write_data;
        end
    end

    assign reg_read_addr_1 = reg_array[reg_read_addr_1];
    assign reg_read_data_2 = reg_array[reg_read_addr_2];

endmodule