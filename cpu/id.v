`include "defines.v"
module id(
    input wire rst,
    
    //来自取指阶段的信息
    input wire[31:0]    		pc_i,
    input wire[31:0]           inst_i,

    //寄存器堆读取回路
    output reg [4:0]          reg1_addr_o,
    output reg [4:0]          reg2_addr_o,
    output reg                 reg1_read_o, //读使能 通过该信号判断源操作数来自imm还是寄存器堆
    output reg                 reg2_read_o,
    input [31:0]             reg1_data_i,
    input [31:0]             reg2_data_i,

    //数据前推->处于执行阶段的指令的运算结果
    input [31:0]                ex_wdata_i,
    input [4:0]                 ex_wd_i,
    input                       ex_wreg_i,
    
    //数据前推->处于访存阶段的指令的运算结果
    input [31:0]                mem_wdata_i,
    input [4:0]                 mem_wd_i,
    input                       mem_wreg_i,

    //译码阶段的结果
	output [31:0]					inst_o, //向后传递指令
    output reg[7:0]                	aluop_o, //运算子类型
    output reg[2:0]               	alusel_o, //运算类型
    output reg[4:0]               	wd_o, //目的寄存器地址
    output reg                     	wreg_o, //指令是否需要写入目的寄存器
    output reg[31:0]                reg1_o, //指令源操作数1
    output reg[31:0]                reg2_o, //指令源操作数2
	//异常处理特殊信号
	output [31:0] excepttype_o, current_inst_addr_o,

    //流水线暂停请求
    output   	                  stallreq_from_id,

    //检测分支和跳转指令后的相关信息
    output reg [31:0]           branch_target_address_o,
    output reg                  branch_flag_o,
    output reg [31:0]           link_addr_o, //返回地址
    output reg                  next_inst_in_delayslot_o, //代表当前指令的下一条指令在分支延迟槽中
    output                      is_in_delayslot_o, //代表当前指令在分支延迟槽中
    input                       is_in_delayslot_i,

	//load指令导致的数据冒险相关信号
	input [7:0]					ex_aluop_i


);

assign inst_o = inst_i; //向后传递指令

reg [31:0]  imm; //立即数
reg [5:0]   opcode;
reg [4:0]   rs,rt,rd;
reg [4:0]   sa;
reg [5:0]   func;
reg         InstValid;

wire [31:0] pc_plus_4, pc_plus_8, imm_sll2_signedext;

//分支跳转指令需要的局部变量
assign pc_plus_4 = pc_i + 4;
assign pc_plus_8 = pc_i + 8;
//立即数左移两位符号扩展
assign imm_sll2_signedext = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
assign is_in_delayslot_o = rst ? 0 : is_in_delayslot_i;

//异常相关变量
reg excepttype_is_syscall, excepttype_is_eret;
assign excepttype_o = {19'b0, excepttype_is_eret, 2'b0, ~InstValid, excepttype_is_syscall, 8'b0};
assign current_inst_addr_o = pc_i;

//TODO 三种异常触发逻辑

always @(*) begin
    if(rst) begin
        {reg1_addr_o,reg2_addr_o,reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wd_o,wreg_o} = 0;
        {opcode,rs,rt,rd,sa,func,imm} = 0;
        {branch_target_address_o, branch_flag_o, link_addr_o,
         next_inst_in_delayslot_o} = 0;
        InstValid = 0;
		excepttype_is_syscall = 0;
		excepttype_is_eret = 0;
    end else begin
        {reg1_read_o,reg2_read_o,
        aluop_o,alusel_o,wreg_o, imm} = 0; //组合逻辑
        //默认情况下，分支跳转相关信号全为0
        {branch_target_address_o, branch_flag_o, link_addr_o,
         next_inst_in_delayslot_o} = 0;
        {opcode,rs,rt,rd,sa,func} = inst_i;
        reg1_addr_o = rs;
        reg2_addr_o = rt;
        wd_o = rd; //默认目的寄存器地址
        InstValid = 0;
		excepttype_is_syscall = 0;
		excepttype_is_eret = 0;
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
                    `FUC_DIV:begin
                        wreg_o = 0;
                        aluop_o = `ALU_DIV;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_DIVU:begin
                        wreg_o = 0;
                        aluop_o = `ALU_DIVU;
                        alusel_o = `ALU_RES_ARITH;
                        reg1_read_o = 1;
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_JR: begin
                        wreg_o = 0;
                        aluop_o = `ALU_JR;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1; //只需要读rs寄存器
                        reg2_read_o = 0;
                        branch_flag_o = 1;
                        link_addr_o = 0;
                        branch_target_address_o = reg1_o;
                        next_inst_in_delayslot_o = 1;
                        InstValid = 1;
                    end
                    `FUC_JALR:begin
                        wreg_o = 1;
						//wd_o = wd
                        aluop_o = `ALU_JALR;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        branch_flag_o = 1;
                        branch_target_address_o = reg1_o;
                        link_addr_o = pc_plus_8;
                        next_inst_in_delayslot_o = 1;
                        InstValid = 1;
                    end
					`FUC_TEQ:begin
						wreg_o = 0;
						aluop_o = `ALU_TEQ;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_TGE:begin
						wreg_o = 0;
						aluop_o = `ALU_TGE;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_TGEU:begin
						wreg_o = 0;
						aluop_o = `ALU_TGEU;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_TLT:begin
						wreg_o = 0;
						aluop_o = `ALU_TLT;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_TLTU:begin
						wreg_o = 0;
						aluop_o = `ALU_TLTU;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_TNE:begin
						wreg_o = 0;
						aluop_o = `ALU_TNE;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 1;
						InstValid = 1;
					end
					`FUC_SYSCALL:begin
						wreg_o = 0;
						aluop_o = `ALU_SYSCALL;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 0;
						reg2_read_o = 0;
						InstValid = 1;
						excepttype_is_syscall = 1;
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
                    `FUC_MADD:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_MADD;
                        reg1_read_o = 1; 
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MADDU:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_MADDU;
                        reg1_read_o = 1; 
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MSUB:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_MSUB;
                        reg1_read_o = 1; 
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    `FUC_MSUBU:begin
                        wreg_o = 0;
                        alusel_o = `ALU_RES_ARITH;
                        aluop_o = `ALU_MSUBU;
                        reg1_read_o = 1; 
                        reg2_read_o = 1;
                        InstValid = 1;
                    end
                    default:InstValid = 0;
                endcase
            end
            //REGIMM类
            `OP_REGIMM:begin
                case(rt)
                    `RT_BLTZ:begin
                        wreg_o = 0;
                        aluop_o = `ALU_BLTZ;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        if(reg1_o[31]) begin // < 0
                            branch_flag_o = 1;
                            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o = 1;
                        end
                        link_addr_o = 0;
                        InstValid = 1;
                    end
                    `RT_BGEZ:begin
                        wreg_o = 0;
                        aluop_o = `ALU_BGEZ;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        if(!reg1_o[31] || reg1_o == 0) begin // >= 0
                            branch_flag_o = 1;
                            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o = 1;
                        end
                        link_addr_o = 0;
                        InstValid = 1;
                    end
                    `RT_BLTZAL:begin
                        wreg_o = 1;
                        wd_o = 5'd31;
                        aluop_o = `ALU_BLTZAL;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        if(reg1_o[31]) begin //< 0
                            branch_flag_o = 1;
                            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o = 1;
                        end
                        link_addr_o = pc_plus_8;
                        InstValid = 1;
                    end
                    `RT_BGEZAL:begin
                        wreg_o = 1;
                        wd_o = 5'd31;
                        aluop_o = `ALU_BGEZAL;
                        alusel_o = `ALU_RES_JUMP_BRANCH;
                        reg1_read_o = 1;
                        reg2_read_o = 0;
                        if(!reg1_o[31] || reg1_o == 0) begin //>= 0
                            branch_flag_o = 1;
                            branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                            next_inst_in_delayslot_o = 1;
                        end
                        link_addr_o = pc_plus_8;
                        InstValid = 1;
                    end
					`RT_TEQI:begin
						wreg_o = 0;
						aluop_o = `ALU_TEQI;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
					`RT_TGEI:begin
						wreg_o = 0;
						aluop_o = `ALU_TGEI;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
					`RT_TGEIU:begin
						wreg_o = 0;
						aluop_o = `ALU_TGEIU;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
					`RT_TLTI:begin
						wreg_o = 0;
						aluop_o = `ALU_TLTI;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
					`RT_TLTIU:begin
						wreg_o = 0;
						aluop_o = `ALU_TLTIU;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
					`RT_TNEI:begin
						wreg_o = 0;
						aluop_o = `ALU_TNEI;
						alusel_o = `ALU_RES_EXCEPTION;
						reg1_read_o = 1;
						reg2_read_o = 0;
						imm = {{16{inst_i[15]}}, inst_i[15:0]};
						InstValid = 1;
					end
                    default: InstValid = 0;
                endcase
            end
			//COP0类
			`OP_COP0:begin
				if(func==`FUC_ERET && inst_i[25]==1) begin //eret指令
					wreg_o = 1;
					aluop_o = `ALU_ERET;
					alusel_o = `ALU_RES_EXCEPTION;
					reg1_read_o = 0;
					reg2_read_o = 0;
					InstValid = 1;
					excepttype_is_eret = 1;
				end else begin
					case(rs)
						`RS_MFC0:begin
							wreg_o = 1;
							alusel_o = `ALU_RES_MOVE;
							aluop_o = `ALU_MFC0;
							reg1_read_o = 0;
							reg2_read_o = 0;
							wd_o = rt;
							InstValid = 1;
						end
						`RS_MTC0:begin
							wreg_o = 0;
							alusel_o = `ALU_RES_MOVE;
							aluop_o = `ALU_MTC0;
							reg1_read_o = 0;
							reg2_read_o = 1;
							InstValid = 1;
						end
						default ;
					endcase
				end
				
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
            `OP_J:begin
                wreg_o = 0;
                aluop_o = `ALU_J;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 0;
                reg2_read_o = 0;
                branch_flag_o = 1;
                branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                link_addr_o = 0;
                next_inst_in_delayslot_o = 1;
                InstValid = 1;
            end
            `OP_JAL:begin
                wreg_o = 1;
                wd_o = 31;
                aluop_o = `ALU_JAL;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 0;
                reg2_read_o = 0;
                branch_flag_o = 1;
                branch_target_address_o = {pc_plus_4[31:28], inst_i[25:0], 2'b00};
                link_addr_o = pc_plus_8;
                next_inst_in_delayslot_o = 1;
                InstValid = 1;
            end
            `OP_BEQ:begin
                wreg_o = 0;
                aluop_o = `ALU_BEQ;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 1;
                reg2_read_o = 1;
                if(reg1_o==reg2_o) begin
                    branch_flag_o = 1;
                    branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o = 1;
                end
                link_addr_o = 0;
                InstValid = 1;
            end
            `OP_BNE:begin
                wreg_o = 0;
                aluop_o = `ALU_BNE;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 1;
                reg2_read_o = 1;
                if(reg1_o != reg1_o) begin
                    branch_flag_o = 1;
                    branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o = 1;
                end
                link_addr_o = 0;
                InstValid = 1;
            end
            `OP_BGTZ:begin
                wreg_o = 0;
                aluop_o = `ALU_BGTZ;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 1;
                reg2_read_o = 0;
                if(!reg1_o[31] && reg1_o!=0) begin // > 0
                    branch_flag_o = 1;
                    branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o = 1;
                end
                link_addr_o = 0;
                InstValid = 1;
            end
            `OP_BLEZ:begin
                wreg_o = 0;
                aluop_o = `ALU_BLEZ;
                alusel_o = `ALU_RES_JUMP_BRANCH;
                reg1_read_o = 1;
                reg2_read_o = 0;
                if(reg1_o[31] || reg1_o==0) begin // <= 0
                    branch_flag_o = 1;
                    branch_target_address_o = pc_plus_4 + imm_sll2_signedext;
                    next_inst_in_delayslot_o = 1;
                end
                link_addr_o = 0;
                InstValid = 1;
			end
			`OP_LB:begin
				wreg_o = 1;
				aluop_o = `ALU_LB;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				wd_o = rt;
				InstValid = 1;
			end
			`OP_LBU:begin
				wreg_o = 1;
				aluop_o = `ALU_LBU;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				wd_o = rt;
				InstValid = 1;
			end
			`OP_LH:begin
				wreg_o = 1;
				aluop_o = `ALU_LH;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				wd_o = rt;
				InstValid = 1;
			end
			`OP_LHU:begin
				wreg_o = 1;
				aluop_o = `ALU_LHU;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				wd_o = rt;
				InstValid = 1;
			end
			`OP_LW:begin
				wreg_o = 1;
				aluop_o = `ALU_LW;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				wd_o = rt;
				InstValid = 1;
			end
			`OP_SB:begin
				wreg_o = 0;
				aluop_o = `ALU_SB;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
			`OP_SH:begin
				wreg_o = 0;
				aluop_o = `ALU_SH;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
			`OP_SW:begin
				wreg_o = 0;
				aluop_o = `ALU_SW;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
			`OP_LWL:begin
				wreg_o = 1;
				aluop_o = `ALU_LWL;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1; //也需要读取rt寄存器的初始值
				wd_o = rt;
				InstValid = 1;
			end
			`OP_LWR:begin
				wreg_o = 1;
				aluop_o = `ALU_LWR;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;//也需要读取rt寄存器的初始值
				wd_o = rt;
				InstValid = 1;
			end
			`OP_SWL:begin
				wreg_o = 0;
				aluop_o = `ALU_SWL;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
			`OP_SWR:begin
				wreg_o = 0;
				aluop_o = `ALU_SWR;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
			`OP_LL:begin
				wreg_o = 1;
				wd_o = rt;
				aluop_o = `ALU_LL;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 0;
				InstValid = 1;
			end
			`OP_SC:begin
				wreg_o = 1;
				wd_o = rt;
				aluop_o = `ALU_SC;
				alusel_o = `ALU_RES_LOAD_STORE;
				reg1_read_o = 1;
				reg2_read_o = 1;
				InstValid = 1;
			end
            default: InstValid = 0;
        endcase
    end
end

//操作数1
always @(*) begin
    if(rst) reg1_o = 0;
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

//load指令导致的数据相关->暂停流水线
reg	stallreq_for_reg1_loadrelate;
reg stallreq_for_reg2_loadrelate;
wire pre_inst_is_load;

assign pre_inst_is_load = (ex_aluop_i==`ALU_LB || ex_aluop_i==`ALU_LBU ||
						ex_aluop_i==`ALU_LH || ex_aluop_i==`ALU_LHU ||
						ex_aluop_i==`ALU_LW || ex_aluop_i==`ALU_LWL ||
						ex_aluop_i==`ALU_LWR || ex_aluop_i==`ALU_LL || 
						ex_aluop_i==`ALU_SC) ? 1 : 0;
//reg1
always @(*) begin
	stallreq_for_reg1_loadrelate = 0;
	if(pre_inst_is_load && ex_wd_i == reg1_addr_o && reg1_read_o) 
		stallreq_for_reg1_loadrelate = 1; 
end
//reg2
always @(*) begin
	stallreq_for_reg2_loadrelate = 0;
	if(pre_inst_is_load && ex_wd_i == reg2_addr_o && reg2_read_o) 
		stallreq_for_reg2_loadrelate = 1; 
end

assign stallreq_from_id = stallreq_for_reg1_loadrelate | stallreq_for_reg2_loadrelate;

endmodule // id