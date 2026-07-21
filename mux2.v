module mux2(
	input [31:0] data_rt, imm,
	input ALUSrc,
	output [31:0] data_out
);

assign data_out = ( ALUSrc == 1'b1) ? imm : data_rt;

endmodule
	