module branch_adder(
    input      [31:0]       pc_plus4,
    input      [31:0]       imm_shifted,
    output     [31:0]       branch_target
);
    assign branch_target = pc_plus4 + imm_shifted;
endmodule
