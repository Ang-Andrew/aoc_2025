`timescale 1ns/1ps

module test_increment;

    function [7:0] increment_gray;
        input [7:0] gray;
        reg [8:0] bin;
        integer i;
        begin
            // Convert Gray to binary
            bin[8] = 1'b0;
            bin[7] = gray[7];
            for (i = 6; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            // Increment binary
            bin = bin + 1;
            // Convert binary back to Gray
            increment_gray[7] = bin[7];
            for (i = 6; i >= 0; i = i - 1)
                increment_gray[i] = bin[i+1] ^ bin[i];
        end
    endfunction

    initial begin
        $display("Testing increment_gray:");
        $display("0 -> %d", increment_gray(0));
        $display("1 -> %d", increment_gray(1));
        $display("3 -> %d", increment_gray(3));
        $display("2 -> %d", increment_gray(2));
        $finish;
    end

endmodule
