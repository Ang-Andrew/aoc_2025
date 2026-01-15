`timescale 1ns/1ps

module tb_v4_debug;

    reg clk;
    reg rst;
    wire [31:0] score;

    top dut (
        .clk(clk),
        .rst(rst),
        .score(score)
    );

    // Expose internal signals for debugging
    wire [7:0] rom_addr = dut.rom_addr;
    wire read_enable = dut.read_enable;
    wire [31:0] rom_data = dut.rom_data;
    wire valid_stage1 = dut.valid_stage1;
    wire valid_stage2 = dut.valid_stage2;
    wire valid_stage3 = dut.valid_stage3;
    wire [31:0] accumulator = dut.accumulator;

    // Clock generation: 4ns period = 250MHz
    initial clk = 0;
    always #2 clk = ~clk;

    integer cycle_count;

    initial begin
        // Reset synchronously
        rst = 1;
        cycle_count = 0;

        // Wait for a clean clock edge after reset
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("Cyc | Addr | En | Rom_Data | V1 | V2 | V3 | Accum    | Score");
        $display("----|------|----|-----------|----|----|----|----------|----------");

        repeat(220) begin
            @(posedge clk);
            cycle_count = cycle_count + 1;
            if (cycle_count <= 15 || cycle_count >= 195) begin
                $display("%3d | %3d  | %d  | %8h | %d  | %d  | %d  | %8d | %8d",
                    cycle_count, rom_addr, read_enable, rom_data,
                    valid_stage1, valid_stage2, valid_stage3, accumulator, score);
            end
        end

        $display("----|------|----|-----------|----|----|----|----------|----------");
        $display("Final Score: %d (0x%X)", score, score);
        if (score == 32'd16764) begin
            $display("✓ TEST PASSED");
        end else begin
            $display("✗ TEST FAILED - Expected 16764");
        end
        $finish;
    end

endmodule
