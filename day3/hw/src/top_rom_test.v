// Day 3: Just read ROM values
module top (
    input wire clk,
    input wire rst,
    output wire [31:0] score
);

    reg [7:0] rom_addr = 0;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(score)
    );

    always @(posedge clk) begin
        if (!rst && rom_addr < 200) begin
            rom_addr <= rom_addr + 1;
        end
    end

endmodule
