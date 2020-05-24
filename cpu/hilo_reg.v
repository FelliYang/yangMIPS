module hilo_reg(
	input clk,
	input rst,
	input we,
	input [31:0] hi_i, lo_i,
	output reg[31:0] hi_o, lo_o	
);

reg[31:0] hi,lo;

always@(posedge clk)begin
	if(rst) begin
		hi <= 0;
		lo <= 0;
	end else if(we)begin
		hi <= hi_i;
		lo <= lo_i;
	end
end

//组合逻辑->读
always @(*) begin
	if(rst) begin
		hi_o = 0;
		lo_o = 0;
	end else if(we) begin
		hi_o = hi_i;
		lo_o = lo_i;
	end else begin
		hi_o = hi;
		lo_o = lo;
	end
end



endmodule // hilo_reg