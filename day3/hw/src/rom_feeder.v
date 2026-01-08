module rom_feeder #(
    parameter FILENAME = "input.hex"
)(
    input wire clk,
    input wire [7:0] addr, 
    output reg [639:0] data
);

    reg [639:0] memory [0:255]; 

    initial begin
        $readmemh(FILENAME, memory);
    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
