// Day 3: Architecture 5 - Baseline with Max Register Distribution
// Use same algorithm as top.v but explicit register placement
// to help synthesizer with timing

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

    // Three separate registers for different stages
    reg [31:0] rom_p1 = 0;      // Register 1: ROM output
    reg [31:0] rom_p2 = 0;      // Register 2: Delayed ROM
    reg [31:0] acc_temp = 0;    // Register 3: Accumulation temp

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_p1 <= 0;
            rom_p2 <= 0;
            acc_temp <= 0;
            score <= 0;
        end else if (rom_counter < 201) begin
            // Stage 1: Capture ROM output
            rom_p1 <= rom_data;

            // Stage 2: Prepare for addition
            rom_p2 <= rom_p1;

            // Stage 3: Accumulate
            acc_temp <= score + rom_p2;

            // Stage 4: Store result
            score <= acc_temp;

            // Stage 5: Increment counter (decoupled)
            rom_counter <= rom_counter + 1;
        end
    end

endmodule
