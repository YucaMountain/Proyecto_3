`timescale 1ns / 1ps

module m1_clk_divider_tb;

    reg clk_in;
    reg rst_n;
    wire clk_out;

    parameter COUNTER_MAX_TB = 5;

    m1_clk_divider #(
        .COUNTER_MAX(COUNTER_MAX_TB)
    ) dut (
        .clk_in (clk_in),
        .rst_n  (rst_n),
        .clk_out(clk_out)
    );

    initial begin
        clk_in = 1'b0;
        forever #5 clk_in = ~clk_in;
    end

    initial begin
        $display("=== Iniciando m1_clk_divider_tb ===");
        $dumpfile("m1_clk_divider_tb.vcd");
        $dumpvars(0, m1_clk_divider_tb);

        rst_n = 1'b0;
        #20;
        rst_n = 1'b1;

        #300;

        $display("=== Fin m1_clk_divider_tb ===");
        $finish;
    end

endmodule
