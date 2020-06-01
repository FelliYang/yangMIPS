`include "defines.v"
module data_ram(
	input clk,
	input ce,
	input [`DataBus]	data_i, 
	input [`DataAddrBus] addr,
	input we,
	input [3:0]  sel,
	output reg [`DataBus] data_o
);

reg[7:0] data_mem0[0:`DataMemNum-1];
reg[7:0] data_mem1[0:`DataMemNum-1];
reg[7:0] data_mem2[0:`DataMemNum-1];
reg[7:0] data_mem3[0:`DataMemNum-1];


//写操作
always @(posedge clk) begin
	if(!ce) begin
	end else if(we)begin
		if(sel[3]) data_mem3[addr[`DataMemNumLog2+1:2]] <= data_i[31:24];
		if(sel[2]) data_mem2[addr[`DataMemNumLog2+1:2]] <= data_i[23:16];
		if(sel[1]) data_mem1[addr[`DataMemNumLog2+1:2]] <= data_i[15:8];
		if(sel[0]) data_mem0[addr[`DataMemNumLog2+1:2]] <= data_i[7:0];
	end
end

//读操作
always @(*) begin
	if(!ce) begin
		data_o = 0;
	end else if(!we) begin
		data_o = {data_mem3[addr[`DataMemNumLog2+1:2]],
				 data_mem2[addr[`DataMemNumLog2+1:2]],
				 data_mem1[addr[`DataMemNumLog2+1:2]],
				 data_mem0[addr[`DataMemNumLog2+1:2]]};
	end else data_o = 0;
end

endmodule // data_ram