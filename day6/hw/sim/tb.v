`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    wire [63:0] count;
    wire done;

    solution uut (
        .clk(clk),
        .rst(rst),
        .count(count),
        .done(done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $dumpfile("build/wave.vcd");
        $dumpvars(0, tb);
        // Dump array if needed: $dumpvars(1, uut.mem);

        rst = 1;
        #100;
        rst = 0;
        
        wait(done);
        #100;
        
        $display("--------------------------------");
        $display("Simulation Done.");
        $display("Result Count: %d", count);
        $display("--------------------------------");
        $finish;
    end
    
    // Watchdog
    initial begin
        #10000000;
        $display("Timeout!");
        $finish;
    end

endmodule
