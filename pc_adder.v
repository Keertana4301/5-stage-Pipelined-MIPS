module pc_adder(
    input      [31:0]       pc_current,
    output     [31:0]       pc_next
);
    assign pc_next = pc_current + 32'd4;
endmodule
