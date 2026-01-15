`timescale 1ns/1ps

module tb_gray_counter_debug;

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

        repeat(250) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (cycle_count % 20 == 0) begin
                $display("Cycle %3d: Score = %d", cycle_count, score);
            end
        end

        $display("\nFinal: %d (0x%X)", score, score);
        if (score == 16764) begin
            $display("✓ TEST PASSED");
        end else begin
            $display("✗ TEST FAILED");
        end
        $finish;
    end

endmodule
