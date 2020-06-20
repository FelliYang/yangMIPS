`include "defines.v"
module yangmips(
    input clk,
    input rst,	
	//中断信号
	input [5:0] int_i,
	output timer_int_o,
	//总线接口
	output [31:0] iwishbone_addr_o,iwishbone_data_o,
	output iwishbone_we_o,
	output [3:0] iwishbone_sel_o,
	output iwishbone_stb_o,
	output iwishbone_cyc_o,
	input [31:0] iwishbone_data_i,
	input iwishbone_ack_i,
	output [31:0] dwishbone_addr_o,dwishbone_data_o,
	output dwishbone_we_o,
	output [3:0] dwishbone_sel_o,
	output dwishbone_stb_o,
	output dwishbone_cyc_o,
	input [31:0] dwishbone_data_i,
	input dwishbone_ack_i
);

//连接IF阶段输出和IF/ID模块|wishbone模块 输入的变量
wire [31:0] pc;
wire 		ce_inst; //指令存储器选择信号
wire 		stallreq_from_if;
wire [31:0] if_inst;

//连接IF/ID模块和译码阶段的变量
wire [31:0] id_pc_i; //译码级pc输入
wire [31:0] id_inst_i; //译码级inst输入

/*********连接译码阶段输出和其他模块输入*****/
//连接译码阶段的输出和ID/EX模块的输入
wire [31:0] reg1_data, reg2_data;
wire [4:0]  reg1_addr, reg2_addr;
wire        reg1_read, reg2_read;
wire [31:0] id_inst_o;
wire [7:0]  id_aluop_o;
wire [2:0]  id_alusel_o;
wire [31:0] id_reg1_o;
wire [31:0] id_reg2_o;
wire [4:0]  id_wd_o;
wire        id_wreg_o;
wire [31:0] id_link_address_o; //转移指令返回地址
wire 		id_is_in_delayslot_o;
wire 		next_inst_in_delayslot_o;
//异常控制相关
wire [31:0] id_excepttype_o, id_current_inst_addr_o;
//连接ID模块和PC_reg模块，用于转移指令的信号
wire [31:0] id_branch_target_address_o;
wire		id_branch_flag_o;

//连接ID/EX模块的输出与执行阶段EX模块的输入
wire [31:0] ex_reg1_i, ex_reg2_i;
wire [4:0]  ex_wd_i;
wire        ex_wreg_i;
wire [2:0]  ex_alusel_i;
wire [7:0]  ex_aluop_i;
wire [31:0] ex_link_address_i;
wire 		ex_is_in_delayslot_i;
wire [31:0] ex_inst_i;
wire [31:0] ex_excepttype_i, ex_current_inst_addr_i;
//连接ID/EX模块和ID模块输入，用于转移的信号
wire 		is_in_delayslot;
//连接HI/LO模块的输出与EX模块的输入
wire [31:0] hi, lo;
//连接COP0模块的输出与EX模块的输入
wire [31:0] cp0_data_o;
wire [4:0] cp0_raddr_i;
//MEM阶段的COP0前递与EX模块的输入
wire [4:0] mem_cp0_waddr_o;
wire [31:0] mem_cp0_wdata_o;
wire 		mem_cp0_we_o;

//连接执行阶段EX模块的输出与EX/MEM模块的输入
wire [31:0] ex_wdata_o;
wire [4:0]  ex_wd_o;
wire        ex_wreg_o;
wire        ex_whilo_o;
wire [31:0] ex_hi_o, ex_lo_o;
wire [7:0]	ex_aluop_o;
wire [31:0] ex_mem_addr_o, ex_reg2_o;
wire [4:0] ex_cp0_waddr_o;
wire [31:0] ex_cp0_wdata_o;
wire 		ex_cp0_we_o;
wire [31:0] ex_excepttype_o, ex_current_inst_addr_o;
wire 		ex_is_in_delayslot_o;
//EX模块与EM/MEM模块之间的临时信号
wire [63:0] ex_hilo_temp_o, ex_hilo_temp_i;
wire [1:0] ex_cnt_o, ex_cnt_i;
//EX模块与除法DIV之间的信号
wire ex_signed_div_o, ex_div_start_o;
wire [31:0]ex_div_opdata1_o, ex_div_opdata2_o;
wire [63:0] ex_div_result_i;
wire        ex_div_ready_i;

//连接EX/MEM模块的输出与访存阶段MEM模块的输入
wire [31:0] mem_wdata_i;
wire [4:0]  mem_wd_i;
wire        mem_wreg_i;
wire        mem_whilo_i;
wire [31:0]  mem_hi_i,mem_lo_i;
wire [7:0]	mem_aluop_o;
wire [31:0] mem_mem_addr_o, mem_reg2_o;
wire [4:0] mem_cp0_waddr_i;
wire [31:0] mem_cp0_wdata_i;
wire 		mem_cp0_we_i;
wire [31:0] mem_excepttype_i, mem_current_inst_addr_i;
wire 		mem_is_in_delayslot_i;
//连接LLbit_reg输出与MEM模块的输入
wire 		mem_LLbit_i;
//连接COP0的输出与MEM的输入
wire [31:0] cp0_status, cp0_cause, cp0_epc;

//连接访存阶段MEM模块的输出与MEM/WB模块的输入
wire [31:0] mem_wdata_o;
wire [4:0]  mem_wd_o;
wire        mem_wreg_o;
wire        mem_whilo_o;
wire [31:0] mem_hi_o,mem_lo_o;
wire 		mem_LLbit_we_o,mem_LLbit_value_o;
//MEM的其他输出信号
wire [31:0] mem_current_inst_address_o, mem_cp0_epc_o, mem_excepttype_o;
wire 		mem_is_in_delayslot_o;
wire 		stallreq_from_mem;
wire [31:0] ram_addr, ram_data_o, ram_data_i;
wire [3:0] 	ram_sel;
wire 		ram_ce, ram_we;

//连接MEM/WB模块的输出与回写阶段的输入
wire [31:0] wb_wdata_i;
wire [4:0]  wb_wd_i;
wire        wb_wreg_i;
wire        wb_whilo_i;
wire [31:0] wb_hi_i, wb_lo_i;
wire 		wb_LLbit_we_i, wb_LLbit_value_i;
wire [4:0] 	wb_cp0_waddr_i;
wire [31:0] wb_cp0_wdata_i;
wire 		wb_cp0_we_i;

/*****CTRL信号*********/
//流水线暂停控制信号
wire stallreq_from_id, stallreq_from_ex;
wire [5:0] stall;
//异常相关信号
wire flush; 
wire [31:0] new_pc;

//pc_reg实例化
pc_reg pc_reg0(
    .clk(clk), .rst(rst), .pc(pc), .ce(ce_inst) , .stall(stall),
	.branch_target_address_i(id_branch_target_address_o),
	.branch_flag_i(id_branch_flag_o),
	.flush(flush), .new_pc(new_pc)
);

//TODO 实例化指令总线接口
wishbone_bus_if wishbone0(
	.clk(clk), .rst(rst), .flush_i(flush), .stall_i(stall),
	.cpu_ce_i(ce_inst), .cpu_data_i(0), .cpu_addr_i(pc), .cpu_we_i(0), .cpu_sel_i(4'b1111), 
	.cpu_data_o(if_inst), .stallreq(stallreq_from_if),

	.wishbone_data_i(iwishbone_data_i), .wishbone_ack_i(iwishbone_ack_i),
	.wishbone_addr_o(iwishbone_addr_o), .wishbone_data_o(iwishbone_data_o),
	.wishbone_we_o(iwishbone_we_o), .wishbone_sel_o(iwishbone_sel_o),
	.wishbone_stb_o(iwishbone_stb_o), .wishbone_cyc_o(iwishbone_cyc_o)
);
//IF/ID模块实例化
if_id if_id0(
    .clk(clk), .rst(rst), .stall(stall),
    .if_pc(pc), .if_inst(if_inst),
    .id_pc(id_pc_i), .id_inst(id_inst_i),
	.flush(flush)
    
);

//译码阶段ID模块实例化
id id0(
    .rst(rst),  
    .pc_i(id_pc_i), .inst_i(id_inst_i),
    
    //送到regfile的信息
    .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
    .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
    
    //来自regfile的输入
    .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),

    //数据前推->处于执行阶段的指令的运算结果
    .ex_wdata_i(ex_wdata_o), .ex_wd_i(ex_wd_o), .ex_wreg_i(ex_wreg_o),
    
    //数据前推->处于访存阶段的指令的运算结果
    .mem_wdata_i(mem_wdata_o), .mem_wd_i(mem_wd_o), .mem_wreg_i(mem_wreg_o),
    
    //送到ID/EX模块的信息
	.inst_o(id_inst_o),
    .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
    .wd_o(id_wd_o), .wreg_o(id_wreg_o), .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
	//异常相关
	.excepttype_o(id_excepttype_o), .current_inst_addr_o(id_current_inst_addr_o),
    //流水线暂停请求
    .stallreq_from_id(stallreq_from_id),

	//转移指令相关信号
	.branch_target_address_o(id_branch_target_address_o),
	.branch_flag_o(id_branch_flag_o), 
	.next_inst_in_delayslot_o(next_inst_in_delayslot_o),
	.is_in_delayslot_o(id_is_in_delayslot_o),
	.link_addr_o(id_link_address_o),
	.is_in_delayslot_i(is_in_delayslot),
	
	//load数据相关
	.ex_aluop_i(ex_aluop_o)
    
);

//RegFile实例化
regfile regfile0(
    .clk(clk), .rst(rst),
    //写端口
    .wdata(wb_wdata_i), .waddr(wb_wd_i), .we(wb_wreg_i),
    //读端口1
    .rdata1(reg1_data), .raddr1(reg1_addr), .re1(reg1_read),
    .rdata2(reg2_data), .raddr2(reg2_addr), .re2(reg2_read)
);


//ID/EX模块实例化
id_ex id_ex0(
    .clk(clk), .rst(rst), .stall(stall),

    //从译码阶段ID模块传过来的信息
	.id_inst(id_inst_o),
    .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
    .id_wd(id_wd_o), .id_wreg(id_wreg_o), 
    .id_alusel(id_alusel_o), .id_aluop(id_aluop_o),
	.id_is_in_delayslot(id_is_in_delayslot_o),
	.id_link_address(id_link_address_o),
	.next_inst_in_delayslot_i(next_inst_in_delayslot_o),
	//异常相关
	.flush(flush),
	.id_excepttype(id_excepttype_o), .id_current_inst_addr(id_current_inst_addr_o),

    //传递到执行阶段EX模块的信息
	.ex_inst(ex_inst_i),
    .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
    .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
    .ex_alusel(ex_alusel_i), .ex_aluop(ex_aluop_i),
	.ex_link_address(ex_link_address_i), 
	.ex_is_in_delayslot(ex_is_in_delayslot_i),
	.ex_excepttype(ex_excepttype_i), .ex_current_inst_addr(ex_current_inst_addr_i),
	//用于分支延迟槽的临时信号
	.is_in_delayslot_o(is_in_delayslot)
);

//EX模块实例化
ex ex0(
    .rst(rst),

    //从ID/EX模块传递过来的信息
	.inst_i(ex_inst_i),
    .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
    .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
    .alusel_i(ex_alusel_i), .aluop_i(ex_aluop_i),
	.link_address_i(ex_link_address_i),
	.is_in_delayslot_i(ex_is_in_delayslot_i),
	.excepttype_i(ex_excepttype_i), .current_inst_addr_i(ex_current_inst_addr_i),
    //来自HI/LO模块的信息
    .hi_i(hi), .lo_i(lo),
	//来自COP0的信息
	.cp0_data_i(cp0_data_o),
	.cp0_raddr_o(cp0_raddr_i),

	/***********数据前推*************/
    //HI/LO数据前推，来自访存阶段MEM模块的信息
    .mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
	//COP0数据前推
	.mem_cp0_waddr_i(mem_cp0_waddr_o), .mem_cp0_wdata_i(mem_cp0_wdata_o), .mem_cp0_we_i(mem_cp0_we_o),

    /********输出到EX/MEM模块的信息********/
    //通用寄存器
    .wdata_o(ex_wdata_o), .wd_o(ex_wd_o), .wreg_o(ex_wreg_o),
    //HI/LO寄存器
    .whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
	//Cop0寄存器
	.cp0_waddr_o(ex_cp0_waddr_o), .cp0_wdata_o(ex_cp0_wdata_o), .cp0_we_o(ex_cp0_we_o),
    //输入到EX/MEM的其他信号
	.aluop_o(ex_aluop_o), .mem_addr_o(ex_mem_addr_o),
	.reg2_o(ex_reg2_o),
	.excepttype_o(ex_excepttype_o), .current_inst_addr_o(ex_current_inst_addr_o),
	.is_in_delayslot_o(ex_is_in_delayslot_o),
    //连接EX/MEM模块的临时信号
    .hilo_temp_i(ex_hilo_temp_i), .cnt_i(ex_cnt_i),
    .hilo_temp_o(ex_hilo_temp_o), .cnt_o(ex_cnt_o),

    //连接EX和除法模块DIV
    .signed_div_o(ex_signed_div_o), .div_start_o(ex_div_start_o),
    .div_opdata1_o(ex_div_opdata1_o), .div_opdata2_o(ex_div_opdata2_o),
    .div_result_i(ex_div_result_i), .div_ready_i(ex_div_ready_i),

    //流水线暂停请求
    .stallreq_from_ex(stallreq_from_ex)
);

//实例化除法DIV模块
div div0(
    .clk(clk), .rst(rst),

    .signed_div_i(ex_signed_div_o), 
    .opdata1_i(ex_div_opdata1_o), .opdata2_i(ex_div_opdata2_o),
    .start_i(ex_div_start_o), .annul_i(1'b0),
    .result_o(ex_div_result_i), .ready_o(ex_div_ready_i)
);

//EX/MEM模块实例化
ex_mem ex_mem0(
    .clk(clk), .rst(rst), .stall(stall),
	.flush(flush),
    //从执行阶段EX模块传递过来的信息
    .ex_wdata(ex_wdata_o), .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o),
    .ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),
	.ex_aluop(ex_aluop_o), .ex_mem_addr(ex_mem_addr_o), 
	.ex_reg2(ex_reg2_o),
	.ex_cp0_waddr(ex_cp0_waddr_o), .ex_cp0_wdata(ex_cp0_wdata_o), .ex_cp0_we(ex_cp0_we_o),
	.ex_excepttype(ex_excepttype_o), .ex_current_inst_addr(ex_current_inst_addr_o),
	.ex_is_in_delayslot(ex_is_in_delayslot_o),
    //连接EX模块的临时信号
    .hilo_i(ex_hilo_temp_o), .cnt_i(ex_cnt_o),
    .hilo_o(ex_hilo_temp_i), .cnt_o(ex_cnt_i),

    //输出到MEM级的信息
    .mem_wdata(mem_wdata_i), .mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i),
    .mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i),
	.mem_aluop(mem_aluop_o), .mem_mem_addr(mem_mem_addr_o), .mem_reg2(mem_reg2_o),
	.mem_cp0_waddr(mem_cp0_waddr_i), .mem_cp0_wdata(mem_cp0_wdata_i), .mem_cp0_we(mem_cp0_we_i),
	.mem_excepttype(mem_excepttype_i), .mem_current_inst_addr(mem_current_inst_addr_i),
	.mem_is_in_delayslot(mem_is_in_delayslot_i)
);

//MEM模块实例化
mem mem0(
    .rst(rst),
    //来自执行阶段的信息
    .wdata_i(mem_wdata_i), .wd_i(mem_wd_i), .wreg_i(mem_wreg_i),
    .whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),
	.aluop_i(mem_aluop_o), .mem_addr_i(mem_mem_addr_o), .reg2_i(mem_reg2_o),
	.cp0_waddr_i(mem_cp0_waddr_i), .cp0_wdata_i(mem_cp0_wdata_i), .cp0_we_i(mem_cp0_we_i),
	.excepttype_i(mem_excepttype_i), .current_inst_address_i(mem_current_inst_addr_i),
	.is_in_delayslot_i(mem_is_in_delayslot_i),
	
	//来自CP0的信息
	.cp0_status_i(cp0_status), .cp0_cause_i(cp0_cause), .cp0_epc_i(cp0_epc),
    
	//输出到MEM/WB模块的信息
    .wdata_o(mem_wdata_o), .wd_o(mem_wd_o), .wreg_o(mem_wreg_o),
    .whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o),
	.LLbit_we_o(mem_LLbit_we_o), .LLbit_value_o(mem_LLbit_value_o),
	.cp0_waddr_o(mem_cp0_waddr_o), .cp0_wdata_o(mem_cp0_wdata_o), .cp0_we_o(mem_cp0_we_o),

	//输出到CP0的信号
	.excepttype_o(mem_excepttype_o), .current_inst_address_o(mem_current_inst_address_o),
	.is_in_delayslot_o(mem_is_in_delayslot_o),

	//输出到CTRL的信号
	.cp0_epc_o(mem_cp0_epc_o),
	//输出到RAM的信号
	.mem_addr_o(ram_addr), .mem_data_o(ram_data_o), .mem_we_o(ram_we),
	.mem_sel_o(ram_sel), .mem_ce_o(ram_ce),

	//从RAM输入的信号
	.mem_data_i(ram_data_i),

	//从LLbit_reg输入的信号
	.LLbit_i(mem_LLbit_i)
);

//TODO 实例化数据总线接口
wishbone_bus_if wishbone1(
	.clk(clk), .rst(rst), .flush_i(flush), .stall_i(stall),
	.cpu_ce_i(ram_ce), .cpu_data_i(ram_data_o), .cpu_addr_i(ram_addr), .cpu_we_i(ram_we), .cpu_sel_i(ram_sel), 
	.cpu_data_o(ram_data_i), .stallreq(stallreq_from_mem),

	.wishbone_data_i(dwishbone_data_i), .wishbone_ack_i(dwishbone_ack_i),
	.wishbone_addr_o(dwishbone_addr_o), .wishbone_data_o(dwishbone_data_o),
	.wishbone_we_o(dwishbone_we_o), .wishbone_sel_o(dwishbone_sel_o),
	.wishbone_stb_o(dwishbone_stb_o), .wishbone_cyc_o(dwishbone_cyc_o)
);

//MEM/WB模块实例化
mem_wb mem_wb0(
    .clk(clk), .rst(rst), .stall(stall), .flush(flush),

    //来自访存阶段mem模块的信息
    .mem_wdata(mem_wdata_o), .mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),
    .mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),
	.mem_LLbit_we(mem_LLbit_we_o), .mem_LLbit_value(mem_LLbit_value_o),
	.mem_cp0_waddr(mem_cp0_waddr_o), .mem_cp0_wdata(mem_cp0_wdata_o), .mem_cp0_we(mem_cp0_we_o),

    //输出到写回阶段的信息
    .wb_wdata(wb_wdata_i), .wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i),
    .wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i),
	.wb_LLbit_we(wb_LLbit_we_i), .wb_LLbit_value(wb_LLbit_value_i),
	.wb_cp0_waddr(wb_cp0_waddr_i), .wb_cp0_wdata(wb_cp0_wdata_i), .wb_cp0_we(wb_cp0_we_i)

);

hilo_reg hilo_reg0(
    .clk(clk), .rst(rst),

    //来自写回阶段的信息
    .we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i),

    //送到执行阶段的信息
    .hi_o(hi), .lo_o(lo)
);

LLbit_reg LLbit_reg0(
	.clk(clk), .rst(rst),

    //来自写回阶段的信息
	.LLbit_i(wb_LLbit_value_i), .we(wb_LLbit_we_i),
    //送到执行阶段的信息
    .LLbit_o(mem_LLbit_i),
	//异常触发信号
	.flush(flush)

);

cp0_reg cp0_reg0(
	.clk(clk), .rst(rst),
	.raddr_i(cp0_raddr_i), .data_o(cp0_data_o),
	.waddr_i(wb_cp0_waddr_i), .wdata_i(wb_cp0_wdata_i), .we_i(wb_cp0_we_i),
	.int_i(int_i), .timer_int_o(timer_int_o),
	.status_o(cp0_status), .cause_o(cp0_cause), .epc_o(cp0_epc),
	.excepttype_i(mem_excepttype_o), .current_inst_addr_i(mem_current_inst_address_o),
	.is_in_delayslot_i(mem_is_in_delayslot_o)

);
//流水线控制暂停模块
ctrl ctrl0(
    .rst(rst),
    .stallreq_from_id(stallreq_from_id), .stallreq_from_ex(stallreq_from_ex),
	.stallreq_from_if(stallreq_from_if), .stallreq_from_mem(stallreq_from_mem),
    .stall(stall),
	.flush(flush), 
	.new_pc(new_pc),
	.excepttype_i(mem_excepttype_o),
	.cp0_epc_i(mem_cp0_epc_o)
);

endmodule // openmips