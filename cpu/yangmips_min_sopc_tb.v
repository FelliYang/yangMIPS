`timescale  1ns/1ps
module yangmips_min_sopc_tb();
    reg  CLOCK_50;
    reg     rst;

    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;    
    end
    
    initial begin
        rst = 1;
        #195 rst = 0;
        #1000 $stop;
    end

    //实例化
    yangmips_min_sopc yangmips_min_sopc0(
        .clk(CLOCK_50), .rst(rst)
    );
endmodule // openmips_min_sopc