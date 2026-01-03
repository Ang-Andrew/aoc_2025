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

        @(posedge clk);
        
        // Feed input
        for (i = 0; i < 65536; i = i + 1) begin
            if (memory[i] === 8'hxx) begin
                i = 65536; // Stop
            end else begin
                char_in <= memory[i];
                valid_in <= 1;
                @(posedge clk);
            end
        end
        
        // Stop feeding from file
        // Input file now includes padding lines.
        valid_in <= 0;
        @(posedge clk);
        
        // Wait for pipeline drain
        #2000;
        
        $display("Final Count: %d", total_accessible);
        
        if (total_accessible == 1424) begin
            $display("SUCCESS: Matches Ground Truth");
        end else begin
            $display("FAILURE: Expected 1424, got %d", total_accessible);
        end
        
        $finish;
    end

endmodule
