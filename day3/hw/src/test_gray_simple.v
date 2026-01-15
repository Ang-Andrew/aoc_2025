`timescale 1ns/1ps

module test_gray;

    reg clk, rst;
    reg [7:0] gray_addr = 0;
    wire [7:0] binary_addr;

    function [7:0] gray_to_binary;
        input [7:0] gray;
        integer i;
        begin
            gray_to_binary[7] = gray[7];
            for (i = 6; i >= 0; i = i - 1)
                gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
        end
    endfunction

    function [7:0] increment_gray;
        input [7:0] gray;
        reg [8:0] bin;
        begin
            bin[8] = 1'b0;
            bin[7] = gray[7];
            bin[6:0] = gray[6:0] ^ {bin[7], bin[7:1]};
            bin = bin + 1;
            increment_gray[7] = bin[7];
            increment_gray[6:0] = bin[7:1] ^ bin[6:0];
        end
    endfunction

    assign binary_addr = gray_to_binary(gray_addr);

    initial clk = 0;
    always #2 clk = ~clk;

    initial begin
        rst = 1;
        #20;
        rst = 0;

        repeat(210) @(posedge clk) begin
            if (!rst && binary_addr < 200) begin
                gray_addr = increment_gray(gray_addr);
                $display("Cycle %3d: Gray=%3d Binary=%3d", $time/4, gray_addr, binary_addr);
            end
        end

        $finish;
    end

endmodule
