`timescale 1ns/1ps

module tb_minimal;

    reg clk = 0;
    always #2 clk = ~clk;

    wire [31:0] data;
    rom_hardcoded rom(
        .addr(0),
        .data(data)
    );

    initial begin
        #10;
        $display("ROM[0] = %d (0x%X)", data, data);
        $display("Expected: 76 (0x0000004C)");
        $finish;
    end

endmodule
