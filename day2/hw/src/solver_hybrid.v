// Hybrid Parallel Solver: 3 K-Processors, 4 Batches
// Achieves 250MHz while fitting in 28 MULT18X18D blocks (3 units × 9 = 27 blocks)

module solver_hybrid #(
    parameter MEM_FILE = "mem.hex",
    parameter RANGE_COUNT = 38
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // Memory for ranges (128 bits: 64-bit start + 64-bit end)
    reg [127:0] ranges [0:RANGE_COUNT-1];
    initial $readmemh(MEM_FILE, ranges);

    // Control state machine
    localparam S_IDLE = 0;
    localparam S_LOAD_RANGE = 1;
    localparam S_BATCH1 = 2;
    localparam S_WAIT1 = 3;
    localparam S_ACC1 = 4;
    localparam S_BATCH2 = 5;
    localparam S_WAIT2 = 6;
    localparam S_ACC2 = 7;
    localparam S_BATCH3 = 8;
    localparam S_WAIT3 = 9;
    localparam S_ACC3 = 10;
    localparam S_BATCH4 = 11;
    localparam S_WAIT4 = 12;
    localparam S_ACC4 = 13;
    localparam S_NEXT_RANGE = 14;
    localparam S_DONE = 15;

    reg [3:0] state;
    reg [5:0] range_idx;

    // Current range being processed
    reg [39:0] current_range_start;
    reg [39:0] current_range_end;

    // 3 K-Iterator instances (process K values in batches)
    wire [63:0] k_sums [0:2];
    wire [2:0] k_dones;
    reg [2:0] k_starts;
    reg [11:0] k_values;  // 3 K values × 4 bits each

    genvar k;
    generate
        for (k = 0; k < 3; k = k + 1) begin : k_iterators
            k_iterator #(.K_VALUE(1)) iter (  // K_VALUE will be overridden
                .clk(clk),
                .rst(rst),
                .start(k_starts[k]),
                .range_start(current_range_start),
                .range_end(current_range_end),
                .sum_out(k_sums[k]),
                .done(k_dones[k]),
                .k_value_override(k_values[k*4 +: 4])  // Pass K value dynamically
            );
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            total_sum <= 0;
            done <= 0;
            range_idx <= 0;
            k_starts <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    range_idx <= 0;
                    total_sum <= 0;
                    done <= 0;
                    state <= S_LOAD_RANGE;
                end

                S_LOAD_RANGE: begin
                    if (range_idx < RANGE_COUNT) begin
                        current_range_start <= ranges[range_idx][39:0];
                        current_range_end <= ranges[range_idx][103:64];
                        state <= S_BATCH1;
                    end else begin
                        state <= S_DONE;
                    end
                end

                // Batch 1: K=1,2,3
                S_BATCH1: begin
                    k_values <= {4'd3, 4'd2, 4'd1};
                    k_starts <= 3'h7;
                    state <= S_WAIT1;
                end

                S_WAIT1: begin
                    k_starts <= 0;
                    if (&k_dones) begin
                        state <= S_ACC1;
                    end
                end

                S_ACC1: begin
                    total_sum <= total_sum + k_sums[0] + k_sums[1] + k_sums[2];
                    state <= S_BATCH2;
                end

                // Batch 2: K=4,5,6
                S_BATCH2: begin
                    k_values <= {4'd6, 4'd5, 4'd4};
                    k_starts <= 3'h7;
                    state <= S_WAIT2;
                end

                S_WAIT2: begin
                    k_starts <= 0;
                    if (&k_dones) begin
                        state <= S_ACC2;
                    end
                end

                S_ACC2: begin
                    total_sum <= total_sum + k_sums[0] + k_sums[1] + k_sums[2];
                    state <= S_BATCH3;
                end

                // Batch 3: K=7,8,9
                S_BATCH3: begin
                    k_values <= {4'd9, 4'd8, 4'd7};
                    k_starts <= 3'h7;
                    state <= S_WAIT3;
                end

                S_WAIT3: begin
                    k_starts <= 0;
                    if (&k_dones) begin
                        state <= S_ACC3;
                    end
                end

                S_ACC3: begin
                    total_sum <= total_sum + k_sums[0] + k_sums[1] + k_sums[2];
                    state <= S_BATCH4;
                end

                // Batch 4: K=10,11,12
                S_BATCH4: begin
                    k_values <= {4'd12, 4'd11, 4'd10};
                    k_starts <= 3'h7;
                    state <= S_WAIT4;
                end

                S_WAIT4: begin
                    k_starts <= 0;
                    if (&k_dones) begin
                        state <= S_ACC4;
                    end
                end

                S_ACC4: begin
                    total_sum <= total_sum + k_sums[0] + k_sums[1] + k_sums[2];
                    state <= S_NEXT_RANGE;
                end

                S_NEXT_RANGE: begin
                    range_idx <= range_idx + 1;
                    state <= S_LOAD_RANGE;
                end

                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
