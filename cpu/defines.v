`ifndef DEFINES
`define DEFINES

//********************* 全局的宏定义    ***************************

//指令译码相关
`define AluOpBus        7:0
`define AluSelBus       2:0   

//指令ROM相关
`define InstAddrBus     31:0            //ROM地址总线
`define InstBus         31:0            //ROM数据总线
`define InstMemNum      131072          //ROM实际大小为128 * 4KB
`define InstMemNumLog2  17              //Rom实际使用地址线的宽度

//数据ROM相关
`define DataAddrBus     31:0            //ROM地址总线
`define DataBus         31:0            //ROM数据总线
`define DataMemNum      131072          //ROM实际大小为128 * 4KB
`define DataMemNumLog2  17              //Rom实际使用地址线的宽度


//指令大类型->使用op域判断
`define OP_SPECIAL      6'b000000
`define OP_SPECIAL2		6'b011100
`define OP_REGIMM		6'b000001
`define OP_ANDI         6'b001100
`define OP_ORI          6'b001101
`define OP_XORI         6'b001110
`define OP_LUI          6'b001111
`define OP_PREF         6'b110011	
`define OP_ADDI			6'b001000
`define OP_ADDIU		6'b001001
`define OP_SLTI			6'b001010
`define OP_SLTIU		6'b001011
`define OP_J			6'b000010
`define OP_JAL			6'b000011
`define OP_BEQ			6'b000100
`define OP_BGTZ			6'b000111
`define OP_BLEZ			6'b000110
`define OP_BNE			6'b000101
`define OP_LB			6'b100000
`define OP_LBU			6'b100100
`define OP_LH			6'b100001
`define OP_LHU			6'b100101
`define OP_LW			6'b100011
`define OP_SB			6'b101000
`define OP_SH			6'b101001
`define OP_SW			6'b101011
`define OP_LWL			6'b100010
`define OP_LWR			6'b100110
`define OP_SWL			6'b101010
`define OP_SWR			6'b101110
`define OP_LL 			6'b110000
`define OP_SC  			6'b111000


