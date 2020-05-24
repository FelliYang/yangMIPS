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

    //HILO模块给出的寄存器值
    input [31:0] hi_i,lo_i,
    
    //访存阶段HI.LO数据前推
    input mem_whilo_i,
    input [31:0] mem_hi_i,mem_lo_i,

    //执行级的结果->通用寄存器
    output reg [4:0] wd_o,
    output reg [31:0] wdata_o,
    output reg     wreg_o,
    //->HILO寄存器
    output reg  whilo_o,
    output reg [31:0] hi_o,lo_o

);
reg [31:0] logicout; //逻辑运算
reg [31:0] shiftres; //移位运算 
reg [31:0] moveres; //移动运算
reg [31:0] HI, LO; //保存寄存器的值

//HI/LO数据相关问题
always@(*)begin
    if(rst) {HI,LO} = 0;
    else begin
        HI = (mem_whilo_i)?mem_hi_i:hi_i;
        LO = (mem_whilo_i)?mem_lo_i:lo_i;
    end
end

//组合逻辑->逻辑运算
always @(*) begin
    if(rst) begin
        logicout = 0;
    end else begin
        logicout = 0;
        case(aluop_i)
            `ALU_OR: logicout = reg1_i | reg2_i;
            `ALU_AND: logicout = reg1_i & reg2_i;
            `ALU_XOR: logicout = reg1_i ^ reg2_i;
            `ALU_NOR: logicout = ~(reg1_i | reg2_i);
        endcase
    end
end
//组合逻辑->移位运算
always @(*) begin
    if(rst) begin
        shiftres = 0;
    end else begin
        shiftres = 0;
        case(aluop_i)
            `ALU_SLL: shiftres = reg2_i << reg1_i[4:0];
            `ALU_SRL: shiftres = reg2_i >> reg1_i[4:0];
            `ALU_SRA: shiftres =  ({32{reg2_i[31]}} << (32-reg1_i[4:0]))
                            | (reg2_i >> reg1_i[4:0]);
        endcase
    end
end

//组合逻辑—>移动运算
always@(*)begin
    if(rst)moveres = 0;
    else begin
        case(aluop_i)
        `ALU_MFHI: moveres = HI;
        `ALU_MFLO: moveres = LO;
        `ALU_MOVZ: moveres = reg1_i;
        `ALU_MOVN: moveres = reg1_i;
        endcase
    end
end

//组合逻辑->根据类型选择
always @(*) begin
    wd_o = wd_i;
    wreg_o = wreg_i;
    case(alusel_i)
        `ALU_RES_LOGIC: wdata_o = logicout;
        `ALU_RES_SHIFT: wdata_o = shiftres;
        `ALU_RES_MOVE: wdata_o = moveres;
    default: wdata_o = 0;
    endcase
end

//如果是MTHI、MTLO指令，需要给出whilo_o,hi_o,lo_i
always@(*)begin
    if(rst) {whilo_o,hi_o,lo_o} = 0;
    else begin
        {whilo_o,hi_o,lo_o} = 0;
        if(aluop_i==`ALU_MTHI) begin
            whilo_o = 1;
            hi_o = reg1_i;
            lo_o = LO;
        end
        if(aluop_i==`ALU_MTLO) begin
            whilo_o = 1;
            hi_o = HI;
            lo_o = reg1_i;
        end
    end
end

endmodule // ex