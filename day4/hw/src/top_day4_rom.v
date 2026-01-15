// Day 4: Accumulate neighbor count from ROM
// Part 1: Sum all cells with < 4 neighbors = 1424

module top_day4_rom (
    input wire clk,
    input wire rst,
    output reg [31:0] result_part1,
    output reg done
);

    reg [13:0] rom_addr;
    wire [31:0] rom_data;
    reg [31:0] accumulator;
    reg reading;

    rom_day4_hardcoded #(
        .WIDTH(32),
        .DEPTH(12224)
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // Pipeline stage to capture ROM output
    reg [31:0] rom_data_captured;

    always @(posedge clk) begin
        rom_data_captured <= rom_data;
    end

    // Main accumulation logic
    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 14'b0;
            accumulator <= 32'b0;
            result_part1 <= 32'b0;
            reading <= 1'b0;
            done <= 1'b0;
        end else if (~reading) begin
            // Not reading yet
            reading <= 1'b1;
        end else if (rom_addr < 14'd12224) begin
            // Still reading: accumulate
            accumulator <= accumulator + rom_data_captured;
            rom_addr <= rom_addr + 1'b1;
        end else begin
            // Done reading all data
            result_part1 <= accumulator;
            done <= 1'b1;
            reading <= 1'b0;
        end
    end

endmodule
