`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] total_presses;
    wire done;

    solution dut (
        .clk(clk),
        .rst(rst),
        .total_presses(total_presses),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("day10.vcd");
        $dumpvars(0, tb);
        
        rst = 1;
        #20;
        rst = 0;
        
        wait(done);
        #50;
        
        $display("Done. Total Presses: %d", total_presses);
        $finish;
    end

endmodule
