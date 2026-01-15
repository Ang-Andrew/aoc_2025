`timescale 1ns/1ps

module tb_gray_counter;

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
        // Reset
        rst = 1;
        #20;
        rst = 0;

        // Run for 600 cycles to process all 200 ROM entries + full pipeline drain
        repeat(600) #4;

        // Check result
        $display("Final Score: %d (0x%X)", score, score);
        if (score == 32'd16764) begin
            $display("✓ TEST PASSED");
            $finish;
        end else begin
            $display("✗ TEST FAILED - Expected 16764");
            $finish;
        end
    end

endmodule
