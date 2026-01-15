`timescale 1ns/1ps

module tb_top_simple;

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
        @(posedge clk);

        repeat(250) @(posedge clk);

        $display("Score: %d", score);
        if (score == 17092) begin
            $display("PASS");
        end else begin
            $display("FAIL - expected 17092");
        end
        $finish;
    end

endmodule
