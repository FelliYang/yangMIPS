`include "defines.v"
module pc_reg(
    input                       clk,
    input                       rst,
    input   [5:0]               stall,                
    output  reg [31:0]           pc,
    output   reg                 ce  
);
    always @(posedge clk) begin
        if(rst==`RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    always @(posedge clk) begin
        if(ce==`ChipDisable) pc <= 32'h00000000;
        else if(!stall[0])
            pc <= pc + 32'h4;
    end

endmodule // pc_reg