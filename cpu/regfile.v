`include "defines.v"
module regfile(
    input   wire clk,
    input   wire rst,
    //写端口
    input   wire  we,
    input   wire[4:0]    waddr,
    input   wire[31:0]    wdata,
    
    //读端口1
    input   wire re1,
    input   wire[4:0] 	raddr1,
    output   reg[31:0]   rdata1,
    
    //读端口2
    input   wire re2,
    input   wire [4:0]		 raddr2,
    output   reg [31:0]      rdata2

);

reg[31:0]        regs[0:31];

//写
always @(posedge clk) begin
    if(!rst) begin
        if(we && waddr != 0) begin
            regs[waddr] <= wdata;
        end     
    end
end

//读1
always @(*) begin
    if(rst || re1 == 0) rdata1 = 0;
    else if(raddr1 == waddr && waddr != 0 && we ) rdata1 = wdata;
    else rdata1 = (raddr1==0) ? 0 : regs[raddr1];
end
//读2s
always @(*) begin
    if(rst || re2 == 0) rdata2 = 0;
    else if(raddr2 == waddr && waddr != 0 && we ) rdata2 = wdata;
    else rdata2 = (raddr2==0) ? 0 : regs[raddr2];
end



endmodule // regfile