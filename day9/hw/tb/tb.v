`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] max_area;
    wire done;

    solution dut (
        .clk(clk),
        .rst(rst),
        .max_area(max_area),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("day9.vcd");
        $dumpvars(0, tb);
        
        rst = 1;
        #20;
        rst = 0;
        
        wait(done);
        #50;
        
        $display("Done. Max Area: %d", max_area);
        $finish;
    end

endmodule
