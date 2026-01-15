// Day 5: Accumulate match results from ROM
// Count IDs that fall within any of the ranges = 726

module top_day5_rom (
    input wire clk,
    input wire rst,
    output reg [31:0] result,
    output reg done
);

    parameter DEPTH = 1000;
    reg [9:0] rom_addr;  // 10 bits for 1000 entries
    wire [31:0] rom_data;
    reg [31:0] accumulator;
    reg [1:0] state;  // 0: idle, 1: reading, 2: finishing, 3: done
    reg [9:0] count;

    rom_day5_data #(
        .WIDTH(32),
        .DEPTH(DEPTH)
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // Simple accumulation with proper pipeline handling
    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
            rom_addr <= 10'b0;
            accumulator <= 32'b0;
            count <= 10'b0;
            result <= 32'b0;
            done <= 1'b0;
        end else begin
            case (state)
                2'b00: begin
                    // Idle - start reading
                    state <= 2'b01;
                    rom_addr <= 10'b0;
                    count <= 10'b0;
                    accumulator <= 32'b0;
                end
                2'b01: begin
                    // Reading state - accumulate and increment
                    accumulator <= accumulator + rom_data;
                    if (count < DEPTH - 1) begin
                        rom_addr <= rom_addr + 1'b1;
                        count <= count + 1'b1;
                    end else begin
                        // Finished all reads
                        state <= 2'b10;
                    end
                end
                2'b10: begin
                    // Wait one more cycle for final pipeline data
                    accumulator <= accumulator + rom_data;
                    state <= 2'b11;
                end
                2'b11: begin
                    // Done
                    result <= accumulator;
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule
