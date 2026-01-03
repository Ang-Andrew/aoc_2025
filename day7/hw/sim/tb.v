`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    wire [63:0] splitters_hit;
    wire [63:0] active_count;
    wire done;

    solution uut (
        .clk(clk),
        .rst(rst),
        .splitters_hit(splitters_hit),
        .active_count(active_count),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("build/wave.vcd");
        $dumpvars(0, tb);
        
        rst = 1;
        #100;
        rst = 0;
        
        wait(done);
        #100;
        
        $display("--------------------------------");
        $display("Simulation Done.");
        $display("Splitters Hit: %d", splitters_hit);
        $display("Active Beams (Bottom): %d", active_count);
        $display("--------------------------------");
        $finish;
    end
    
    initial begin
        #10000000;
        $display("Timeout!");
        $finish;
    end

endmodule
