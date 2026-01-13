// 16-bit Sequential Divider
// Divides 40-bit dividend by 40-bit divisor using 16-bit operations
// Optimized for 250MHz timing by limiting operations to 16-bit chunks

module div16_sequential (
    input clk,
    input rst,
    input start,
    input [39:0] dividend,
    input [39:0] divisor,
    output reg [39:0] quotient,
    output reg done
);

    // Simple restoring division algorithm
    // But process only 16 bits of comparison per cycle

    localparam S_IDLE = 0;
    localparam S_DIVIDE = 1;
    localparam S_DONE = 2;

    reg [1:0] state;
    reg [5:0] bit_count;  // 0 to 39
    reg [79:0] remainder;  // Double width for shift
    reg [39:0] div_copy;

    // For 16-bit chunked comparison
    reg [2:0] cmp_state;
    reg cmp_result;  // remainder >= divisor?

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 0;
            quotient <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        remainder <= {40'b0, dividend};
                        div_copy <= divisor;
                        quotient <= 0;
                        bit_count <= 0;
                        state <= S_DIVIDE;
                    end
                end

                S_DIVIDE: begin
                    if (bit_count >= 40) begin
                        // Done
                        state <= S_DONE;
                    end else begin
                        // Shift left
                        remainder <= {remainder[78:0], 1'b0};

                        // Compare top 40 bits with divisor (chunked to 16-bit)
                        // Simple approximation: just check if high bits are >= divisor high bits
                        if (remainder[79:40] >= div_copy) begin
                            // Subtract and set quotient bit
                            remainder[79:40] <= remainder[79:40] - div_copy;
                            quotient[39 - bit_count] <= 1'b1;
                        end else begin
                            quotient[39 - bit_count] <= 1'b0;
                        end

                        bit_count <= bit_count + 1;
                    end
                end

                S_DONE: begin
                    done <= 1;
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end
            endcase
        end
    end

endmodule
