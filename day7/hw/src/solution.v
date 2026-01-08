`timescale 1ns/1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] splitters_hit,
    output reg done
);
    `include "params.vh"
    
    // Memory: One row per cycle
    // Note: If memory is too wide for BRAM width, inferred as distributed or multiple BRAMs.
    // WIDTH=141 -> 282 bits. Fits in standard 36k BRAM (which can be configured wide) or distributed.
    // Actually, simple array of regs is fine for simulation.
    reg [ROW_BITS-1:0] mem [0:HEIGHT-1];
    
    initial begin
        $readmemh("../input/input.hex", mem);
    end
    
    reg [31:0] y;
    reg [WIDTH-1:0] active_mask;
    
    // Pipeline Registers? Or 1-cycle logic?
    // 141-wide logic is fine for 1 cycle at modest freq.
    // Let's do 1 row per cycle.
    
    reg [ROW_BITS-1:0] current_row_data;
    wire [WIDTH-1:0] next_active;
    wire [15:0]      row_hit_count; // Max 141 hits
    
    // Combinational Logic for Next State
    // Cell Logic:
    // next_active[i] is true if:
    // (active[i] | S[i]) AND ^[i] IS FALSE (Pass through)
    // (active[i-1] | S[i-1]) AND ^[i-1] IS TRUE (Split Right)
    // (active[i+1] | S[i+1]) AND ^[i+1] IS TRUE (Split Left)
    
    // Decode helpers
    // code[i] = current_row_data[2*i +: 2]
    // IsSplit(i) = (code[i] == 1)
    // IsSource(i) = (code[i] == 2)
    // Pass(i) = (code[i] != 1) => . or S.
    // Actually, logic:
    // If S, it adds to active.
    // EffectiveActive[i] = Active[i] | IsSource[i].
    // If EffectiveActive[i]:
    //    If IsSplit(i): Hit++, Throw Left (i-1), Throw Right (i+1).
    //    Else: Pass Down (i).
    
    genvar i;
    
    wire [WIDTH-1:0] effective_active;
    wire [WIDTH-1:0] is_split;
    wire [WIDTH-1:0] beam_throwing_left; // From i to i-1
    wire [WIDTH-1:0] beam_throwing_right; // From i to i+1
    wire [WIDTH-1:0] beam_passing_down;   // From i to i
    
    // Population Count Logic
    // We need to count bits in (effective_active & is_split).
    // Parallel adder tree?
    // Verilog behavioral: integer loop is fine for synthesis tools sometimes, 
    // but building an adder tree explicitly is safer for "Principal FPGA Engineer" style.
    // For now, I'll use a behavioral loop in a function/always_comb for clarity and brevity in prompt.
    // Correct popcount is critical.
    
    // 1. Decode & Logic
    generate
        for (i=0; i<WIDTH; i=i+1) begin : cells
            wire [1:0] code = current_row_data[2*i+1 : 2*i];
            assign is_split[i] = (code == 2'd1);
            wire is_source = (code == 2'd2);
            
            assign effective_active[i] = active_mask[i] | is_source;
            
            assign beam_throwing_left[i]  = effective_active[i] & is_split[i];
            assign beam_throwing_right[i] = effective_active[i] & is_split[i];
            assign beam_passing_down[i]   = effective_active[i] & (~is_split[i]);
        end
    endgenerate
    
    // 2. Next State Routing
    generate
        for (i=0; i<WIDTH; i=i+1) begin : routing
            wire from_left;
            wire from_right;
            wire from_up;
            
            if (i == 0) assign from_left = 0;
            else assign from_left = beam_throwing_right[i-1]; // i-1 throws Right to i
            
            if (i == WIDTH-1) assign from_right = 0;
            else assign from_right = beam_throwing_left[i+1]; // i+1 throws Left to i
            
            assign from_up = beam_passing_down[i];
            
            assign next_active[i] = from_left | from_right | from_up;
        end
    endgenerate
    
    // 3. Count Splitters
    reg [15:0] pop_count;
    integer k;
    always @(*) begin
        pop_count = 0;
        for (k=0; k<WIDTH; k=k+1) begin
            if (effective_active[k] && is_split[k]) begin
                pop_count = pop_count + 1;
            end
        end
    end
    
    // FSM / Sequential
    always @(posedge clk) begin
        if (rst) begin
            y <= 0;
            active_mask <= 0;
            splitters_hit <= 0;
            done <= 0;
            // Pre-load first row for next cycle?
            // Or fetch in cycle.
            // Let's use registered fetch if frequency high, but logic here assumes 'current_row_data' is ready.
            // Mem read is usually synchronous.
            // If we use 'assign current_row_data = mem[y]', it's behavioral async read.
            // Let's use async read for simplicity (distributed RAM).
        end else begin
            if (!done) begin
                // Process Row y
                // Update stats
                splitters_hit <= splitters_hit + pop_count;
                active_mask <= next_active;
                
                if (y == HEIGHT - 1) begin
                    done <= 1;
                end else begin
                    y <= y + 1;
                end
            end
        end
    end
    
    // Async Read
    always @(*) begin
        if (y < HEIGHT) current_row_data = mem[y];
        else current_row_data = 0;
    end

endmodule
