`include "defines.v"
module id(
    input wire rst,
    
    //来自取指阶段的信息
    input wire[`InstAddrBus]    pc_i,
    input wire[`InstBus]        inst_i,
    
    //寄存器堆读取回路
    output reg [`RegAddrBus]   reg1_addr_o,
    output reg [`RegAddrBus]   reg2_addr_o,
    output reg                 reg1_read_o, //读使能 通过该信号判断源操作数来自imm还是寄存器堆
    output reg                 reg2_read_o,
    input [`RegBus]             reg1_data_i,
    input [`RegBus]             reg2_data_i,
    
    //译码阶段的结果
    output reg[7:0]                aluop_o, //运算子类型
    output reg[2:0]               alusel_o, //运算类型
    output reg[4:0]                wd_o, //目的寄存器地址
    output reg                     wreg_o, //指令是否需要写入目的寄存器
    output reg[`RegBus]            reg1_o, //指令源操作数1
    output reg[`RegBus]            reg2_o //指令源操作数2

);

reg [31:0] imm; //立即数
reg [5:0] opcode;
reg [4:0] sa;
reg [5:0] func;

always @(*) begin
    if(rst == 1) begin
        {reg1_addr_o,reg2_addr_o,reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wd_o,wreg_o} = 0;
    end else begin
        {reg1_addr_o,reg2_addr_o,reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wd_o,wreg_o} = 0; //组合逻辑
        opcode = inst_i[31:26];
        reg1_addr_o = inst_i[25:21];
        reg2_addr_o = inst_i[20:16];
        wd_o = reg2_addr_o;
        case(opcode)
            `EXE_ORI:begin //ori 指令
                wreg_o <= 1;
                alusel_o <= `EXE_RES_LOGIC;
                aluop_o <= `EXE_OR_OP;
                reg1_read_o <= 1; //只需要读一个寄存器
                reg2_read_o <= 0;
                imm <= {16'h0, inst_i[15:0]}; //逻辑扩展
            end
        endcase
    end
end

//操作数1
always @(*) begin
    if(rst==1) reg1_o <= 0;
    else reg1_o <= (reg1_read_o)?reg1_data_i : imm;
end
//操作数2
always @(*) begin
    if(rst) reg2_o <= 0;
    else reg2_o <= (reg2_read_o)?reg2_data_i : imm;
end

endmodule // id