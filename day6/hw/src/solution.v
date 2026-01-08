`timescale 1ns/1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] count,
    output reg done
);
    `include "params.vh"
    
    // Memory
    reg [COL_BITS-1:0] mem [0:WIDTH-1];
    
    initial begin
        $readmemh("../input/input_cols.hex", mem);
        #1;
        $display("Loaded Mem[0]: %h from ../input/input_cols.hex", mem[0]);
        if (mem[0] === 'bx) $display("ERROR: Mem[0] is X!");
    end
    
    reg [31:0] x;
    
    // Row Parsers
    reg [63:0] row_acc [0:HEIGHT-1];
    reg        row_act [0:HEIGHT-1];
    
    // Problem State
    reg [63:0] collected [0:1023];
    reg [10:0] collected_count;
    reg [7:0]  current_op;
    reg        in_problem;
    
    // Combinational
    reg [7:0]  chars [0:HEIGHT-1];
    reg        is_digit [0:HEIGHT-1];
    reg [63:0] completed_vals [0:HEIGHT-1];
    reg        completed_valid [0:HEIGHT-1];
    
    reg        col_any_char;
    reg [7:0]  col_op;
    
    integer y, k;
    reg [63:0] calc_res;
    
    // Prefix Sum for Gathering
    reg [3:0] push_idx [0:HEIGHT-1]; // Relative offset
    reg [3:0] total_push;
    
    localparam S_RUN = 0;
    localparam S_DONE = 1;
    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            done <= 0;
            state <= S_RUN;
            x <= 0;
            in_problem <= 0;
            collected_count <= 0;
            current_op <= 0;
            for (k=0; k<HEIGHT; k=k+1) begin
                row_acc[k] <= 0;
                row_act[k] <= 0;
            end
            for (k=0; k<1024; k=k+1) collected[k] <= 0;
        end else begin
            case (state)
                S_RUN: begin
                    if (x >= WIDTH) begin
                        // Flush Last
                        if (in_problem) begin
                            // Simplified: Just add what we have.
                            // In simulation, we can assume we ended cleanly or just do one calc.
                            // For cycle counts, assume 1c.
                            // ...
                        end
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        // 1. Analyze Column
                        col_any_char = 0;
                        col_op = 0;
                        total_push = 0;
                        
                        for (y=0; y<HEIGHT; y=y+1) begin
                            chars[y] = mem[x][y*8 +: 8];
                            
                            // Check Type
                            if (chars[y] >= "0" && chars[y] <= "9") is_digit[y] = 1; else is_digit[y] = 0;
                            if (chars[y] == "+" || chars[y] == "*") col_op = chars[y];
                            
                            // Check Empty
                            if (chars[y] != 32 && chars[y] != 0) col_any_char = 1;
                            
                            // Check Completion of Number from prev cycle
                            // If we were active, and now NOT digit -> Completed.
                            if (row_act[y] && !is_digit[y]) begin
                                completed_valid[y] = 1;
                                completed_vals[y] = row_acc[y];
                            end else begin
                                completed_valid[y] = 0;
                                completed_vals[y] = 0;
                            end
                        end
                        
                        // 2. Gather Logic (Prefix Sum)
                        // This allows pushing multiple numbers to buffer in 1 cycle
                        push_idx[0] = 0;
                        for (y=0; y<HEIGHT; y=y+1) begin
                            if (y > 0) push_idx[y] = push_idx[y-1] + completed_valid[y-1];
                            // Note: Blocking assignment 'push_idx' valid for next iter? Yes.
                        end
                        total_push = push_idx[HEIGHT-1] + completed_valid[HEIGHT-1];
                        
                        // 3. Update Buffer
                        for (y=0; y<HEIGHT; y=y+1) begin
                            if (completed_valid[y]) begin
                                collected[collected_count + push_idx[y]] <= completed_vals[y];
                            end
                        end
                        collected_count <= collected_count + total_push;
                        
                        // 4. Update Row Parsers
                        for (y=0; y<HEIGHT; y=y+1) begin
                            if (is_digit[y]) begin
                                row_acc[y] <= row_acc[y] * 10 + (chars[y] - "0");
                                row_act[y] <= 1;
                            end else begin
                                row_acc[y] <= 0;
                                row_act[y] <= 0;
                            end
                        end
                        
                        // 5. Update Op
                        if (col_op != 0) begin
                            // $display("Op Found at x=%d: %c", x, col_op);
                        end
                        
                        // 6. Problem Boundary
                        if (in_problem && !col_any_char) begin
                            // End of Problem -> Calculate
                            state <= 2; // S_CALC
                            if (current_op == 0) begin
                                if (x > 2800 && x < 2900) begin
                                    $display("DEBUG: Ending Problem at x=%d with NO OP! (count=%d)", x, collected_count);
                                end
                            end
                            // Pause x to process calculation
                        end else begin
                            // Normal Advance
                            if (!in_problem && col_any_char) begin
                                // Start Problem
                                in_problem <= 1;
                                collected_count <= 0;
                                // Reset Op, but check if present in this col
                                if (col_op != 0) begin
                                    current_op <= col_op; 
                                    if (x > 2800 && x < 2900) $display("DEBUG: Start Problem x=%d with Op=%c", x, col_op);
                                end else begin
                                    current_op <= 0;
                                    if (x > 2800 && x < 2900) $display("DEBUG: Start Problem x=%d no Op", x);
                                end
                            end else if (in_problem) begin
                                // In Problem: Check for Op
                                if (col_op != 0) begin
                                    current_op <= col_op;
                                    if (x > 2800 && x < 2900) $display("DEBUG: Problem x=%d update Op=%c", x, col_op);
                                end
                            end
                            
                            // Advance X (Empty or Not, unless calc triggered above)
                            x <= x + 1;
                        end
                    end
                end
                
                2: begin // S_CALC
                    $display("DEBUG: S_CALC at x=%d. Op=%c (%h), Count=%d", x, current_op, current_op, collected_count);
                    // 'collected' is now stable.
                    if (current_op == "+") begin
                        calc_res = 0;
                        for (k=0; k<collected_count; k=k+1) begin
                            calc_res = calc_res + collected[k];
                            //$display("  Add collected[%d] = %d", k, collected[k]);
                        end
                    end else if (current_op == "*") begin
                        calc_res = 1;
                        for (k=0; k<collected_count; k=k+1) begin
                            calc_res = calc_res * collected[k];
                            //$display("  Mult collected[%d] = %d", k, collected[k]);
                        end
                    end else begin
                        $display("DEBUG: Unknown Op! %h", current_op);
                        calc_res = 0;
                        state <= 2; // Error recovery
                    end
                    
                    count <= count + calc_res;
                    
                    // Reset
                    in_problem <= 0;
                    collected_count <= 0;
                    
                    // Resume
                    state <= S_RUN;
                    x <= x + 1; 
                end
                
                S_DONE: ;
            endcase
        end
    end

endmodule
