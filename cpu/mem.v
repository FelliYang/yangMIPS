`include "defines.v"
module mem(
    input rst,
    
    /********来自执行级的信息********/
    input [4:0]wd_i,
    input [31:0]wdata_i,
    input       wreg_i,
    input       whilo_i,
    input [31:0] hi_i,lo_i,
	input [7:0] aluop_i,
	input [31:0] mem_addr_i, reg2_i,
	input [4:0]	cp0_waddr_i,
	input [31:0] cp0_wdata_i,
	input 		cp0_we_i,
	//异常相关
	input [31:0] excepttype_i, current_inst_address_i,
	input is_in_delayslot_i,
    
    /*******访存阶段的结果********/
    output reg [4:0] wd_o,
    output reg[31:0] wdata_o,
    output reg      wreg_o,
    output reg      whilo_o,
    output reg [31:0]  hi_o, lo_o,
	output reg[4:0] cp0_waddr_o,
	output reg[31:0] cp0_wdata_o,
	output reg		cp0_we_o,

	/*****存储器访问*****/
	//从存储器读取数据
	input [`DataBus] mem_data_i, //从存储器读取的数据
	//输出到存储器的信息
	output reg [`DataAddrBus] mem_addr_o,
	output reg [`DataBus] mem_data_o,
	output 			mem_we_o, //写使能
	output reg [3:0] mem_sel_o, //字节选择信号
	output reg		mem_ce_o, //数据存储器使能信号

	/*****LL SC指令相关信号*****/
	input LLbit_i,
	output reg LLbit_we_o,
	output reg LLbit_value_o,

	/****异常相关的其他信号*****/
	//CP0信息
	input [31:0] cp0_status_i, cp0_cause_i, cp0_epc_i,
	//输入到ctrl的信息
	output [31:0] current_inst_address_o, cp0_epc_o,
	output reg [31:0] excepttype_o,
	output is_in_delayslot_o

);

	//异常处理
	assign is_in_delayslot_o = is_in_delayslot_i;
	assign current_inst_address_o = current_inst_address_i;
	assign cp0_epc_o = cp0_epc_i;

	//确定异常类型
	always @(*) begin
		if(rst) excepttype_o = 0;
		else begin
			excepttype_o = 0;
			if(current_inst_address_i!=0) begin //发生异常的地址不可能是0X00
				if((cp0_cause_i[15:8]&cp0_status_i[15:8]) != 8'b0 &&
					cp0_status_i[1]==0 && cp0_status_i[0]==1)begin //interrupt
						excepttype_o = 32'h00000001;
				end else if (excepttype_i[8] == 1'b1) begin //system call
					excepttype_o = 32'h00000008;
				end else if (excepttype_i[9] == 1'b1) begin //inst_invalid
					excepttype_o = 32'h0000000a;
				end else if(excepttype_i[10] == 1'b1) begin //trap
					excepttype_o = 32'h0000000d;
				end else if (excepttype_i[11] == 1'b1) begin //ov
					excepttype_o = 32'h0000000c;
				end else if (excepttype_i[12] == 1'b1) begin //eret
					excepttype_o = 32'h0000000e;
				end
				
			end
		end
	end

	//异常情况下，修改存储器写信号
	reg mem_we;
	assign mem_we_o = mem_we & (~{|excepttype_o});

    //组合逻辑
    always @(*) begin
        if(rst) {wd_o,wdata_o,wreg_o,whilo_o,hi_o,lo_o,
		mem_addr_o, mem_data_o, mem_we, mem_sel_o, mem_ce_o,
		LLbit_we_o, LLbit_value_o,
		cp0_waddr_o,cp0_wdata_o,cp0_we_o} = 0;
        else begin
            wd_o = wd_i;
            wdata_o = wdata_i;
            wreg_o = wreg_i;
            whilo_o = whilo_i;
            hi_o = hi_i;
            lo_o = lo_i;
			cp0_waddr_o = cp0_waddr_i;
			cp0_wdata_o = cp0_wdata_i;
			cp0_we_o = cp0_we_i;
			//存储器相关信号
			 mem_ce_o = 0;
			 mem_sel_o = 4'b1111;
			{mem_addr_o, mem_data_o, mem_we} = 0;
			//LL SC 特殊信号
			{LLbit_we_o, LLbit_value_o} = 0;
			case(aluop_i)
				`ALU_LB: begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					case(mem_addr_i[1:0]) //判断低两位
						2'b00: begin
							wdata_o = {{24{mem_data_i[31]}}, mem_data_i[31:24]};
							mem_sel_o = 4'b1000;
						end
						2'b01:begin
							wdata_o = {{24{mem_data_i[23]}}, mem_data_i[23:16]};
							mem_sel_o = 4'b0100;
						end
						2'b10:begin
							wdata_o = {{24{mem_data_i[15]}}, mem_data_i[15:8]};
							mem_sel_o = 4'b0010;
						end
						2'b11:begin
							wdata_o = {{24{mem_data_i[7]}}, mem_data_i[7:0]};
							mem_sel_o = 4'b0001;
						end
					endcase
				end
				`ALU_LBU: begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					case(mem_addr_i[1:0]) //判断低两位
						2'b00: begin
							wdata_o = {24'b0, mem_data_i[31:24]};
							mem_sel_o = 4'b1000;
						end
						2'b01:begin
							wdata_o = {24'b0, mem_data_i[23:16]};
							mem_sel_o = 4'b0100;
						end
						2'b10:begin
							wdata_o = {24'b0, mem_data_i[15:8]};
							mem_sel_o = 4'b0010;
						end
						2'b11:begin
							wdata_o = {24'b0, mem_data_i[7:0]};
							mem_sel_o = 4'b0001;
						end
					endcase
				end
				`ALU_LH:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o = 4'b1100;
							wdata_o = {{16{mem_data_i[31]}}, mem_data_i[31:16]};
						end
						2'b10:begin
							mem_sel_o = 4'b0011;
							wdata_o = {{16{mem_data_i[15]}}, mem_data_i[15:0]};
						end
						default:wdata_o = 0; //地址对齐错误，应当发出异常
					endcase
				end
				`ALU_LHU:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o = 4'b1100;
							wdata_o = {16'b0, mem_data_i[31:16]};
						end
						2'b10:begin
							mem_sel_o = 4'b0011;
							wdata_o = {16'b0, mem_data_i[15:0]};
						end
						default:wdata_o = 0; //地址对齐错误，应当发出异常
					endcase
				end
				`ALU_LW:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					mem_sel_o = 4'b1111;
					wdata_o = mem_data_i;
				end
				`ALU_LWL:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					mem_sel_o = 4'b1111;
					case(mem_addr_i[1:0])
						2'b00: begin
							wdata_o = mem_data_i;
						end
						2'b01:begin
							wdata_o = {mem_data_i[23:0], reg2_i[7:0]};
						end
						2'b10:begin
							wdata_o = {mem_data_i[15:0], reg2_i[15:0]};
						end
						2'b11:begin
							wdata_o = {mem_data_i[7:0], reg2_i[23:0]};
						end
					endcase
				end
				`ALU_LWR:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					mem_sel_o = 4'b1111;
					case(mem_addr_i[1:0])
						2'b00: begin
							wdata_o = {reg2_i[31:8], mem_data_i[31:24]};
						end
						2'b01:begin
							wdata_o = {reg2_i[31:16], mem_data_i[31:16]};
						end
						2'b10:begin
							wdata_o = {reg2_i[31:23], mem_data_i[31:8]};
						end
						2'b11:begin
							wdata_o = mem_data_i;
						end
					endcase
				end
				`ALU_SB:begin
					mem_addr_o = mem_addr_i;
					mem_we = 1;
					mem_ce_o = 1;
					mem_data_o = {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o = 4'b1000;
						end
						2'b01:begin
							mem_sel_o = 4'b0100;
						end
						2'b10:begin
							mem_sel_o = 4'b0010;
						end
						2'b11:begin
							mem_sel_o = 4'b0001;
						end
						default:mem_sel_o = 4'b0000;
					endcase
				end
				`ALU_SH:begin
					mem_addr_o = mem_addr_i;
					mem_we = 1;
					mem_ce_o = 1;
					mem_data_o = {reg2_i[15:0],reg2_i[15:0]};
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_sel_o = 4'b1100;
						end
						2'b10:begin
							mem_sel_o = 4'b0011;
						end
						default:mem_sel_o = 4'b0000;
					endcase
				end
				`ALU_SW:begin
					mem_addr_o = mem_addr_i;
					mem_we = 1;
					mem_ce_o = 1;
					mem_data_o = reg2_i;
					mem_sel_o = 4'b1111;
				end
				`ALU_SWL:begin
					mem_addr_o = mem_addr_i;
					mem_we = 1;
					mem_ce_o = 1;
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_data_o = reg2_i;
							mem_sel_o = 4'b1111;
						end
						2'b01:begin
							mem_data_o = {8'b0, reg2_i[31:8]};
							mem_sel_o = 4'b0111;
						end
						2'b10:begin
							mem_data_o = {16'b0, reg2_i[31:16]};
							mem_sel_o = 4'b0011;
						end
						2'b11:begin
							mem_data_o = {24'b0, reg2_i[31:24]};
							mem_sel_o = 4'b0001;
						end
						default:mem_sel_o = 4'b0000;
					endcase
				end
				`ALU_SWR:begin
					mem_addr_o = mem_addr_i;
					mem_we = 1;
					mem_ce_o = 1;
					case(mem_addr_i[1:0])
						2'b00: begin
							mem_data_o = {reg2_i[7:0], 24'b0};
							mem_sel_o = 4'b1000;
						end
						2'b01:begin
							mem_data_o = {reg2_i[15:0], 16'b0};
							mem_sel_o = 4'b1100;
						end
						2'b10:begin
							mem_data_o = {reg2_i[23:0], 8'b0};
							mem_sel_o = 4'b1110;
						end
						2'b11:begin
							mem_data_o = reg2_i;
							mem_sel_o = 4'b1111;
						end
						default:mem_sel_o = 4'b0000;
					endcase
				end
				`ALU_LL:begin
					mem_addr_o = mem_addr_i;
					mem_we = 0;
					mem_ce_o = 1;
					wdata_o = mem_data_i;
					mem_sel_o = 4'b1111;
					LLbit_we_o = 1;
					LLbit_value_o = 1;
				end
				`ALU_SC:begin
					if(LLbit_i==1) begin //原子操作
						mem_addr_o = mem_addr_i;
						mem_we = 1;
						mem_ce_o = 1;
						mem_data_o = reg2_i;
						mem_sel_o = 4'b1111;
						wdata_o = 1;
						LLbit_we_o = 1;
						LLbit_value_o = 0;	
					end else wdata_o = 0;

				end
			endcase
        end
    end


endmodule // mem