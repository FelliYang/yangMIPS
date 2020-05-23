`ifndef DEFINES
`define DEFINES

//********************* 全局的宏定义    ***************************
`define RstEnable       1'b1            //复位信号有效
`define RstDisable      1'b0            //复位信号无效
`define ZeroWord        32'h00000000    //32位的数值0
`define WriteEnable     1'b1            //使能写
`define WriteDisable    1'b0            //禁止写
`define ReadEnable      1'b1            //使能读
`define ReadDisable     1'b0            //禁止读
`define ChipEnable      1'b1            //芯片使能
`define ChipDisable     1'b0            //芯片禁止

//寄存器堆相关
`define RegAddrBus      4:0             
`define RegBus          31:0
`define RegNum          32


//指令译码相关
`define AluOpBus        7:0
`define AluSelBus       2:0   

//指令ROM相关
`define InstAddrBus     31:0            //ROM地址总线
`define InstBus         31:0            //ROM数据总线
`define InstMemNum      131072          //ROM实际大小为128 * 4KB
`define InstMemNumLog2  17              //Rom实际使用地址线的宽度

//指令大类型->使用op域判断
`define OP_SPECIAL      6'b000000
`define OP_ANDI         6'b001100
`define OP_ORI          6'b001101
`define OP_XORI         6'b001110
`define OP_LUI          6'b001111
`define OP_PREF         6'b110011	

//指令子类型->使用function域判断
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


//aluop ->运算子类型	前3位表示alusel运算类型 后5位表示子类型编号
`define ALU_AND		   	8'b001_00000
`define ALU_OR	    	8'b001_00001
`define ALU_XOR		  	8'b001_00010
`define ALU_NOR		  	8'b001_00011
`define ALU_ANDI	  	8'b001_00100
`define ALU_ORI		  	8'b001_00101
`define ALU_XORI	  	8'b001_00110
`define ALU_LUI		  	8'b001_00111

`define ALU_SLL		  	8'b010_00000
`define ALU_SLLV	  	8'b010_00001
`define ALU_SRL		  	8'b010_00010
`define ALU_SRLV	 	8'b010_00011
`define ALU_SRA	 		8'b010_00100
`define ALU_SRAV  		8'b010_00101

`define ALU_NOP			8'b000_00000
 
//alusel -> 运算类型
`define ALU_RES_LOGIC   3'b001
`define ALU_RES_NOP     3'b000
`define ALU_RES_SHIFT 	3'b010



`endif