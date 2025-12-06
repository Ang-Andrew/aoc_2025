module input_rom #(
    parameter FILENAME = "input.hex"
)(
    input wire clk,
    input wire [12:0] addr, 
    output reg [16:0] data
);

    reg [16:0] memory [0:8191]; // Depth up to 8192

    initial begin
        $readmemh(FILENAME, memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
