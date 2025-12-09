module generator #(
    parameter MAX_K = 12
)(
    input clk,
    input rst,
    input stall,
    output reg [63:0] out_val,
    output reg out_valid,
    output reg done
);
    
    // State Machine
    localparam S_INIT_LEVEL  = 0;
    localparam S_CALC_START  = 1;
    localparam S_RUN         = 2;
    localparam S_DONE        = 3;
    
    reg [1:0] state;
    reg [3:0] k;
    
    // Data Registers
    reg [63:0] multiplier; // The repetition factor (e.g. 101)
    reg [63:0] x_limit;    // The count limit (e.g. 90)
    reg [63:0] x_count;    // Current count
    reg [63:0] base_x;     // 10^(k-1)
    
    // Helper signals for Shift-Add logic to replace multiplication
    // We need to compute: 
    // 1. Next Multiplier: M_new = M_old * 10 - 9.
    // 2. Next X_Limit:    L_new = L_old * 10.
    // 3. Next Base:       B_new = B_old * 10
    // 4. Start Val:       Val   = (B_new - 1) * M_new = (10^k - 1) * (10^k + 1) = 10^2k - 1.
    //    Actually simpler: The first palindrome of len 2k is always 10...01 * 10...0 = 10...00...01 ??
    //    Wait. k=1 (len 2): 11. 
    //    k=2 (len 4): 1001. Start is 10 * 101? No.
    //    Range for k=2 is 10..99.
    //    First val is 10 * 101 = 1010.
    //    So Val_start = Base_X * Multiplier.
    //    Wait, Base_X * 10 is the new Base.
    //    Let's stick to iterative updates.
    
    // Arithmetic helpers (Combinatorial)
    wire [63:0] mult_times_10 = (multiplier << 3) + (multiplier << 1);
    wire [63:0] limit_times_10 = (x_limit << 3) + (x_limit << 1);
    wire [63:0] base_times_10 = (base_x << 3) + (base_x << 1);
    
    // Initialization Logic helper
    // We need Val = Base * Mult.
    // We can't do this in 1 cycle without DSP.
    // But notice: P_first for k is always '1' followed by k-1 zeros, then '1' followed by k-1 zeros?
    // Ex k=2: 1010. k=3: 100100.
    // Actually, P_first = Base * Mult is hard.
    // But P_first(k) = P_first(k-1) * 100 + something?
    // Let's just use a multi-cycle shift-add initialization state if needed, 
    // OR just recognize that out_val tracks the current value.
    // When we switch K, the Gap jumps. 
    // New Val = Old_Limit_End + ??? No continuous.
    
    // Let's implement a simple iterative multiplier for the "Start Value" calculation.
    // It only runs once per K level (12 times total).
    
    reg [63:0] init_a, init_b;
    reg [63:0] init_res;
    reg [6:0]  init_ctr;
    reg        init_busy;
    
    always @(posedge clk) begin
        if (rst) begin
            k <= 1;
            state <= S_INIT_LEVEL;
            done <= 0;
            out_valid <= 0;
            out_val <= 0;
            
            // k=1 constants
            multiplier <= 11; 
            x_limit <= 9;
            base_x <= 1; // 10^(k-1) for k=1 is 10^0 = 1
            x_count <= 0;
            
            // For k=1, start val is 1 * 11 = 11.
            // But we start loop at 0 count.
            // Logic: val <= val + multiplier.
            // So if we start at "Start - Multiplier", first add gives Start.
            // Start = 11. Multiplier = 11. So Init Reg should be 0.
            out_val <= 0; 
            
            init_busy <= 0;
        end else begin
            out_valid <= 0; 
            
            case (state)
                S_INIT_LEVEL: begin
                    // Prepare for Level K
                    if (k == 1) begin
                         state <= S_RUN;
                         // out_val is 0. 
                         // multiplier is 11.
                         $display("GEN INIT k=1");
                    end else begin
                         // Update constants
                         multiplier <= mult_times_10 - 9; 
                         x_limit <= limit_times_10;
                         base_x <= base_times_10;
                         
                         state <= S_CALC_START;
                         
                         // Load the Iterative Multiplier inputs
                         // Correctness: mult_times_10 depends on current 'multiplier'.
                         // 'multiplier' register updates at clock edge.
                         // 'init_b' updates at clock edge.
                         // Both see OLD 'multiplier'. So 'mult_times_10' uses OLD 'multiplier'.
                         // This is correct: we want New Mult based on Old Mult.
                         // But we want Init_A to be New Base. New Base = Old Base * 10.
                         // base_times_10 uses Old Base.
                         // So this is correct.
                         init_a <= base_times_10;
                         init_b <= mult_times_10 - 9;
                         init_res <= 0;
                         init_ctr <= 0;
                         init_busy <= 1;
                         $display("GEN INIT k=%d starting MUL", k);
                    end
                end
                
                S_CALC_START: begin
                    // Iterative shift-add multiplication for (init_a * init_b)
                    if (init_ctr >= 64) begin
                        // Done.
                        // Result in init_res is Start Value.
                        // We need out_val = Start - Multiplier.
                        // Note: 'multiplier' was updated in prev cycle (S_INIT_LEVEL).
                        // So 'multiplier' now holds the NEW multiplier.
                        // init_res holds New_Base * New_Mult.
                        out_val <= init_res - multiplier;
                        x_count <= 0;
                        state <= S_RUN;
                        init_busy <= 0;
                    end else begin
                        if ((init_b >> init_ctr) & 1) begin
                            init_res <= init_res + (init_a << init_ctr);
                        end
                        init_ctr <= init_ctr + 1;
                    end
                end
                
                S_RUN: begin
                    if (!stall) begin
                        out_valid <= 1; 
                        out_val <= out_val + multiplier; 
                        x_count <= x_count + 1;
                        
                        // Check logic 
                        if (x_count == x_limit - 1) begin
                             if (k >= MAX_K) begin
                                 done <= 1;
                                 state <= S_DONE;
                                 out_valid <= 1; // Emit this last one
                             end else begin
                                 k <= k + 1;
                                 state <= S_INIT_LEVEL; 
                             end
                        end
                    end else begin
                        // Stalled. Hold Valid high if we were running.
                         out_valid <= 1;
                    end
                end
                
                S_DONE: begin
                    done <= 1;
                    out_valid <= 0;
                end
            endcase
            
            // Reset override
            if (rst) begin
               state <= S_INIT_LEVEL;
               k <= 1;
            end
        end
    end

endmodule
