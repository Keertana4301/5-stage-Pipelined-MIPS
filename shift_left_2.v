module shift_left_2(
    input      [31:0]       data_in,
    output     [31:0]       data_out
);
    assign data_out = {data_in[29:0], 2'b00};
endmodule