/****指令子类型->使用function域判断****/
/*special*/
//移位指令
`define FUC_SLL         6'b000000
`define FUC_SLLV        6'b000100
`define FUC_SRL         6'b000010
`define FUC_SRLV        6'b000110
`define FUC_SRA         6'b000011
`define FUC_SRAV        6'b000111
//逻辑指令
`define FUC_AND         6'b100100
`define FUC_OR          6'b100101
`define FUC_XOR         6'b100110
`define FUC_NOR         6'b100111
//移动指令
`define FUC_MOVZ		6'b001010
`define FUC_MOVN		6'b001011
`define FUC_MFHI		6'b010000
`define FUC_MTHI		6'b010001
`define FUC_MFLO		6'b010010
`define FUC_MTLO		6'b010011
//算数指令
`define FUC_ADD			6'b100000
`define FUC_ADDU		6'b100001
`define FUC_SUB			6'b100010
`define FUC_SUBU		6'b100011
`define FUC_SLT			6'b101010
`define FUC_SLTU		6'b101011
`define FUC_MULT		6'b011000
`define FUC_MULTU		6'b011001
`define FUC_DIV			6'b011010
`define FUC_DIVU		6'b011011
//跳转分支指令
`define FUC_JR			6'b001000
`define FUC_JALR		6'b001001
/*special2->*/
`define FUC_CLZ			6'b100000
`define FUC_CLO			6'b100001
`define FUC_MUL			6'b000010
`define FUC_MADD		6'b000000
`define FUC_MADDU		6'b000001
`define FUC_MSUB		6'b000100
`define FUC_MSUBU		6'b000101

/*****指令子类型->使用rt域判断*****/
`define RT_BLTZ			5'b00000
`define RT_BLTZAL		5'b10000
`define RT_BGEZ			5'b00001
`define RT_BGEZAL		5'b10001


/*aluop ->运算子类型	前3位表示alusel运算类型 后5位表示子类型编号*/
//空指令
`define ALU_NOP			8'b000_00000
//逻辑指令
`define ALU_AND		   	8'b001_00000
`define ALU_OR	    	8'b001_00001
`define ALU_XOR		  	8'b001_00010
`define ALU_NOR		  	8'b001_00011
`define ALU_ANDI	  	8'b001_00100
`define ALU_ORI		  	8'b001_00101
`define ALU_XORI	  	8'b001_00110
`define ALU_LUI		  	8'b001_00111
//移位指令
`define ALU_SLL		  	8'b010_00000
`define ALU_SLLV	  	8'b010_00001
`define ALU_SRL		  	8'b010_00010
`define ALU_SRLV	 	8'b010_00011
`define ALU_SRA	 		8'b010_00100
`define ALU_SRAV  		8'b010_00101
//移动指令
`define ALU_MOVZ		8'b011_00000
`define ALU_MOVN		8'b011_00001
`define ALU_MFHI		8'b011_00010
`define ALU_MFLO		8'b011_00011
`define ALU_MTHI		8'b011_00100
`define ALU_MTLO		8'b011_00101
//简单运算指令
`define ALU_ADD			8'b100_00000
`define ALU_ADDU		8'b100_00001
`define ALU_SUB			8'b100_00010
`define ALU_SUBU		8'b100_00011	
`define ALU_SLT			8'b100_00100
`define ALU_SLTU		8'b100_00101
`define ALU_ADDI		8'b100_00110
`define ALU_ADDIU		8'b100_00111
`define ALU_SLTI		8'b100_01000
`define ALU_SLTIU		8'b100_01001
`define ALU_CLZ			8'b100_01010
`define ALU_CLO			8'b100_01011
`define ALU_MUL			8'b100_01100
`define ALU_MULT		8'b100_01101
`define ALU_MULTU		8'b100_01110
`define ALU_MADD		8'b100_01111
`define ALU_MADDU		8'b100_10000
`define ALU_MSUB		8'b100_10001
`define ALU_MSUBU		8'b100_10010
`define ALU_DIV			8'b100_10011
`define ALU_DIVU		8'b100_10100
//跳转分支指令
`define ALU_JR  		8'b101_00000
`define ALU_JALR		8'b101_00001
`define ALU_J			8'b101_00010
`define ALU_JAL			8'b101_00011
`define ALU_BEQ			8'b101_00100
`define ALU_BGTZ		8'b101_00101
`define ALU_BLEZ		8'b101_00110
`define ALU_BNE			8'b101_00111
`define ALU_BLTZ		8'b101_01000
`define ALU_BLTZAL		8'b101_01001
`define ALU_BGEZ		8'b101_01010
`define ALU_BGEZAL		8'b101_01011
//存储指令
`define ALU_LB			8'b110_00000
`define ALU_LBU			8'b110_00001
`define ALU_LH			8'b110_00010
`define ALU_LW			8'b110_00011
`define ALU_LHU			8'b110_00100
`define ALU_SB			8'b110_00101
`define ALU_SH			8'b110_00110
`define ALU_SW			8'b110_00111
`define ALU_LWL			8'b110_01000
`define ALU_LWR			8'b110_01001
`define ALU_SWL			8'b110_01010
`define ALU_SWR			8'b110_01011
`define ALU_LL			8'b100_01100
`define ALU_SC			8'b100_01101


/*alusel -> 运算类型*/
`define ALU_RES_NOP     3'b000
`define ALU_RES_LOGIC   3'b001
`define ALU_RES_SHIFT 	3'b010
`define ALU_RES_MOVE	3'b011
`define ALU_RES_ARITH	3'b100 //算数指令
`define ALU_RES_JUMP_BRANCH 3'b101
`define ALU_RES_LOAD_STORE 3'b110

`define CP0_COUNT		5'b01001
`define CP0_COMPARE		5'b01011
`define CP0_STATUS		5'b01100
`define CP0_CAUSE		5'b01101
`define CP0_EPC			5'b01110
`define CP0_PRID		5'b01111
`define CP0_CONFIG		5'b10000	

`endif