    module mem_wb(
    input clk,
    input rst,
    input [5:0] stall,
    //访存阶段的结果
    input [4:0] mem_wd,
    input [31:0] mem_wdata,
    input       mem_wreg,
    input       mem_whilo,
    input [31:0] mem_hi,mem_lo,

    //送到回写阶段的信息
    output reg[4:0] wb_wd,
    output reg[31:0] wb_wdata,
    output reg     wb_wreg,
    output reg     wb_whilo,
    output reg [31:0] wb_hi,wb_lo
);

always @(posedge clk) begin
    if(rst) {wb_wd,wb_wdata,wb_wreg,wb_whilo, wb_hi, wb_lo} <= 0;
    else if(!stall[4]) begin
        wb_wd <= mem_wd;
        wb_wdata <= mem_wdata;
        wb_wreg <= mem_wreg;
        wb_whilo <= mem_whilo;
        wb_hi <= mem_hi;
        wb_lo <= mem_lo;
    end else if(stall[4] && !stall[5])
        {wb_wd,wb_wdata,wb_wreg,wb_whilo,wb_hi,wb_lo} <= 0;
end
endmodule // mem_wb