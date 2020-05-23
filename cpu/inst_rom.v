`include "defines.v"
module inst_rom(
    input ce,
    input [31:0]    addr,
    output reg [31:0]   inst
);
    //定义指令数组 大小是InstMemNum - 1 元素宽度是32
    reg[31:0] inst_mem[0:`InstMemNum - 1];

    //使用文件 inst_rom.data 初始化指令存储器
    initial $readmemh("inst_rom.data", inst_mem);

    always @(*) begin
        if(ce == 0) inst = 0;
        else inst = inst_mem[addr[`InstMemNumLog2+1:2]];
    end

endmodule // inst_rom