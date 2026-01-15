`timescale 1ns/1ps

module tb_accum_test;

    reg clk = 0;
    always #2 clk = ~clk;

    reg rst = 1;
    reg [8:0] counter = 0;
    reg [31:0] sum = 0;
    wire [31:0] rom_data;

    rom_hardcoded rom(
        .addr(counter[7:0]),
        .data(rom_data)
    );

    initial begin
        @(posedge clk);
        rst = 0;

        $display("Cyc | Counter | ROM_data | Sum");
        $display("----|---------|----------|--------");

        repeat(210) begin
            @(posedge clk);
            if (counter < 200) begin
                sum = sum + rom_data;
                counter = counter + 1;
                if (counter <= 5 || counter >= 195) begin
                    $display("%3d | %7d | %8d | %8d", $time/4, counter, rom_data, sum);
                end
            end
        end

        $display("----|---------|----------|--------");
        $display("Final Sum: %d (expected 17092)", sum);
        $finish;
    end

endmodule
