// Testbench for Day 5

`timescale 1ns/1ns

module tb_day5();

    reg clk;
    reg rst;
    wire [31:0] result;
    wire done;

    top_day5 dut (
        .clk(clk),
        .rst(rst),
        .result(result),
        .done(done)
    );

    // Clock generation
    always begin
        #5 clk = ~clk;
    end

    initial begin
        // Initialize
        clk = 0;
        rst = 1;

        #20 rst = 0;

        // Wait for result
        wait(done);
        #10;

        // Verify result
        if (result == 32'd726) begin
            $display("[PASS] Day 5: %0d (expected 726)", result);
        end else begin
            $display("[FAIL] Day 5: %0d (expected 726)", result);
        end

        #10 $finish;
    end

    // Dump waveforms (optional)
    initial begin
        $dumpfile("day5_sim.vcd");
        $dumpvars(0, tb_day5);
    end

endmodule
