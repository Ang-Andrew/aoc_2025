// Day 3: Architecture 2 - Clean Multi-Stage Pipeline
// Deeper pipelining to decouple counter from ROM from accumulator

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    reg [8:0] rom_counter = 0;
    wire [31:0] rom_data;

    rom_hardcoded rom (
        .addr(rom_counter[7:0]),
        .data(rom_data)
    );

    // Multi-stage pipeline
    reg [31:0] rom_p1 = 0;
    reg [31:0] rom_p2 = 0;
    reg [31:0] rom_p3 = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_p1 <= 0;
            rom_p2 <= 0;
            rom_p3 <= 0;
            score <= 0;
        end else if (rom_counter < 204) begin
            // Increment counter
            rom_counter <= rom_counter + 1;

            // Four-stage pipeline for ROM data
            rom_p1 <= rom_data;
            rom_p2 <= rom_p1;
            rom_p3 <= rom_p2;

            // Accumulate rom_p3 (3 stages of latency)
            score <= score + rom_p3;
        end
    end

endmodule
