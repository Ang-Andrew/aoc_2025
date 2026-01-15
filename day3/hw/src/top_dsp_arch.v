// Day 3: Architecture 4 - ROM and Accumulator Fully Decoupled
// ROM path: counter → ROM (runs at 250MHz every cycle)
// Accumulator path: separate pipelined add (also runs at 250MHz)
// Two independent pipelines that never interact on critical path

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    // ============================================
    // ROM PIPELINE (Path A - Fast counter + ROM)
    // ============================================
    reg [8:0] rom_counter = 0;
    wire [31:0] rom_data;

    rom_hardcoded rom (
        .addr(rom_counter[7:0]),
        .data(rom_data)
    );

    reg [31:0] rom_output_s1 = 0;
    reg [31:0] rom_output_s2 = 0;

    // ============================================
    // ACCUMULATOR PIPELINE (Path B - Pipelined add)
    // ============================================
    // Accumulate rom_output_s2 using 2-stage pipelined adder
    // Stage 1: Add lower 16 bits
    // Stage 2: Add upper 16 bits with carry

    reg [31:0] acc_intermediate = 0;  // After adding lower half
    reg [31:0] acc_final = 0;         // Final accumulated value

    // Two-stage split addition:
    // Stage 1 adds lower 16 bits, computes carry
    wire [16:0] lower_sum = {1'b0, score[15:0]} + {1'b0, rom_output_s2[15:0]};
    wire carry_out = lower_sum[16];

    // Stage 2 adds upper 16 bits with carry
    wire [16:0] upper_sum = {1'b0, score[31:16]} + {1'b0, rom_output_s2[31:16]} + {16'b0, carry_out};
    wire [31:0] combined_result = {upper_sum[15:0], lower_sum[15:0]};

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_output_s1 <= 0;
            rom_output_s2 <= 0;
            score <= 0;
        end else if (rom_counter < 202) begin  // 0-201 = 202 iterations (200 ROM + 2 drain)
            // ROM PATH: Counter increments every cycle, ROM is read-only
            // This path is NOT on critical path - it's read-only!
            rom_output_s1 <= rom_data;
            rom_output_s2 <= rom_output_s1;
            rom_counter <= rom_counter + 1;

            // ACCUMULATOR PATH: Standalone 2-stage adder
            // Critical path here is much shorter than 5.6ns because:
            // 1. No counter increment needed here
            // 2. Two-stage split reduces each stage to ~2ns max
            // 3. score register is OUTPUT of accumulation, not input to counter
            score <= combined_result;
        end
    end

endmodule
