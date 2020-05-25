module ctrl(
	input rst,
	input stallreq_from_id, //来自译码阶段的暂停请求
	input stallreq_from_ex, //来自执行阶段的暂停请求
	output reg [5:0] stall
);

always @(*) begin
	if(rst) stall = 0;
	else if(stallreq_from_id) stall = 6'b000111;
	else if(stallreq_from_ex) stall = 6'b001111;
	else stall = 0;
end

endmodule // ctrlinput rst,