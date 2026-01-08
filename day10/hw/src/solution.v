`timescale 1ns/1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] total_presses,
    output reg done
);
    `include "params.vh"
    
    // Memory
    reg [31:0] mem [0:STREAM_DEPTH-1];
    
    initial begin
        $readmemh("../input/input_stream.hex", mem);
    end
    
    reg [31:0] ptr; // Memory pointer
    
    // Matrix: 32x32
    // Stored as rows.
    reg [31:0] mat [0:31];
    
    reg [15:0] rows, cols;
    // Pivot tracking
    reg [31:0] pivot_map; // bit i is set if col i is pivot
    reg [31:0] free_map;  // bit i is set if col i is free
    reg [4:0]  pivot_rows [0:31]; // Maps Pivot Col -> Row Index
    
    // FSM
    localparam S_READ_HEADER = 0;
    localparam S_READ_ROWS = 1;
    localparam S_RREF_PIVOT = 2;
    localparam S_RREF_ELIM = 3;
    localparam S_SEARCH = 4;
    localparam S_DONE = 5;
    
    reg [3:0] state;
    
    // RREF Vars
    reg [5:0] pivot_row; // 0..31
    reg [5:0] curr_col;  // 0..31
    reg [5:0] scan_row;
    
    // Search Vars
    reg [31:0] assignment;
    reg [15:0] iter_count;
    reg [15:0] max_iter;
    reg [31:0] min_w;
    reg [5:0]  free_vars [0:31];
    reg [5:0]  num_free;
    
    integer k, r, c;
    reg found;
    reg [5:0] sel;
    reg [31:0] temp;
    
    reg impossible;
    reg row_has_pivot;
    
    reg [5:0] r_idx;
    reg val;
    reg [31:0] w;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_READ_HEADER;
            ptr <= 0;
            total_presses <= 0;
            done <= 0;
            for (k=0; k<32; k=k+1) begin
                mat[k] <= 0;
                pivot_rows[k] <= 0;
                free_vars[k] <= 0;
            end
        end else begin
            case (state)
                S_READ_HEADER: begin
                    if (ptr >= STREAM_DEPTH) begin
                        state <= S_DONE; // Should handle FFFFFFFF check ideally
                    end else begin
                        rows = mem[ptr][15:0];
                        cols = mem[ptr][31:16];
                        
                        if (rows == 16'hFFFF) begin
                            state <= S_DONE;
                            done <= 1;
                        end else begin
                            ptr <= ptr + 1;
                            state <= S_READ_ROWS;
                            scan_row <= 0;
                            // $display("Reading Problem: Rows=%d, Cols=%d", rows, cols);
                        end
                    end
                end
                
                S_READ_ROWS: begin
                    mat[scan_row] <= mem[ptr];
                    ptr <= ptr + 1;
                    if (scan_row == rows - 1) begin
                        state <= S_RREF_PIVOT;
                        pivot_row <= 0;
                        curr_col <= 0;
                        // Init Pivot Map? 
                        // Will define pivot cols during RREF.
                    end else begin
                        scan_row <= scan_row + 1;
                    end
                end
                
                S_RREF_PIVOT: begin
                    // Find pivot in curr_col starting at pivot_row
                    // Can do in 1 cycle with function or loop
                    // For logic simplicity, use loop in logic
                    // Scan rows `pivot_row` to `rows-1`
                    
                    // reg found;
                    // reg [5:0] sel;
                    found = 0;
                    sel = 0;
                    
                    for (k=0; k<32; k=k+1) begin
                        // Verilog loop unroll
                        if (k >= pivot_row && k < rows && !found) begin
                            if (mat[k][curr_col]) begin
                                found = 1;
                                sel = k;
                            end
                        end
                    end
                    
                    if (found) begin
                        // Swap pivot_row and sel
                        // reg [31:0] temp;
                        temp = mat[pivot_row];
                        mat[pivot_row] <= mat[sel];
                        mat[sel] <= temp;
                        
                        // Mark as pivot col?
                        // For search later, we need to know.
                        // Can store `pivot_cols` array.
                        // Actually, just proceed to ELIM.
                        state <= S_RREF_ELIM;
                    end else begin
                        // No pivot in this col -> Free Var?
                        // Continue to next col, same row
                        if (curr_col < cols - 1) begin
                            curr_col <= curr_col + 1;
                        end else begin
                            // Finished columns
                            state <= S_SEARCH;
                        end
                    end
                end
                
                S_RREF_ELIM: begin
                    // $display("RREF Pivot: Row=%d, Col=%d", pivot_row, curr_col);
                    // Eliminate all other rows using pivot_row
                    for (k=0; k<32; k=k+1) begin
                        if (k < rows) begin
                            if (k != pivot_row && mat[k][curr_col]) begin
                                mat[k] <= mat[k] ^ mat[pivot_row];
                            end
                        end
                    end
                    
                    // Note pivot col
                    // We need to store that `curr_col` is a pivot variable.
                    // And it is solved by `pivot_row`.
                    pivot_rows[curr_col] <= pivot_row; // Assuming we can use this later
                    
                    // Advance
                    if (curr_col < cols - 1 && pivot_row < rows - 1) begin
                        curr_col <= curr_col + 1;
                        pivot_row <= pivot_row + 1;
                        state <= S_RREF_PIVOT;
                    end else begin
                        state <= S_SEARCH;
                    end
                end
                
                S_SEARCH: begin
                    // Pre-Search Setup
                    // 1. Identify Free Vars
                    // 2. Identify Pivot Cols
                    // 3. Check Consistency (Impossible?)
                    
                    // Implementation Shortcut:
                    // Since free vars are few, we can iterate ALL assignments 2^F?
                    // Wait, we need to know WHICH cols are free.
                    // Re-scan matrix to find pivots?
                    // Better: We tracked pivots?
                    // Actually, simple RREF implies:
                    // Pivot vars are the leading 1s of rows.
                    // Scan each row to find leading 1. That col is pivot.
                    // Any col NOT a leading 1 is free.
                    
                    // Check Impossible: Row [0 0 ... 0 | 1]
                    // reg impossible;
                    impossible = 0;
                    for (k=0; k<32; k=k+1) begin
                        if (k < rows) begin
                            // Check bits 0..cols-1
                            // If all 0, and bit `cols` is 1 -> Impossible
                            if ((mat[k] & ((1<<cols)-1)) == 0 && mat[k][cols]) impossible = 1;
                        end
                    end
                    
                    if (impossible) begin
                        state <= S_READ_HEADER; // Next Problem
                    end else begin
                        // Gather Pivot/Free Map
                        pivot_map = 0;
                        for (k=0; k<32; k=k+1) begin
                            if (k < rows) begin
                                // Find leading 1
                        // Reuse variable `c`
                        // row_has_pivot declared outside
                        // reg row_has_pivot;
                        row_has_pivot = 0;
                                for (c=0; c<32; c=c+1) begin
                                    if (c < cols && !row_has_pivot) begin
                                        if (mat[k][c]) begin
                                            pivot_map[c] = 1;
                                            pivot_rows[c] = k;
                                            row_has_pivot = 1;
                                        end
                                    end
                                end
                            end
                        end
                        
                        free_map = (~pivot_map) & ((1<<cols)-1);
                        
                        // Populate free_vars list
                        num_free = 0;
                        for (c=0; c<32; c=c+1) begin
                            if (c < cols) begin
                                if (free_map[c]) begin
                                    free_vars[num_free] = c;
                                    num_free = num_free + 1;
                                end
                            end
                        end
                        
                        iter_count <= 0;
                        max_iter <= (1 << num_free); // Warning: overflow if num_free=16. 
                        // Use 0 means 65536? Or logic `cnt < (1<<F)`
                        
                        min_w <= 32'hFFFFFFFF;
                        
                        // New State INTER_SEARCH
                        state <= 6; 
                        // $display("Start Search: NumFree=%d, PivotMap=%x", num_free, pivot_map);
                    end
                end
                
                6: begin // S_INTER_SEARCH
                    if (iter_count < (1 << num_free) || (num_free > 16)) begin
                        // 1. Assign Free Vars
                        assignment = 0;
                        for (c=0; c<16; c=c+1) begin
                            if (c < num_free) begin
                                if ((iter_count >> c) & 1) assignment[free_vars[c]] = 1;
                            end
                        end
                        
                        // 2. Solve Pivots
                        for (c=0; c<32; c=c+1) begin
                            if (c < cols && pivot_map[c]) begin
                                r_idx = pivot_rows[c];
                                val = mat[r_idx][cols]; // Target
                                
                                // Debug X
                                // if (val === 1'bx) $display("DEBUG X: Target val is X. r_idx=%d", r_idx);
                                // if (r_idx >= rows) $display("DEBUG X: r_idx %d >= rows %d", r_idx, rows);
                                
                                for (k=0; k<32; k=k+1) begin
                                    if (k < cols && free_map[k]) begin
                                        if (mat[r_idx][k]) val = val ^ assignment[k];
                                    end
                                end
                                assignment[c] = val;
                            end
                        end

                        w = 0;
                        for (c=0; c<32; c=c+1) if (c < cols && assignment[c]) w = w + 1;
                        
                        if (w < min_w) begin
                             min_w <= w;
                             // $display("Iter %d: New MinW=%d (w=%d). Assign=%x", iter_count, w, w, assignment);
                        end else begin
                             // $display("Iter %d: w=%d (MinW=%d). Assign=%x. Cols=%d", iter_count, w, min_w, assignment, cols);
                        end
                        
                        // Next Iter
                        iter_count <= iter_count + 1;
                        
                        // Safety: Max 65536
                        if (iter_count == 16'hFFFF) begin
                            // Handle logic break
                            state <= 7; // Done Search
                        end
                    end else begin
                        state <= 7; // Done Search
                    end
                end
                
                7: begin // Accumulate
                    if (min_w != 32'hFFFFFFFF) begin
                         total_presses <= total_presses + min_w;
                         // $display("Problem Solved: MinW=%d", min_w);
                    end else begin
                         // $display("Problem Incorrectly Unsolved?");
                    end
                    state <= S_READ_HEADER;
                end
                
                S_DONE: ;
            endcase
        end
    end

endmodule
