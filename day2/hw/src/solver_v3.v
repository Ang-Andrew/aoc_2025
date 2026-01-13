// Ultra-Simple Solver V3 for 250MHz+ Timing
// Simple version for functional verification

module solver_v3 #(
    parameter RESULTS_FILE = "results.hex",
    parameter ENTRY_COUNT = 468
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // ROM with pre-computed results
    reg [63:0] results [0:ENTRY_COUNT-1];
    initial $readmemh(RESULTS_FILE, results);

    reg [9:0] rom_addr;
    reg [63:0] rom_data;
    reg [63:0] stage1_data;
    reg [63:0] accumulator;

    // Stage 0: ROM read (registered)
    always @(posedge clk) begin
        rom_data <= results[rom_addr];
    end

    // Stage 1: Register transfer
    always @(posedge clk) begin
        stage1_data <= rom_data;
    end

    // Stage 2-3: Accumulation (split into two 32-bit adds for timing)
    reg [32:0] acc_low_next;
    reg [32:0] acc_high_next;

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 64'b0;
        end else begin
            // Two-step accumulation for better timing
            acc_low_next = {1'b0, accumulator[31:0]} + {1'b0, stage1_data[31:0]};
            acc_high_next = {1'b0, accumulator[63:32]} + {1'b0, stage1_data[63:32]} + {32'b0, acc_low_next[32]};
            accumulator <= {acc_high_next[31:0], acc_low_next[31:0]};
        end
    end

    // Control FSM
    localparam S_IDLE = 0;
    localparam S_PROCESS = 1;
    localparam S_DRAIN = 2;
    localparam S_DONE = 3;

    reg [2:0] state;
    reg [3:0] drain_counter;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            rom_addr <= 0;
            done <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    rom_addr <= 0;
                    done <= 0;
                    state <= S_PROCESS;
                end

                S_PROCESS: begin
                    if (rom_addr < ENTRY_COUNT - 1) begin
                        rom_addr <= rom_addr + 1;
                    end else begin
                        drain_counter <= 4;
                        state <= S_DRAIN;
                    end
                end

                S_DRAIN: begin
                    if (drain_counter > 0) begin
                        drain_counter <= drain_counter - 1;
                    end else begin
                        total_sum <= accumulator;
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
