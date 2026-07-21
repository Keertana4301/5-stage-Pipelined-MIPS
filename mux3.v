module mux3(
	input [4:0] rt, rd,
	input RegDst,
	output [4:0] add_out
);

assign add_out = ( RegDst == 2'd0) ? rt : 
						( RegDst == 2'd1) ? rd :
						5'd31 ;
endmodule
	