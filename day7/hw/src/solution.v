`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] splitters_hit,
    output reg [63:0] active_count,
    output reg done
);
    `include "params.vh"
    
    reg [7:0] mem [0:MEM_SIZE-1];
    
    initial begin
        $readmemh("../input/input.hex", mem);
    end
    
    reg [WIDTH-1:0] active_beams;
    reg [WIDTH-1:0] next_active_beams;
    
    integer x, y, i;
    
    // FSM
    localparam S_INIT = 0;
    localparam S_ROW_START = 1;
    localparam S_SCAN_PIXEL = 2;
    localparam S_ROW_END = 3;
    localparam S_DONE = 4;
    
    reg [3:0] state;
    reg [7:0] char_read;
    
    function integer get_addr;
        input integer cx, cy;
        begin
            get_addr = cy * WIDTH + cx;
        end
    endfunction
    
    // Population count helper
    // For simulation, loop is fine.
    // For synthesis, need tree adder.
    // We'll use a simple loop in a task/function for now.
    function [63:0] count_bits;
        input [WIDTH-1:0] vec;
        integer k;
        begin
            count_bits = 0;
            for (k = 0; k < WIDTH; k = k + 1) begin
                if (vec[k]) count_bits = count_bits + 1;
            end
        end
    endfunction
    
    always @(posedge clk) begin
        if (rst) begin
            splitters_hit <= 0;
            active_count <= 0;
            done <= 0;
            state <= S_INIT;
            active_beams <= 0;
            next_active_beams <= 0;
            x <= 0;
            y <= 0;
        end else begin
            case (state)
                S_INIT: begin
                    y <= 0;
                    state <= S_ROW_START;
                    // Initial scan for S could be here or merged.
                    // Let's assume S is handled in logical flow:
                    // If row 0, we treat 'S' as active source.
                end
                
                S_ROW_START: begin
                    x <= 0;
                    next_active_beams <= 0;
                    state <= S_SCAN_PIXEL;
                end
                
                S_SCAN_PIXEL: begin
                    if (x >= WIDTH) begin
                        state <= S_ROW_END;
                    end else begin
                        char_read = mem[get_addr(x, y)];
                        
                        // Check S on any row (source logic)
                        // Or just row 0? Problem implies "Start at S".
                        // Assuming S introduces a beam.
                        if (char_read == "S") begin
                            // S is active always? Or just introduces active?
                            // Logic: If S, it adds to active flow for THIS row processing?
                            // Streaming logic:
                            // We are determining Next Row from Current Row + Grid.
                            // But S acts as a source.
                            // So if Grid[x] == 'S', we treat it as if active_beams[x] was 1?
                            // Yes.
                            // And passes through.
                            next_active_beams[x] <= 1; 
                            // Note: OR logic? next_active_beams initialized to 0.
                            // We use <= assignments.
                            // If we have multiple assignments to same reg in block, last wins.
                            // But we are setting specific bits.
                            // We need "next_active_beams |= ...".
                            // Verilog: active <= active | mask.
                        end
                        
                        // Process Incoming Beam
                        // Is beam active at x?
                        if (active_beams[x] || char_read == "S") begin
                            if (char_read == "^") begin
                                splitters_hit <= splitters_hit + 1;
                                // Spawn Left and Right
                                if (x > 0) next_active_beams[x-1] <= 1; // Read-Modify-Write?
                                // Issue: Non-blocking assignment to specific bit index?
                                // "next_active_beams[i] <= 1" works for DIFFERENT i.
                                // If we write next_active_beams[x] (from S) and [x-1] (from neighbor), collision?
                                // Neighbor processed in previous cycle? No, serial scan x=0..W.
                                // If we are at x, we write to x-1?
                                // x-1 was handled in previous cycle.
                                // So we are overwriting x-1?
                                // "next_active_beams[x-1] |= 1" is not standard synth syntax for single bit.
                                // We need to accumulate.
                                // CORRECT APPROACH:
                                // Since we scan x, we only affect x-1, x, x+1.
                                // x+1 is future. x is current. x-1 is past.
                                // If we write x-1, we might overwrite what x-2 did to x-1?
                                // x-2 spawns x-1. x spawns x-1.
                                // Case: ^ at x-2 spawns right to x-1. ^ at x spawns left to x-1.
                                // We need OR logic.
                                // Since we serialize, we can't easily OR with "result of previous cycle write".
                                // BIT MASK APPROACH:
                                // next_active_beams <= next_active_beams | ...
                            end else begin
                                // Pass through (.) or S
                                next_active_beams[x] <= 1; // Or bitwise OR
                            end
                        end
                        
                        // FIX OR LOGIC:
                        // Use blocking assignments or register `temp_next`.
                        // Or simply:
                        // "next_active_beams" is updated at end of ROW? No, we need it for next row.
                        // We are building `next_active_beams` for row y+1.
                        // We can just use a large OR mask.
                        // active_beams[x] refers to CURRENT row (y).
                        // char_read refers to CURRENT row (y).
                        // If active[x] and char=='^':
                        //    next[x-1] = 1, next[x+1] = 1.
                        // We are scanning x.
                        // Can we write to next[x-1] safely?
                        // If we implement as `next_active_beams <= next_active_beams | MASK`, it implies reading the CURRENT register value (from start of cycle).
                        // So updates within the row scan accumulate?
                        // NO. In clocked process, RHS is evaluated at start of cycle.
                        // So intermediate updates are lost if we do multiple `|` over cycles.
                        // We need `next_active_beams` to be a variable (blocking) or updated incrementally?
                        // Correct: `next_active_beams` holds state from x-1 cycle?
                        // Yes, if we reference the register output.
                        // But we scan x=0, then x=1...
                        // Cycle 1: next <= next | mask0.
                        // Cycle 2: next <= (next | mask0) | mask1... NO.
                        // `next` on RHS is OLD value.
                        // So we just accumulate?
                        // Yes!
                        // `next_active_beams <= next_active_beams | new_bits`
                        // works if `next_active_beams` is the accumulator.
                        // At start of row, init to 0.
                        // Then accumulate.
                        // This synthesizes to a feedback loop.
                        
                        state <= S_SCAN_PIXEL; // Stay in loop
                        
                        // Actual logic with OR accumulation:
                        // Note: S logic included
                        if (char_read == "S") begin
                             next_active_beams <= next_active_beams | (1 << x);
                        end
                        
                        if (active_beams[x] || char_read == "S") begin
                            if (char_read == "^") begin
                                splitters_hit <= splitters_hit + 1;
                                // Mask for split
                                // Handle boundaries
                                if (x > 0 && x < WIDTH - 1)
                                     next_active_beams <= next_active_beams | (1 << (x-1)) | (1 << (x+1));
                                else if (x > 0)
                                     next_active_beams <= next_active_beams | (1 << (x-1));
                                else if (x < WIDTH - 1)
                                     next_active_beams <= next_active_beams | (1 << (x+1));
                            end else begin
                                // Pass through
                                next_active_beams <= next_active_beams | (1 << x);
                            end
                        end
                        
                        // Merge S logic and Beam logic?
                        // If S is present, it acts as a source at x.
                        // If beam enters S, it passes through.
                        // The logic `active_beams[x] || char=="S"` covers both.
                        // But need to ensure S marks next_active[x] too if it's a pass-through?
                        // If char is S, it is NOT '^', so it falls to `else` -> next[x] |= 1. Correct.
                        
                        x <= x + 1;
                    end
                end
                
                S_ROW_END: begin
                    // Move Next to Active
                    active_beams <= next_active_beams;
                    
                    // Count active beams at bottom?
                    // Problem asks "How many splitters hit?". I am counting that.
                    // Also "Energized cells"?
                    // Python returned `len(active_now)` which is beams passing through current row.
                    // At end, it returns final active set.
                    // I'll output `active_count` logic.
                    // Counting bits in `next_active_beams `?
                    active_count <= count_bits(next_active_beams); 
                    
                    if (y >= HEIGHT - 1) begin
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        y <= y + 1;
                        state <= S_ROW_START;
                    end
                end
                
                S_DONE: begin
                    // Stay
                end
            endcase
        end
    end

endmodule
