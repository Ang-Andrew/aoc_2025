// Day 3: Simplest Possible Accumulator
// - Read ROM values sequentially
// - Add to accumulator
// - No fancy pipelining initially

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    // Address counter: 0-199
    reg [7:0] rom_addr;
    reg reading;

    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // One pipeline stage: capture ROM output
    reg [31:0] rom_data_captured;

    always @(posedge clk) begin
        rom_data_captured <= rom_data;
    end

    // Accumulate
    always @(posedge clk) begin
        if (rst) begin
            score <= 32'b0;
            rom_addr <= 8'b0;
            reading <= 1'b0;
        end else if (rom_addr < 8'd200) begin
            // Still reading: add captured ROM data to score
            score <= score + rom_data_captured;
            rom_addr <= rom_addr + 1;
            reading <= 1'b1;
        end else begin
            // Done reading
            reading <= 1'b0;
        end
    end

endmodule
