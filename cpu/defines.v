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

//指令码相关
`define EXE_ORI         6'b001101
`define EXE_NOP         6'b000000

//aluop ->运算子类型
`define EXE_OR_OP       8'b00100101
`define EXE_NOP_OP      8'b00000000
 
//alusel -> 运算类型
`define EXE_RES_LOGIC   3'b001
`define EXE_RES_NOP     3'b000



`endif