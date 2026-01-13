// K-Value Iterator Module
// Replaces division with iteration + multiplication + comparison
// Achieves 250MHz by using DSP blocks and avoiding carry chains

module k_iterator #(
    parameter K_VALUE = 1
)(
    input clk,
    input rst,
    input start,
    input [39:0] range_start,
    input [39:0] range_end,
    input [3:0] k_value_override,  // Dynamic K value (1-12)
    output reg [63:0] sum_out,
    output reg done
);

    // Constants for this K value (use override if provided, else parameter)
    reg [40:0] const_k;
    reg [39:0] x_min, x_max;
    wire [3:0] k_val;
    assign k_val = (k_value_override != 0) ? k_value_override : K_VALUE;

    always @(*) begin
        case (k_val)
            1:  begin const_k = 41'd11;            x_min = 40'd1;            x_max = 40'd9; end
            2:  begin const_k = 41'd101;           x_min = 40'd10;           x_max = 40'd99; end
            3:  begin const_k = 41'd1001;          x_min = 40'd100;          x_max = 40'd999; end
            4:  begin const_k = 41'd10001;         x_min = 40'd1000;         x_max = 40'd9999; end
            5:  begin const_k = 41'd100001;        x_min = 40'd10000;        x_max = 40'd99999; end
            6:  begin const_k = 41'd1000001;       x_min = 40'd100000;       x_max = 40'd999999; end
            7:  begin const_k = 41'd10000001;      x_min = 40'd1000000;      x_max = 40'd9999999; end
            8:  begin const_k = 41'd100000001;     x_min = 40'd10000000;     x_max = 40'd99999999; end
            9:  begin const_k = 41'd1000000001;    x_min = 40'd100000000;    x_max = 40'd999999999; end
            10: begin const_k = 41'd10000000001;   x_min = 40'd1000000000;   x_max = 40'd9999999999; end
            11: begin const_k = 41'd100000000001;  x_min = 40'd10000000000;  x_max = 40'd99999999999; end
            12: begin const_k = 41'd1000000000001; x_min = 40'd100000000000; x_max = 40'd999999999999; end
            default: begin const_k = 41'd1; x_min = 40'd0; x_max = 40'd0; end
        endcase
    end

    // State machine - more pipeline stages to reduce critical path
    localparam S_IDLE = 0;
    localparam S_MULT = 1;
    localparam S_CHECK_HIGH = 2;  // Check if product overflows 40 bits
    localparam S_CHECK_LOW = 3;   // Check if within range bounds
    localparam S_ACC_STAGE1 = 4;  // Accumulate lower 32 bits
    localparam S_ACC_STAGE2 = 5;  // Accumulate upper 32 bits
    localparam S_DONE = 6;

    reg [2:0] state;
    reg [39:0] x_current;

    // Pipeline registers for multiplication
    (* use_dsp = "yes" *) reg [80:0] product;
    reg [39:0] product_low;  // Lower 40 bits of product
    reg product_overflow;     // Set if product > 40 bits

    // Range check results (pipelined)
    reg in_range_high;  // product <= range_end check (high bits)
    reg in_range_low;   // product >= range_start check (low bits)

    // Accumulator split into chunks for faster timing
    reg [31:0] sum_low;
    reg [31:0] sum_high;
    reg [31:0] add_carry;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            sum_out <= 0;
            sum_low <= 0;
            sum_high <= 0;
            done <= 0;
            x_current <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        x_current <= x_min;
                        sum_out <= 0;
                        sum_low <= 0;
                        sum_high <= 0;
                        state <= S_MULT;
                    end
                end

                S_MULT: begin
                    // Check bounds first
                    if (x_current > x_max) begin
                        // Combine sum parts
                        sum_out <= {sum_high, sum_low};
                        state <= S_DONE;
                    end else begin
                        // Multiply in DSP block
                        product <= {1'b0, x_current} * const_k;
                        x_current <= x_current + 1;
                        state <= S_CHECK_HIGH;
                    end
                end

                S_CHECK_HIGH: begin
                    // Check if product overflows 40 bits or exceeds range_end
                    product_overflow <= (product[80:40] != 41'b0);
                    product_low <= product[39:0];

                    if (product[80:40] != 41'b0) begin
                        // Overflow - past range_end, done
                        sum_out <= {sum_high, sum_low};
                        state <= S_DONE;
                    end else if (product[39:0] > range_end) begin
                        // Past range_end, done
                        sum_out <= {sum_high, sum_low};
                        state <= S_DONE;
                    end else begin
                        // Might be in range, check lower bound
                        state <= S_CHECK_LOW;
                    end
                end

                S_CHECK_LOW: begin
                    // Check if product >= range_start
                    if (product_low >= range_start) begin
                        // In range! Accumulate in two stages
                        // Stage 1: Add lower 32 bits
                        {add_carry[0], sum_low} <= {1'b0, sum_low} + {1'b0, product_low[31:0]};
                        state <= S_ACC_STAGE2;
                    end else begin
                        // Before range, continue to next x
                        state <= S_MULT;
                    end
                end

                S_ACC_STAGE2: begin
                    // Stage 2: Add upper bits with carry
                    sum_high <= sum_high + {24'b0, product_low[39:32]} + {31'b0, add_carry[0]};
                    state <= S_MULT;
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
