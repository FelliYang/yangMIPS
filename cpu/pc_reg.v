`include "defines.v"
module pc_reg(
    input                       clk,
    input                       rst,
    input   [5:0]               stall,                
    output  reg [31:0]           pc,
    output   reg                 ce,  

    //ID阶段译码跳转分支指令产生的相关信号
    input [31:0] branch_target_address_i, //跳转目标地址
    input       branch_flag_i //跳转标志
);
    always @(posedge clk) begin
        if(rst) begin
            ce <= 0;
        end else begin
            ce <= 1;
        end
    end

    always @(posedge clk) begin
        if(!ce) pc <= 32'h00000000;
        else if(!stall[0]) begin
            if(branch_flag_i) //跳转到目标地址
                pc <= branch_target_address_i;
            else pc <= pc + 32'h4;
        end
            
    end

endmodule // pc_reg