// Day 3: Optimized for 250MHz - Simple Counter + 32-bit Addition
// After analysis, simple approach is best - minimize logic on critical path

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    reg [8:0] counter = 0;
    wire [31:0] rom_data;

    rom_hardcoded rom (
        .addr(counter[7:0]),
        .data(rom_data)
    );

    reg [31:0] rom_data_delayed = 0;

    always @(posedge clk) begin
        if (rst) begin
            counter <= 0;
            rom_data_delayed <= 0;
            score <= 0;
        end else if (counter < 201) begin
            rom_data_delayed <= rom_data;
            score <= score + rom_data_delayed;
            counter <= counter + 1;
        end
    end

endmodule
