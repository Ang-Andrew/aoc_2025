// Ultra-Optimized Solver V2 for 250MHz Timing
// CRITICAL PATH OPTIMIZATION: Store const_k in ROM to eliminate 2-level mux
//
// Key improvements over V1:
// 1. const_k stored in ROM → eliminates 12-way mux (saves 2 LUT levels + routing)
// 2. Simpler Stage 1 logic → better timing margin
// 3. 16-bit arithmetic chunks → shallower carry chains
// 4. Explicit separation of operations → cleaner pipeline
//
// Target: 250MHz (4ns period)
// Critical path budget: ~3.5ns logic + routing per stage

module solver_v2 #(
    parameter DIVISIONS_FILE = "divisions_v2.hex",
    parameter ENTRY_COUNT = 468  // 39 ranges × 12 K values
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // ==== Stage 0: ROM with Registered Outputs ====
    // ROM contains: x_start (40) + x_end (40) + const_k (41) + valid (1) = 122 bits (stored in 128-bit)
    reg [127:0] divisions [0:ENTRY_COUNT-1];
    initial $readmemh(DIVISIONS_FILE, divisions);

    reg [9:0] rom_addr;
    reg [127:0] rom_data;

    always @(posedge clk) begin
        rom_data <= divisions[rom_addr];  // Registered ROM output
    end

    // ==== Stage 1: Unpack ROM Data (Pure Register Transfer) ====
    // NO LOGIC - just wire assignments to registers
    reg [39:0] stage1_x_start, stage1_x_end;
    reg [40:0] stage1_const_k;
    reg stage1_valid;

    always @(posedge clk) begin
        stage1_x_start <= rom_data[39:0];
        stage1_x_end <= rom_data[79:40];
        stage1_const_k <= rom_data[120:80];
        stage1_valid <= rom_data[121];
    end

    // ==== Stage 2-4: Chunked Addition (x_start + x_end) ====
    // Use 16-bit chunks for shallow logic depth
    // Stage 2: Low 16 bits
    reg [16:0] stage2_add_low;  // 16 bits + carry
    reg [39:0] stage2_x_start, stage2_x_end;
    reg [40:0] stage2_const_k;
    reg stage2_valid;

    always @(posedge clk) begin
        stage2_add_low <= {1'b0, stage1_x_start[15:0]} + {1'b0, stage1_x_end[15:0]};
        stage2_x_start <= stage1_x_start;
        stage2_x_end <= stage1_x_end;
        stage2_const_k <= stage1_const_k;
        stage2_valid <= stage1_valid;
    end

    // Stage 3: Mid 16 bits
    reg [16:0] stage3_add_mid;
    reg [15:0] stage3_add_low;
    reg [39:0] stage3_x_start, stage3_x_end;
    reg [40:0] stage3_const_k;
    reg stage3_valid;

    always @(posedge clk) begin
        stage3_add_mid <= {1'b0, stage2_x_start[31:16]} + {1'b0, stage2_x_end[31:16]} + {16'b0, stage2_add_low[16]};
        stage3_add_low <= stage2_add_low[15:0];
        stage3_x_start <= stage2_x_start;
        stage3_x_end <= stage2_x_end;
        stage3_const_k <= stage2_const_k;
        stage3_valid <= stage2_valid;
    end

    // Stage 4: High 8 bits and assemble
    reg [40:0] stage4_sum;
    reg [40:0] stage4_count;  // Will come from parallel subtraction pipeline
    reg [40:0] stage4_const_k;
    reg stage4_valid;

    always @(posedge clk) begin
        stage4_sum <= {stage3_x_start[39:32] + stage3_x_end[39:32] + {7'b0, stage3_add_mid[16]},
                       stage3_add_mid[15:0], stage3_add_low};
        stage4_const_k <= stage3_const_k;
        stage4_valid <= stage3_valid;
    end

    // ==== Stage 2b-4b: Parallel Chunked Subtraction (x_end - x_start + 1) ====
    // Stage 2b: Low 16 bits
    reg [16:0] stage2_sub_low;

    always @(posedge clk) begin
        stage2_sub_low <= {1'b0, stage1_x_end[15:0]} - {1'b0, stage1_x_start[15:0]} + 17'd1;
    end

    // Stage 3b: Mid 16 bits
    reg [16:0] stage3_sub_mid;
    reg [15:0] stage3_sub_low;

    always @(posedge clk) begin
        stage3_sub_mid <= {1'b0, stage2_x_end[31:16]} - {1'b0, stage2_x_start[31:16]} - {16'b0, stage2_sub_low[16]};
        stage3_sub_low <= stage2_sub_low[15:0];
    end

    // Stage 4b: High 8 bits and assemble
    always @(posedge clk) begin
        stage4_count <= {stage3_x_end[39:32] - stage3_x_start[39:32] - {7'b0, stage3_sub_mid[16]},
                         stage3_sub_mid[15:0], stage3_sub_low};
    end

    // ==== Stage 5-7: Pipelined DSP Multiplication (sum * count) ====
    (* use_dsp = "yes" *) reg [81:0] stage5_mult1;
    (* use_dsp = "yes" *) reg [81:0] stage6_mult1;
    reg [40:0] stage5_const_k, stage6_const_k;
    reg stage5_valid, stage6_valid;

    always @(posedge clk) begin
        stage5_mult1 <= stage4_sum * stage4_count;
        stage5_const_k <= stage4_const_k;
        stage5_valid <= stage4_valid;
    end

    always @(posedge clk) begin
        stage6_mult1 <= stage5_mult1;
        stage6_const_k <= stage5_const_k;
        stage6_valid <= stage5_valid;
    end

    // Stage 7: Pipeline delay
    (* use_dsp = "yes" *) reg [81:0] stage7_mult1;
    reg [40:0] stage7_const_k;
    reg stage7_valid;

    always @(posedge clk) begin
        stage7_mult1 <= stage6_mult1;
        stage7_const_k <= stage6_const_k;
        stage7_valid <= stage6_valid;
    end

    // ==== Stage 8-10: Pipelined DSP Multiplication (* const_k) ====
    (* use_dsp = "yes" *) reg [122:0] stage8_mult2;
    (* use_dsp = "yes" *) reg [122:0] stage9_mult2;
    reg stage8_valid, stage9_valid;

    always @(posedge clk) begin
        stage8_mult2 <= stage7_mult1 * stage7_const_k;
        stage8_valid <= stage7_valid;
    end

    always @(posedge clk) begin
        stage9_mult2 <= stage8_mult2;
        stage9_valid <= stage8_valid;
    end

    // Stage 10: Pipeline delay
    (* use_dsp = "yes" *) reg [122:0] stage10_mult2;
    reg stage10_valid;

    always @(posedge clk) begin
        stage10_mult2 <= stage9_mult2;
        stage10_valid <= stage9_valid;
    end

    // ==== Stage 11: Divide by 2 ====
    reg [63:0] stage11_result;
    reg stage11_valid;

    always @(posedge clk) begin
        stage11_result <= stage10_mult2[64:1];  // Arithmetic series formula: sum/2
        stage11_valid <= stage10_valid;
    end

    // ==== Stage 12-13: Two-Stage Chunked Accumulation ====
    reg [31:0] acc_low, acc_high;
    reg [32:0] stage12_new_low;
    reg [31:0] stage12_add_high;
    reg stage12_valid;

    always @(posedge clk) begin
        if (stage11_valid) begin
            stage12_new_low <= {1'b0, acc_low} + {1'b0, stage11_result[31:0]};
            stage12_add_high <= stage11_result[63:32];
            stage12_valid <= 1'b1;
        end else begin
            stage12_valid <= 1'b0;
        end
    end

    always @(posedge clk) begin
        if (stage12_valid) begin
            acc_low <= stage12_new_low[31:0];
            acc_high <= acc_high + stage12_add_high + {31'b0, stage12_new_low[32]};
        end
    end

    // ==== Control FSM ====
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
                        // All ROM entries read, drain pipeline (13 stages + margin)
                        drain_counter <= 18;
                        state <= S_DRAIN;
                    end
                end

                S_DRAIN: begin
                    if (drain_counter > 0) begin
                        drain_counter <= drain_counter - 1;
                    end else begin
                        total_sum <= {acc_high, acc_low};
                        done <= 1;
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
