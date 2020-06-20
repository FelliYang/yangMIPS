`include "defines.v"
module yangmips_min_sopc(
    input clk,
    input rst
);

wire [5:0] int;
wire timer_int;
assign int = {5'b0, timer_int};

//实例化处理器 openMips
yangmips yangmips0(
    .clk(clk), .rst(rst),
	.int_i(int), .timer_int_o(timer_int)
);



endmodule // openmips_min_sopc