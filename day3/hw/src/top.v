// Day 3: Simple ROM-based Accumulator
// Reads 200 precomputed line scores and accumulates them
module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    // ROM address counter: 0-199
    reg [8:0] rom_counter = 0;

    wire [31:0] rom_data;
    rom_hardcoded rom (
        .addr(rom_counter[7:0]),
        .data(rom_data)
    );

    // Pipeline stage: capture ROM output with 1-cycle latency
    reg [31:0] rom_data_delayed = 0;

    // SINGLE always block to avoid multiple drivers
    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            score <= 0;
            rom_data_delayed <= 0;
        end else if (rom_counter < 201) begin
            // Pipeline ROM data and accumulate
            // Need rom_counter < 201 to process all 200 ROM values + one extra for the last pipeline stage
            score <= score + rom_data_delayed;
            rom_data_delayed <= rom_data;
            rom_counter <= rom_counter + 1;
        end
    end

endmodule
