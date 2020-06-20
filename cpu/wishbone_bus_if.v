module wishbone_bus_if(
	input clk, rst,
	/***来自ctrl模块****/
	input [5:0] stall_i,
	input 	flush_i,
	/****CPU侧的接口*****/
	input 	cpu_ce_i, //CPU选通该芯片
	input 	[31:0] cpu_data_i, cpu_addr_i,
	input 	cpu_we_i,
	input [3:0] cpu_sel_i,
	output 	reg [31:0] cpu_data_o,
	/*******wishbone侧的接口********/
	input 	[31:0] wishbone_data_i,
	input			wishbone_ack_i,
	output	reg[31:0] wishbone_addr_o, wishbone_data_o,
	output reg wishbone_we_o,
	output reg [3:0] wishbone_sel_o,
	output reg wishbone_stb_o, wishbone_cyc_o,

	output reg stallreq
);

localparam WB_IDLE			=	2'b00;
localparam WB_BUSY			= 	2'b01;
localparam WB_WAIT_FOR_STALL=	2'b10;

reg[1:0] state; //状态机
reg [31:0] data_buf; //寄存通过wishbone总线访问到的数据

//状态机状态转换
always @(posedge clk) begin
	if(rst) begin
		state <= WB_IDLE;
		data_buf <= 0;
		{wishbone_addr_o,wishbone_data_o,wishbone_we_o,wishbone_sel_o,wishbone_stb_o,wishbone_cyc_o} <= 0;
	end else begin
		case(state)
			WB_IDLE: begin
				if(cpu_ce_i==1 && flush_i==0) begin
					wishbone_stb_o <= 1; wishbone_cyc_o <= 1;
					wishbone_addr_o <= cpu_addr_i;
					wishbone_data_o <= cpu_data_i;
					wishbone_we_o <= cpu_we_i;
					wishbone_sel_o <= cpu_sel_i;
					state <= WB_BUSY; //改变状态
					data_buf <= 0;
				end
			end
			WB_BUSY: begin
				if(wishbone_ack_i==1) begin
					{wishbone_addr_o,wishbone_data_o,wishbone_we_o,wishbone_sel_o,wishbone_stb_o,wishbone_cyc_o} <= 0;
					state <= WB_IDLE;
					if(cpu_we_i==0) data_buf <= wishbone_data_i;
					if(stall_i!=0) begin
						state <= WB_WAIT_FOR_STALL;
					end
				end else if(flush_i==1) begin
					{wishbone_addr_o,wishbone_data_o,wishbone_we_o,wishbone_sel_o,wishbone_stb_o,wishbone_cyc_o} <= 0;
					state <= WB_IDLE;
					data_buf <= 0;
				end
			end
			WB_WAIT_FOR_STALL: begin
				if(stall_i==0) begin
					state <= WB_IDLE;
				end
			end
		endcase
	end
end

/****组合逻辑->提供CPU数据*****/
always @(*) begin
	if(rst) begin
		stallreq = 0;
		cpu_data_o = 0;
	end else begin
		stallreq = 0;
		cpu_data_o = 0;
		case(state)
			WB_IDLE:begin
				if(cpu_ce_i==1 && flush_i==0) begin
					stallreq = 1;
				end
			end
			WB_BUSY:begin
				if(wishbone_ack_i==1) begin
					stallreq = 0;
					if(wishbone_we_o==0) begin
						cpu_data_o = wishbone_data_i;
					end
				end else begin
					stallreq = 1;
					cpu_data_o = 0;
				end
			end
			WB_WAIT_FOR_STALL:begin
				cpu_data_o = data_buf;
			end
		endcase
	end
end

endmodule // wishbone_bus_if