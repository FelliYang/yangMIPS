module yangmips_min_sopc(
    input clk,
    input rst
);
//连接指令存储器
wire [31:0] inst_addr;
wire [31:0] inst;
wire        rom_ce;

//实例化处理器 openMips
yangmips yangmips0(
    .clk(clk), .rst(rst),
    .rom_addr_o(inst_addr), .rom_ce_o(rom_ce),
    .rom_data_i(inst)
);

//实例指令存储器
inst_rom inst_rom0(
    .ce(rom_ce),
    .addr(inst_addr),
    .inst(inst)
);

endmodule // openmips_min_sopc