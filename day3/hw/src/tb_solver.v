`timescale 1ns/1ps

module tb_solver;

    reg clk;
    reg reset;
    reg [7:0] char_in;
    reg valid_in;
    wire [31:0] total_joltage;

    // Memory for input
    reg [7:0] memory [0:32767]; // Increased size for real input
    integer mem_size;
    integer i;

    solver dut (
        .clk(clk),
        .reset(reset),
        .char_in(char_in),
        .valid_in(valid_in),
        .total_joltage(total_joltage)
    );

    // Clock generation
    initial clk = 0;
    always #2 clk = ~clk; // 250MHz = 4ns period, toggle every 2ns? No, #2 is 2 units.
    // If unit is 1ns, #2 is 2ns. Period 4ns => 250 MHz.

    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_solver);

        // Load memory
        $readmemh("../input/input.hex", memory);
        
        // Reset
        reset = 1;
        valid_in = 0;
        char_in = 0;
        #10;
        reset = 0;
        #10;

        // Valid bytes in hex file counting loop
        // We assume the memory is zero-initialized or we stop at a large number
        // Just loop a reasonable amount or find end.
        // For simplicity, let's just loop 1000 or until 0?
        // readmemh might accept bounds.
        
        // Valid bytes in hex file counting loop
        // We assume the memory is zero-initialized or we stop at a large number
        @(posedge clk); // Align to clock
        
        for (i = 0; i < 32768; i = i + 1) begin
            if (memory[i] === 8'hxx) begin
                // Stop if undefined (end of file usually)
                 i = 32768;
            end else begin
                char_in <= memory[i];
                valid_in <= 1;
                @(posedge clk);
            end
        end
        
        // Clear valid after loop
        valid_in <= 0;
        @(posedge clk);
        
        #50;
        $display("Final Total Joltage: %d", total_joltage);
        if (total_joltage == 17092) begin
            $display("SUCCESS: Matches Ground Truth");
        end else begin
            $display("FAILURE: Expected 17092, got %d", total_joltage);
        end
        
        $finish;
    end

endmodule
