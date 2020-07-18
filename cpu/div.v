module div(
	input clk,
	input rst,
	
	input	signed_div_i, //有符号乘法还是无符号乘法
	input [31:0] opdata1_i, opdata2_i,
	input start_i, annul_i, //启动信号和中止信号
	
	output reg [63:0] result_o,
	output reg ready_o
);
	reg [5:0]  cnt; //记录试商法周期数
	
	localparam DivFree = 0;
	localparam DivByZero = 1;
	localparam DivOn = 2;
	localparam DivEnd = 3;
	reg [1:0] state, next_state;

	//状态机状态更新
	always @(posedge clk) begin
		if(rst) state <= DivFree;
		else state <= next_state;
	end
	//状态机下一个状态
	always @(*) begin
		if(rst) next_state = DivFree;
		else begin
			next_state = state;
			case(state)
				DivFree: begin
					if(start_i && !annul_i && opdata2_i==0)
						next_state = DivByZero;
					else if(start_i && !annul_i)
						next_state = DivOn;
				end
				DivByZero:begin
					next_state = DivEnd;
				end
				DivOn:begin
					if(annul_i) next_state = DivFree;
					else if(cnt==32)  next_state = DivEnd;
				end
				DivEnd: begin
					if(start_i == 0) 
						next_state = DivFree;
				end
			endcase
		end
	end
	
	reg [31:0] temp_op1, temp_op2; //操作数绝对值
	reg [64:0] tempresult; //中间结果
 	reg [31:0] divisor; //除数

	wire [32:0] minusres; //被减数减去除数的结果
	assign  minusres = {1'b0,tempresult[63:32]} - {1'b0,divisor};

	//每个状态完成的具体工作

	//result信号和ready信号
	always @(posedge clk) begin
		if(rst) {ready_o, result_o} <= 0;
		else begin
			case(state)
				DivFree:begin
					if(next_state == DivOn) begin 
						cnt <= 0; //开始计数
						//有符号数除法使用操作数的绝对值进行除法
						if(signed_div_i && opdata1_i[31]) temp_op1 = ~opdata1_i + 1;
						else temp_op1 = opdata1_i; //阻塞赋值
						if(signed_div_i && opdata2_i[31]) temp_op2 = ~opdata2_i + 1;
						else temp_op2 = opdata2_i; //阻塞赋值
						//初始化
						tempresult <= {32'b0, temp_op1, 1'b0};
						divisor <= temp_op2;
					end //除数不为0
				end
				DivOn:begin
					if(next_state == DivOn) begin
						if(minusres[32]) begin
							//结果为负数
							tempresult <= {tempresult[63:0], 1'b0};
						end
						else begin
							//结果为正数
							tempresult <= {minusres[31:0], tempresult[31:0],1'b1};
						end
						cnt <= cnt + 1;
					end
					if(next_state == DivEnd) begin
						ready_o <= 1;
						//修正结果 ->商
						if(signed_div_i && (opdata1_i[31] ^ opdata2_i[31]))
							result_o[31:0] <= ~tempresult[31:0] + 1;
						else result_o[31:0] <= tempresult[31:0];
						//修正结果->余数
						if(signed_div_i && (opdata1_i[31] ^ tempresult[64]))
							result_o[63:32] <= ~tempresult[64:33] + 1;
						else result_o[63:32] <= tempresult[64:33];
					end
					if(next_state == DivFree) begin
						{ready_o, result_o} <= 0;
					end
				end
				DivByZero:begin
					if(next_state == DivEnd) begin
						ready_o <= 1;
						result_o <= 0;
					end
				end
				DivEnd:begin
					if(next_state==DivFree)
						result_o <= 0;
						ready_o <= 0;
				end
			endcase
		end
	end

endmodule // div