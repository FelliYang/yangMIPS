module mem(
    input rst,
    
    //来自执行级的信息
    input [4:0]wd_i,
    input [31:0]wdata_i,
    input       wreg_i,
    input       whilo_i,
    input [31:0] hi_i,lo_i,
    
    //访存阶段的结果
    output reg [4:0] wd_o,
    output reg[31:0] wdata_o,
    output reg      wreg_o,
    output reg      whilo_o,
    output reg [31:0]  hi_o, lo_o

);
    //组合逻辑
    always @(*) begin
        if(rst) {wd_o,wdata_o,wreg_o,whilo_o,hi_o,lo_o} = 0;
        else begin
            wd_o = wd_i;
            wdata_o = wdata_i;
            wreg_o = wreg_i;
            whilo_o = whilo_i;
            hi_o = hi_i;
            lo_o = lo_i;
        end
    end


endmodule // mem