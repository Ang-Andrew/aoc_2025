`timescale 1ns/1ps

module tb_solver;

    reg clk;
    reg rst;
    reg valid_in;
    reg [511:0] data_in;
    reg [127:0] mask_in;
    wire [31:0] total_score;
    wire done;

    // Memory for input (Wide)
    reg [639:0] memory [0:255]; 
    integer i;

    tree_solver dut (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_in),
        .data_in(data_in),
        .mask_in(mask_in),
        .total_score(total_score),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #2 clk = ~clk; 

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_solver);

        // Load memory
        $readmemh("data/input.hex", memory);
        
        // Reset
        rst = 1;
        valid_in = 0;
        data_in = 0;
        mask_in = 0;
        #10;
        rst = 0;
        #10;

        @(posedge clk); 
        
        // Loop through loaded vectors
        for (i = 0; i < 200; i = i + 1) begin
             // Check if data is valid (mask check) or just run fixed size?
             // Memory initialized to X or 0? 
             // We can check if memory[i] is X.
             if (memory[i][0] === 1'bx) begin
                 // Skip
             end else begin
                 data_in <= memory[i][511:0];
                 mask_in <= memory[i][639:512];
                 valid_in <= 1;
                 @(posedge clk);
             end
        end
        
        valid_in <= 0;
        @(posedge clk);
        
        // Wait for pipeline to drain (7 stages)
        #100;
        
        $display("Final Total Score: %d", total_score);
        // Expected value depends on input. For AoC Day 3 Input, reference is needed.
        // Assuming user knows the reference (e.g. 17092 was for old logic/input).
        // Let's just output it.
        
        $finish;
    end

endmodule
