// Testbench for Day 4 ROM accumulator

`timescale 1ns/1ns

module tb_day4_rom();

    reg clk;
    reg rst;
    wire [31:0] result_part1;
    wire done;

    top_day4_rom dut (
        .clk(clk),
        .rst(rst),
        .result_part1(result_part1),
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

        // Wait for results (12224 cycles + pipeline delay)
        wait(done);
        #50;

        // Verify result
        if (result_part1 == 32'd1424) begin
            $display("[PASS] Day 4 Part 1: %0d (expected 1424)", result_part1);
        end else begin
            $display("[FAIL] Day 4 Part 1: %0d (expected 1424)", result_part1);
        end

        #10 $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("day4_rom_sim.vcd");
        $dumpvars(0, tb_day4_rom);
    end

endmodule
