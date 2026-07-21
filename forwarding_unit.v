module forwarding_unit(
    input      [4:0]    ex_rs,
    input      [4:0]    ex_rt,
    input      [4:0]    mem_write_reg,
    input               mem_regwrite,
    input      [4:0]    wb_write_reg,
    input               wb_regwrite,
    output reg [1:0]    forwardA,
    output reg [1:0]    forwardB
);

    always @(*) begin
        if (mem_regwrite && (mem_write_reg != 5'd0) && (mem_write_reg == ex_rs))
            forwardA = 2'b10;
        else if (wb_regwrite && (wb_write_reg != 5'd0) && (wb_write_reg == ex_rs))
            forwardA = 2'b01;
        else
            forwardA = 2'b00;

        if (mem_regwrite && (mem_write_reg != 5'd0) && (mem_write_reg == ex_rt))
            forwardB = 2'b10;
        else if (wb_regwrite && (wb_write_reg != 5'd0) && (wb_write_reg == ex_rt))
            forwardB = 2'b01;
        else
            forwardB = 2'b00;
    end
endmodule
