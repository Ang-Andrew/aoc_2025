// Simple wrapper for cocotb testing of solver_v3
module top_tb(
    input clk,
    input rst,
    output [63:0] total_sum,
    output done
);

    solver_v3 #(
        .RESULTS_FILE("/workspace/day2/hw/src/results.hex"),  // Absolute path for Docker
        .ENTRY_COUNT(468)
    ) dut (
        .clk(clk),
        .rst(rst),
        .total_sum(total_sum),
        .done(done)
    );

endmodule
