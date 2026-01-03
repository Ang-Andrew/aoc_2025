`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] count,
    output reg done
);
    `include "params.vh"
    
    // Memory
    reg [7:0] mem [0:MEM_SIZE-1];
    
    initial begin
        $readmemh("../input/input.hex", mem);
    end

    // Column Mask RAM (distributed RAM or just reg array if small)
    // WIDTH approx 100-200. Reg array is fine.
    reg col_mask [0:WIDTH-1];
    
    // FSM
    localparam S_MASK_COL = 0;
    localparam S_MASK_NEXT = 1;
    localparam S_FIND_START = 2;
    localparam S_FIND_END = 3;
    localparam S_SOLVE_ROW_INIT = 4;
    localparam S_SOLVE_PIXEL = 5;
    localparam S_SOLVE_CALC = 6;
    localparam S_DONE = 7;
    
    reg [3:0] state;
    
    integer x, y, i;
    integer r_start, r_end;
    
    // Parsing state
    reg [63:0] current_val;
    reg val_valid;
    reg [7:0] op_char; // +, *
    
    // Problem operands
    // Assume max 10 operands per problem? 
    // Example has ~3. Let's reserve space for 16.
    reg [63:0] operands [0:15];
    integer op_count;
    
    reg [7:0] char_read;
    
    // Helper for address
    function integer get_addr;
        input integer cx, cy;
        begin
            get_addr = cy * WIDTH + cx;
        end
    endfunction
    
    reg col_has_data;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            done <= 0;
            state <= S_MASK_COL;
            x <= 0;
            y <= 0;
            col_has_data <= 0;
        end else begin
            case (state)
                // --------------------------------------------------
                // Phase 1: Build Column Mask
                // Scan column x, all y.
                // --------------------------------------------------
                S_MASK_COL: begin
                    char_read = mem[get_addr(x, y)];
                    if (char_read != 32 && char_read != 0) begin // Space or null
                        col_has_data <= 1;
                    end
                    
                    if (y == HEIGHT - 1) begin
                        state <= S_MASK_NEXT;
                    end else begin
                        y <= y + 1;
                    end
                end
                
                S_MASK_NEXT: begin
                    col_mask[x] <= col_has_data;
                    col_has_data <= 0;
                    y <= 0;
                    if (x == WIDTH - 1) begin
                        x <= 0;
                        state <= S_FIND_START;
                    end else begin
                        x <= x + 1;
                        state <= S_MASK_COL;
                    end
                end
                
                // --------------------------------------------------
                // Phase 2: Iterate Regions
                // --------------------------------------------------
                S_FIND_START: begin
                    if (x >= WIDTH) begin
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        if (col_mask[x] == 1) begin
                            r_start <= x;
                            state <= S_FIND_END;
                        end else begin
                            x <= x + 1;
                        end
                    end
                end
                
                S_FIND_END: begin
                    if (x >= WIDTH || col_mask[x] == 0) begin
                        r_end <= x; // Exclusive end
                        // Start solving this region
                        state <= S_SOLVE_ROW_INIT;
                        y <= 0;
                        op_count <= 0;
                        op_char <= 0;
                    end else begin
                        x <= x + 1;
                    end
                end
                
                // --------------------------------------------------
                // Phase 3: Solve Region
                // Scan [r_start, r_end) for each row y from 0..HEIGHT-1
                // --------------------------------------------------
                S_SOLVE_ROW_INIT: begin
                    // Prepare to scan row y in range
                    i <= r_start; // iterator for x in parsing
                    current_val <= 0;
                    val_valid <= 0;
                    state <= S_SOLVE_PIXEL;
                end
                
                S_SOLVE_PIXEL: begin
                    if (i >= r_end) begin
                        // End of row segment
                        if (val_valid) begin
                             operands[op_count] <= current_val;
                             op_count <= op_count + 1;
                        end
                        // Next row
                        if (y == HEIGHT - 1) begin
                            state <= S_SOLVE_CALC;
                        end else begin
                            y <= y + 1;
                            state <= S_SOLVE_ROW_INIT;
                        end
                    end else begin
                        char_read = mem[get_addr(i, y)];
                        // Check digit
                        if (char_read >= "0" && char_read <= "9") begin
                            current_val <= current_val * 10 + (char_read - "0");
                            val_valid <= 1;
                        end else if (char_read == "+" || char_read == "*") begin
                            if (val_valid) begin
                                operands[op_count] <= current_val;
                                op_count <= op_count + 1;
                            end
                            op_char <= char_read;
                            val_valid <= 0;
                            current_val <= 0;
                        end else begin
                            // Space or other
                            if (val_valid) begin
                                operands[op_count] <= current_val;
                                op_count <= op_count + 1;
                                val_valid <= 0;
                                current_val <= 0;
                            end
                        end
                        i <= i + 1;
                    end
                end
                
                S_SOLVE_CALC: begin
                    if (op_char == "+") begin
                        // Sum operands
                        // We can't do variable Ioop easily in one cycle if op_count is large?
                        // Just iterate i
                        // Re-use i as accumulator loop var? No, create logic
                        // Since we just need sum, let's do a quick loop logic or assume small count
                        // Let's iterate.
                         // But we can do it:
                         // Reuse `i`
                         // Reset `i` to 0
                         // We need a sub-state. Or just do it here:
                         // Simple unrolled for small count or loop next cycle
                         // For simplicity, let's assume we accumulate in `current_val` (reused as acc)
                         // But we just finished logic.
                         // Let's add a SUM_LOOP state.
                         // Actually, let's just do it in one cycle if op_count is small (e.g. < 4)
                         // But it might be larger.
                         // Let's modify logic to accumulate *as we find them*?
                         // Problem: "123 * 45 * 6". We find 123, then 45, then 6.
                         // We don't know the operator until the end (+ or *).
                         // So we MUST buffer operands.
                         // Ok, let's add `S_CALC_LOOP`.
                    end
                    // Just move to next region for now (logic below)
                    // ...
                    
                    // Temp Implementation: Only first 2 operands (to test structure) or loop
                    // Let's add S_CALC_LOOP
                    i <= 0;
                    current_val <= (op_char == "*") ? 1 : 0; // Init acc
                    state <= 8; // S_CALC_LOOP (magic number for now, define below)
                end

                8: begin // S_CALC_LOOP
                    if (i >= op_count) begin
                        count <= count + current_val;
                        // Done with region. Resume finding next region.
                        x <= r_end; // Resume search from here
                        state <= S_FIND_START; 
                    end else begin
                        if (op_char == "+") begin
                            current_val <= current_val + operands[i];
                        end else if (op_char == "*") begin
                            current_val <= current_val * operands[i];
                        end
                        i <= i + 1;
                    end
                end
                
                S_DONE: begin
                    // done <= 1 assigned above
                end
            endcase
        end
    end

endmodule
