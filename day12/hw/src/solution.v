/* verilator lint_off BLKSEQ */
/* verilator lint_off UNUSEDSIGNAL */
module solution (
    input clk,
    input rst,
    output reg [63:0] total_count,
    output reg done
);
    // Data Memories
    reg [31:0] mem [0:262143];       // Input Problems (256K)
    reg [31:0] shape_mem [0:4095];   // Shape Variations
    reg [31:0] shape_idx_mem [0:63]; // Shape ID -> {Start, Count}
    
    initial begin
        $readmemh("input.hex", mem);
        $readmemh("shapes.hex", shape_mem);
        $readmemh("shape_idx.hex", shape_idx_mem);
    end
    
    // Problem Vars
    integer prob_idx, num_probs;
    integer W, H, NumItems;
    integer prob_ptr, items_ptr;
    
    // Search State
    integer depth;
    integer cur_v; 
    
    // Current Placement Position
    integer cur_r, cur_c; 
    
    // Current Shape Data
    reg [31:0] s_packed;
    reg [31:0] s_w, s_h;
    reg [63:0] s_mask;
    integer var_start, var_count, shape_id;
    integer prev_shape_id; // For symmetry breaking

    // Grid: 50x50. Bit 49=Col 0, Bit 0=Col 49.
    reg [49:0] grid [0:49];
    
    // Stack: Store {ShapeID(16), VarIdx(16), R(16), C(16)}
    // Actually we fit R, C in 8 bits each.
    // Stack: {ShapeID[15:0], VarIdx[15:0], R[15:0], C[15:0]}
    reg [63:0] stack [0:511]; 

    // Helpers
    reg collision;
    reg [49:0] row_mask;
    reg [7:0] rev_row;
    integer mr, i;
    integer base_addr;
    integer debug_cnt;
    reg is_same_shape;

    // FSM
    localparam S_START        = 0;
    localparam S_FETCH_PROB   = 1;
    localparam S_INIT_ITEM    = 2; // Setup scan range for new item
    localparam S_FETCH_VAR    = 3; // Load shape variation
    localparam S_CHECK_FIT    = 4; // Check collision at cur_r, cur_c
    localparam S_NEXT_POS     = 5; // Move to next position (r, c)
    localparam S_PLACE_MOVE   = 6; // Valid! Place and recurse
    localparam S_NEXT_VAR     = 7; // Try next variation
    localparam S_BACKTRACK    = 8;
    localparam S_UNDO_FETCH   = 9;
    localparam S_UNDO_GRID    = 10;
    localparam S_FINISH_PROB  = 11;
    localparam S_DONE_ALL     = 12;

    reg [3:0] state;

    always @(posedge clk) begin
        if (rst) begin
            total_count <= 0;
            done <= 0;
            state <= S_START;
            prob_ptr <= 1;
            debug_cnt <= 0;
        end else begin
            case (state)
                S_START: begin
                    if (debug_cnt == 0) $display("SIM START: Reset active.");
                    num_probs = mem[0];
                    prob_idx <= 0;
                    prob_ptr <= 1;
                    state <= S_FETCH_PROB;
                end

                S_FETCH_PROB: begin
                    if (prob_idx >= num_probs) begin
                        state <= S_DONE_ALL;
                        done <= 1;
                    end else begin
                        W = {16'b0, mem[prob_ptr][31:16]};
                        H = {16'b0, mem[prob_ptr][15:0]};
                        NumItems = mem[prob_ptr+1];
                        items_ptr = prob_ptr + 2;
                        for (i=0; i<50; i=i+1) grid[i] <= 0;
                        depth <= 0;
                        state <= S_INIT_ITEM;
                    end
                end

                S_INIT_ITEM: begin
                    if (depth == NumItems) begin
                        total_count <= total_count + 1;
                        state <= S_FINISH_PROB;
                    end else begin
                        shape_id = mem[items_ptr + depth];
                        
                        // Symmetry Breaking: If same shape as prev, start after prev pos
                        is_same_shape = 0;
                        cur_r = 0; 
                        cur_c = 0;
                        
                        if (depth > 0) begin
                             // Unpack prev shape id (High 16 bits of stack word?)
                             // Stack: {ShapeID[15:0], VarIdx[15:0], cur_r[15:0], cur_c[15:0]}
                             prev_shape_id = {16'b0, stack[depth-1][63:48]};
                             if (prev_shape_id == shape_id) begin
                                 is_same_shape = 1;
                                 cur_r = {16'b0, stack[depth-1][31:16]};
                                 cur_c = {16'b0, stack[depth-1][15:0]};
                                 
                                 // Advance by 1
                                 cur_c = cur_c + 1;
                                 if (cur_c >= W) begin
                                     cur_c = 0;
                                     cur_r = cur_r + 1;
                                 end
                             end
                        end
                        
                        cur_v <= 0;
                        state <= S_FETCH_VAR;
                    end
                end

                S_FETCH_VAR: begin
                    var_start = {16'b0, shape_idx_mem[shape_id][31:16]};
                    var_count = {16'b0, shape_idx_mem[shape_id][15:0]};
                    
                    if (cur_v >= var_count) begin
                        state <= S_BACKTRACK;
                    end else begin
                        base_addr = 1 + (var_start + cur_v) * 4;
                        s_packed <= shape_mem[base_addr];
                        s_h <= shape_mem[base_addr+1];
                        s_mask[31:0] <= shape_mem[base_addr+2];
                        s_mask[63:32] <= shape_mem[base_addr+3];
                        
                        // If checking new variation, reset pos to start (if NOT same shape)
                        // If SAME shape, we keep pos >= prev pos regardless of variation
                        // Wait, Python iterates variations THEN positions? 
                        // "to_place_items" is list of vars. 
                        // Python iterates vars, then positions.
                        // But symmetry constraint applies to Items.
                        // "If item is same as prev... start_pos = last_pos + 1".
                        // This applies to the ITEM, regardless of which variation it picks.
                        // So yes, for current Item (and Var), start from `prev_pos + 1` (if same).
                        // If we are iterating Valid Pos, we start `cur_r/c` at Init.
                        // If we fail check, we increment.
                        // If we fail ALL positions, we try Next Var? 
                        // YES. But Next Var starts scanning from... Where?
                        // From the SAME start point!
                        // So we should save `init_r, init_c`? 
                        
                        // Logic fix: S_INIT sets start point.
                        // S_FETCH loads var.
                        // We need to RESTORE start point in S_FETCH_VAR?
                        // If `is_same_shape`, restore `prev_pos + 1`. Else `0`.
                        
                        if (depth > 0 && is_same_shape) begin
                             // Re-calc start pos or use saved?
                             // Just re-read stack
                             cur_r = {16'b0, stack[depth-1][31:16]};
                             cur_c = {16'b0, stack[depth-1][15:0]};
                             cur_c = cur_c + 1;
                             if (cur_c >= W) begin
                                 cur_c = 0;
                                 cur_r = cur_r + 1;
                             end
                        end else begin
                             cur_r = 0;
                             cur_c = 0;
                        end

                        state <= S_CHECK_FIT;
                    end
                end

                S_CHECK_FIT: begin
                    // Check bounds and grid
                    // s_w is unpacked from s_packed[7:0] implicitly
                    // Wait, we need to unpack s_w
                    s_w = {24'b0, s_packed[7:0]};
                    
                    if (cur_r >= H) begin
                        // Exhausted positions
                        state <= S_NEXT_VAR;
                    end else if (cur_r + s_h > H || cur_c + s_w > W) begin
                        // Out of bounds (Width/Height)
                        state <= S_NEXT_POS;
                    end else begin
                        // Check Grid Collision
                        collision = 0;
                        for (mr = 0; mr < 8; mr = mr + 1) begin
                            if (mr < s_h) begin
                                rev_row = {s_mask[mr*8], s_mask[mr*8+1], s_mask[mr*8+2], s_mask[mr*8+3], s_mask[mr*8+4], s_mask[mr*8+5], s_mask[mr*8+6], s_mask[mr*8+7]};
                                row_mask = {rev_row, 42'b0} >> cur_c;
                                if ((grid[cur_r+mr] & row_mask) != 0) collision = 1;
                            end
                        end
                        
                        if (!collision) state <= S_PLACE_MOVE;
                        else state <= S_NEXT_POS;
                    end
                end

                S_NEXT_POS: begin
                    cur_c = cur_c + 1;
                    if (cur_c >= W) begin
                        cur_c = 0;
                        cur_r = cur_r + 1;
                    end
                    state <= S_CHECK_FIT;
                end
                
                S_PLACE_MOVE: begin
                    // XOR Grid
                    for (mr = 0; mr < 8; mr = mr + 1) begin
                        if (mr < s_h) begin
                            rev_row = {s_mask[mr*8], s_mask[mr*8+1], s_mask[mr*8+2], s_mask[mr*8+3], s_mask[mr*8+4], s_mask[mr*8+5], s_mask[mr*8+6], s_mask[mr*8+7]};
                            row_mask = {rev_row, 42'b0} >> cur_c;
                            grid[cur_r+mr] <= grid[cur_r+mr] ^ row_mask;
                        end
                    end
                    // Push Stack: {ShapeID, VarIdx, R, C}
                    stack[depth] <= {shape_id[15:0], cur_v[15:0], cur_r[15:0], cur_c[15:0]};
                    depth <= depth + 1;
                    
                    if (debug_cnt < 2000 && prob_idx < 2) begin
                        $display("Place: P%d D%d V%d at %d,%d", prob_idx, depth, cur_v, cur_r, cur_c);
                        debug_cnt <= debug_cnt + 1;
                    end
                    
                    state <= S_INIT_ITEM;
                end

                S_NEXT_VAR: begin
                    cur_v <= cur_v + 1;
                    state <= S_FETCH_VAR;
                end

                S_BACKTRACK: begin
                    if (depth == 0) begin
                        state <= S_FINISH_PROB;
                    end else begin
                        depth <= depth - 1;
                        state <= S_UNDO_FETCH;
                    end
                end
                
                S_UNDO_FETCH: begin
                    // Restore from stack to undo grid
                    // Stack: {ShapeID, VarIdx, R, C}
                    shape_id = {16'b0, stack[depth][63:48]}; // actually shape_id stored in top 16
                    cur_v = {16'b0, stack[depth][47:32]};
                    cur_r = {16'b0, stack[depth][31:16]};
                    cur_c = {16'b0, stack[depth][15:0]};
                    
                    // Reload mask (Need to fetch from mem)
                    var_start = {16'b0, shape_idx_mem[shape_id][31:16]};
                    base_addr = 1 + (var_start + cur_v) * 4;
                    
                    // We need s_h and s_mask to undo
                    s_packed <= shape_mem[base_addr]; 
                    s_h <= shape_mem[base_addr+1];
                    s_mask[31:0] <= shape_mem[base_addr+2];
                    s_mask[63:32] <= shape_mem[base_addr+3];
                    
                    state <= S_UNDO_GRID;
                end

                S_UNDO_GRID: begin
                    for (mr = 0; mr < 8; mr = mr + 1) begin
                        if (mr < s_h) begin
                            rev_row = {s_mask[mr*8], s_mask[mr*8+1], s_mask[mr*8+2], s_mask[mr*8+3], s_mask[mr*8+4], s_mask[mr*8+5], s_mask[mr*8+6], s_mask[mr*8+7]};
                            row_mask = {rev_row, 42'b0} >> cur_c;
                            grid[cur_r+mr] <= grid[cur_r+mr] ^ row_mask;
                        end
                    end
                    // After undo, try next variation?
                    // No, we were iterating POSITIONS (?)
                    // Wait, if we backtrack, we popped a state where we placed Item D at (R, C) using Var V.
                    // We should try Next POS for Var V?
                    // OR Next Var V+1?
                    // Python: `for (base_mask...)`: `for shift...`
                    // Inner loop matches Positions.
                    // If recursive call returns, we continue Inner loop (Pos).
                    // So we should goto S_NEXT_POS from S_UNDO_GRID.
                    // But we must restore `cur_c, cur_r` correctly.
                    // `S_UNDO_FETCH` restored them.
                    
                    state <= S_NEXT_POS;
                end

                S_FINISH_PROB: begin
                    if (total_count % 1 == 0) $display("Solved %d (Total count %d)", prob_idx, total_count);
                    prob_idx <= prob_idx + 1;
                    prob_ptr <= items_ptr + NumItems;
                    state <= S_FETCH_PROB;
                end

                S_DONE_ALL: begin
                end
            endcase
        end
    end
endmodule
