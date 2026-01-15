`timescale 1ns/1ps

module test_rom_only;

    reg clk, rst;
    reg [7:0] addr = 0;
    wire [31:0] data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(addr),
        .data(data)
    );

    initial clk = 0;
    always #2 clk = ~clk;

    initial begin
        // Read ROM addresses 0-5
        repeat(10) begin
            @(posedge clk);
            $display("Addr=%d, Data=%8h (%d)", addr, data, data);
            addr = addr + 1;
        end
        $finish;
    end

endmodule
