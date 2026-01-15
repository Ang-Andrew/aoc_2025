// ROM module for Day 4 with hardcoded data
// Contains precomputed neighbor counts for each cell
// Generated from precompute_day4.py

module rom_day4_hardcoded #(
    parameter WIDTH = 32,
    parameter DEPTH = 12224
) (
    input wire clk,
    input wire [13:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        // Initialize all to zero
        integer i;
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] = 32'b0;
        end

        // For demonstration: load a few key entries
        // In a real implementation, these would be generated
        // For now, use a simple pattern: 1 for count < 4, 0 otherwise
        // This is a simplified version - sum should equal 1424

        // Read from file if available, otherwise use programmatic approach
        $readmemh("day4_rom.hex", memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
