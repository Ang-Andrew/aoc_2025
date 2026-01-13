`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] total_sum;
    wire done;

    solver_ultra #(
        .DIVISIONS_FILE("src/divisions.hex"),
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

    // Monitor stage 8 output
    integer contrib_count;
    reg [63:0] manual_sum;
    always @(posedge clk) begin
        if (rst) begin
            contrib_count = 0;
            manual_sum = 0;
        end else if (dut.stage8_valid) begin
            contrib_count = contrib_count + 1;
            manual_sum = manual_sum + dut.stage8_result;
            if (contrib_count <= 5) begin
                $display("Contrib %0d: %0d, manual_sum=%0d", contrib_count, dut.stage8_result, manual_sum);
            end
        end
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;
        
        wait(done);
        #100;
        
        $display("Done. Total Sum: %0d (0x%h)", total_sum, total_sum);
        $display("Manual sum from stage8: %0d", manual_sum);
        $display("Contrib count: %0d", contrib_count);
        // Expected: 32976912643
        if (total_sum == 64'd32976912643) begin
             $display("SUCCESS: Sum matches expected.");
        end else begin
             $display("FAILURE: Sum mismatch. Expected 32976912643.");
             $display("Ratio: got/expected = %0f", $itor(total_sum) / 32976912643.0);
        end
        $finish;
    end

endmodule
