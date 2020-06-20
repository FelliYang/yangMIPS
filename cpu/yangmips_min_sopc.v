`include "defines.v"
module yangmips_min_sopc(
    input clk,
    input rst
);
//连接指令存储器
wire [`InstAddrBus] inst_addr;
wire [`InstBus] inst;
wire        rom_ce;
wire [`DataAddrBus] ram_addr;
wire [`DataBus] ram_data_i, ram_data_o;
wire ram_ce, ram_we;
wire [3:0] ram_sel;

wire [5:0] int;
wire timer_int;
assign int = {5'b0, timer_int};

//实例化处理器 openMips
yangmips yangmips0(
    .clk(clk), .rst(rst),
    .rom_addr_o(inst_addr), .rom_ce_o(rom_ce),
    .rom_data_i(inst),
	.ram_addr_o(ram_addr), .ram_data_o(ram_data_o),
	.ram_ce_o(ram_ce), .ram_we_o(ram_we),
	.ram_sel_o(ram_sel), .ram_data_i(ram_data_i),
	.int_i(int), .timer_int_o(timer_int)
);

//实例化指令存储器
inst_rom inst_rom0(
    .ce(rom_ce),
    .addr(inst_addr),
    .inst(inst)
);

//实例化数据存储器
data_ram data_ram0(
	.clk(clk), .ce(ram_ce),
	.data_i(ram_data_o), .addr(ram_addr),
	.we(ram_we), .sel(ram_sel),
	.data_o(ram_data_i)
);

endmodule // openmips_min_sopc