`timescale 1ns/1ps

module tb_clean_v1;

    reg clk;
    reg rst;
    wire [31:0] score;

    top dut (
        .clk(clk),
        .rst(rst),
        .score(score)
    );

    // Clock: 250MHz = 4ns period
    initial clk = 0;
    always #2 clk = ~clk;

    integer cycle;

    initial begin
        $display("====================================================");
        $display("Day 3: ROM-based Accumulator Test");
        $display("====================================================");

        // Synchronous reset
        rst = 1;
        cycle = 0;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Run the accumulation
        // ROM reads: cycles 1-200 (with read_active for 200 cycles)
        // Pipeline depth: 4 stages
        // Total time needed: 200 (read) + 4 (pipeline drain) = 204 cycles
        // Add margin: 220 cycles total

        $display("\nCycle | Score (Hex)");
        $display("-------|------------");

        repeat(250) begin
            @(posedge clk);
            cycle = cycle + 1;

            // Print every 20 cycles or early cycles
            if (cycle <= 5 || cycle % 20 == 0) begin
                $display("%5d | 0x%08X (%d)", cycle, score, score);
            end
        end

        $display("-------|------------");
        $display("\nFinal Result: %d (0x%X)", score, score);
        $display("Expected:    17092 (0x42CC)");

        if (score == 32'd17092) begin
            $display("✓ TEST PASSED!");
            $finish;
        end else begin
            $display("✗ TEST FAILED - Got %d instead of 17092", score);
            $display("Error: %d", 17092 - score);
            $finish;
        end
    end

endmodule
