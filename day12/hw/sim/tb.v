`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    wire [63:0] total_count;
    wire done;

    solution uut (
        .clk(clk),
        .rst(rst),
        .total_count(total_count),
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
        $display("Valid Regions: %d", total_count);
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
