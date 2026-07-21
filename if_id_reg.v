module if_id_reg(
    input                   clk,
    input                   rst,
    input                   stall,      
    input                   flush,      
    input      [31:0]       instr_in,
    input      [31:0]       pc_plus4_in,
    output reg [31:0]       instr_out,
    output reg [31:0]       pc_plus4_out
);
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            instr_out    <= 32'b0;
            pc_plus4_out <= 32'b0;
        end else if (flush) begin
            instr_out    <= 32'b0;
            pc_plus4_out <= 32'b0;
        end else if (!stall) begin
            instr_out    <= instr_in;
            pc_plus4_out <= pc_plus4_in;
        end
        
    end
endmodule
