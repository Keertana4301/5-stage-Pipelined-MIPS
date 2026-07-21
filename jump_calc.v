module jump_calc(
    input      [31:0]       pc_plus4,
    input      [25:0]       jump_offset,
    output     [31:0]       jump_addr
);
    assign jump_addr = {pc_plus4[31:28], jump_offset, 2'b00};
endmodule
