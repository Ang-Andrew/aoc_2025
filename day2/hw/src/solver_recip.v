// Sequential Solver using Reciprocal Multiplication
// Processes one range at a time, one K value at a time
// Optimized for 250MHz timing with minimal resources

module solver_recip #(
    parameter MEM_FILE = "mem.hex",
    parameter RANGE_COUNT = 38
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);

    // Memory for ranges (128 bits: 64-bit start + 64-bit end, but we use 40 bits each)
    reg [127:0] ranges [0:RANGE_COUNT-1];
    initial $readmemh(MEM_FILE, ranges);

    // State machine
    localparam S_IDLE = 0;
    localparam S_LOAD_RANGE = 1;
    localparam S_CALC = 2;
    localparam S_WAIT = 3;
    localparam S_ACC = 4;
    localparam S_NEXT_K = 5;
    localparam S_NEXT_RANGE = 6;
    localparam S_DONE = 7;

    reg [2:0] state;
    reg [5:0] range_idx;
    reg [3:0] k_value;

    // Current range being processed
    reg [39:0] current_range_start;
    reg [39:0] current_range_end;

    // Range calculator instance
    wire [63:0] calc_sum;
    wire calc_done;
    reg calc_start;

    recip_range_calc #(.K_VALUE(1)) calc_inst (
        .clk(clk),
        .rst(rst),
        .start(calc_start),
        .range_start(current_range_start),
        .range_end(current_range_end),
        .k_override(k_value),
        .sum_out(calc_sum),
        .done(calc_done)
    );

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            total_sum <= 0;
            done <= 0;
            range_idx <= 0;
            k_value <= 1;
            calc_start <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    range_idx <= 0;
                    k_value <= 1;
                    total_sum <= 0;
                    done <= 0;
                    state <= S_LOAD_RANGE;
                end

                S_LOAD_RANGE: begin
                    if (range_idx < RANGE_COUNT) begin
                        current_range_start <= ranges[range_idx][39:0];
                        current_range_end <= ranges[range_idx][103:64];
                        k_value <= 1;
                        state <= S_CALC;
                    end else begin
                        state <= S_DONE;
                    end
                end

                S_CALC: begin
                    // Start calculation for current K and range
                    calc_start <= 1;
                    state <= S_WAIT;
                end

                S_WAIT: begin
                    calc_start <= 0;
                    if (calc_done) begin
                        state <= S_ACC;
                    end
                end

                S_ACC: begin
                    // Accumulate result
                    total_sum <= total_sum + calc_sum;
                    state <= S_NEXT_K;
                end

                S_NEXT_K: begin
                    if (k_value < 12) begin
                        k_value <= k_value + 1;
                        state <= S_CALC;
                    end else begin
                        // Done with all K values for this range
                        state <= S_NEXT_RANGE;
                    end
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
