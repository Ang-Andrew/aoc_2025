module input_rom #(
    parameter FILENAME = "input.hex"
)(
    input wire clk,
    input wire [12:0] addr, 
    output reg [271:0] data
);

    reg [271:0] memory [0:255]; // Depth appropriate for ~4096 vectors (4096/16 = 256)

    initial begin
        $readmemh(FILENAME, memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
