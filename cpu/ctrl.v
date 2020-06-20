module ctrl(
	input rst,
	input stallreq_from_if,
	input stallreq_from_id, //来自译码阶段的暂停请求
	input stallreq_from_ex, //来自执行阶段的暂停请求
	input stallreq_from_mem,
	output reg [5:0] stall,

	//异常相关信息
	input [31:0] excepttype_i, cp0_epc_i,
	output reg [31:0] new_pc,
	output reg flush
	
);

always @(*) begin
	if(rst) begin 
		stall = 0;
		flush = 0;
		new_pc = 0;
	end else if(excepttype_i!=0) begin
		flush = 1;
		stall = 0;
		case (excepttype_i)
			32'h1: new_pc = 32'h20; //interrupt
			32'h8: new_pc = 32'h40;  //syscall
			32'ha: new_pc = 32'h40;  //inst_invalid
			32'hd: new_pc = 32'h40;  //trap
			32'hc: new_pc = 32'h40;  //ov
			32'he: new_pc = cp0_epc_i; //eret
			default: ;
		endcase
	end else if (stallreq_from_mem) begin
		stall = 6'b011111;
		flush = 0;
		new_pc = 0;
	end else if(stallreq_from_ex) begin
		stall = 6'b001111;
		flush = 0;
		new_pc = 0;
	end else if(stallreq_from_id) begin 
		stall = 6'b000111;
		flush = 0;
		new_pc = 0;
	end else if(stallreq_from_if) begin
		stall = 6'b000111;
		flush = 0;
		new_pc = 0;
	end	else begin 
		stall = 0;
		flush = 0;
		new_pc = 0;
	end
end

endmodule // ctrlinput rst,