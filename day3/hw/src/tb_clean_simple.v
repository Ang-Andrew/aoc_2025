`timescale 1ns/1ps

module tb_clean_simple;

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
        // Synchronous reset
        rst = 1;
        cycle = 0;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        // Run for 250 cycles
        repeat(250) @(posedge clk);

        cycle = 250;

        $display("========================================");
        $display("Final Score (decimal): %0d", score);
        $display("Expected (decimal):    17092");
        $display("Hex: 0x%08X", score);
        $display("Expected Hex: 0x000042CC");
        $display("========================================");

        if (score == 32'd17092) begin
            $display("✓ TEST PASSED!");
            $finish;
        end else begin
            $display("✗ TEST FAILED");
            $display("Delta: %d", 17092 - score);
            $finish;
        end
    end

endmodule
