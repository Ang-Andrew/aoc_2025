// Generic ROM feeder with parametrized width
module rom_feeder_generic #(
    parameter FILENAME = "data/input.hex",
    parameter WIDTH = 32
)(
    input wire clk,
    input wire [7:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:255];

    initial begin
        $readmemh(FILENAME, memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
