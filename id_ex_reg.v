module id_ex_reg(
    input                   clk,
    input                   rst,
    input                   flush,      

    input                   RegWrite_in,
    input                   MemtoReg_in,
    input                   MemRead_in,
    input                   MemWrite_in,
    input                   ALUSrc_in,
    input                   Branch_in,
    input      [2:0]        ALUOp_in,

    input      [31:0]       data1_in,
    input      [31:0]       data2_in,
    input      [31:0]       sign_imm_in,
    input      [31:0]       branch_offset_in,
    input      [31:0]       pc_plus4_in,
    input      [4:0]        rs_in,
    input      [4:0]        rt_in,
    input      [4:0]        write_reg_in,

    output reg              RegWrite_out,
    output reg              MemtoReg_out,
    output reg              MemRead_out,
    output reg              MemWrite_out,
    output reg              ALUSrc_out,
    output reg              Branch_out,
    output reg [2:0]        ALUOp_out,

    output reg [31:0]       data1_out,
    output reg [31:0]       data2_out,
    output reg [31:0]       sign_imm_out,
    output reg [31:0]       branch_offset_out,
    output reg [31:0]       pc_plus4_out,
    output reg [4:0]        rs_out,
    output reg [4:0]        rt_out,
    output reg [4:0]        write_reg_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            RegWrite_out      <= 1'b0;
            MemtoReg_out      <= 1'b0;
            MemRead_out       <= 1'b0;
            MemWrite_out      <= 1'b0;
            ALUSrc_out        <= 1'b0;
            Branch_out        <= 1'b0;
            ALUOp_out         <= 3'b0;
            data1_out         <= 32'b0;
            data2_out         <= 32'b0;
            sign_imm_out      <= 32'b0;
            branch_offset_out <= 32'b0;
            pc_plus4_out      <= 32'b0;
            rs_out            <= 5'b0;
            rt_out            <= 5'b0;
            write_reg_out     <= 5'b0;
        end else if (flush) begin
            RegWrite_out      <= 1'b0;
            MemtoReg_out      <= 1'b0;
            MemRead_out       <= 1'b0;
            MemWrite_out      <= 1'b0;
            ALUSrc_out        <= 1'b0;
            Branch_out        <= 1'b0;
            ALUOp_out         <= 3'b0;
            data1_out         <= 32'b0;
            data2_out         <= 32'b0;
            sign_imm_out      <= 32'b0;
            branch_offset_out <= 32'b0;
            pc_plus4_out      <= 32'b0;
            rs_out            <= 5'b0;
            rt_out            <= 5'b0;
            write_reg_out     <= 5'b0;
        end else begin
            RegWrite_out      <= RegWrite_in;
            MemtoReg_out      <= MemtoReg_in;
            MemRead_out       <= MemRead_in;
            MemWrite_out      <= MemWrite_in;
            ALUSrc_out        <= ALUSrc_in;
            Branch_out        <= Branch_in;
            ALUOp_out         <= ALUOp_in;
            data1_out         <= data1_in;
            data2_out         <= data2_in;
            sign_imm_out      <= sign_imm_in;
            branch_offset_out <= branch_offset_in;
            pc_plus4_out      <= pc_plus4_in;
            rs_out            <= rs_in;
            rt_out            <= rt_in;
            write_reg_out     <= write_reg_in;
        end
    end
endmodule
