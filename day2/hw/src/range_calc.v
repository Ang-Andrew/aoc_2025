module range_calc #(
    parameter MAX_K = 12
)(
    input clk,
    input rst,
    input start,
    input [63:0] range_start,
    input [63:0] range_end,
    output reg [63:0] sum_out,
    output reg done
);

    reg [3:0] k;
    reg [3:0] state;

    // Multipliers for K=1..12: (10^k + 1)
    // We can store them in a LUT case statement to save logic vs calculating
    reg [63:0] const_k;
    reg [63:0] const_k_reg;  // Registered version for stable division
    always @(*) begin
        case (k)
            1: const_k = 11;
            2: const_k = 101;
            3: const_k = 1001;
            4: const_k = 10001;
            5: const_k = 100001;
            6: const_k = 1000001;
            7: const_k = 10000001;
            8: const_k = 100000001;
            9: const_k = 1000000001;
            10: const_k = 10000000001;
            11: const_k = 100000000001;
            12: const_k = 1000000000001;
            default: const_k = 1;
        endcase
    end

    // Register const_k for stable use in division
    always @(posedge clk) begin
        const_k_reg <= const_k;
    end
    
    // Bounds for K: [10^(k-1), 10^k - 1] * const_k  <-- Wait.
    // The "Invalid IDs" are P = x * (10^k+1).
    // Valid x range for K is [10^(k-1), 10^k - 1].
    // e.g. K=1: x in [1, 9]. P in [11, 99].
    // K=2: x in [10, 99]. P in [1010, 9999].
    reg [63:0] x_min, x_max;
    always @(*) begin
        case (k)
            1: begin x_min=1; x_max=9; end
            2: begin x_min=10; x_max=99; end
            3: begin x_min=100; x_max=999; end
            4: begin x_min=1000; x_max=9999; end
            5: begin x_min=10000; x_max=99999; end
            6: begin x_min=100000; x_max=999999; end
            7: begin x_min=1000000; x_max=9999999; end
            8: begin x_min=10000000; x_max=99999999; end
            9: begin x_min=100000000; x_max=999999999; end
            10: begin x_min=1000000000; x_max=9999999999; end
            11: begin x_min=10000000000; x_max=99999999999; end
            12: begin x_min=100000000000; x_max=999999999999; end
            default: begin x_min=0; x_max=0; end
        endcase
    end

    // Divider Interface
    reg div_start;
    reg [63:0] div_dividend_1, div_dividend_2;
    wire [63:0] div_q_1, div_q_2;
    wire div_done_1, div_done_2;
    
    // Two dividers per core? That's 80 dividers total. logic-heavy but fits.
    // Or reuse 1 divider? Reuse saves area, doubles latency.
    // 80 dividers * 300 LUTs = 24k. Tight on 25F.
    // Let's use 1 divider and sequence states.
    
    div64 d1 (
        .clk(clk), .rst(rst), .start(div_start),
        .dividend(div_dividend_1), .divisor(const_k),
        .quotient(div_q_1), .done(div_done_1)
    );
    
    reg [2:0] sub_state;
    reg [63:0] res_start_idx;
    reg [63:0] res_end_idx;
    reg [127:0] calc_temp;

    // Pipeline registers for breaking up the multiplication
    reg [63:0] pipe_sum;       // res_start_idx + res_end_idx
    reg [63:0] pipe_count;     // res_end_idx - res_start_idx + 1
    (* use_dsp = "yes" *) reg [127:0] pipe_prod1;    // sum * count
    reg [63:0] pipe_const_k_reg;  // Registered const_k for multiplication

    // Split 64-bit additions into two 32-bit stages
    reg [31:0] add_low;
    reg add_carry;
    reg [31:0] sub_low;
    reg sub_borrow;

    localparam ST_IDLE = 0;
    localparam ST_DIV1 = 1;
    localparam ST_DIV2 = 2;
    localparam ST_CALC1 = 3;
    localparam ST_CALC1B = 4;  // Second stage of addition
    localparam ST_CALC2 = 5;
    localparam ST_CALC3 = 6;
    localparam ST_CALC4 = 7;
    localparam ST_NEXT = 8;
    localparam ST_DONE = 9;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= ST_IDLE;
            sum_out <= 0;
            done <= 0;
            k <= 1;
            div_start <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (start) begin
                        k <= 1;
                        sum_out <= 0;
                        done <= 0;
                        state <= ST_NEXT;  // Go to NEXT first to let const_k_reg settle
                    end
                end
                
                ST_DIV1: begin
                    div_start <= 0; // Pulse
                    if (div_done_1) begin
                        // Clip with X bounds
                        if (div_q_1 < x_min) res_start_idx <= x_min;
                        else res_start_idx <= div_q_1;
                        
                        // Setup Div 2: Floor(End / Const)
                        div_dividend_1 <= range_end;
                        div_start <= 1;
                        state <= ST_DIV2;
                    end
                end
                
                ST_DIV2: begin
                    div_start <= 0;
                    if (div_done_1) begin
                        // Clip
                        if (div_q_1 > x_max) res_end_idx <= x_max;
                        else res_end_idx <= div_q_1;

                        state <= ST_CALC1;
                    end
                end

                ST_CALC1: begin
                    if (res_start_idx <= res_end_idx) begin
                        // First pipeline stage: calculate lower 32 bits of additions
                        {add_carry, add_low} <= {1'b0, res_start_idx[31:0]} + {1'b0, res_end_idx[31:0]};
                        {sub_borrow, sub_low} <= {1'b0, res_end_idx[31:0]} - {1'b0, res_start_idx[31:0]} + 33'd1;
                        pipe_const_k_reg <= const_k;
                        state <= ST_CALC1B;
                    end else begin
                        // No contribution, skip to next
                        if (k >= MAX_K) state <= ST_DONE;
                        else begin
                            k <= k + 1;
                            state <= ST_NEXT;
                        end
                    end
                end

                ST_CALC1B: begin
                    // Second pipeline stage: calculate upper 32 bits and complete additions
                    pipe_sum <= {res_start_idx[63:32] + res_end_idx[63:32] + {31'b0, add_carry}, add_low};
                    pipe_count <= {res_end_idx[63:32] - res_start_idx[63:32] - {31'b0, sub_borrow}, sub_low};
                    state <= ST_CALC2;
                end

                ST_CALC2: begin
                    // Third pipeline stage: first multiplication (sum * count)
                    pipe_prod1 <= pipe_sum * pipe_count;
                    state <= ST_CALC3;
                end

                ST_CALC3: begin
                    // Third pipeline stage: second multiplication (* const_k)
                    calc_temp <= pipe_prod1 * pipe_const_k_reg;
                    state <= ST_CALC4;
                end

                ST_CALC4: begin
                    // Fourth pipeline stage: divide by 2 and add to sum
                    sum_out <= sum_out + (calc_temp >> 1);

                    if (k >= MAX_K) state <= ST_DONE;
                    else begin
                        k <= k + 1;
                        state <= ST_NEXT;
                    end
                end
                
                ST_NEXT: begin
                    // 1 Cycle delay to latch new K/Const/Bounds
                     // Setup Div 1 for next K
                    div_dividend_1 <= range_start + const_k - 1;
                    div_start <= 1;
                    state <= ST_DIV1;
                end
                
                ST_DONE: begin
                    done <= 1;
                    if (!start) begin  // Wait for start to go low, then return to IDLE
                        state <= ST_IDLE;
                    end
                end
            endcase
         end
    end

endmodule
