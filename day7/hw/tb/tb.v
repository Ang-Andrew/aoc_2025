`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] splitters_hit;
    wire done;

    solution dut (
        .clk(clk),
        .rst(rst),
        .splitters_hit(splitters_hit),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("day7.vcd");
        $dumpvars(0, tb);
        
        rst = 1;
        #20;
        rst = 0;
        
        wait(done);
        #50;
        
        $display("Done. Splitters: %d", splitters_hit);
        $finish;
    end

endmodule
