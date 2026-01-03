module rom_feeder #(
    parameter MEM_FILE = "../input/input.hex",
    parameter MEM_SIZE = 32768
)(
    input wire clk,
    input wire reset,
    output reg [7:0] char_out,
    output reg valid_out,
    output reg done
);

    reg [7:0] memory [0:MEM_SIZE-1];
    reg [15:0] addr;

    initial begin
        $readmemh(MEM_FILE, memory);
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            addr <= 0;
            valid_out <= 0;
            done <= 0;
            char_out <= 0;
        end else begin
            if (addr < MEM_SIZE && !done) begin
                char_out <= memory[addr];
                // Check for uninitialized memory (assuming hex file is contiguous and ends)
                // This is tricky in synthesis without explicit size. 
                // We'll rely on MEM_SIZE or a specific end marker if available.
                // For now, just run full size.
                valid_out <= 1;
                addr <= addr + 1;
            end else begin
                valid_out <= 0;
                done <= 1;
            end
        end
    end

endmodule
