`timescale 1ns / 1ps

module tb_day1_full;

    reg clk;
    reg reset;
    
    // ROM Interface
    reg [12:0] rom_addr;
    wire [271:0] rom_data; 
    
    // Solver Interface
    reg valid_in;
    wire [31:0] part1;
    wire [31:0] part2;
    
    // Control
    integer max_cycles = 257; // 4098 / 16 ceiling
    integer i;

    // Instantiate Modules
    input_rom #(
        .FILENAME("data/input.hex")
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    day1_solver solver_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .flat_data(rom_data),
        .valid_mask(16'hFFFF), // always valid mask for simplified test
        .part1_count(part1),
        .part2_count(part2)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("day1_full.vcd");
        $dumpvars(0, tb_day1_full);
        
        reset = 1;
        valid_in = 0;
        rom_addr = 0;
        #20;
        reset = 0;
        #20;
        
        // Loop through approx 257 batches
        for (i = 0; i < max_cycles; i = i + 1) begin
            rom_addr = i;
            #10; 
            
            valid_in = 1;
            #10; 
            valid_in = 0;
        end
        
        #100;
        $display("-------------------------------------------");
        $display("FINAL ANSWERS");
        $display("-------------------------------------------");
        $display("Part 1: %d", part1);
        $display("Part 2: %d", part2);
        $display("-------------------------------------------");
        $finish;
    end

endmodule
