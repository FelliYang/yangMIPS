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

    //数据前推->处于执行阶段的指令的运算结果
    input [31:0]                ex_wdata_i,
    input [4:0]                 ex_wd_i,
    input                       ex_wreg_i,
    
    //数据前推->处于访存阶段的指令的运算结果
    input [31:0]                mem_wdata_i,
    input [4:0]                 mem_wd_i,
    input                       mem_wreg_i,

    //译码阶段的结果
    output reg[7:0]                aluop_o, //运算子类型
    output reg[2:0]               alusel_o, //运算类型
    output reg[4:0]                wd_o, //目的寄存器地址
    output reg                     wreg_o, //指令是否需要写入目的寄存器
    output reg[`RegBus]            reg1_o, //指令源操作数1
    output reg[`RegBus]            reg2_o, //指令源操作数2

    //流水线暂停请求
    output reg                  stallreq_from_id

);

reg [31:0]  imm; //立即数
reg [5:0]   opcode;
reg [4:0]   rs,rt,rd;
reg [4:0]   sa;
reg [5:0]   func;
reg         InstValid;


always @(*) begin
    if(rst == 1) begin
        {reg1_addr_o,reg2_addr_o,reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wd_o,wreg_o} = 0;
        {opcode,rs,rt,rd,sa,func,imm} = 0;
        InstValid = 1;
    end else begin
        {reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wreg_o, imm} = 0; //组合逻辑
        {opcode,rs,rt,rd,sa,func} = inst_i;
        reg1_addr_o = rs;
        reg2_addr_o = rt;
        wd_o = rd; //默认目的寄存器地址
        InstValid = 0;
        case(opcode)
            //special类
            `OP_SPECIAL:begin
                case(func)
                    `FUC_AND: begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_LOGIC;
                            aluop_o = `ALU_AND;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;  
                        end
                    end
                    `FUC_OR:begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_LOGIC;
                            aluop_o = `ALU_OR;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;  
                        end 
                    end
                    `FUC_XOR:begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_LOGIC;
                            aluop_o = `ALU_XOR;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;  
                        end
                    end
                    `FUC_NOR:begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_LOGIC;
                            aluop_o = `ALU_NOR;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;  
                        end
                    end
                    `FUC_SLLV:begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SLL;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;
                        end
                    end
                    `FUC_SRLV:begin
                       if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SRL;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;
                        end
                    end
                    `FUC_SRAV:begin
                        if(sa==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SRA;
                            reg1_read_o = 1;
                            reg2_read_o = 1;
                            InstValid = 1;
                        end
                    end
                    `FUC_SLL:begin
                        if(rs==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SLL;
                            reg1_read_o = 0;
                            reg2_read_o = 1; //只读取rt
                            imm[4:0] = sa; //把sa存放到imm里面
                            InstValid = 1;
                        end
                    end
                    `FUC_SRL:begin
                        if(rs==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SRL;
                            reg1_read_o = 0;
                            reg2_read_o = 1; //只读取rt
                            imm[4:0] = sa; //把sa存放到imm里面
                            InstValid = 1;
                        end
                    end
                    `FUC_SRA:begin
                        if(rs==0) begin
                            wreg_o = 1;
                            alusel_o = `ALU_RES_SHIFT;
                            aluop_o = `ALU_SRA;
                            reg1_read_o = 0;
                            reg2_read_o = 1; //只读取rt
                            imm[4:0] = sa; //把sa存放到imm里面
                            InstValid = 1;
                        end
                    end
                    //移动指令
                    `FUC_MOVZ:begin
                        wreg_o = (reg2_o==0)? 1: 0;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o =  `ALU_MOVZ;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MOVN:begin
                        wreg_o = (reg2_o!=0)?1:0;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o = `ALU_MOVN;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MFHI:begin
                        wreg_o = 1;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o =  `ALU_MFHI;
                        reg1_read_o = 0;
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_MFLO:begin
                        wreg_o = 1;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o =  `ALU_MFLO;
                        reg1_read_o = 0;
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_MTHI:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o =`ALU_MTHI;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_MTLO:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_MOVE;
                        aluop_o =`ALU_MTLO;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_ADD:begin
                        wreg_o = 1;
                        aluop_o = `ALU_ADD;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_ADDU:begin
                        wreg_o = 1;
                        aluop_o = `ALU_ADDU;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_SUB:begin
                        wreg_o = 1;
                        aluop_o = `ALU_SUB;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_SUBU:begin
                        wreg_o = 1;
                        aluop_o = `ALU_SUBU;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_SLT:begin
                        wreg_o = 1;
                        aluop_o = `ALU_SLT;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_SLTU:begin
                        wreg_o = 1;
                        aluop_o = `ALU_SLTU;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MULT:begin
                        wreg_o = 0;
                        aluop_o = `ALU_MULT;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MULTU:begin
                        wreg_o = 0;
                        aluop_o = `ALU_MULTU;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    
                default: InstValid = 0; //未定义指令
                
                endcase
            end
            //special2类
            `OP_SPECIAL2:begin
                case(func) 
                    `FUC_CLZ:begin
                        wreg_o = 1;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_CLZ;
                        reg1_read_o = 1; //只需要读一个寄存器
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_CLO:begin
                        wreg_o = 1;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_CLO;
                        reg1_read_o = 1; //只需要读一个寄存器
                        reg2_read_o = 0;
                        InstValid = 1;
                    end
                    `FUC_MUL:begin
                        wreg_o = 1;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_MUL;
                        reg1_read_o = 1; 
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                endcase
            end
            `OP_ANDI:begin
                wreg_o = 1;
                alusel_o = `ALU_RES_LOGIC;
                aluop_o = `ALU_ANDI;
                reg1_read_o = 1; //只需要读一个寄存器
                reg2_read_o = 0;
                imm = {16'h0, inst_i[15:0]}; //逻辑扩展
                wd_o = rt; //目的寄存器为rt
                InstValid = 1;
            end
            `OP_ORI:begin //ori 指令
                wreg_o = 1;
                alusel_o = `ALU_RES_LOGIC;
                aluop_o = `ALU_ORI;
                reg1_read_o = 1; //只需要读一个寄存器
                reg2_read_o = 0;
                imm = {16'h0, inst_i[15:0]}; //逻辑扩展
                wd_o = rt; //目的寄存器为rt
                InstValid = 1;
            end
            `OP_XORI:begin
                wreg_o = 1;
                alusel_o = `ALU_RES_LOGIC;
                aluop_o = `ALU_XORI;
                reg1_read_o = 1; //只需要读一个寄存器
                reg2_read_o = 0;
                imm = {16'h0, inst_i[15:0]}; //逻辑扩展
                wd_o = rt; //目的寄存器为rt
                InstValid = 1;
            end
            `OP_LUI:begin
                wreg_o = 1;
                alusel_o = `ALU_RES_LOGIC;
                aluop_o = `ALU_LUI;
                reg1_read_o = 1; //只需要读一个寄存器
                reg2_read_o = 0;
                imm = {inst_i[15:0],16'h0};
                wd_o = rt; //目的寄存器为rt
                InstValid = 1;
            end
            `OP_PREF:begin
                alusel_o = `ALU_RES_NOP;
                aluop_o = `ALU_NOP;
                InstValid = 1;
            end
            `OP_ADDI:begin
                wreg_o = 1;;
                alusel_o = `ALU_RES_ARITH;
                aluop_o = `ALU_ADDI; //addi 使用alu类别
                reg1_read_o = 1;
                reg2_read_o = 0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]}; //符号扩展
                wd_o = rt;
                InstValid = 1;
            end
            `OP_ADDIU:begin
                wreg_o = 1;
                alusel_o = `ALU_RES_ARITH;
                aluop_o = `ALU_ADDIU;
                reg1_read_o = 1;
                reg2_read_o = 0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]}; //符号扩展
                wd_o = rt;
                InstValid = 1;
            end
            `OP_SLTI:begin
                wreg_o = 1;
                alusel_o =  `ALU_RES_ARITH;
                aluop_o = `ALU_SLTI;
                reg1_read_o = 1;
                reg2_read_o = 0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]}; //符号扩展
                wd_o = rt;
                InstValid = 1;
            end
            `OP_SLTIU:begin
                wreg_o = 1;
                alusel_o =  `ALU_RES_ARITH;
                aluop_o = `ALU_SLTIU;
                reg1_read_o = 1;
                reg2_read_o = 0;
                imm = {{16{inst_i[15]}}, inst_i[15:0]}; //符号扩展
                wd_o = rt;
                InstValid = 1;
            end
            default: InstValid = 0;
        endcase
    end
end

//操作数1
always @(*) begin
    if(rst==1) reg1_o = 0;
    else begin
        if(reg1_read_o) begin
            if(ex_wreg_i && ex_wd_i==reg1_addr_o && ex_wd_i != 0) 
                reg1_o = ex_wdata_i;
            else if(mem_wreg_i && mem_wd_i==reg1_addr_o && mem_wd_i != 0)
                reg1_o = mem_wdata_i;
            else reg1_o = reg1_data_i;
        end
        else reg1_o = imm;
    end
end
//操作数2
always @(*) begin
    if(rst) reg2_o = 0;
    else begin
        if(reg2_read_o) begin
            if(ex_wreg_i && ex_wd_i==reg2_addr_o && ex_wd_i != 0) 
                reg2_o = ex_wdata_i;
            else if(mem_wreg_i && mem_wd_i==reg2_addr_o && mem_wd_i != 0)
                reg2_o = mem_wdata_i;
            else reg2_o = reg2_data_i;
        end
        else reg2_o = imm;
    end
end

endmodule // id