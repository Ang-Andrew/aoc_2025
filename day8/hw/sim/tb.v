`timescale 1ns / 1ps

module tb;

    reg clk;
    reg rst;
    wire [63:0] product_max;
    wire done;

    solution uut (
        .clk(clk),
        .rst(rst),
        .product_max(product_max),
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
        $display("Max Product: %d", product_max);
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
