module yangmips(
    input clk,
    input rst,
    input [31:0] rom_data_i, //从指存储器取得的指令
    output [31:0] rom_addr_o, //输出到指令存储器的地址
    output        rom_ce_o  //指令存储器使能信号
);

//连接IF阶段输出和IF/ID模块输入的变量
wire [31:0] pc;

//连接IF/ID模块和译码阶段的变量
wire [31:0] id_pc_i; //译码级pc输入
wire [31:0] id_inst_i; //译码级inst输入

//连接译码阶段的输出和ID/EX模块的输入
wire [31:0] reg1_data, reg2_data;
wire [4:0]  reg1_addr, reg2_addr;
wire        reg1_read, reg2_read;
wire [7:0]  id_aluop_o;
wire [2:0]  id_alusel_o;
wire [31:0] id_reg1_o;
wire [31:0] id_reg2_o;
wire [4:0]  id_wd_o;
wire        id_wreg_o;

//连接ID/EX模块的输出与执行阶段EX模块的输入
wire [31:0] ex_reg1_i, ex_reg2_i;
wire [4:0]  ex_wd_i;
wire        ex_wreg_i;
wire [2:0]  ex_alusel_i;
wire [7:0]  ex_aluop_i;

//连接HI/LO模块的输出于EX模块的输入
wire [31:0] hi, lo;

//连接执行阶段EX模块的输出与EX/MEM模块的输入
wire [31:0] ex_wdata_o;
wire [4:0]  ex_wd_o;
wire        ex_wreg_o;
wire        ex_whilo_o;
wire [31:0] ex_hi_o, ex_lo_o;
//EX模块与EM/MEM模块之间的临时信号
wire [63:0] ex_hilo_temp_o, ex_hilo_temp_i;
wire [1:0] ex_cnt_o, ex_cnt_i;

//连接EX/MEM模块的输出与访存阶段MEM模块的输入
wire [31:0] mem_wdata_i;
wire [4:0]  mem_wd_i;
wire        mem_wreg_i;
wire        mem_whilo_i;
wire [31:0]  mem_hi_i,mem_lo_i;

//连接访存阶段MEM模块的输出与MEM/WB模块的输入
wire [31:0] mem_wdata_o;
wire [4:0]  mem_wd_o;
wire        mem_wreg_o;
wire        mem_whilo_o;
wire [31:0] mem_hi_o,mem_lo_o;

//连接MEM/WB模块的输出与回写阶段的输入
wire [31:0] wb_wdata_i;
wire [4:0]  wb_wd_i;
wire        wb_wreg_i;
wire        wb_whilo_i;
wire [31:0]  wb_hi_i, wb_lo_i;

//流水线暂停控制信号
wire stallreq_from_id, stallreq_from_ex;
wire [5:0] stall;

//pc_reg实例化
pc_reg pc_reg0(
    .clk(clk), .rst(rst), .pc(pc), .ce(rom_ce_o) , .stall(stall)
);
assign rom_addr_o = pc;

//IF/ID模块实例化
if_id if_id0(
    .clk(clk), .rst(rst), .stall(stall),
    .if_pc(pc), .if_inst(rom_data_i),
     .id_pc(id_pc_i), .id_inst(id_inst_i)
    
);

//译码阶段ID模块实例化
id id0(
    .rst(rst),  
    .pc_i(id_pc_i), .inst_i(id_inst_i),
    
    //送到regfile的信息
    .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
    .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
    
    //来自regfile的输入
    .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),

    //数据前推->处于执行阶段的指令的运算结果
    .ex_wdata_i(ex_wdata_o), .ex_wd_i(ex_wd_o), .ex_wreg_i(ex_wreg_o),
    
    //数据前推->处于访存阶段的指令的运算结果
    .mem_wdata_i(mem_wdata_o), .mem_wd_i(mem_wd_o), .mem_wreg_i(mem_wreg_o),
    
    //送到ID/EX模块的信息
    .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
    .wd_o(id_wd_o), .wreg_o(id_wreg_o), .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),

    //流水线暂停请求
    .stallreq_from_id(stallreq_from_id)
    
);

//RegFile实例化
regfile regfile0(
    .clk(clk), .rst(rst),
    //写端口
    .wdata(wb_wdata_i), .waddr(wb_wd_i), .we(wb_wreg_i),
    //读端口1
    .rdata1(reg1_data), .raddr1(reg1_addr), .re1(reg1_read),
    .rdata2(reg2_data), .raddr2(reg2_addr), .re2(reg2_read)
);


