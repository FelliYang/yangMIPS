module id_ex(
    input clk,
    input rst,

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
    output reg [7:0]ex_aluop
);

always @(posedge clk ) begin
    if(rst == 1) {ex_reg1, ex_reg2, ex_wd, ex_wreg , ex_alusel, ex_aluop} <= 0;
    else begin
        ex_reg1 <= id_reg1;
        ex_reg2 <= id_reg2;
        ex_wd <= id_wd;
        ex_wreg <= id_wreg;
        ex_alusel <= id_alusel;
        ex_aluop <= id_aluop;
    end
end

endmodule // id_ex