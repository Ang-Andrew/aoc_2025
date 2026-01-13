`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] total_sum;
    wire done;

    solver_v3 #(
        .RESULTS_FILE("src/results.hex"),
        .ENTRY_COUNT(468)
    ) dut (
        .clk(clk),
        .rst(rst),
        .total_sum(total_sum),
        .done(done)
    );

    initial begin
        clk = 0;
        forever #2 clk = ~clk;  // 250 MHz clock (4ns period)
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

        // Report performance
        $display("");
        $display("Performance at 250MHz:");
        $display("  Cycles: ~%0d", (468 + 6));
        $display("  Time: ~%0.2f us", (468.0 + 6.0) * 4.0 / 1000.0);

        $finish;
    end

endmodule
