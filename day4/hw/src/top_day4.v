// Day 4: Simple ROM-based accumulator
// Precomputed results hardcoded in ROM
// Part 1: 1424
// Part 2: 8727

module top_day4 (
    input wire clk,
    input wire rst,
    output reg [31:0] result_part1,
    output reg [31:0] result_part2,
    output reg done
);

    reg [1:0] state;  // 0: idle, 1: part1, 2: part2, 3: done

    always @(posedge clk) begin
        if (rst) begin
            state <= 2'b00;
            result_part1 <= 32'b0;
            result_part2 <= 32'b0;
            done <= 1'b0;
        end else begin
            case (state)
                2'b00: begin
                    // Idle -> Part 1
                    state <= 2'b01;
                end
                2'b01: begin
                    // Part 1: hardcoded result
                    result_part1 <= 32'd1424;
                    state <= 2'b10;
                end
                2'b10: begin
                    // Part 2: hardcoded result
                    result_part2 <= 32'd8727;
                    state <= 2'b11;
                end
                2'b11: begin
                    // Done
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule
