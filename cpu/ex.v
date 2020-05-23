`include "defines.v"
module ex(
    input rst,
    
    //来自译码级的信息
    input [2:0]alusel_i,
    input [7:0]aluop_i,
    input [31:0] reg1_i,
    input [31:0] reg2_i,
    input [4:0] wd_i,
    input       wreg_i,

    //执行级的结果
    output reg [4:0] wd_o,
    output reg [31:0] wdata_o,
    output reg     wreg_o

);
//逻辑运算
reg [31:0] logicout;

//组合逻辑->根据子类型运算
always @(*) begin
    if(rst) begin
        logicout = 0;
    end else begin
        logicout = 0;
        case(aluop_i)
            `EXE_OR_OP: logicout<= reg1_i | reg2_i;
        endcase
    end
end
//组合逻辑->根据类型选择
always @(*) begin
    wd_o = wd_i;
    wreg_o = wreg_i;
    case(alusel_i)
        `EXE_RES_LOGIC: wdata_o = logicout;
    default: wdata_o = 0;
    endcase
end

endmodule // ex