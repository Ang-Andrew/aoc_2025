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
    reg [2:0] state;
    
    // Multipliers for K=1..12: (10^k + 1)
    // We can store them in a LUT case statement to save logic vs calculating
    reg [63:0] const_k;
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
    
    localparam ST_IDLE = 0;
    localparam ST_DIV1 = 1;
    localparam ST_DIV2 = 2;
    localparam ST_CALC = 3;
    localparam ST_NEXT = 4;
    localparam ST_DONE = 5;
    
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
                        state <= ST_DIV1;
                        k <= 1;
                        sum_out <= 0;
                        done <= 0;
                        
                        // Setup Div 1: Ceil(Start / Const)
                        // Actually: floor((Start + Const - 1) / Const)
                        div_dividend_1 <= range_start + const_k - 1;
                        div_start <= 1;
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
                        
                        state <= ST_CALC;
                    end
                end
                
                ST_CALC: begin
                    if (res_start_idx <= res_end_idx) begin
                        // Sum arithmetic progression
                        // Val = id * Const.
                        // Sum = (id_start + id_end) * count / 2 * Const.
                        // Count = end - start + 1.
                        // Sum += (res_start_idx + res_end_idx) * (res_end_idx - res_start_idx + 1) / 2 * const_k;
                        
                        // We use a multiply-accumulate?
                        // This math is 64-bit mults. might need cycles or DSP inference.
                        // (S+E) is 65 bits. Count is 64. Result 128 bit. 
                        // Then * const_k (64 bit). Result 192 bit.
                        // This logic is HUGE.
                        // Wait, do we need full precision? Total sum fits in 64 bits (Day 2 result: 32e9).
                        // 32e9 fits in 35 bits.
                        // The inputs are ~10^10.
                        // S+E ~ 2*10^10.
                        // Count ~ varies.
                        // Maybe simpler:
                        // for range_calc, we can just assume Python verified logic fits? 
                        // Verilog `*` will synthesize DSPs or huge logic. 
                        // "Logic-only solutions".
                        // Is there a simpler way?
                        // Invalid IDs are sparse.
                        // Actually no, for K=1, indices are 1..9.
                        // K=10, indices 10^9..10^10.
                        // The sum is huge.
                        // Wait, Day 2 result is only 32 billion?
                        // If ranges are small, maybe count is small?
                        // If Range is "100-200", maybe 0 hits.
                        // The sum logic: `sum_out <= sum_out + ...`
                        // I'll trust standard `*` synthesis for now, since we saved Area on Generator/Divs.
                        // ECP5 has 18x18 multipliers. 64x64 is expensive but doable.
                        // Or I iterate.
                        // I'll write the expression. If synthesis fails, I'd optimize.
                        sum_out <= sum_out + ((res_start_idx + res_end_idx) * (res_end_idx - res_start_idx + 1) / 2) * const_k;
                    end
                    
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
                end
            endcase
         end
    end

endmodule
