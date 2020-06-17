`include "defines.v"
module ex(
    input rst,
    
    //来自译码级的信息
	input [31:0] inst_i,
    input [2:0]alusel_i,
    input [7:0]aluop_i,
    input [31:0] reg1_i,
    input [31:0] reg2_i,
    input [4:0] wd_i,
    input       wreg_i,
    input  [31:0] link_address_i, //转移指令返回地址
    input         is_in_delayslot_i, //当前指令是否位于分支延迟槽

    //HILO模块给出的寄存器值
    input [31:0] hi_i,lo_i,
    //访存阶段HI.LO数据前推
    input mem_whilo_i,
    input [31:0] mem_hi_i,mem_lo_i,

	//CP0模块的寄存器内容
	input [31:0] cp0_data_i,
	output [4:0] cp0_raddr_o,
	//访存阶段CP0最新数据前推
	input [4:0] mem_cp0_waddr_i,
	input [31:0] mem_cp0_wdata_i,
	input 		mem_cp0_we_i,

    //指令多周期执行时，来自EX/MEM模块的临时信号
    input [63:0] hilo_temp_i,
    input [1:0] cnt_i, 
    output reg [63:0] hilo_temp_o, //运算中间结果
    output reg [1:0] cnt_o, //周期计数
    //与除法模块之间的连接信号
    output reg signed_div_o, //有符号除法
    output reg div_start_o, //开始除法运算
    output reg [31:0]div_opdata1_o, //被除数
    output reg [31:0]div_opdata2_o, //除数
    input [63:0] div_result_i, //除法结果
    input       div_ready_i, //除法运算完成


	/**传递给EX/MEM模块的信号**/
    //通用寄存器堆
    output reg [4:0] wd_o,
    output reg [31:0] wdata_o,
    output reg     wreg_o,
    //HILO寄存器
    output reg  whilo_o,
    output reg [31:0] hi_o,lo_o,
	//COP0寄存器堆
	output reg [4:0] cp0_waddr_o,
	output reg [31:0] cp0_wdata_o,
	output reg 		cp0_we_o,
	//其他传给MEM级的信号(用于存储指令)
	output [7:0] aluop_o,
	output [31:0] mem_addr_o,
	output [31:0] reg2_o, 

    //流水线暂停请求
    output reg stallreq_from_ex

);

//直接传递信号
assign aluop_o = aluop_i;
assign reg2_o = reg2_i;
assign mem_addr_o = reg1_i + {{16{inst_i[15]}}, inst_i[15:0]};

reg [31:0] logicout; //逻辑运算
reg [31:0] shiftres; //移位运算 
reg [31:0] moveres; //移动运算
reg [31:0] arithres; //算数运算
reg [31:0] HI, LO; //保存寄存器的值


//标志位
wire        ov_sum; //加法溢出位

//局部变量
wire [31:0]  reg2_i_mux; //操作数2根据指令需要，转换成相反数的补码表示
wire [31:0]  result_sum; //加法结果
wire        reg1_lt_reg2;
wire [31:0] opdata1_mult;  //被乘数
wire [31:0] opdata2_mult; //乘数
wire [63:0] hilo_temp; //零时保存乘法结果
reg [63:0] multres;
reg [63:0] hilo_temp1; //临时保存乘加或乘减结果

//流水线暂停信号
reg stallreq_from_mul, stallreq_from_div;
always @(*) begin
    stallreq_from_ex = stallreq_from_mul || stallreq_from_div;
end


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

/*乘法运算*/
//有符号数的乘法过程中先取两个操作数绝对值，后期修正
assign opdata1_mult = ((aluop_i==`ALU_MUL || aluop_i==`ALU_MULT
                    || aluop_i==`ALU_MADD || aluop_i==`ALU_MSUB) && 
                    reg1_i[31]==1 ) ? (~reg1_i+1) : reg1_i;
assign opdata2_mult = ((aluop_i==`ALU_MUL || aluop_i==`ALU_MULT
                    || aluop_i==`ALU_MADD || aluop_i==`ALU_MSUB) &&
                     reg2_i[31]==1) ? (~reg2_i+1) : reg2_i;
assign hilo_temp = opdata1_mult * opdata2_mult;
//组合逻辑->修正乘法结果
always @(*) begin
    if(rst) multres = 0;
    else if((aluop_i==`ALU_MUL || aluop_i==`ALU_MULT
         || aluop_i==`ALU_MADD || aluop_i==`ALU_MSUB) &&
         (reg1_i[31] ^ reg2_i[31]) ) multres = ~hilo_temp + 1;
    else multres = hilo_temp;
end

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
		`ALU_MFC0: moveres = cp0_waddr_o==mem_cp0_waddr_i && mem_cp0_we_i? mem_cp0_wdata_i : cp0_data_i;
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
        `ALU_CLZ: arithres =    reg1_i[31] ? 0 : reg1_i[30] ? 1 : reg1_i[29] ? 2 : reg1_i[28] ? 3 :
                                reg1_i[27] ? 4 : reg1_i[26] ? 5 : reg1_i[25] ? 6 : reg1_i[24] ? 7 :
                                reg1_i[23] ? 8 : reg1_i[22] ? 9 : reg1_i[21] ? 10 : reg1_i[20] ? 11 :
                                reg1_i[19] ? 12 : reg1_i[18] ? 13 : reg1_i[17] ? 14 : reg1_i[16] ? 15 :
                                reg1_i[15] ? 16 : reg1_i[14] ? 17 : reg1_i[13] ? 18 : reg1_i[12] ? 19 :
                                reg1_i[11] ? 20 : reg1_i[10] ? 21 : reg1_i[9] ? 22 : reg1_i[8] ? 23 :
                                reg1_i[7] ? 24 : reg1_i[6] ? 25 : reg1_i[5] ? 26 : reg1_i[4] ? 27 :
                                reg1_i[3] ? 28 : reg1_i[2] ? 29 : reg1_i[1] ? 30 : reg1_i[0] ? 31 : 32;
        `ALU_CLO: arithres =    !reg1_i[31] ? 0 : !reg1_i[30] ? 1 : !reg1_i[29] ? 2 : !reg1_i[28] ? 3 :
                                !reg1_i[27] ? 4 : !reg1_i[26] ? 5 : !reg1_i[25] ? 6 : !reg1_i[24] ? 7 :
                                !reg1_i[23] ? 8 : !reg1_i[22] ? 9 : !reg1_i[21] ? 10 : !reg1_i[20] ? 11 :
                                !reg1_i[19] ? 12 : !reg1_i[18] ? 13 : !reg1_i[17] ? 14 : !reg1_i[16] ? 15 :
                                !reg1_i[15] ? 16 : !reg1_i[14] ? 17 : !reg1_i[13] ? 18 : !reg1_i[12] ? 19 :
                                !reg1_i[11] ? 20 : !reg1_i[10] ? 21 : !reg1_i[9] ? 22 : !reg1_i[8] ? 23 :
                                !reg1_i[7] ? 24 : !reg1_i[6] ? 25 : !reg1_i[5] ? 26 : !reg1_i[4] ? 27 :
                                !reg1_i[3] ? 28 : !reg1_i[2] ? 29 : !reg1_i[1] ? 30 : !reg1_i[0] ? 31 : 32;
        `ALU_MUL: arithres = multres[31:0];
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
        `ALU_RES_JUMP_BRANCH: wdata_o = link_address_i;
    default: wdata_o = 0;
    endcase
