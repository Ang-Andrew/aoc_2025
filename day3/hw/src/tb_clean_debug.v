`timescale 1ns/1ps

module tb_clean_debug;

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

        $display("Cycle | ROM_data | ROM_val_r1 | Score");
        $display("------|----------|-----------|--------");

        repeat(25) begin
            @(posedge clk);
            cycle = cycle + 1;
            if (cycle <= 10 || cycle >= 20) begin
                $display("%5d | %8d | %d | %d", cycle, dut.rom_data, dut.rom_valid_r1, score);
            end
        end

        $display("------|----------|-----------|--------");
        $display("\nFinal Score: %d (expected 17092)", score);
        $finish;
    end

endmodule
