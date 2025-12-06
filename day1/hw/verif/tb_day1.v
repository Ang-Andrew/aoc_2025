`timescale 1ns / 1ps

module tb_day1;

    reg clk;
    reg reset;
    reg valid_in;
    reg direction;
    reg [15:0] distance;
    
    wire [31:0] part1;
    wire [31:0] part2;

    day1_solver uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .direction(direction),
        .distance(distance),
        .part1_count(part1),
        .part2_count(part2)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test sequence
    initial begin
        $dumpfile("day1.vcd");
        $dumpvars(0, tb_day1);
        
        reset = 1;
        valid_in = 0;
        #20;
        reset = 0;
        #10;
        
        // Example Sequence from Prompt:
        // L68, L30, R48, L5, R60, L55, L1, L99, R14, L82
        // Start 50.
        // Expected Part 1: 3
        // Expected Part 2: 6
        
        // 1. L68 (Left=0)
        send_cmd(0, 68); 
        // 2. L30
        send_cmd(0, 30);
        // 3. R48 (Right=1)
        send_cmd(1, 48);
        // 4. L5
        send_cmd(0, 5);
        // 5. R60
        send_cmd(1, 60);
        // 6. L55
        send_cmd(0, 55);
        // 7. L1
        send_cmd(0, 1);
        // 8. L99
        send_cmd(0, 99);
        // 9. R14
        send_cmd(1, 14);
        // 10. L82
        send_cmd(0, 82);
        
        #50;
        
        $display("Final Results:");
        $display("Part 1: %d (Expected 3)", part1);
        $display("Part 2: %d (Expected 6)", part2);
        
        if (part1 == 3 && part2 == 6)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");
            
        $finish;
    end

    task send_cmd(input dir, input [15:0] dist);
        begin
            direction = dir;
            distance = dist;
            valid_in = 1;
            #10; // Wait one clock cycle
            valid_in = 0;
            #10; // Gap
        end
    endtask

endmodule
