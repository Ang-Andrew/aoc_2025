`timescale 1ns/1ps

module tb_v4;

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

    integer cycle_count;

    initial begin
        // Reset
        rst = 1;
        cycle_count = 0;
        #20;
        rst = 0;
        #20;

        $display("Cycle |  Score   |  Hex");
        $display("------|----------|----------");

        repeat(220) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (cycle_count <= 10 || cycle_count % 20 == 0) begin
                $display("%5d | %8d | 0x%08x", cycle_count, score, score);
            end
        end

        $display("------|----------|----------");
        $display("Final: %d (0x%X)", score, score);

        if (score == 32'd16764) begin
            $display("✓ TEST PASSED - Score matches expected 16764");
            $finish;
        end else begin
            $display("✗ TEST FAILED - Expected 16764, got %d", score);
            $finish;
        end
    end

endmodule
