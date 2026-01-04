`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] total_presses,
    output reg done
);
    
    // RAM for Input stream
    // Size? Example has ~3 problems * ~10 words lines = 30 words.
    // Real input might be larger. 
    // Let's alloc 16KB (4096 words)
    reg [31:0] mem [0:4095];
    
    initial begin
        $readmemh("../input/input.hex", mem);
    end
    
    integer mem_idx;
    integer rows, cols;
    integer r, c, k;
    
    // Matrix storage: Max 32x32
    // Rows contain bit vectors.
    reg [31:0] matrix [0:31];
    
    // Solver state
    localparam S_READ_HEADER = 0;
    localparam S_READ_MATRIX = 1;
    localparam S_ELIMINATE = 2;
    localparam S_SEARCH = 3;
    localparam S_DONE = 4;
    
    reg [3:0] state;
    
    // Elimination Vars
    integer pivot_row;
    integer pivot_cols [0:31]; // To track which col is pivot
    integer free_vars [0:31];
    integer num_free;
    
    // Search Vars
    reg [31:0] assignment; // x vector
    integer min_w;
    integer search_iter;
    integer weight;
    integer is_pivot;
    integer total_iters;
    integer iter_count;
    integer possible;
    integer row_target;
    integer row_sum;
    integer local_piv_val;
    
    // Function to count simple bits
    function integer popcount;
        input [31:0] val;
        integer i;
        begin
            popcount = 0;
            for (i=0; i<32; i=i+1) if (val[i]) popcount = popcount + 1;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            total_presses <= 0;
            done <= 0;
            state <= S_READ_HEADER;
            mem_idx <= 0;
        end else begin
            case (state)
                S_READ_HEADER: begin
                    // Check if end of memory (0 or invalid)
                    if (mem[mem_idx] === 32'bx || mem_idx >= 4095) begin // Or explicit sentinel
                         state <= S_DONE;
                         done <= 1;
                    end else begin
                        rows = mem[mem_idx][31:16];
                        cols = mem[mem_idx][15:0];
                        if (rows == 0 && cols == 0) begin
                            state <= S_DONE;
                            done <= 1;
                        end else begin
                            mem_idx <= mem_idx + 1;
                            r <= 0;
                            state <= S_READ_MATRIX;
                        end
                    end
                end
                
                S_READ_MATRIX: begin
                    matrix[r] <= mem[mem_idx];
                    mem_idx <= mem_idx + 1;
                    if (r == rows - 1) begin
                        state <= S_ELIMINATE;
                        pivot_row <= 0; // Current row we are trying to fill
                        c <= 0; // Current col we are checking
                    end else begin
                        r <= r + 1;
                    end
                end
                
                S_ELIMINATE: begin
                    // Gaussian Step
                    // We iterate columns 0..cols-1
                    // 'c' is current column index
                    // 'pivot_row' is current row we want to place pivot in
                    
                    if (c >= cols) begin
                         // Done elimination
                         // Identify free vars
                         // For synthesis, this needs multi-cycle or fixed logic
                         // We'll do a SEARCH init state logic next
                         state <= S_SEARCH;
                         
                         // Determine pivot columns and free columns
                         num_free = 0;
                         // This loop logic is complex for one cycle in synthesis?
                         // For sim it's fine.
                         // We need to check which cols have pivots.
                         // But we didn't track them explicitly in `pivot_cols` array during loop.
                         // Let's do it in SEARCH setup.
                         search_iter <= 0;
                         min_w <= 9999;
                    end else begin

                        // Find pivot in column c from pivot_row down
                        // Using loop here for brevity in finding 'sel' row
                        k = pivot_row;
                        while (k < rows && matrix[k][c] == 0) k = k + 1;
                        
                        if (k < rows) begin
                            // Found pivot at row k
                            if (k != pivot_row) begin
                                // Swap pivot_row and k
                                matrix[pivot_row] <= matrix[k];
                                matrix[k] <= matrix[pivot_row];
                            end else begin
                                // Eliminate other rows
                                for (r=0; r<rows; r=r+1) begin
                                    if (r != pivot_row && matrix[r][c] == 1) begin
                                        matrix[r] <= matrix[r] ^ matrix[pivot_row];
                                    end
                                end
                                // Note this col has pivot
                                pivot_cols[pivot_row] <= c; 
                                pivot_row <= pivot_row + 1;
                                c <= c + 1;
                            end
                        end else begin
                             // No pivot in this column. It is free variable.
                             c <= c + 1;
                        end
                    end
                end
                
                S_SEARCH: begin
                    // Exhaustive search over free variables.
                    // 1. Identify Free Columns
                    if (search_iter == 0) begin
                        num_free = 0;
                        for (k=0; k<cols; k=k+1) begin
                            // Check if k is in pivot_cols[0..pivot_row-1]
                            // Simplified check: since RREF is staircase, pivots are ordered? 
                            // Not strictly if we just picked first available. 
                            // But usually Gaussian ensures pivots are roughly left-to-right.
                            // Better: Explicitly check existence.
                            is_pivot = 0;
                            for (r=0; r<pivot_row; r=r+1) begin
                                if (pivot_cols[r] == k) is_pivot = 1;
                            end
                            if (is_pivot == 0) begin
                                free_vars[num_free] = k;
                                num_free = num_free + 1;
                            end
                        end
                        
                        min_w <= 9999; // Init min weight high
                        search_iter <= 1;
                        iter_count <= 0;
                        // Limit iteration count if num_free is huge? 
                        // For AoC, it should be small.
                        total_iters = 1 << num_free;
                    end else if (search_iter == 1) begin
                        // Check done
                    if (iter_count >= total_iters) begin
                            total_presses <= total_presses + min_w;
                            state <= S_READ_HEADER;
                        end else begin
                            // Formulate assignment
                            assignment = 0;
                            
                            // Set free vars based on iter_count bits
                            for (k=0; k<num_free; k=k+1) begin
                                if ((iter_count >> k) & 1) begin
                                    assignment[free_vars[k]] = 1;
                                end
                            end
                            
                            // Back-solve for pivot vars
                            // matrix[r] contains equation: pivot + sum(free*coeffs) = target
                            // pivot = target - sum(...) = target XOR sum(...)
                            
                            possible = 1;
                            for (r=0; r<pivot_row; r=r+1) begin
                                // Row r corresponds to pivot at pivot_cols[r]
                                // Target is at column 'cols'
                                row_target = matrix[r][cols]; 
                                
                                // Calculate contribution from *other* cols (free vars mostly)
                                // In RREF, row r has 1 at pivot_col and 0 at other pivots.
                                // So we just XOR sum the free vars present in this row.
                                row_sum = 0;
                                for (k=0; k<num_free; k=k+1) begin
                                    if (matrix[r][free_vars[k]]) begin
                                        row_sum = row_sum ^ assignment[free_vars[k]];
                                    end
                                end
                                
                                // pivot_val = target ^ row_sum
                                local_piv_val = row_target ^ row_sum;
                                assignment[pivot_cols[r]] = local_piv_val;
                            end
                            
                            // Verify Rows > pivot_row (zero rows)
                            // They must have 0 = target. If target=1, impossible.
                            for (r=pivot_row; r<rows; r=r+1) begin
                                if (matrix[r][cols] == 1) possible = 0;
                            end
                            
                            // Update Min Weight
                            if (possible) begin
                                weight = popcount(assignment);
                                if (weight < min_w) min_w <= weight;
                            end
                            
                            iter_count <= iter_count + 1;
                        end
                    end
                end
                
                S_DONE: begin
                    // Done
                end
            endcase
        end
    end

endmodule