end

//累乘指令MADD MADDU MSUB MSUBU
always @(*) begin
    if(rst) {hilo_temp_o, cnt_o, stallreq_from_mul, hilo_temp1} = 0;
    else begin
        case(aluop_i)
            `ALU_MADD, `ALU_MADDU: begin
                if(cnt_i == 0) begin //执行阶段第一个周期
                    hilo_temp_o = multres;
                    cnt_o = 1;
                    stallreq_from_mul = 1; //请求暂停流水线
                    hilo_temp1 = 0;
                end else if(cnt_i == 1) begin //第二个周期
                    hilo_temp_o = 0;
                    cnt_o = 2;
                    stallreq_from_mul = 0; //不再暂停流水线，时钟上升沿时一切正常
                    hilo_temp1 = hilo_temp_i + {HI, LO};
                end
            end
            `ALU_MSUB, `ALU_MSUBU: begin
                if(cnt_i == 0) begin //执行阶段第一个周期
                    hilo_temp_o = ~multres + 1; //减法，取被减数的补码
                    cnt_o = 1;
                    stallreq_from_mul = 1; //请求暂停流水线
                    hilo_temp1 = 0;
                end else if(cnt_i == 1) begin //第二个周期
                    hilo_temp_o = 0;
                    cnt_o = 2;
                    stallreq_from_mul = 0; //不再暂停流水线，时钟上升沿时一切正常
                    hilo_temp1 = hilo_temp_i + {HI, LO};
                end
            end
            default:{hilo_temp_o, cnt_o, stallreq_from_mul, hilo_temp1} = 0;
        endcase
    end
