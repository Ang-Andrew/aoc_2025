`timescale 1ns/1ps

module tb_top_debug;

    reg clk = 0;
    always #2 clk = ~clk;

    reg rst = 1;
    wire [31:0] score;

    top dut (
        .clk(clk),
        .rst(rst),
        .score(score)
    );

    initial begin
        @(posedge clk);
        rst = 0;

        $display("Cyc | ROM_counter | ROM_data | rom_data_delayed | Score");
        $display("----|-------------|----------|-----------------|--------");

        repeat(210) begin
            @(posedge clk);
            $display("%3d | %11d | %8d | %15d | %8d",
                $time/4, dut.rom_counter, dut.rom_data,
                dut.rom_data_delayed, score);

            if (dut.rom_counter >= 200) begin
                $display("Done. Final Score: %d", score);
                $finish;
            end
        end

        $finish;
    end

endmodule
