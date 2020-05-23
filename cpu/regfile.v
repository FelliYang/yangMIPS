`include "defines.v"
module regfile(
    input   wire clk,
    input   wire rst,
    //写端口
    input   wire  we,
    input   wire[`RegAddrBus]    waddr,
    input   wire[`RegBus]    wdata,
    
    //读端口1
    input   wire re1,
    input   wire[`RegAddrBus] raddr1,
    output   reg[`RegBus]   rdata1,
    
    //读端口2
    input   wire re2,
    input   wire [`RegAddrBus] raddr2,
    output   reg [`RegBus]      rdata2

);

reg[`RegBus]        regs[0:`RegNum - 1];

//写
always @(posedge clk) begin
    if(rst == `RstDisable) begin
        if(we == `WriteEnable && waddr != 0) begin
            regs[waddr] <= wdata;
        end     
    end
end

//读1
always @(*) begin
    if(rst == `RstEnable || re1 == `ReadDisable) rdata1 <= `ZeroWord;
    else if(raddr1 == waddr && waddr != 0 && we == `WriteEnable) rdata1 <= wdata;
    else rdata1 <= (raddr1==0) ? 0 : regs[raddr1];
end
//读2s
always @(*) begin
    if(rst == `RstEnable || re2 == `ReadDisable) rdata1 <= `ZeroWord;
    else if(raddr2 == waddr && waddr != 0 && we == `WriteEnable) rdata2 <= wdata;
    else rdata2 <= (raddr2==0) ? 0 : regs[raddr2];
end



endmodule // regfile