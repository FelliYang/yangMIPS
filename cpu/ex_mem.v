module ex_mem(
    input clk,
    input rst,
    input [5:0] stall,
	input flush, //异常发生清空寄存器

    /******执行级的结果******/
    input [4:0]         ex_wd,
    input [31:0]        ex_wdata,
    input               ex_wreg,
    input               ex_whilo,
    input [31:0]        ex_hi,ex_lo,
	input [7:0] 		ex_aluop,
	input [31:0]		ex_mem_addr, 
	input [31:0] 		ex_reg2,
	input [5:0]			ex_cp0_waddr,
	input [31:0]		ex_cp0_wdata,
	input 				ex_cp0_we,
	//异常相关
	input [31:0]		ex_excepttype, ex_current_inst_addr,
	input				ex_is_in_delayslot,

    //指令多周期执行时，来自EX模块的临时信号
    input [63:0] hilo_i,
    input [1:0] cnt_i, 
    output reg [63:0] hilo_o,
    output reg [1:0] cnt_o,

    /******送到访存阶段的信息*******/
    output reg [4:0]    mem_wd,
    output reg [31:0]   mem_wdata,
    output reg          mem_wreg,
    output reg          mem_whilo,
    output reg [31:0]   mem_hi,mem_lo,
	output reg [7:0]	mem_aluop,
	output reg [31:0]	mem_mem_addr, mem_reg2,
	output reg [5:0] 	mem_cp0_waddr,
	output reg [31:0]	mem_cp0_wdata,
	output reg 			mem_cp0_we,
	output reg [31:0]	mem_excepttype, mem_current_inst_addr,
	output reg			mem_is_in_delayslot
);

always @(posedge clk) begin
    if(rst || flush) {mem_aluop, mem_mem_addr, mem_reg2, 
		mem_wd, mem_wdata,mem_wreg, mem_whilo, mem_hi, mem_lo, 
		hilo_o, cnt_o,
		mem_cp0_waddr, mem_cp0_wdata, mem_cp0_we,
		mem_excepttype, mem_current_inst_addr, mem_is_in_delayslot} <= 0;
    else if(!stall[3])begin
        mem_wd <= ex_wd;
        mem_wdata <= ex_wdata;
        mem_wreg <= ex_wreg;
        mem_whilo <= ex_whilo;
        mem_hi <= ex_hi;
        mem_lo <= ex_lo;
		mem_aluop <= ex_aluop;
		mem_mem_addr <= ex_mem_addr;
		mem_reg2 <= ex_reg2;
        hilo_o <= 0;
        cnt_o <= 0;
		mem_cp0_waddr <= ex_cp0_waddr;
		mem_cp0_wdata <= ex_cp0_wdata;
		mem_cp0_we <= ex_cp0_we;
		mem_excepttype <= ex_excepttype;
		mem_current_inst_addr <= ex_current_inst_addr;
		mem_is_in_delayslot <= ex_is_in_delayslot;
    end else if(stall[3] && !stall[4]) begin
        {mem_aluop, mem_mem_addr, mem_reg2, 
		mem_wd,mem_wdata, mem_wreg, mem_whilo, mem_hi, mem_lo,
		mem_cp0_waddr, mem_cp0_wdata, mem_cp0_we,
		mem_excepttype, mem_current_inst_addr, mem_is_in_delayslot} <= 0;
        hilo_o <= hilo_i;
        cnt_o <= cnt_i;
    end else begin
        {hilo_o, cnt_o} <= 0;
    end
        
end


endmodule // ex_m