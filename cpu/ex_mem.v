module ex_mem(
    input clk,
    input rst,
    input [5:0] stall,
    //执行级的结果
    input [4:0]         ex_wd,
    input [31:0]        ex_wdata,
    input               ex_wreg,
    input               ex_whilo,
    input [31:0]        ex_hi,ex_lo,

    //指令多周期执行时，来自EX模块的临时信号
    input [63:0] hilo_i,
    input [1:0] cnt_i, 
    output reg [63:0] hilo_o,
    output reg [1:0] cnt_o,

    //送到访存阶段的信息
    output reg[4:0]     mem_wd,
    output reg[31:0]    mem_wdata,
    output reg          mem_wreg,
    output reg          mem_whilo,
    output reg [31:0]   mem_hi,mem_lo
);

always @(posedge clk) begin
    if(rst) {mem_wd, mem_wdata,mem_wreg, mem_whilo, mem_hi, mem_lo, hilo_o, cnt_o} <= 0;
    else if(!stall[3])begin
        mem_wd <= ex_wd;
        mem_wdata <= ex_wdata;
        mem_wreg <= ex_wreg;
        mem_whilo <= ex_whilo;
        mem_hi <= ex_hi;
        mem_lo <= ex_lo;
        hilo_o <= 0;
        cnt_o <= 0;
    end else if(stall[3] && !stall[4]) begin
        {mem_wd,mem_wdata, mem_wreg, mem_whilo, mem_hi, mem_lo, hilo_o, cnt_o} <= 0;
        hilo_o <= hilo_i;
        cnt_o <= cnt_i;
    end else begin
        {hilo_o, cnt_o} <= 0;
    end
        
end


endmodule // ex_m