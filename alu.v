module alu(
	input [31:0] data_rs,data_rt,
	input [2:0] control,
	output reg [31:0] data_rd,
	output zero
);

always @(*) begin
	case(control)
		3'd0: data_rd <= data_rs + data_rt;
		3'd1: data_rd <= data_rs - data_rt;
		3'd2: 
			 if (data_rs < data_rt) begin
				data_rd <= 32'd1;
			 end else begin
				data_rd <= 32'd0;
			 end
		3'd3: data_rd <= data_rs & data_rt;
		3'd4: data_rd <= data_rs | data_rt;
		3'd5: data_rd <= data_rs ^ data_rt;
		3'd6: data_rd <= ~(data_rs | data_rt);
		3'd7: data_rd <= data_rs + data_rt;
		default: data_rd <= data_rs + data_rt;
	endcase
end
assign zero = (data_rd == 32'd0) ? 1'b1 : 1'b0;
endmodule
				