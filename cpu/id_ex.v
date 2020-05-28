module id_ex(
    input clk,
    input rst,
    input [5:0] stall,
    //译码阶段的结果
    input [31:0] id_reg1,
    input [31:0] id_reg2,
    input [4:0]  id_wd,
    input id_wreg,
    input [2:0]id_alusel,
    input [7:0]id_aluop,

    //送到执行阶段的信息
    output reg[31:0] ex_reg1,
    output reg[31:0] ex_reg2,
    output reg[4:0] ex_wd,
    output reg ex_wreg,
    output reg[2:0]ex_alusel,
    output reg [7:0]ex_aluop,

    //跳转分支指令相关信号
    input id_is_in_delayslot,
    input [31:0] id_link_address,
    input next_inst_in_delayslot_i,
    output reg ex_is_in_delayslot,
    output reg [31:0] ex_link_address,
    output reg is_in_delayslot_o //返回给ID级的信号，表示指令处于分支延迟槽
);

always @(posedge clk ) begin
    if(rst) begin
       {ex_reg1, ex_reg2, ex_wd, ex_wreg , ex_alusel, ex_aluop} <= 0;
       {ex_is_in_delayslot,ex_link_address,is_in_delayslot_o} <= 0; 
    end
    else if (!stall[2])begin
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_wd <= id_wd;
        ex_wreg <= id_wreg;
        ex_alusel <= id_alusel;
        ex_aluop <= id_aluop;
        ex_is_in_delayslot <= id_is_in_delayslot;
        ex_link_address <= id_link_address;
        is_in_delayslot_o <= next_inst_in_delayslot_i;
    end else if(stall[2] && !stall[3]) begin
        {ex_reg1, ex_reg2, ex_wd,ex_wreg, ex_alusel, ex_aluop} <= 0;
        {ex_is_in_delayslot,ex_link_address,is_in_delayslot_o} <= 0; 
    end
       
end

endmodule // id_ex