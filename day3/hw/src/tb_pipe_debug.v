`timescale 1ns/1ps

module tb_pipe_debug;

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

        $display("Cyc | rom_data_r1 | sum_low_r2 | rom_valid_r3 | accum_r3 | score");
        $display("----|-------------|-----------|--------------|----------|--------");

        repeat(15) begin
            @(posedge clk);
            cycle = cycle + 1;
            $display("%3d | %11d | %9d | %12d | %8d | %8d",
                cycle,
                dut.rom_data_r1,
                dut.sum_low_r2,
                dut.rom_valid_r3,
                dut.accum_r3,
                score);
        end

        $display("----|-------------|-----------|--------------|----------|--------");
        $finish;
    end

endmodule
