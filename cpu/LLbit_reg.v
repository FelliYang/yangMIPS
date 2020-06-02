/**
*LL SC原子操作专用寄存器
*/
module LLbit_reg(
	input clk, rst,
	input flush, //表示异常是否发生
	//写操作
	input LLbit_i, we,
	//读操作
	output reg LLbit_o
);

reg LLbit;

//写操作
always @(clk) begin
	if(rst) LLbit <= 0;
	else if(flush) LLbit <= 0;
	else if (we) LLbit <= LLbit_i;	
end

//读操作
always @(*) begin
	if(flush) LLbit_o = 0; //减少数据旁路线，在时钟上升沿之前就将最新的结果送出去
	else if(we) LLbit_o = LLbit_i;
	else LLbit_o = LLbit;
end

endmodule // LLbit_reg