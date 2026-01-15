`timescale 1ns/1ps

module tb_v4_final;

    reg clk;
    reg rst;
    wire [31:0] score;

    top dut (
        .clk(clk),
        .rst(rst),
        .score(score)
    );

    // Clock generation: 4ns period = 250MHz
    initial clk = 0;
    always #2 clk = ~clk;

    initial begin
        // Synchronous reset
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Wait for 210 cycles:
        // - 200 ROM reads (cycles 0-199)
        // - 1 extra for ROM latency (cycle 200)
        // - 3+ cycles for pipeline to drain (stages 1,2,3)
        repeat(210) @(posedge clk);

        $display("Final Score: %d (0x%X)", score, score);
        if (score == 32'd16764) begin
            $display("✓ TEST PASSED");
        end else begin
            $display("✗ TEST FAILED - Expected 16764");
        end
        $finish;
    end

endmodule
