`timescale 1ns/1ps

module tb;
    reg clk;
    reg rst;
    wire [63:0] total_sum;
    wire done;

    solver #(
        .MEM_FILE("src/mem.hex"), 
        // I will run from day2/hw so path is src/mem.hex?
        // Let's assume we run from day2/hw.
        .RANGE_COUNT(38),
        .MAX_K(12) // Limit was 2147483647 in py, k=10 is 10^10 range
                   // Input max is 9393974421 which is 10 digits
                   // So k=5 (5*2=10 digits) should be enough?
                   // No, MAX_K=9 covers up to 18 digits (9*2).
                   // Let's keep MAX_K=12 safe.
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
        $dumpfile("day2.vcd");
        $dumpvars(0, tb);
        rst = 1;
        #100;
        rst = 0;
        
        wait(done);
        #100;
        
        $display("Done. Total Sum: %0d (0x%h)", total_sum, total_sum);
        // Expected: 32976912643
        if (total_sum == 64'd32976912643) begin
             $display("SUCCESS: Sum matches expected.");
        end else begin
             $display("FAILURE: Sum mismatch. Expected 32976912643.");
        end
        $finish;
    end

endmodule
