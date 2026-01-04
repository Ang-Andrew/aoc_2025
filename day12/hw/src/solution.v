module solution (
    input clk,
    input rst,
    output reg [63:0] total_count,
    output reg done
);
    // Data Memories
    reg [31:0] mem [0:1023];       // For tiny/smaller tests, use small buffer
    reg [31:0] shape_mem [0:1023]; 
    reg [31:0] shape_idx_mem [0:15]; 
    
    // Stack: stores {VariationIdx(32), Position(32)}
    // Depth max ~400
    reg [63:0] stack [0:511];
    
    initial begin
        $readmemh("input.hex", mem);
        $readmemh("shapes.hex", shape_mem);
        $readmemh("shape_idx.hex", shape_idx_mem);
    end
    
    // Grid State
    reg [0:2499] grid; // 50x50 max
    
    // Problem Vars
    integer prob_idx;
    integer num_probs;
    integer W, H, NumItems;
    integer prob_ptr;
    integer items_ptr; // Points to start of items in 'mem'
    
    // Iteration Vars
    integer depth;
    integer shape_id;
    integer var_start, var_count;
    integer var_idx; // 0..var_count-1
    integer pos; // 0..W*H-1
    
    // Current Shape Vars
    reg [31:0] s_w, s_h;
    reg [63:0] s_mask;
    
    // State Machine
    localparam S_INIT = 0;
    localparam S_LOAD_PROB = 1;
    localparam S_INIT_SEARCH = 2; // Setup depth 0
    localparam S_LOAD_ITEM = 3;   // Get item for current depth
    localparam S_TRY_FIT = 4;     // Check if current Var/Pos fits
    localparam S_PLACE = 5;       // Fit! Update grid, push stack
    localparam S_BACKTRACK = 6;   // Pop stack, undo
    localparam S_NEXT_CHOICE = 7; // Increment Pos/Var
    localparam S_DONE_PROB = 8;
    localparam S_ALL_DONE = 9;
    
    reg [3:0] state;
    
    // Temporaries for checking
    integer r_chk, c_chk;
    reg collision;
    integer mr; // mask row
    integer abs_pos;
    reg [7:0] mask_row_bits;
    integer cur_r, cur_c;
    integer base_addr;
    
    // Helper to get raw shape data
    // shape_mem layout: [Count] global, then [W, H, low, high] per var.
    // var_start points to start of W word.
    // Each var is 4 words.
    // Address = 1 (skip count) + var_ptr * 4 + offset
    
    always @(posedge clk) begin
        if (rst) begin
            total_count <= 0;
            done <= 0;
            state <= S_INIT;
            prob_ptr <= 1; // Skip num_probs at 0
        end else begin
            case (state)
                S_INIT: begin
                    num_probs = mem[0];
                    prob_idx <= 0;
                    prob_ptr <= 1;
                    state <= S_LOAD_PROB;
                end
                
                S_LOAD_PROB: begin
                    if (prob_idx >= num_probs) begin
                        state <= S_ALL_DONE;
                        done <= 1;
                    end else begin
                        // Read Header {W, H} {NumItems}
                        // mem[prob_ptr] is packed W:16, H:16
                        W = mem[prob_ptr][31:16];
                        H = mem[prob_ptr][15:0];
                        NumItems = mem[prob_ptr+1];
                        items_ptr = prob_ptr + 2;
                        
                        // Advance prob_ptr for next time
                        prob_ptr = prob_ptr + 2 + NumItems; 
                        
                        // Init Search
                        grid <= 0;
                        depth <= 0;
                        
                        // Init Stack[0] vars to 0
                        var_idx <= 0;
                        pos <= 0;
                        
                        state <= S_LOAD_ITEM;
                    end
                end
                
                S_LOAD_ITEM: begin
                    // Check if solution found
                    if (depth == NumItems) begin
                        // Success!
                        total_count <= total_count + 1; // Count solutions? Or just 1 per problem?
                        // Problem asks "how many regions can fit...". Usually means "Is it solvable?". 
                        // Wait, "how many OF the regions can fit". Simple count of solvable problems.
                        // So if we find solution, we are done with this problem.
                        state <= S_DONE_PROB; 
                    end else begin
                        // Get Shape ID for this depth
                        shape_id = mem[items_ptr + depth];
                        
                        // Look up variations
                        // shape_idx_mem: {Start:16, Count:16}
                        var_start = shape_idx_mem[shape_id][31:16];
                        var_count = shape_idx_mem[shape_id][15:0];
                        
                        // If resuming (backtracked), use stack values.
                        // But logic handles that in S_NEXT_CHOICE.
                        // Here we just load the shape params for the current stack choice.
                        
                        // Load Shape Data from ROM
                        // var_idx is current attempt
                        // Addr = 1 + (var_start + var_idx) * 4
                        // But wait, flattened idx? Yes.
                        // Let's assume shape_idx_mem stores global index into variation array.
                        
                        // integer base_addr; // MOVED TO TOP
                        base_addr = 1 + (var_start + var_idx) * 4;
                        s_w = shape_mem[base_addr];
                        s_h = shape_mem[base_addr+1];
                        s_mask[31:0] = shape_mem[base_addr+2];
                        s_mask[63:32] = shape_mem[base_addr+3];
                        
                        state <= S_TRY_FIT;
                    end
                end
                
                S_TRY_FIT: begin
                    // Check bounds and collision
                    // pos is linear index r*W + c
                    cur_r = pos / W;
                    cur_c = pos % W;
                    
                    // Boundary check: Bottom and Right
                    if ((cur_r + s_h > H) || (cur_c + s_w > W)) begin
                        collision = 1;
                    end else begin
                        // Collision Check
                        collision = 0;
                        for (mr = 0; mr < s_h; mr = mr + 1) begin
                            // Shift grid row
                            abs_pos = (cur_r + mr) * W + cur_c;
                            
                            // Mask row is 8 bits from s_mask >> (mr*8)
                            mask_row_bits = (s_mask >> (mr * 8)) & 8'hFF;
                            
                            // Check grid bits at abs_pos .. abs_pos+s_w
                            // In Verilog vector: grid is [0..N]. simple shift: grid >> (size - 1 - index)?
                            // Using Big Endian indexing [0:2499]. Bit 0 is top-left.
                            // To access range [abs_pos]:
                            // (grid >> (2499 - (abs_pos + k))) & 1
                            // Actually pure vector select is hard with variable index.
                            // Easier: Manual bit check loop.
                            for (c_chk = 0; c_chk < s_w; c_chk = c_chk + 1) begin
                                if ((mask_row_bits >> c_chk) & 1) begin
                                    if (grid[abs_pos + c_chk]) collision = 1;
                                end
                            end
                        end
                    end
                    
                    if (collision == 0) begin
                        state <= S_PLACE;
                    end else begin
                        state <= S_NEXT_CHOICE;
                    end
                end
                
                S_PLACE: begin
                    // Update Grid (XOR)
                    // Re-calculate loop to set bits (Hardware would parallelize this)
                    cur_r = pos / W;
                    cur_c = pos % W;
                    for (mr = 0; mr < s_h; mr = mr + 1) begin
                        abs_pos = (cur_r + mr) * W + cur_c;
                        mask_row_bits = (s_mask >> (mr * 8)) & 8'hFF;
                        for (c_chk = 0; c_chk < s_w; c_chk = c_chk + 1) begin
                            if ((mask_row_bits >> c_chk) & 1) begin
                                grid[abs_pos + c_chk] = 1;
                            end
                        end
                    end
                    
                    // Push to Stack
                    // Stack stores move we JUST made
                    stack[depth][63:32] = var_idx;
                    stack[depth][31:0] = pos;
                    
                    // Advance
                    depth <= depth + 1;
                    // Reset next level choices
                    var_idx <= 0;
                    pos <= 0;
                    
                    state <= S_LOAD_ITEM;
                end
                
                S_NEXT_CHOICE: begin
                    // Try next Position
                    pos <= pos + 1;
                    if (pos >= W*H) begin
                        // Reset pos, try next Variation
                        pos <= 0;
                        var_idx <= var_idx + 1;
                        if (var_idx >= var_count) begin
                            // All variations exhausted -> Backtrack
                            state <= S_BACKTRACK;
                        end else begin
                            // Reload shape data for new var
                            // Go to Load is messy? Need to re-load S vars.
                            // Can jump to LOAD_ITEM, it re-reads based on var_idx
                            state <= S_LOAD_ITEM;
                        end
                    end else begin
                        // Just new pos, shape/var same
                        state <= S_TRY_FIT;
                    end
                end
                
                S_BACKTRACK: begin
                    if (depth == 0) begin
                        // Search exhausted for this problem, no solution
                        state <= S_DONE_PROB;
                        // total_count not incremented
                    end else begin
                        // Pop
                        depth <= depth - 1;
                        
                        // Restore state from stack
                        var_idx = stack[depth-1][63:32]; // Wait, depth-1 is the level we are returning TO
                        pos = stack[depth-1][31:0];
                        
                        // Wait, logic check:
                        // depth was incremented. So stack[depth-1] holds the valid move we made.
                        // We need to UNDO that move.
                        
                        // Re-load Item ID for the depth we are undoing
                        shape_id = mem[items_ptr + (depth - 1)];
                        var_start = shape_idx_mem[shape_id][31:16];
                        
                        // Re-load var params from stack var_idx
                        // Use blocking assignment to get s_mask immediately for UNDO
                        var_idx = stack[depth - 1][63:32];
                        pos = stack[depth - 1][31:0];
                        
                        // integer base_addr;
                        base_addr = 1 + (var_start + var_idx) * 4;
                        s_w = shape_mem[base_addr];
                        s_h = shape_mem[base_addr+1];
                        s_mask[31:0] = shape_mem[base_addr+2];
                        s_mask[63:32] = shape_mem[base_addr+3];
                        
                        // UNDO Grid (XOR mask again)
                        cur_r = pos / W;
                        cur_c = pos % W;
                        for (mr = 0; mr < s_h; mr = mr + 1) begin
                            abs_pos = (cur_r + mr) * W + cur_c;
                            mask_row_bits = (s_mask >> (mr * 8)) & 8'hFF;
                            for (c_chk = 0; c_chk < s_w; c_chk = c_chk + 1) begin
                                if ((mask_row_bits >> c_chk) & 1) begin
                                    grid[abs_pos + c_chk] = 0; // Clear it logic (since we know it was set)
                                end
                            end
                        end
                        
                        // Now we are at the state "After processing move at depth-1".
                        // We want to try the NEXT choice for this depth.
                        // So go to S_NEXT_CHOICE.
                        state <= S_NEXT_CHOICE;
                    end
                end
                
                S_DONE_PROB: begin
                    $display("Solved Problem %d", prob_idx);
                    prob_idx <= prob_idx + 1;
                    state <= S_LOAD_PROB;
                end
                
                S_ALL_DONE: begin
                    // Stick done
                end
            endcase
        end
    end

endmodule
