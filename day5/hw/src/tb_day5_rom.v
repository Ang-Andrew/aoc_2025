// Testbench for Day 5 ROM accumulator

`timescale 1ns/1ns

module tb_day5_rom();

    reg clk;
    reg rst;
    wire [31:0] result;
    wire done;

    top_day5_rom dut (
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

        // Wait for result (1000 cycles + pipeline delay)
        wait(done);
        #50;

        // Verify result
        if (result == 32'd726) begin
            $display("[PASS] Day 5: %0d (expected 726)", result);
        end else begin
            $display("[FAIL] Day 5: %0d (expected 726)", result);
        end

        #10 $finish;
    end

    // Dump waveforms
    initial begin
        $dumpfile("day5_rom_sim.vcd");
        $dumpvars(0, tb_day5_rom);
    end

endmodule
