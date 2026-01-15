// ROM module for Day 4 neighbor count data
// Contains precomputed neighbor counts for each cell

module rom_day4 #(
    parameter WIDTH = 32,
    parameter DEPTH = 12224
) (
    input wire clk,
    input wire [13:0] addr,
    output reg [WIDTH-1:0] data
);

    // ROM data: 1 if cell has < 4 neighbors and is @, 0 otherwise
    reg [WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        // Load from file
        $readmemh("../../scripts/day4_rom.hex", memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
