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
reg [31:0] arithres; //算数运算
reg [31:0] HI, LO; //保存寄存器的值


//标志位
wire        ov_sum; //加法溢出位
wire [31:0]  reg2_i_mux; //操作数2根据指令需要，转换成相反数的补码表示
wire [31:0]  result_sum; //加法结果
wire        reg1_lt_reg2;

//算数运算
//所有减法运算，需要对操作数2取反+1，得到相反数的补码表示
assign reg2_i_mux = ((aluop_i == `ALU_SUB) ||
                    (aluop_i == `ALU_SUBU) ||
                    (aluop_i == `ALU_SLT) ||
                    (aluop_i == `ALU_SLTI)) ?
                    (~reg2_i) +1 : reg2_i;
assign result_sum = reg1_i + reg2_i_mux;
//指令add addi sub需要判断溢出，此时 执行的是reg1 和 reg2_i_mux的加法
assign ov_sum = ((!reg1_i[31]) && (!reg2_i_mux[31]) && result_sum[31]) ||
                    ((reg1_i[31]) && (reg2_i_mux[31]) && !result_sum[31]);
//SLT和SLTU指令
assign reg1_lt_reg2 = ((aluop_i == `ALU_SLT)) ?
         (  (reg1_i[31]&&!reg2_i[31]) || //三种reg1操作数小于reg2操作数的情况
             (!reg1_i[31]&&!reg2_i[31] && result_sum[31]) || 
             (reg1_i[31] && reg2_i[31] && result_sum[31])   ):
             (reg1_i < reg2_i); //无符号数直接使用比较运算符

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
            `ALU_OR, `ALU_ORI, `ALU_LUI: logicout = reg1_i | reg2_i;
            `ALU_AND, `ALU_ANDI: logicout = reg1_i & reg2_i;
            `ALU_XOR, `ALU_XORI: logicout = reg1_i ^ reg2_i;
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
        moveres = 0;
        case(aluop_i)
        `ALU_MFHI: moveres = HI;
        `ALU_MFLO: moveres = LO;
        `ALU_MOVZ: moveres = reg1_i;
        `ALU_MOVN: moveres = reg1_i;
        endcase
    end
end

always@(*)begin
    if(rst) arithres = 0;
    else begin
        arithres = 0;
        case(aluop_i)
        `ALU_AND, `ALU_ADDU, `ALU_ADDI, `ALU_ADDIU,`ALU_SUB, `ALU_SUBU: arithres = result_sum;
        `ALU_SLT, `ALU_SLTU, `ALU_SLTI, `ALU_SLTIU: arithres = reg1_lt_reg2;
        endcase
    end
end

//组合逻辑->根据类型选择
always @(*) begin
    wd_o = wd_i;
    if(((aluop_i==`ALU_ADD) || (aluop_i==`ALU_ADDI) || (aluop_i==`ALU_SUB)) && ov_sum==1)
        wreg_o = 0; //溢出不改变寄存器
    else wreg_o = wreg_i;

    case(alusel_i)
        `ALU_RES_LOGIC: wdata_o = logicout;
        `ALU_RES_SHIFT: wdata_o = shiftres;
        `ALU_RES_MOVE: wdata_o = moveres;
        `ALU_RES_ARITH: wdata_o = arithres;
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