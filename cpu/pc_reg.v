`include "defines.v"
module pc_reg(
    input                       clk,
    input                       rst,
    input   [5:0]               stall,                
    output  reg [31:0]           pc,
    output   reg                 ce,  //指令片选信号

    //ID阶段译码跳转分支指令产生的相关信号
    input [31:0] branch_target_address_i, //跳转目标地址
    input       branch_flag_i, //跳转标志

	//MEM阶段产生的异常地址
	input flush,
	input [31:0] new_pc
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
		else if(flush==1) begin //产生异常
			pc <= new_pc; //跳转到异常地址
		end
        else if(!stall[0]) begin
            if(branch_flag_i) //跳转到目标地址
                pc <= branch_target_address_i;
            else pc <= pc + 32'h4;
        end
            
    end

endmodule // pc_reg