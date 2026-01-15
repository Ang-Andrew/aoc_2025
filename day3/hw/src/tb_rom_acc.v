`timescale 1ns/1ps

module tb_rom_acc;

    reg clk;
    reg rst;
    wire [31:0] score;

    top dut (
        .clk(clk),
        .rst(rst),
        .score(score)
    );

    // Clock generation: period = 4ns (250 MHz)
    initial clk = 0;
    always #2 clk = ~clk;

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_rom_acc);

        // Reset
        rst = 1;
        #10;
        rst = 0;
        #10;

        // Run for enough cycles: 201 iterations * 4ns + margin = 810 + 100 = 910ns
        // With #2 clk period (500 MHz equivalent), we need ~455 cycles
        // Run for 600 cycles to be safe
        repeat (600) @(posedge clk);

        $display("Final Total Score: %d", score);
        $finish;
    end

endmodule
