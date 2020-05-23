module ex_mem(
    input clk,
    input rst,

    //执行级的结果
    input [4:0] ex_wd,
    input [31:0] ex_wdata,
    input       ex_wreg,

    //送到访存阶段的信息
    output reg[4:0] mem_wd,
    output reg[31:0] mem_wdata,
    output reg    mem_wreg
);

always @(posedge clk) begin
    if(rst) {mem_wd, mem_wdata,mem_wreg} <= 0;
    else begin
        mem_wd <= ex_wd;
        mem_wdata <= ex_wdata;
        mem_wreg <= ex_wreg;
    end
end


endmodule // ex_m