end

//除法指令 DIV DIVU
always @(*) begin
    if(rst) {stallreq_from_div, signed_div_o, div_start_o, div_opdata1_o, div_opdata2_o} = 0;
    else begin
        case(aluop_i)
            `ALU_DIV:begin
                if(div_ready_i==0) begin
                    div_start_o = 1;
                    signed_div_o = 1;
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;    
                    stallreq_from_div = 1;
                end else begin
                    {stallreq_from_div, signed_div_o, div_start_o, div_opdata1_o, div_opdata2_o} = 0;
                end
            end
            `ALU_DIVU:begin
                if(div_ready_i==0) begin
                    div_start_o = 1;
                    signed_div_o = 0;
                    div_opdata1_o = reg1_i;
                    div_opdata2_o = reg2_i;    
                    stallreq_from_div = 1;
                end else begin
                    {stallreq_from_div, signed_div_o, div_start_o, div_opdata1_o, div_opdata2_o} = 0;
                end
            end
        default:
            {stallreq_from_div, signed_div_o, div_start_o, div_opdata1_o, div_opdata2_o} = 0;
        endcase 
    end
end

//如果是MTHI、MTLO指令，需要给出whilo_o,hi_o,lo_i
//如果是mult、multu指令，也需要传递hilo的写入信息
always@(*)begin
    if(rst) {whilo_o,hi_o,lo_o} = 0;
    else begin
        {whilo_o,hi_o,lo_o} = 0;
        case(aluop_i)
            `ALU_MTHI: begin
                whilo_o = 1;
                hi_o = reg1_i;
                lo_o = LO;
            end
            `ALU_MTLO: begin
                whilo_o = 1;
                hi_o = HI;
                lo_o = reg1_i; 
            end
            `ALU_MULT, `ALU_MULTU: begin
                whilo_o = 1;
                {hi_o, lo_o} = multres;
            end
            `ALU_MADD,  `ALU_MADDU, `ALU_MSUB, `ALU_MSUBU:begin
                whilo_o = 1;
                {hi_o, lo_o} = hilo_temp1;
            end
            `ALU_DIV, `ALU_DIVU:begin
                whilo_o = 1;
                {hi_o, lo_o} = div_result_i;
            end
        endcase
        
    end
end

//CPO指令实现
always @(*) begin
	if(rst) begin
		{cp0_waddr_o, cp0_wdata_o, cp0_we_o} = 0;
	end else if(aluop_i==`ALU_MTC0) begin //mtc0指令
		cp0_we_o = 1;
		cp0_wdata_o = reg2_i;
		cp0_waddr_o = inst_i[15:11]; 
	end else begin
		{cp0_waddr_o, cp0_wdata_o, cp0_we_o} = 0;
	end
end
assign cp0_raddr_o = rst ? 0 : inst_i[15:11];

endmodule // ex