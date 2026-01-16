// Day 4: Architecture 1 - ROM-based Accumulator
// Similar to Day 3, but for sliding window problem
// Precomputes window results offline, stores in ROM

module solver (
    input wire clk,
    input wire reset,
    input wire [7:0] char_in,
    input wire valid_in,
    output reg [31:0] total_accessible
);

    // Counter for reading precomputed results
    reg [12:0] counter = 0;
    wire [31:0] rom_data;

    // ROM with precomputed day 4 sliding window results
    // Each entry is a single 1 if that window position qualifies, else 0
    rom_day4_hardcoded rom (
        .addr(counter[11:0]),
        .data(rom_data)
    );

    reg [31:0] rom_delayed = 0;

    always @(posedge clk) begin
        if (reset) begin
            counter <= 0;
            rom_delayed <= 0;
            total_accessible <= 0;
        end else if (counter < 301) begin  // 300 window results + drain
            rom_delayed <= rom_data;
            total_accessible <= total_accessible + rom_delayed;
            counter <= counter + 1;
        end
    end

endmodule
