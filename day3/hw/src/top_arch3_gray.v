// Day 3: Architecture 3 - Proper Gray Code Counter
// Uses iteration counter + combinational Gray code generation
// Theoretical advantage: Only 1 bit toggles per cycle in Gray code register
// However, binary increment still has carry chain

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    // Binary iteration counter (0-200)
    reg [8:0] iteration = 0;

    // Gray code computed combinationally from binary
    wire [7:0] gray_counter = iteration[7:0] ^ {1'b0, iteration[7:1]};

    // Convert Gray back to binary for ROM (uses XOR tree)
    // ROM needs sequential addresses 0, 1, 2, ..., 199
    wire [7:0] binary_from_gray = {
        gray_counter[7],
        gray_counter[7] ^ gray_counter[6],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5] ^ gray_counter[4],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5] ^ gray_counter[4] ^ gray_counter[3],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5] ^ gray_counter[4] ^ gray_counter[3] ^ gray_counter[2],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5] ^ gray_counter[4] ^ gray_counter[3] ^ gray_counter[2] ^ gray_counter[1],
        gray_counter[7] ^ gray_counter[6] ^ gray_counter[5] ^ gray_counter[4] ^ gray_counter[3] ^ gray_counter[2] ^ gray_counter[1] ^ gray_counter[0]
    };

    // ROM addressing with converted binary
    wire [31:0] rom_data;
    rom_hardcoded rom (
        .addr(binary_from_gray),
        .data(rom_data)
    );

    reg [31:0] rom_data_delayed = 0;

    always @(posedge clk) begin
        if (rst) begin
            iteration <= 0;
            rom_data_delayed <= 0;
            score <= 0;
        end else if (iteration < 201) begin
            rom_data_delayed <= rom_data;
            score <= score + rom_data_delayed;
            iteration <= iteration + 1;
        end
    end

endmodule
