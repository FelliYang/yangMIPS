`include "defines.v"
module if_id(
    input                clk,
    input                rst,
    input [5:0]         stall,
	input				flush, //异常清空清号
    //取指阶段的结果
    input  [31:0]       if_pc,
    input [31:0]        if_inst,

    //送到译码阶段的信息
    output reg[31:0]    id_pc,
    output reg[31:0]    id_inst
);

always @(posedge clk) begin
    if(rst || flush)
        {id_pc, id_inst} <= 0;
    else if(!stall[1])begin
        {id_pc, id_inst} <= {if_pc, if_inst};
    end else if(stall[1] && !stall[2])
        {id_pc, id_inst} <= 0;
end

endmodule // if_id