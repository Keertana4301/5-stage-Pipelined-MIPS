module ex_mem_reg(
    input                   clk,
    input                   rst,

    input                   RegWrite_in,
    input                   MemtoReg_in,
    input                   MemRead_in,
    input                   MemWrite_in,
    input      [31:0]       alu_result_in,
    input      [31:0]       mem_write_data_in,
    input      [4:0]        write_reg_in,

    output reg              RegWrite_out,
    output reg              MemtoReg_out,
    output reg              MemRead_out,
    output reg              MemWrite_out,
    output reg [31:0]       alu_result_out,
    output reg [31:0]       mem_write_data_out,
    output reg [4:0]        write_reg_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite_out       <= 1'b0;
            MemtoReg_out       <= 1'b0;
            MemRead_out        <= 1'b0;
            MemWrite_out       <= 1'b0;
            alu_result_out     <= 32'b0;
            mem_write_data_out <= 32'b0;
            write_reg_out      <= 5'b0;
        end else begin
            RegWrite_out       <= RegWrite_in;
            MemtoReg_out       <= MemtoReg_in;
            MemRead_out        <= MemRead_in;
            MemWrite_out       <= MemWrite_in;
            alu_result_out     <= alu_result_in;
            mem_write_data_out <= mem_write_data_in;
            write_reg_out      <= write_reg_in;
        end
    end
endmodule
