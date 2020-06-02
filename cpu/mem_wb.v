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
	input mem_LLbit_we, mem_LLbit_value,

    //送到回写阶段的信息
    output reg[4:0] wb_wd,
    output reg[31:0] wb_wdata,
    output reg     wb_wreg,
    output reg     wb_whilo,
    output reg [31:0] wb_hi,wb_lo,
	output reg wb_LLbit_we, wb_LLbit_value
);

always @(posedge clk) begin
    if(rst) {wb_wd,wb_wdata,wb_wreg,wb_whilo, wb_hi, wb_lo,
		wb_LLbit_we, wb_LLbit_value} <= 0;
    else if(!stall[4]) begin
        wb_wd <= mem_wd;
        wb_wdata <= mem_wdata;
        wb_wreg <= mem_wreg;
        wb_whilo <= mem_whilo;
        wb_hi <= mem_hi;
        wb_lo <= mem_lo;
		wb_LLbit_value <= mem_LLbit_value;
		wb_LLbit_we <= mem_LLbit_we;
    end else if(stall[4] && !stall[5])
        {wb_wd,wb_wdata,wb_wreg,wb_whilo,wb_hi,wb_lo,
		wb_LLbit_we, wb_LLbit_value} <= 0;
end
endmodule // mem_wb