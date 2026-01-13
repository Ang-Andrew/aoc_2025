`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] total_sum;
    wire done;

    solver_v2 #(
        .DIVISIONS_FILE("src/divisions_v2.hex"),
        .ENTRY_COUNT(468)
    ) dut (
        .clk(clk),
        .rst(rst),
        .total_sum(total_sum),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #20 clk = ~clk;
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;

        wait(done);
        #100;

        $display("Done. Total Sum: %0d (0x%h)", total_sum, total_sum);
        if (total_sum == 64'd32976912643) begin
             $display("SUCCESS: Sum matches expected.");
        end else begin
             $display("FAILURE: Sum mismatch. Expected 32976912643.");
        end
        $finish;
    end

endmodule
