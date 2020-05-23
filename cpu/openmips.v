module openmips(
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

//连接执行阶段EX模块的输出与EX/MEM模块的输入
wire [31:0] ex_wdata_o;
wire [4:0]  ex_wd_o;
wire        ex_wreg_o;

//连接EX/MEM模块的输出与访存阶段MEM模块的输入
wire [31:0] mem_wdata_i;
wire [4:0]  mem_wd_i;
wire        mem_wreg_i;

//连接访存阶段MEM模块的输出与MEM/WB模块的输入
wire [31:0] mem_wdata_o;
wire [4:0]  mem_wd_o;
wire        mem_wreg_o;

//连接MEM/WB模块的输出与回写阶段的输入
wire [31:0] wb_wdata_i;
wire [4:0]  wb_wd_i;
wire        wb_wreg_i;
//pc_reg实例化
pc_reg pc_reg0(
    .clk(clk), .rst(rst), .pc(pc), .ce(rom_ce_o)
);
assign rom_addr_o = pc;

//IF/ID模块实例化
if_id if_id0(
    .clk(clk), .rst(rst), .if_pc(pc),
    .if_inst(rom_data_i), .id_pc(id_pc_i), .id_inst(id_inst_i)
);

//译码阶段ID模块实例化
id id0(
    .rst(rst), .pc_i(id_pc_i), .inst_i(id_inst_i),
    
    //送到regfile的信息
    .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),
    .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
    
    //来自regfile的输入
    .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
    
    //送到ID/EX模块的信息
    .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
    .wd_o(id_wd_o), .wreg_o(id_wreg_o), .reg1_o(id_reg1_o), .reg2_o(id_reg2_o)
    
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
    .clk(clk), .rst(rst),

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
    
    //输出到EX/MEM模块的信息
    .wdata_o(ex_wdata_o), .wd_o(ex_wd_o), .wreg_o(ex_wreg_o)
);

//EX/MEM模块实例化
ex_mem ex_mem0(
    .clk(clk),
    .rst(rst),

    //从执行阶段EX模块传递过来的信息
    .ex_wdata(ex_wdata_o), .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o),

    //输出到MEM级的信息
    .mem_wdata(mem_wdata_i), .mem_wd(mem_wd_i), .mem_wreg(mem_wreg_i)
);

//MEM模块实例化
mem mem0(
    .rst(rst),

    //来自执行阶段的信息
    .wdata_i(mem_wdata_i), .wd_i(mem_wd_i), .wreg_i(mem_wreg_i),

    //输出到MEM/WB模块的信息
    .wdata_o(mem_wdata_o), .wd_o(mem_wd_o), .wreg_o(mem_wreg_o)
);

//MEM/WB模块实例化
mem_wb mem_wb0(
    .clk(clk), .rst(rst),

    //来自访存阶段mem模块的信息
    .mem_wdata(mem_wdata_o), .mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),

    //输出到写回阶段的信息
    .wb_wdata(wb_wdata_i), .wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i)

);

endmodule // openmips