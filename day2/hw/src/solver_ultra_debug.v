// Ultra-Optimized Solver for 250MHz Timing - DEBUG VERSION
// Key optimizations:
// 1. Fully pipelined DSP blocks with internal registers
// 2. ROM with output registers
// 3. Maximum 2 LUT levels per clock cycle
// 4. Parallel 20-bit arithmetic instead of serial 16-bit
// 5. Minimal routing distances

module solver_ultra #(
    parameter DIVISIONS_FILE = "divisions.hex",
    parameter ENTRY_COUNT = 468  // 39 ranges × 12 K values
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // ==== Stage 0: ROM with Registered Outputs ====
    // ROM must have output registers for timing
    reg [95:0] divisions [0:ENTRY_COUNT-1];
    initial $readmemh(DIVISIONS_FILE, divisions);

    reg [9:0] rom_addr;
    reg [95:0] rom_data;

    always @(posedge clk) begin
        rom_data <= divisions[rom_addr];  // Registered ROM output
    end

    // ==== Stage 1: Unpack ROM Data (Purely Registers) ====
    reg [39:0] stage1_x_start, stage1_x_end;
    reg stage1_valid;
    reg [3:0] stage1_k_value;
    reg [40:0] stage1_const_k;

    // Constant lookup (LUT-based, but simple)
    function [40:0] get_const_k;
        input [3:0] k;
        begin
            case (k)
                1: get_const_k = 41'd11;
                2: get_const_k = 41'd101;
                3: get_const_k = 41'd1001;
                4: get_const_k = 41'd10001;
                5: get_const_k = 41'd100001;
                6: get_const_k = 41'd1000001;
                7: get_const_k = 41'd10000001;
                8: get_const_k = 41'd100000001;
                9: get_const_k = 41'd1000000001;
                10: get_const_k = 41'd10000000001;
                11: get_const_k = 41'd100000000001;
                12: get_const_k = 41'd1000000000001;
                default: get_const_k = 41'd1;
            endcase
        end
    endfunction

    reg [9:0] stage1_addr;

    always @(posedge clk) begin
        stage1_x_start <= rom_data[39:0];
        stage1_x_end <= rom_data[79:40];
        stage1_valid <= rom_data[80];
        stage1_k_value <= (rom_addr % 12) + 1;
        stage1_const_k <= get_const_k((rom_addr % 12) + 1);
        stage1_addr <= rom_addr;
    end

    // ==== Stage 2: Parallel Addition (x_start + x_end) ====
    // Split into two 20-bit additions for shallow logic
    reg [20:0] stage2_add_low, stage2_add_high;
    reg [40:0] stage2_sum;
    reg stage2_valid;
    reg [39:0] stage2_x_start, stage2_x_end;
    reg [40:0] stage2_const_k;
    reg [9:0] stage2_addr;
    reg [3:0] stage2_k;

    always @(posedge clk) begin
        // Low 20 bits
        stage2_add_low <= {1'b0, stage1_x_start[19:0]} + {1'b0, stage1_x_end[19:0]};
        // High 20 bits with carry
        stage2_add_high <= {1'b0, stage1_x_start[39:20]} + {1'b0, stage1_x_end[39:20]};
        stage2_valid <= stage1_valid;
        stage2_x_start <= stage1_x_start;
        stage2_x_end <= stage1_x_end;
        stage2_const_k <= stage1_const_k;
        stage2_addr <= stage1_addr;
        stage2_k <= stage1_k_value;
    end

    // ==== Stage 3: Complete Addition with Carry Propagation ====
    reg [40:0] stage3_sum;
    reg [40:0] stage3_count;  // Will be computed in parallel
    reg stage3_valid;
    reg [40:0] stage3_const_k;
    reg [9:0] stage3_addr;
    reg [3:0] stage3_k;

    always @(posedge clk) begin
        // Combine with carry propagation (1 level of LUTs)
        stage3_sum <= {stage2_add_high + {20'b0, stage2_add_low[20]}, stage2_add_low[19:0]};
        stage3_valid <= stage2_valid;
        stage3_const_k <= stage2_const_k;
        stage3_addr <= stage2_addr;
        stage3_k <= stage2_k;
    end

    // ==== Stage 2b & 3b: Parallel Subtraction (x_end - x_start + 1) ====
    reg [20:0] stage2_sub_low, stage2_sub_high;

    always @(posedge clk) begin
        // Low 20 bits: x_end - x_start + 1
        stage2_sub_low <= {1'b0, stage1_x_end[19:0]} - {1'b0, stage1_x_start[19:0]} + 21'd1;
        // High 20 bits
        stage2_sub_high <= {1'b0, stage1_x_end[39:20]} - {1'b0, stage1_x_start[39:20]};
    end

    always @(posedge clk) begin
        // Combine with borrow propagation
        stage3_count <= {stage2_sub_high - {20'b0, stage2_sub_low[20]}, stage2_sub_low[19:0]};
    end

    // ==== Stage 4-5-6: Pipelined DSP Multiplication (sum * count) ====
    // Use 3-stage pipeline in DSP for maximum frequency
    (* use_dsp = "yes" *) reg [81:0] stage4_mult1;
    (* use_dsp = "yes" *) reg [81:0] stage5_mult1;
    reg stage4_valid, stage5_valid;
    reg [40:0] stage4_const_k, stage5_const_k;
    reg [9:0] stage4_addr, stage5_addr;
    reg [3:0] stage4_k, stage5_k;

    always @(posedge clk) begin
        // Stage 4: First multiplication stage
        stage4_mult1 <= stage3_sum * stage3_count;
        stage4_valid <= stage3_valid;
        stage4_const_k <= stage3_const_k;
        stage4_addr <= stage3_addr;
        stage4_k <= stage3_k;
    end

    always @(posedge clk) begin
        // Stage 5: Pipeline delay for multiplication
        stage5_mult1 <= stage4_mult1;
        stage5_valid <= stage4_valid;
        stage5_const_k <= stage4_const_k;
        stage5_addr <= stage4_addr;
        stage5_k <= stage4_k;
    end

    // ==== Stage 6-7-8: Pipelined DSP Multiplication (* const_k) ====
    (* use_dsp = "yes" *) reg [122:0] stage6_mult2;
    (* use_dsp = "yes" *) reg [122:0] stage7_mult2;
    reg stage6_valid, stage7_valid;
    reg [9:0] stage6_addr, stage7_addr;
    reg [3:0] stage6_k, stage7_k;
    reg [40:0] stage6_const_k, stage7_const_k;

    always @(posedge clk) begin
        // Stage 6: Second multiplication (result * const_k)
        stage6_mult2 <= stage5_mult1 * stage5_const_k;
        stage6_valid <= stage5_valid;
        stage6_addr <= stage5_addr;
        stage6_k <= stage5_k;
        stage6_const_k <= stage5_const_k;
    end

    always @(posedge clk) begin
        // Stage 7: Pipeline delay
        stage7_mult2 <= stage6_mult2;
        stage7_valid <= stage6_valid;
        stage7_addr <= stage6_addr;
        stage7_k <= stage6_k;
        stage7_const_k <= stage6_const_k;
    end

    // ==== Stage 8: Divide by 2 and Prepare Accumulation ====
    reg [63:0] stage8_result;
    reg stage8_valid;
    reg [9:0] stage8_addr;

    always @(posedge clk) begin
        // Divide by 2 (arithmetic series formula) - just shift right by 1
        // Result is in bits [64:1]
        stage8_result <= stage7_mult2[64:1];
        stage8_valid <= stage7_valid;
        stage8_addr <= stage7_addr;

        // DEBUG
        if (stage7_valid && stage7_addr < 5) begin
            $display("Entry %0d (k=%0d, const_k=%0d): result=%0d, mult2=%0d",
                     stage7_addr, stage7_k, stage7_const_k, stage7_mult2[64:1], stage7_mult2);
        end
    end

    // ==== Stage 9-10: Two-Stage Accumulation (32-bit chunks) ====
    reg [31:0] acc_low, acc_high;
    reg [32:0] stage9_new_low;
    reg [31:0] stage9_add_high;
    reg stage9_valid;

    always @(posedge clk) begin
        // Stage 9: Add lower 32 bits
        if (stage8_valid) begin
            stage9_new_low <= {1'b0, acc_low} + {1'b0, stage8_result[31:0]};
            stage9_add_high <= stage8_result[63:32];
            stage9_valid <= 1'b1;
        end else begin
            stage9_valid <= 1'b0;
        end
    end

    always @(posedge clk) begin
        // Stage 10: Add upper 32 bits with carry
        if (stage9_valid) begin
            acc_low <= stage9_new_low[31:0];
            acc_high <= acc_high + stage9_add_high + {31'b0, stage9_new_low[32]};
        end
    end

    // ==== Control FSM (Simplified) ====
    localparam S_IDLE = 0;
    localparam S_PROCESS = 1;
    localparam S_DRAIN = 2;
    localparam S_DONE = 3;

    reg [2:0] state;
    reg [9:0] drain_counter;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            rom_addr <= 0;
            acc_low <= 0;
            acc_high <= 0;
            done <= 0;
            drain_counter <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    rom_addr <= 0;
                    acc_low <= 0;
                    acc_high <= 0;
                    done <= 0;
                    state <= S_PROCESS;
                end

                S_PROCESS: begin
                    if (rom_addr < ENTRY_COUNT - 1) begin
                        rom_addr <= rom_addr + 1;
                    end else begin
                        // All ROM entries have been read, wait for pipeline to drain
                        // Pipeline depth is ~10 stages, so wait 15 cycles to be safe
                        drain_counter <= 15;
                        state <= S_DRAIN;
                    end
                end

                S_DRAIN: begin
                    if (drain_counter > 0) begin
                        drain_counter <= drain_counter - 1;
                    end else begin
                        total_sum <= {acc_high, acc_low};
                        done <= 1;
                        $display("Final sum: %0d (0x%h)", {acc_high, acc_low}, {acc_high, acc_low});
                        state <= S_DONE;
                    end
                end

                S_DONE: begin
                    // Stay done
                end
            endcase
        end
    end

endmodule
