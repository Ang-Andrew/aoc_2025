// Day 3: Architecture 6 - Split Byte-wise Accumulator
// Split 32-bit accumulator into 16-bit lower and upper halves
// This allows synthesis tool to place them independently for parallelism
// Similar to baseline but with explicit byte-width hints to synthesizer

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

    // Pipeline stage: same as baseline but with explicit register
    reg [31:0] rom_data_delayed = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_data_delayed <= 0;
            score <= 0;
        end else if (rom_counter < 201) begin

            // Delay ROM data by one cycle (same as baseline)
            rom_data_delayed <= rom_data;

            // Accumulate using split lower/upper addition
            // Lower 16-bit addition
            wire [16:0] add_lower = {1'b0, score[15:0]} + {1'b0, rom_data_delayed[15:0]};
            wire carry_out = add_lower[16];

            // Upper 16-bit addition with carry
            wire [16:0] add_upper = {1'b0, score[31:16]} + {1'b0, rom_data_delayed[31:16]} + {16'b0, carry_out};

            // Combine results
            score <= {add_upper[15:0], add_lower[15:0]};

            // Counter increments
            rom_counter <= rom_counter + 1;
        end
    end

endmodule
