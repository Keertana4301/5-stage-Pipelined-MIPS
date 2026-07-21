module mips(
    input                   clk,
    input                   rst,
    output     [31:0]       debug_wb_data,      
    output     [4:0]        debug_wb_reg,       
    output                  debug_wb_regwrite,  
    output     [31:0]       debug_pc            
);

    wire [31:0] pc_current, pc_next, pc_plus4_IF;
    wire [31:0] instruction_IF;

    wire        stall;             
    wire        branch_taken_EX;   
    wire        jump_ID;           
    wire [31:0] branch_target_EX;
    wire [31:0] jump_address_ID;

    assign pc_next = branch_taken_EX ? branch_target_EX :
                      jump_ID        ? jump_address_ID  :
                      stall          ? pc_current        :
                                       pc_plus4_IF;

    program_counter PC(
        .clk(clk),
        .rst(rst),
        .pc_in(pc_next),
        .pc_out(pc_current)
    );

    pc_adder PC_ADD(
        .pc_current(pc_current),
        .pc_next(pc_plus4_IF)
    );

    instruction_memory IMEM(
        .clk(clk),
        .pc_addr(pc_current),
        .instruction(instruction_IF)
    );

    wire [31:0] instr_ID, pc_plus4_ID;
    wire        if_id_flush = branch_taken_EX | jump_ID;

    if_id_reg IF_ID(
        .clk(clk),
        .rst(rst),
        .stall(stall),
        .flush(if_id_flush),
        .instr_in(instruction_IF),
        .pc_plus4_in(pc_plus4_IF),
        .instr_out(instr_ID),
        .pc_plus4_out(pc_plus4_ID)
    );

    wire [5:0]  opcode_ID = instr_ID[31:26];
    wire [5:0]  funct_ID  = instr_ID[5:0];
    wire [4:0]  rs_ID     = instr_ID[25:21];
    wire [4:0]  rt_ID     = instr_ID[20:16];
    wire [4:0]  rd_ID     = instr_ID[15:11];
    wire [15:0] imm_ID    = instr_ID[15:0];
    wire [25:0] jaddr_ID  = instr_ID[25:0];

    wire [1:0]  RegDst_ID;
    wire        Jump_ID_ctrl, Branch_ID, MemRead_ID, MemtoReg_ID;
    wire [2:0]  ALUOp_ID;
    wire        MemWrite_ID, ALUSrc_ID, RegWrite_ID;

    control_unit CTRL(
        .opcode(opcode_ID),
        .funct(funct_ID),
        .RegDst(RegDst_ID),
        .Jump(Jump_ID_ctrl),
        .Branch(Branch_ID),
        .MemRead(MemRead_ID),
        .MemtoReg(MemtoReg_ID),
        .ALUOp(ALUOp_ID),
        .MemWrite(MemWrite_ID),
        .ALUSrc(ALUSrc_ID),
        .RegWrite(RegWrite_ID)
    );

    assign jump_ID = Jump_ID_ctrl;

    wire [31:0] read_data1_ID, read_data2_ID;
    wire [31:0] write_data_WB;
    wire [4:0]  write_reg_WB;
    wire        RegWrite_WB;

    register REGFILE(
        .clk(clk),
        .rst(rst),
        .rs(rs_ID),
        .rt(rt_ID),
        .rd(write_reg_WB),
        .data_in(write_data_WB),
        .RegWrite(RegWrite_WB),
        .data_rs(read_data1_ID),
        .data_rt(read_data2_ID)
    );

    wire [31:0] sign_imm_ID;
    sign_extend SIGNEXT(
        .imm_in(imm_ID),
        .imm_out(sign_imm_ID)
    );

    wire [31:0] branch_offset_ID;
    shift_left_2 SLL2_BRANCH(
        .data_in(sign_imm_ID),
        .data_out(branch_offset_ID)
    );

    wire [4:0] write_reg_ID;
    mux3 REG_DST_MUX(
        .rt(rt_ID),
        .rd(rd_ID),
        .RegDst(RegDst_ID[0]),
        .add_out(write_reg_ID)
    );

    jump_calc JUMP_CALC(
        .pc_plus4(pc_plus4_ID),
        .jump_offset(jaddr_ID),
        .jump_addr(jump_address_ID)
    );

    wire        MemRead_EX;
    wire [4:0]  rt_EX;
    hazard_unit HAZARD(
        .id_ex_memread(MemRead_EX),
        .id_ex_rt(rt_EX),
        .if_id_rs(rs_ID),
        .if_id_rt(rt_ID),
        .stall(stall)
    );

    wire        id_ex_flush = branch_taken_EX | stall;

    wire        RegWrite_EX, MemtoReg_EX, MemWrite_EX, ALUSrc_EX, Branch_EX;
    wire [2:0]  ALUOp_EX;
    wire [31:0] data1_EX, data2_EX, sign_imm_EX, branch_offset_EX, pc_plus4_EX;
    wire [4:0]  rs_EX, write_reg_EX;

    id_ex_reg ID_EX(
        .clk(clk),
        .rst(rst),
        .flush(id_ex_flush),

        .RegWrite_in(RegWrite_ID),
        .MemtoReg_in(MemtoReg_ID),
        .MemRead_in(MemRead_ID),
        .MemWrite_in(MemWrite_ID),
        .ALUSrc_in(ALUSrc_ID),
        .Branch_in(Branch_ID),
        .ALUOp_in(ALUOp_ID),

        .data1_in(read_data1_ID),
        .data2_in(read_data2_ID),
        .sign_imm_in(sign_imm_ID),
        .branch_offset_in(branch_offset_ID),
        .pc_plus4_in(pc_plus4_ID),
        .rs_in(rs_ID),
        .rt_in(rt_ID),
        .write_reg_in(write_reg_ID),

        .RegWrite_out(RegWrite_EX),
        .MemtoReg_out(MemtoReg_EX),
        .MemRead_out(MemRead_EX),
        .MemWrite_out(MemWrite_EX),
        .ALUSrc_out(ALUSrc_EX),
        .Branch_out(Branch_EX),
        .ALUOp_out(ALUOp_EX),

        .data1_out(data1_EX),
        .data2_out(data2_EX),
        .sign_imm_out(sign_imm_EX),
        .branch_offset_out(branch_offset_EX),
        .pc_plus4_out(pc_plus4_EX),
        .rs_out(rs_EX),
        .rt_out(rt_EX),
        .write_reg_out(write_reg_EX)
    );

    wire [31:0] alu_result_MEM_fwd;   
    wire [31:0] write_data_WB_fwd;    
    wire [4:0]  write_reg_MEM;
    wire        RegWrite_MEM;

    wire [1:0]  forwardA, forwardB;
    forwarding_unit FWD(
        .ex_rs(rs_EX),
        .ex_rt(rt_EX),
        .mem_write_reg(write_reg_MEM),
        .mem_regwrite(RegWrite_MEM),
        .wb_write_reg(write_reg_WB),
        .wb_regwrite(RegWrite_WB),
        .forwardA(forwardA),
        .forwardB(forwardB)
    );

    wire [31:0] fwd_data1 = (forwardA == 2'b10) ? alu_result_MEM_fwd :
                             (forwardA == 2'b01) ? write_data_WB_fwd :
                             data1_EX;

    wire [31:0] fwd_data2 = (forwardB == 2'b10) ? alu_result_MEM_fwd :
                             (forwardB == 2'b01) ? write_data_WB_fwd :
                             data2_EX;

    wire [31:0] alu_input2_EX;
    mux2 ALU_SRC_MUX(
        .data_rt(fwd_data2),
        .imm(sign_imm_EX),
        .ALUSrc(ALUSrc_EX),
        .data_out(alu_input2_EX)
    );

    wire [31:0] alu_result_EX;
    wire        zero_EX;
    alu ALU(
        .data_rs(fwd_data1),
        .data_rt(alu_input2_EX),
        .control(ALUOp_EX),
        .data_rd(alu_result_EX),
        .zero(zero_EX)
    );

    branch_adder BRANCH_ADD(
        .pc_plus4(pc_plus4_EX),
        .imm_shifted(branch_offset_EX),
        .branch_target(branch_target_EX)
    );

    assign branch_taken_EX = Branch_EX & zero_EX;

    wire        MemtoReg_MEM, MemRead_MEM, MemWrite_MEM;
    wire [31:0] alu_result_MEM, mem_write_data_MEM;

    ex_mem_reg EX_MEM(
        .clk(clk),
        .rst(rst),

        .RegWrite_in(RegWrite_EX),
        .MemtoReg_in(MemtoReg_EX),
        .MemRead_in(MemRead_EX),
        .MemWrite_in(MemWrite_EX),
        .alu_result_in(alu_result_EX),
        .mem_write_data_in(fwd_data2),
        .write_reg_in(write_reg_EX),

        .RegWrite_out(RegWrite_MEM),
        .MemtoReg_out(MemtoReg_MEM),
        .MemRead_out(MemRead_MEM),
        .MemWrite_out(MemWrite_MEM),
        .alu_result_out(alu_result_MEM),
        .mem_write_data_out(mem_write_data_MEM),
        .write_reg_out(write_reg_MEM)
    );

    assign alu_result_MEM_fwd = alu_result_MEM;

    wire [31:0] mem_data_MEM;

    data_memory DMEM(
        .clk(clk),
        .mem_access_addr(alu_result_MEM),
        .mem_write_data(mem_write_data_MEM),
        .mem_write_en(MemWrite_MEM),
        .mem_read(MemRead_MEM),
        .mem_read_data(mem_data_MEM)
    );

    wire        MemtoReg_WB;
    wire [31:0] mem_read_data_WB, alu_result_WB;

    mem_wb_reg MEM_WB(
        .clk(clk),
        .rst(rst),

        .RegWrite_in(RegWrite_MEM),
        .MemtoReg_in(MemtoReg_MEM),
        .mem_read_data_in(mem_data_MEM),
        .alu_result_in(alu_result_MEM),
        .write_reg_in(write_reg_MEM),

        .RegWrite_out(RegWrite_WB),
        .MemtoReg_out(MemtoReg_WB),
        .mem_read_data_out(mem_read_data_WB),
        .alu_result_out(alu_result_WB),
        .write_reg_out(write_reg_WB)
    );

    mux2 WB_MUX(
        .data_rt(alu_result_WB),
        .imm(mem_read_data_WB),
        .ALUSrc(MemtoReg_WB),
        .data_out(write_data_WB)
    );

    assign write_data_WB_fwd = write_data_WB;

    assign debug_wb_data     = write_data_WB;
    assign debug_wb_reg      = write_reg_WB;
    assign debug_wb_regwrite = RegWrite_WB;
    assign debug_pc          = pc_current;

endmodule