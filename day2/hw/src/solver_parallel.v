// Parallel Solver using 12 K-Iterator Units
// Achieves 250MHz by eliminating division and using DSP blocks

module solver_parallel #(
    parameter MEM_FILE = "mem.hex",
    parameter RANGE_COUNT = 38
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // Memory for ranges (128 bits: 64-bit start + 64-bit end from file)
    // We truncate to 40 bits when using since max value is <2^34
    reg [127:0] ranges [0:RANGE_COUNT-1];
    initial $readmemh(MEM_FILE, ranges);

    // Control state machine
    localparam S_IDLE = 0;
    localparam S_START_ITERS = 1;
    localparam S_WAIT_ITERS = 2;
    localparam S_ACCUMULATE = 3;
    localparam S_NEXT_RANGE = 4;
    localparam S_DONE = 5;

    reg [2:0] state;
    reg [5:0] range_idx;

    // Current range being processed
    reg [39:0] current_range_start;
    reg [39:0] current_range_end;

    // 12 K-Iterator instances
    wire [63:0] k_sums [0:11];
    wire [11:0] k_dones;
    reg [11:0] k_starts;

    genvar k;
    generate
        for (k = 0; k < 12; k = k + 1) begin : k_iterators
            k_iterator #(.K_VALUE(k+1)) iter (
                .clk(clk),
                .rst(rst),
                .start(k_starts[k]),
                .range_start(current_range_start),
                .range_end(current_range_end),
                .sum_out(k_sums[k]),
                .done(k_dones[k])
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
                    state <= S_START_ITERS;
                end

                S_START_ITERS: begin
                    if (range_idx < RANGE_COUNT) begin
                        // Load current range (truncate 64-bit to 40-bit)
                        current_range_start <= ranges[range_idx][39:0];
                        current_range_end <= ranges[range_idx][103:64];  // End is in [127:64], take lower 40
                        // Start all 12 K-iterators in parallel
                        k_starts <= 12'hFFF;
                        state <= S_WAIT_ITERS;
                    end else begin
                        state <= S_DONE;
                    end
                end

                S_WAIT_ITERS: begin
                    // Clear start signals
                    k_starts <= 0;
                    // Wait for all iterators to finish
                    if (&k_dones) begin  // All done
                        state <= S_ACCUMULATE;
                    end
                end

                S_ACCUMULATE: begin
                    // Sum results from all 12 K-iterators
                    total_sum <= total_sum + k_sums[0] + k_sums[1] + k_sums[2] + k_sums[3] +
                                             k_sums[4] + k_sums[5] + k_sums[6] + k_sums[7] +
                                             k_sums[8] + k_sums[9] + k_sums[10] + k_sums[11];
                    state <= S_NEXT_RANGE;
                end

                S_NEXT_RANGE: begin
                    range_idx <= range_idx + 1;
                    state <= S_START_ITERS;
                end

                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
