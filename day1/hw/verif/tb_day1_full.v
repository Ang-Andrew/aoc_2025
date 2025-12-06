`timescale 1ns / 1ps

module tb_day1_full;

    reg clk;
    reg reset;
    
    // ROM Interface
    reg [12:0] rom_addr;
    wire [16:0] rom_data; // 16: Dir, 15-0: Dist
    
    // Solver Interface
    reg valid_in;
    wire [31:0] part1;
    wire [31:0] part2;
    
    // Control
    integer max_cycles = 4098;
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
        .direction(rom_data[16]),
        .distance(rom_data[15:0]),
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
        
        // Loop through all 4098 instructions
        // Pipeline:
        // Clock 0: valid_in=0, addr=0.
        // Clock 1: valid_in=1, data valid from ROM (addr 0).
        // Clock 2: valid_in=1, addr=1.
        
        // Wait for ROM to stabilize first data?
        // With synchronous ROM, addr->q takes 1 cycle.
        
        for (i = 0; i < 4098; i = i + 1) begin
            rom_addr = i;
            // Needed to fetch data
            #10; 
            
            // Now ROM data out is valid for instruction 'i'
            valid_in = 1;
            #10; // Execute solver for 1 cycle
            valid_in = 0;
            
            // Wait a cycle or just proceed?
            // Solver takes data on posedge where valid_in is high.
            // valid_in needs to be distinct pulses or held high?
            // Logic is: `else if (valid_in)`. If held high, it runs every cycle.
            // We want 1 step per instruction.
            // My loop structure above effectively creates valid pulses.
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
