`include "defines.v"
module cp0_reg(
	input clk, rst,
	input [4:0]raddr_i, waddr_i,
	input we_i,
	input [31:0] wdata_i,
	input [5:0] int_i, //6个外部硬件中断

	/****异常输入****/
	input [31:0] excepttype_i, current_inst_addr_i,
	input is_in_delayslot_i,
	
	output reg [31:0] data_o,
	output reg [31:0] count_o, compare_o, status_o, cause_o,
				epc_o, config_o, prid_o,
	output reg timer_int_o //是否有定时中断发生
);

reg [31:0] count, compare, status, cause, epc;
reg [31:0] config_reg, prid;

//写操作
always @(posedge clk) begin
	if(rst) begin
		{count,compare, cause, epc} <= 0;
		//Status CU字段为4‘b0001
		status <= 32'h1000_0000;
		//Config初始值BE字段为1
		config_reg <= 32'h0000_8000;
		//公司编号 0x48 处理器编号 1 版本号 1.0
		prid <= 32'h0048_0102;
		timer_int_o <= 0;
	end else begin
		count <= count + 1; //每周期+1
		cause[15:10] <= int_i; //第10-15位保存外部中断声明
		if(compare!=0 && count == compare) 
			timer_int_o <= 1;
	end

	if(we_i) begin
		case (waddr_i)
			`CP0_COUNT: count <= wdata_i; 
			`CP0_COMPARE: begin
				compare <= wdata_i;
				timer_int_o <= 0; //重置定时器中断
			end
			`CP0_STATUS: status <= wdata_i;
			`CP0_EPC: epc <= wdata_i;
			`CP0_CAUSE: begin
				//只有部分位是可以写的
				cause[9:8] <= wdata_i[9:8];
				cause[23:22] <= wdata_i[23:22];
			end
			default: ;
		endcase
	end

	case(excepttype_i)
		32'h1: begin						//中断
			if(is_in_delayslot_i) begin 
				epc <= current_inst_addr_i - 4;
				cause[31] <= 1; //DB = 1
			end else begin
				epc <= current_inst_addr_i;
				cause[31] <= 0;
			end
			status[1] <= 1'b1;
			cause[6:2] <= 0; //execode字段
		end
		32'h8: begin						//syscall
			if(status[1] == 1'b0) begin 
				if(is_in_delayslot_i) begin
					epc <= current_inst_addr_i - 4;
					cause[31] <= 1; //DB = 1
				end else begin
					epc <= current_inst_addr_i;
					cause[31] <= 0;
				end
			end 
			status[1] <= 1'b1;
			cause[6:2] <= 5'b01000; //execode字段
		end
		32'ha:begin							//Inst_inValid
			if(status[1] == 1'b0) begin 
				if(is_in_delayslot_i) begin
					epc <= current_inst_addr_i - 4;
					cause[31] <= 1; //DB = 1
				end else begin
					epc <= current_inst_addr_i;
					cause[31] <= 0;
				end
			end 
			status[1] <= 1'b1;
			cause[6:2] <= 5'b01010; //execode字段
		end
		32'hd:begin							//trap
			if(status[1] == 1'b0) begin 
				if(is_in_delayslot_i) begin
					epc <= current_inst_addr_i - 4;
					cause[31] <= 1; //DB = 1
				end else begin
					epc <= current_inst_addr_i;
					cause[31] <= 0;
				end
			end 
			status[1] <= 1'b1;
			cause[6:2] <= 5'b01101; //execode字段
		end
		32'hc:begin							//溢出异常
			if(status[1] == 1'b0) begin 
				if(is_in_delayslot_i) begin
					epc <= current_inst_addr_i - 4;
					cause[31] <= 1; //DB = 1
				end else begin
					epc <= current_inst_addr_i;
					cause[31] <= 0;
				end
			end 
			status[1] <= 1'b1;
			cause[6:2] <= 5'b01100; //execode字段
		end
		32'he:begin							//eret
			status[1] <= 0;
		end
		
		
	endcase
end 

//读操作
always @(*) begin
	if(rst) data_o = 0;
	else begin
		data_o = 0;
		if(we_i) begin
			case (raddr_i)
				`CP0_COUNT: data_o = wdata_i;
				`CP0_COMPARE: data_o = wdata_i;
				`CP0_STATUS: data_o = wdata_i;
				`CP0_CAUSE: data_o = {wdata_i[31:24],cause_o[23:22], wdata_i[21:10], cause_o[9:8], wdata_i[7:0]};
				`CP0_EPC: data_o = wdata_i;
				`CP0_PRID: data_o = prid;
				`CP0_CONFIG: data_o = config_reg;
				default: ;
			endcase
		end else begin
			case (raddr_i)
				`CP0_COUNT: data_o = count;
				`CP0_COMPARE: data_o = compare;
				`CP0_STATUS: data_o = status;
				`CP0_CAUSE: data_o = cause;
				`CP0_EPC: data_o = epc;
				`CP0_PRID: data_o = prid;
				`CP0_CONFIG: data_o = config_reg;
				default: ;
			endcase
		end
	end
end
//输出cp0寄存器
always @(*) begin
	if(rst) {count_o,compare_o,status_o, cause_o, epc_o,prid_o,config_o} = 0;
	else begin
		{count_o,compare_o,status_o, cause_o, epc_o,prid_o,config_o} = 
		{count, compare, status,cause, epc, prid, config_reg};
		if(we_i) begin
			case (waddr_i)
				`CP0_COUNT: count_o = wdata_i;
				`CP0_COMPARE: compare_o = wdata_i;
				`CP0_STATUS: status_o = wdata_i;
				`CP0_CAUSE: cause_o = {wdata_i[31:24],cause_o[23:22], wdata_i[21:10], cause_o[9:8], wdata_i[7:0]};
				`CP0_EPC: epc_o = wdata_i;
				`CP0_PRID: prid_o = prid;
				`CP0_CONFIG: config_o = config_reg;
				default: ;
			endcase
		end
	end
end
endmodule // cp0_reg