//ID/EX模块实例化
id_ex id_ex0(
    .clk(clk), .rst(rst), .stall(stall),

    //从译码阶段ID模块传过来的信息
    .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
    .id_wd(id_wd_o), .id_wreg(id_wreg_o), 
    .id_alusel(id_alusel_o), .id_aluop(id_aluop_o),

    //传递到执行阶段EX模块的信息
    .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i),
    .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i),
    .ex_alusel(ex_alusel_i), .ex_aluop(ex_aluop_i)
);

//EX模块实例化
ex ex0(
    .rst(rst),

    //从ID/EX模块传递过来的信息
    .reg1_i(ex_reg1_i), .reg2_i(ex_reg2_i),
    .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
    .alusel_i(ex_alusel_i), .aluop_i(ex_aluop_i),

    //来自HI/LO模块的信息
    .hi_i(hi), .lo_i(lo),

    //HI/LO数据前推，来自访存阶段MEM模块的信息
    .mem_whilo_i(mem_whilo_o), .mem_hi_i(mem_hi_o), .mem_lo_i(mem_lo_o),
    
    //输出到EX/MEM模块的信息->通用寄存器
    .wdata_o(ex_wdata_o), .wd_o(ex_wd_o), .wreg_o(ex_wreg_o),
    //->HI/LO寄存器
    .whilo_o(ex_whilo_o), .hi_o(ex_hi_o), .lo_o(ex_lo_o),
    
    //连接EX/MEM模块的临时信号
    .hilo_temp_i(ex_hilo_temp_i), .cnt_i(ex_cnt_i),
    .hilo_temp_o(ex_hilo_temp_o), .cnt_o(ex_cnt_o),

    //流水线暂停请求
    .stallreq_from_ex(stallreq_from_ex)
);

//EX/MEM模块实例化
ex_mem ex_mem0(
    .clk(clk), .rst(rst), .stall(stall),

    //从执行阶段EX模块传递过来的信息
    .ex_wdata(ex_wdata_o), .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o),
    .ex_whilo(ex_whilo_o), .ex_hi(ex_hi_o), .ex_lo(ex_lo_o),

    //连接EX模块的临时信号
    .hilo_i(ex_hilo_temp_o), .cnt_i(ex_cnt_o),
    .hilo_o(ex_hilo_temp_i), .cnt_o(ex_cnt_i),

    //输出到MEM级的信息
    .mem_wdata(mem_wdata_i), .mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i),
    .mem_whilo(mem_whilo_i), .mem_hi(mem_hi_i), .mem_lo(mem_lo_i)
);

//MEM模块实例化
mem mem0(
    .rst(rst),

    //来自执行阶段的信息
    .wdata_i(mem_wdata_i), .wd_i(mem_wd_i), .wreg_i(mem_wreg_i),
    .whilo_i(mem_whilo_i), .hi_i(mem_hi_i), .lo_i(mem_lo_i),

    //输出到MEM/WB模块的信息
    .wdata_o(mem_wdata_o), .wd_o(mem_wd_o), .wreg_o(mem_wreg_o),
    .whilo_o(mem_whilo_o), .hi_o(mem_hi_o), .lo_o(mem_lo_o)
);

//MEM/WB模块实例化
mem_wb mem_wb0(
    .clk(clk), .rst(rst), .stall(stall),

    //来自访存阶段mem模块的信息
    .mem_wdata(mem_wdata_o), .mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),
    .mem_whilo(mem_whilo_o), .mem_hi(mem_hi_o), .mem_lo(mem_lo_o),

    //输出到写回阶段的信息
    .wb_wdata(wb_wdata_i), .wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i),
    .wb_whilo(wb_whilo_i), .wb_hi(wb_hi_i), .wb_lo(wb_lo_i)

);

hilo_reg hilo_reg0(
    .clk(clk), .rst(rst),

    //来自写回阶段的信息
    .we(wb_whilo_i), .hi_i(wb_hi_i), .lo_i(wb_lo_i),

    //送到执行阶段的信息
    .hi_o(hi), .lo_o(lo)
);

//流水线控制暂停模块
ctrl ctrl0(
    .rst(rst),
    .stallreq_from_id(stallreq_from_id), .stallreq_from_ex(stallreq_from_ex),
    .stall(stall)
);

endmodule // openmips