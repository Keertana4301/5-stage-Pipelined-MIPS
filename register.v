module register(
    input               clk,
    input               rst,
    input      [4:0]    rs, rt, rd,
    input      [31:0]   data_in,
    input               RegWrite,
    output     [31:0]   data_rs,
    output     [31:0]   data_rt
);
    integer i;
    reg [31:0] reg_array [31:0];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                reg_array[i] <= 32'b0;
        end else begin
            if (RegWrite && (rd != 5'd0))
                reg_array[rd] <= data_in;
        end
    end

    assign data_rs = (rs == 5'd0) ? 32'b0 :
                      (RegWrite && (rd == rs)) ? data_in :
                      reg_array[rs];

    assign data_rt = (rt == 5'd0) ? 32'b0 :
                      (RegWrite && (rd == rt)) ? data_in :
                      reg_array[rt];
endmodule
