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

    // Monitor stage 3 (sum and count)
    integer stage3_count;
    always @(posedge clk) begin
        if (rst) begin
            stage3_count = 0;
        end else if (dut.stage3_valid && stage3_count < 3) begin
            stage3_count = stage3_count + 1;
            $display("Stage3 Entry %0d: sum=%0d count=%0d", stage3_count, dut.stage3_sum, dut.stage3_count);
        end
    end

    // Monitor stage 5 (after first mult)
    integer mult1_count;
    always @(posedge clk) begin
        if (rst) begin
            mult1_count = 0;
        end else if (dut.stage5_valid && mult1_count < 3) begin
            mult1_count = mult1_count + 1;
            $display("Stage5 Entry %0d: mult1=%0d const_k=%0d", mult1_count, dut.stage5_mult1, dut.stage5_const_k);
        end
    end

    // Monitor stage 7 (before divide by 2)
    integer contrib_count;
    always @(posedge clk) begin
        if (rst) begin
            contrib_count = 0;
        end else if (dut.stage7_valid && contrib_count < 3) begin
            contrib_count = contrib_count + 1;
            $display("Stage7 Entry %0d: mult2=%0d result=%0d", contrib_count, dut.stage7_mult2, dut.stage7_mult2[64:1]);
        end
    end

    initial begin
        rst = 1;
        #100;
        rst = 0;

        wait(done);
        #100;

        $display("Final Total Sum: %0d", total_sum);
        if (total_sum == 64'd32976912643) begin
             $display("SUCCESS");
        end else begin
             $display("FAILURE: Expected 32976912643");
        end
        $finish;
    end

endmodule
