`timescale 1ns / 1ps

module tb_day1;

    reg clk;
    reg reset;
    reg valid_in;
    reg [271:0] flat_data;
    reg [15:0] valid_mask;
    
    wire [31:0] part1;
    wire [31:0] part2;

    day1_solver uut (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .flat_data(flat_data),
        .valid_mask(valid_mask),
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
        flat_data = 0;
        valid_mask = 0;
        #20;
        reset = 0;
        #10;
        
        // Example Sequence: L68, L30, R48, L5, R60, L55, L1, L99, R14, L82
        // L=0, R=1.
        // Pack into flat_data. Item 0 is LSB.
        // Item format: {dir, dist[15:0]} (17 bits)
        
        // 0: L68 -> 0 | 68 -> 0x00044
        // 1: L30 -> 0 | 30 -> 0x0001E
        // 2: R48 -> 1 | 48 -> 0x10030
        // 3: L5  -> 0 | 5  -> 0x00005
        // 4: R60 -> 1 | 60 -> 0x1003C
        // 5: L55 -> 0 | 55 -> 0x00037
        // 6: L1  -> 0 | 1  -> 0x00001
        // 7: L99 -> 0 | 99 -> 0x00063
        // 8: R14 -> 1 | 14 -> 0x1000E
        // 9: L82 -> 0 | 82 -> 0x00052
        // 10-15: 0
        
        flat_data = 0;
        // Construct vector manually or loop
        flat_data[17*0 +: 17] = 17'h00044;
        flat_data[17*1 +: 17] = 17'h0001E;
        flat_data[17*2 +: 17] = 17'h10030;
        flat_data[17*3 +: 17] = 17'h00005;
        flat_data[17*4 +: 17] = 17'h1003C;
        flat_data[17*5 +: 17] = 17'h00037;
        flat_data[17*6 +: 17] = 17'h00001;
        flat_data[17*7 +: 17] = 17'h00063;
        flat_data[17*8 +: 17] = 17'h1000E;
        flat_data[17*9 +: 17] = 17'h00052;
        
        valid_mask = 16'h03FF; // 10 valid
        valid_in = 1;
        
        #10;
        valid_in = 0;
        
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

endmodule
