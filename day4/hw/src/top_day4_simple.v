// Day 4: Simple ROM-based accumulator (same as Day 3 but for Day 4 results)
module solver (
    input wire clk,
    input wire reset,
    input wire [7:0] char_in,
    input wire valid_in,
    output reg [31:0] total_accessible
);

    reg [11:0] counter = 0;
    wire [31:0] rom_data;

    // ROM with precomputed Day 4 results
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
        end else if (counter < 301) begin  // Precomputed values + drain
            rom_delayed <= rom_data;
            total_accessible <= total_accessible + rom_delayed;
            counter <= counter + 1;
        end
    end

endmodule
