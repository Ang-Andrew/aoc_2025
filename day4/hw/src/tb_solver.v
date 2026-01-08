`timescale 1ns/1ps

module tb_solver;

    reg clk;
    reg reset;
    reg [7:0] char_in;
    reg valid_in;
    wire [31:0] total_accessible;

    // Memory for input
    reg [7:0] memory [0:65535]; // Large enough for input
    integer i;

    solver dut (
        .clk(clk),
        .reset(reset),
        .char_in(char_in),
        .valid_in(valid_in),
        .total_accessible(total_accessible)
    );

    // Clock generation
    initial clk = 0;
    always #2 clk = ~clk;

    // Cycle counting
    integer cycles;
    initial cycles = 0;
    always @(posedge clk) cycles = cycles + 1;

    initial begin
        $dumpfile("day4.vcd");
        $dumpvars(0, tb_solver);

        // Initialize memory to X

        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end

        // Load memory
        $readmemh("../input/input.hex", memory);
        
        #10;

        // Reset
        reset = 1;
        valid_in = 0;
        char_in = 0;
        #10;
        reset = 0;
        #10;

        @(posedge clk);
        


        // Feed input
        for (i = 0; i < 18905; i = i + 1) begin
            char_in <= memory[i];
            valid_in <= 1;
            @(posedge clk);
            // Optional: Insert bubble to test stalling/bubbles
            // valid_in <= 0;
            // char_in <= 0;
            // @(posedge clk);
        end
        
        valid_in <= 0;
        char_in <= 0;
        @(posedge clk);

        // Explicitly send trailing newline (0x0A) to ensure last line is processed
        char_in <= 8'h0A;
        valid_in <= 1;
        @(posedge clk);
        valid_in <= 0;
        char_in <= 0;
        @(posedge clk);

        // Stop feeding from file
        // Input file now includes padding lines.
        valid_in <= 0;
        char_in <= 0;
        @(posedge clk);
        
        // Flush pipeline with dummy dot characters
        // Send enough to push the last data through
        valid_in <= 1;
        char_in <= 8'h2E; // '.'
        repeat (2048) @(posedge clk);
        valid_in <= 0;
        
        // Wait for pipeline drain
        #5000;
        
        

        $writememh("dut_mem.hex", dut.mem);
        
        $display("Final Count: %d", total_accessible);
        $display("Simulation cycles: %d", cycles);
        $display("Items sent: %d", i);
        $display("DUT Captured Width: %d", dut.width);
        
        if (total_accessible == 1424) begin
            $display("SUCCESS: Matches Ground Truth");
        end else begin
            $display("FAILURE: Expected 1424, got %d", total_accessible);
        end
        
        $finish;
    end
    
endmodule
