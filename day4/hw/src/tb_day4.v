// Testbench for Day 4

`timescale 1ns/1ns

module tb_day4();

    reg clk;
    reg rst;
    wire [31:0] result_part1;
    wire [31:0] result_part2;
    wire done;

    top_day4 dut (
        .clk(clk),
        .rst(rst),
        .result_part1(result_part1),
        .result_part2(result_part2),
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

        // Wait for results
        wait(done);
        #10;

        // Verify results
        if (result_part1 == 32'd1424) begin
            $display("[PASS] Part 1: %0d (expected 1424)", result_part1);
        end else begin
            $display("[FAIL] Part 1: %0d (expected 1424)", result_part1);
        end

        if (result_part2 == 32'd8727) begin
            $display("[PASS] Part 2: %0d (expected 8727)", result_part2);
        end else begin
            $display("[FAIL] Part 2: %0d (expected 8727)", result_part2);
        end

        #10 $finish;
    end

    // Dump waveforms (optional)
    initial begin
        $dumpfile("day4_sim.vcd");
        $dumpvars(0, tb_day4);
    end

endmodule
