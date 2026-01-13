// Reciprocal-based Range Calculator for 250MHz timing
// Uses fixed-point reciprocal multiplication instead of division
// Achieves high frequency by using only DSP blocks and simple logic

module recip_range_calc #(
    parameter K_VALUE = 1
)(
    input clk,
    input rst,
    input start,
    input [39:0] range_start,
    input [39:0] range_end,
    input [3:0] k_override,  // Dynamic K value (1-12)
    output reg [63:0] sum_out,
    output reg done
);

    // Constants for each K value
    reg [40:0] const_k;
    reg [39:0] x_min, x_max;
    reg [63:0] reciprocal;  // Fixed-point reciprocal: floor(2^60 / const_k)

    wire [3:0] k_val;
    assign k_val = (k_override != 0) ? k_override : K_VALUE;

    always @(*) begin
        case (k_val)
            1: begin
                const_k = 41'd11;
                x_min = 40'd1;
                x_max = 40'd9;
                reciprocal = 64'h0A3D70A3D70A3D70;  // 2^60 / 11
            end
            2: begin
                const_k = 41'd101;
                x_min = 40'd10;
                x_max = 40'd99;
                reciprocal = 64'h011E511E511E511E;  // 2^60 / 101
            end
            3: begin
                const_k = 41'd1001;
                x_min = 40'd100;
                x_max = 40'd999;
                reciprocal = 64'h0012277B5D74C29E;  // 2^60 / 1001
            end
            4: begin
                const_k = 41'd10001;
                x_min = 40'd1000;
                x_max = 40'd9999;
                reciprocal = 64'h0001249F7F9C75A8;  // 2^60 / 10001
            end
            5: begin
                const_k = 41'd100001;
                x_min = 40'd10000;
                x_max = 40'd99999;
                reciprocal = 64'h00001D1A3B4F93C8;  // 2^60 / 100001
            end
            6: begin
                const_k = 41'd1000001;
                x_min = 40'd100000;
                x_max = 40'd999999;
                reciprocal = 64'h000002FBDB6E8F78;  // 2^60 / 1000001
            end
            7: begin
                const_k = 41'd10000001;
                x_min = 40'd1000000;
                x_max = 40'd9999999;
                reciprocal = 64'h00000048D1514938;  // 2^60 / 10000001
            end
            8: begin
                const_k = 41'd100000001;
                x_min = 40'd10000000;
                x_max = 40'd99999999;
                reciprocal = 64'h0000000744A99F28;  // 2^60 / 100000001
            end
            9: begin
                const_k = 41'd1000000001;
                x_min = 40'd100000000;
                x_max = 40'd999999999;
                reciprocal = 64'h00000000B9F0ED48;  // 2^60 / 1000000001
            end
            10: begin
                const_k = 41'd10000000001;
                x_min = 40'd1000000000;
                x_max = 40'd9999999999;
                reciprocal = 64'h000000001298DA08;  // 2^60 / 10000000001
            end
            11: begin
                const_k = 41'd100000000001;
                x_min = 40'd10000000000;
                x_max = 40'd99999999999;
                reciprocal = 64'h0000000001DFD200;  // 2^60 / 100000000001
            end
            12: begin
                const_k = 41'd1000000000001;
                x_min = 40'd100000000000;
                x_max = 40'd999999999999;
                reciprocal = 64'h00000000002FF280;  // 2^60 / 1000000000001
            end
            default: begin
                const_k = 41'd1;
                x_min = 40'd0;
                x_max = 40'd0;
                reciprocal = 64'h1000000000000000;
            end
        endcase
    end

    // State machine - heavily pipelined for 250MHz
    localparam S_IDLE = 0;
    localparam S_MULT_START = 1;  // Multiply range_start * reciprocal
    localparam S_MULT_START2 = 2; // Pipeline stage 2
    localparam S_MULT_END = 3;    // Multiply range_end * reciprocal
    localparam S_MULT_END2 = 4;   // Pipeline stage 2
    localparam S_CLIP = 5;        // Clip to x_min, x_max
    localparam S_CHECK = 6;       // Check if valid range
    localparam S_SUM_CALC1 = 7;   // Calculate x_start + x_end
    localparam S_SUM_CALC2 = 8;   // Calculate x_end - x_start + 1
    localparam S_MULT1 = 9;       // Multiply sum * count
    localparam S_MULT2 = 10;      // Pipeline stage
    localparam S_MULT3 = 11;      // Multiply by const_k
    localparam S_MULT4 = 12;      // Pipeline stage
    localparam S_DIVIDE = 13;     // Divide by 2 (shift)
    localparam S_DONE = 14;

    reg [3:0] state;

    // Pipeline registers for DSP multiplications
    (* use_dsp = "yes" *) reg [103:0] mult_result_start;  // 40*64=104 bits
    (* use_dsp = "yes" *) reg [103:0] mult_result_end;
    (* use_dsp = "yes" *) reg [81:0] mult_intermediate;   // 41*41=82 bits
    (* use_dsp = "yes" *) reg [122:0] mult_final;         // 82*41=123 bits

    reg [39:0] x_start, x_end;
    reg [40:0] sum_vals, count_vals;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            sum_out <= 0;
            done <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        state <= S_MULT_START;
                    end
                end

                S_MULT_START: begin
                    // Multiply range_start * reciprocal (DSP block, fast)
                    mult_result_start <= range_start * reciprocal;
                    state <= S_MULT_START2;
                end

                S_MULT_START2: begin
                    // Pipeline delay, extract quotient
                    // Add 1 for ceiling division
                    x_start <= mult_result_start[99:60] + 1;
                    state <= S_MULT_END;
                end

                S_MULT_END: begin
                    // Multiply range_end * reciprocal
                    mult_result_end <= range_end * reciprocal;
                    state <= S_MULT_END2;
                end

                S_MULT_END2: begin
                    // Extract quotient (floor division)
                    x_end <= mult_result_end[99:60];
                    state <= S_CLIP;
                end

                S_CLIP: begin
                    // Clip x_start and x_end to valid bounds
                    if (x_start < x_min) x_start <= x_min;
                    if (x_end > x_max) x_end <= x_max;
                    state <= S_CHECK;
                end

                S_CHECK: begin
                    if (x_start <= x_end) begin
                        state <= S_SUM_CALC1;
                    end else begin
                        // No valid range, result is 0
                        sum_out <= 0;
                        state <= S_DONE;
                    end
                end

                S_SUM_CALC1: begin
                    // Calculate sum = x_start + x_end (for arithmetic series)
                    sum_vals <= {1'b0, x_start} + {1'b0, x_end};
                    state <= S_SUM_CALC2;
                end

                S_SUM_CALC2: begin
                    // Calculate count = x_end - x_start + 1
                    count_vals <= {1'b0, x_end} - {1'b0, x_start} + 41'd1;
                    state <= S_MULT1;
                end

                S_MULT1: begin
                    // Multiply sum * count (DSP)
                    mult_intermediate <= sum_vals * count_vals;
                    state <= S_MULT2;
                end

                S_MULT2: begin
                    // Pipeline delay
                    state <= S_MULT3;
                end

                S_MULT3: begin
                    // Multiply by const_k (DSP)
                    mult_final <= mult_intermediate * const_k;
                    state <= S_MULT4;
                end

                S_MULT4: begin
                    // Pipeline delay
                    state <= S_DIVIDE;
                end

                S_DIVIDE: begin
                    // Divide by 2 (arithmetic series formula: sum * count / 2)
                    // Right shift by 1
                    sum_out <= mult_final[63:1];
                    state <= S_DONE;
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
