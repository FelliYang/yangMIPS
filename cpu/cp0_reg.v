`include "defines.v"
module cp0_reg(
	input clk, rst,
	input [4:0]raddr_i, waddr_i,
	input we_i,
	input [31:0] wdata_i,
	input [5:0] int_i, //6个外部硬件中断
	
	output reg [31:0] data_o,
	output reg [31:0] count_o, compare_o, status_o, cause_o,
				epc_o, config_o, prid_o,
	output reg timer_int_o //是否有定时中断发生
);

//写操作
always @(posedge clk) begin
	if(rst) begin
		{count_o,compare_o, cause_o, epc_o} <= 0;
		//Status CU字段为4‘b0001
		status_o <= 32'h1000_0000;
		//Config初始值BE字段为1
		config_o <= 32'h0000_8000;
		//公司编号 0x48 处理器编号 1 版本号 1.0
		prid_o <= 32'h0048_0102;
		timer_int_o <= 0;
	end else begin
		count_o <= count_o + 1; //每周期+1
		cause_o[15:10] <= int_i; //第10-15位保存外部中断声明
		if(compare_o!=0 && count_o == compare_o) 
			timer_int_o <= 1;
	end

	if(we_i) begin
		case (waddr_i)
			`CP0_COUNT: count_o <= wdata_i; 
			`CP0_COMPARE: begin
				compare_o <= wdata_i;
				timer_int_o <= 0; //重置定时器中断
			end
			`CP0_STATUS: status_o <= wdata_i;
			`CP0_EPC: epc_o <= wdata_i;
			`CP0_CAUSE: begin
				//只有部分位是可以写的
				cause_o[9:8] <= wdata_i[9:8];
				cause_o[23:22] <= wdata_i[23:22];
			end
			default: ;
		endcase
	end
end 

//读操作
always @(*) begin
	if(rst) data_o <= 0;
	else begin
		if(we_i) begin
			case (raddr_i)
				`CP0_COUNT: data_o = wdata_i;
				`CP0_COMPARE: data_o = wdata_i;
				`CP0_STATUS: data_o = wdata_i;
				`CP0_CAUSE: data_o = {wdata_i[31:24],cause_o[23:22], wdata_i[21:10], cause_o[9:8], wdata_i[7:0]};
				`CP0_EPC: data_o = wdata_i;
				`CP0_PRID: data_o = prid_o;
				`CP0_CONFIG: data_o = config_o;
				default: ;
			endcase
		end else begin
			case (raddr_i)
				`CP0_COUNT: data_o = count_o;
				`CP0_COMPARE: data_o = compare_o;
				`CP0_STATUS: data_o = status_o;
				`CP0_CAUSE: data_o = cause_o;
				`CP0_EPC: data_o = epc_o;
				`CP0_PRID: data_o = prid_o;
				`CP0_CONFIG: data_o = config_o;
				default: ;
			endcase
		end
	end
end

endmodule // cp0_reg