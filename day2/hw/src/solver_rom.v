// ROM-Based Solver - 250MHz Architecture
// Uses pre-computed division results from ROM
// All arithmetic chunked into 16-bit operations for fast timing

module solver_rom #(
    parameter DIVISIONS_FILE = "divisions.hex",
    parameter ENTRY_COUNT = 468  // 39 ranges × 12 K values
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // ROM containing pre-computed x_start and x_end for each (range, K) combination
    // Each entry: [39:0] = x_start, [79:40] = x_end, [80] = valid
    reg [95:0] divisions [0:ENTRY_COUNT-1];
    initial $readmemh(DIVISIONS_FILE, divisions);

    // Constants for each K value
    reg [40:0] const_k;
    always @(*) begin
        case (k_value)
            1: const_k = 41'd11;
            2: const_k = 41'd101;
            3: const_k = 41'd1001;
            4: const_k = 41'd10001;
            5: const_k = 41'd100001;
            6: const_k = 41'd1000001;
            7: const_k = 41'd10000001;
            8: const_k = 41'd100000001;
            9: const_k = 41'd1000000001;
            10: const_k = 41'd10000000001;
            11: const_k = 41'd100000000001;
            12: const_k = 41'd1000000000001;
            default: const_k = 41'd1;
        endcase
    end

    // State machine
    localparam S_IDLE = 0;
    localparam S_LOAD = 1;
    localparam S_CHECK = 2;
    localparam S_ADD_LOW = 3;     // x_start + x_end (lower 16 bits)
    localparam S_ADD_MID = 4;     // x_start + x_end (middle 16 bits)
    localparam S_ADD_HIGH = 5;    // x_start + x_end (upper bits)
    localparam S_SUB_LOW = 6;     // x_end - x_start + 1 (lower 16 bits)
    localparam S_SUB_MID = 7;     // x_end - x_start + 1 (middle 16 bits)
    localparam S_SUB_HIGH = 8;    // x_end - x_start + 1 (upper bits)
    localparam S_MULT1 = 9;       // sum * count (DSP, fast)
    localparam S_MULT2 = 10;      // Pipeline delay
    localparam S_MULT3 = 11;      // * const_k (DSP, fast)
    localparam S_MULT4 = 12;      // Pipeline delay
    localparam S_DIVIDE = 13;     // / 2 (shift)
    localparam S_ACC_LOW = 14;    // Accumulate to total (lower 32 bits)
    localparam S_ACC_HIGH = 15;   // Accumulate to total (upper 32 bits)
    localparam S_NEXT = 16;
    localparam S_DONE = 17;

    reg [4:0] state;
    reg [9:0] entry_idx;  // 0 to 467
    reg [3:0] k_value;    // For const_k lookup

    // Current entry data
    reg [39:0] x_start, x_end;
    reg valid;

    // 16-bit chunked arithmetic registers
    reg [15:0] add_low, add_mid;
    reg [7:0] add_high;
    reg add_carry1, add_carry2;

    reg [15:0] sub_low, sub_mid;
    reg [7:0] sub_high;
    reg sub_borrow1, sub_borrow2;

    // Final values for arithmetic series
    reg [40:0] sum_vals;   // x_start + x_end
    reg [40:0] count_vals; // x_end - x_start + 1

    // DSP multiplications (fast, hardened blocks)
    (* use_dsp = "yes" *) reg [81:0] mult_intermediate;  // sum * count
    (* use_dsp = "yes" *) reg [122:0] mult_final;        // * const_k

    // Split accumulator for 32-bit chunked addition
    reg [31:0] total_low, total_high;
    reg [31:0] add_temp;
    reg acc_carry;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            total_sum <= 0;
            total_low <= 0;
            total_high <= 0;
            done <= 0;
            entry_idx <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    entry_idx <= 0;
                    total_sum <= 0;
                    total_low <= 0;
                    total_high <= 0;
                    done <= 0;
                    state <= S_LOAD;
                end

                S_LOAD: begin
                    if (entry_idx < ENTRY_COUNT) begin
                        // Load pre-computed division result from ROM
                        x_start <= divisions[entry_idx][39:0];
                        x_end <= divisions[entry_idx][79:40];
                        valid <= divisions[entry_idx][80];

                        // Determine which K value this is (entry_idx mod 12 + 1)
                        k_value <= (entry_idx % 12) + 1;

                        state <= S_CHECK;
                    end else begin
                        // All entries processed
                        total_sum <= {total_high, total_low};
                        state <= S_DONE;
                    end
                end

                S_CHECK: begin
                    if (valid) begin
                        // Valid range, compute arithmetic series sum
                        state <= S_ADD_LOW;
                    end else begin
                        // Invalid range, skip to next
                        entry_idx <= entry_idx + 1;
                        state <= S_LOAD;
                    end
                end

                // Chunked addition: x_start + x_end
                S_ADD_LOW: begin
                    {add_carry1, add_low} <= {1'b0, x_start[15:0]} + {1'b0, x_end[15:0]};
                    state <= S_ADD_MID;
                end

                S_ADD_MID: begin
                    {add_carry2, add_mid} <= {1'b0, x_start[31:16]} + {1'b0, x_end[31:16]} + {16'b0, add_carry1};
                    state <= S_ADD_HIGH;
                end

                S_ADD_HIGH: begin
                    add_high <= x_start[39:32] + x_end[39:32] + {7'b0, add_carry2};
                    sum_vals <= {x_start[39:32] + x_end[39:32] + {7'b0, add_carry2}, add_mid, add_low};
                    state <= S_SUB_LOW;
                end

                // Chunked subtraction: x_end - x_start + 1
                S_SUB_LOW: begin
                    {sub_borrow1, sub_low} <= {1'b0, x_end[15:0]} - {1'b0, x_start[15:0]} + 17'd1;
                    state <= S_SUB_MID;
                end

                S_SUB_MID: begin
                    {sub_borrow2, sub_mid} <= {1'b0, x_end[31:16]} - {1'b0, x_start[31:16]} - {16'b0, sub_borrow1};
                    state <= S_SUB_HIGH;
                end

                S_SUB_HIGH: begin
                    sub_high <= x_end[39:32] - x_start[39:32] - {7'b0, sub_borrow2};
                    count_vals <= {x_end[39:32] - x_start[39:32] - {7'b0, sub_borrow2}, sub_mid, sub_low};
                    state <= S_MULT1;
                end

                // DSP multiplications (fast)
                S_MULT1: begin
                    mult_intermediate <= sum_vals * count_vals;
                    state <= S_MULT2;
                end

                S_MULT2: begin
                    // Pipeline delay for DSP
                    state <= S_MULT3;
                end

                S_MULT3: begin
                    mult_final <= mult_intermediate * const_k;
                    state <= S_MULT4;
                end

                S_MULT4: begin
                    // Pipeline delay for DSP
                    state <= S_DIVIDE;
                end

                S_DIVIDE: begin
                    // Divide by 2 (arithmetic series formula)
                    // Shift right by 1
                    // Result is in mult_final[64:1] (63 bits)
                    add_temp <= mult_final[32:1];  // Lower 32 bits
                    state <= S_ACC_LOW;
                end

                S_ACC_LOW: begin
                    // Accumulate lower 32 bits
                    {acc_carry, total_low} <= {1'b0, total_low} + {1'b0, add_temp};
                    add_temp <= mult_final[64:33];  // Upper 32 bits
                    state <= S_ACC_HIGH;
                end

                S_ACC_HIGH: begin
                    // Accumulate upper 32 bits with carry
                    total_high <= total_high + add_temp + {31'b0, acc_carry};
                    entry_idx <= entry_idx + 1;
                    state <= S_LOAD;
                end

                S_NEXT: begin
                    entry_idx <= entry_idx + 1;
                    state <= S_LOAD;
                end

                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
