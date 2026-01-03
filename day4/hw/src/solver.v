`default_nettype none

module solver (
    input wire clk,
    input wire reset,
    input wire [7:0] char_in,
    input wire valid_in,
    output reg [31:0] total_accessible
);

    // Constants
    localparam MAX_WIDTH = 2048; // Max line width
    localparam RAM_SIZE = 8192;  // enough for 2 lines of max width
    localparam CHAR_AT = 8'h40;
    localparam CHAR_NL = 8'h0A;

    // Registers
    reg [12:0] width; // Measured line width
    reg [12:0] col_counter;
    reg [31:0] global_count; // Total valid chars processed
    reg is_first_line;
    reg [15:0] line_idx; // Full counter for debug

    // Window: 3x3 of 1-bit (@ or .)
    // w[y][x] where y=0 is oldest (top), y=2 is newest (bottom)
    reg w[0:2][0:2];



    // RAM for Line Buffering (Stores 1 bit: is_paper)
    reg mem [0:RAM_SIZE-1];
    reg [12:0] wr_ptr;
    
    // Inputs
    wire is_newline = (char_in == CHAR_NL);
    wire is_paper = (char_in == CHAR_AT);
    
    // Derived signals
    wire [12:0] rd_ptr_L1 = wr_ptr - width;     // Row r-1
    wire [12:0] rd_ptr_L2 = wr_ptr - (width << 1); // Row r-2 (approx, we handle wrap in logic if needed)
    // Actually, simple circular buffer logic:
    // If we write at wr_ptr, the pixel exactly above is at wr_ptr - width.
    // The pixel 2 rows above is at wr_ptr - 2*width.
    // We assume RAM_SIZE is power of 2 for automatic wrap.

    // RAM Read Data
    // We need synchronous read. So data available next cycle.
    reg r_p0, r_p1, r_p2; // p0=newest(streaming), p1=row-1, p2=row-2
    // Wait, streaming data `is_paper` is current row.
    // mem read of (wr_ptr - width) is row-1.
    // mem read of (wr_ptr - 2width) is row-2.
    // BRAM has 1 cycle latency.
    
    // Pipeline:
    // Cycle 0: valid_in arrives. Address calc.
    // Cycle 1: RAM data available. Update Window. Compute Result.
    // Actually window update needs the data. Window shift happens.
    
    reg val_d1;
    reg [7:0] char_d1;
    reg is_paper_d1;
    reg is_newline_d1;
    reg [12:0] col_cnt_d1;
    reg [12:0] width_d1;
    reg [15:0] line_idx_d1; // Update delay register size
    
    reg r_L1_val;
    reg r_L2_val;
    
    initial begin : init_mem
        integer i;
        for (i = 0; i < RAM_SIZE; i = i + 1) begin
            mem[i] = 0;
        end
    end

    always @(posedge clk) begin
        if (valid_in) begin
            // RAM Write (Current pixel)
            if (!is_newline) begin
                mem[wr_ptr] <= is_paper;
                r_L1_val <= mem[wr_ptr - width]; // Read row-1
                r_L2_val <= mem[wr_ptr - (width << 1)]; // Read row-2
            end
        end
    end
    
    // Main FSM
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            total_accessible <= 0;
            width <= 0;
            col_counter <= 0;
            is_first_line <= 1;
            wr_ptr <= 0;
            line_idx <= 0;
            
            // Clear window
            w[0][0]<=0; w[0][1]<=0; w[0][2]<=0;
            w[1][0]<=0; w[1][1]<=0; w[1][2]<=0;
            w[2][0]<=0; w[2][1]<=0; w[2][2]<=0;
            
            val_d1 <= 0;
        end else if (valid_in) begin
            // 1. Width Measurement
            if (is_newline) begin
                if (is_first_line) begin
                    width <= col_counter;
                    is_first_line <= 0; // Next line is not first
                end
                col_counter <= 0;
                line_idx <= line_idx + 1;
                
                // Keep valid high to process the last pixel
                val_d1 <= 1; 
                line_idx_d1 <= line_idx;
                col_cnt_d1 <= col_counter;
            end else begin
                col_counter <= col_counter + 1;
                wr_ptr <= wr_ptr + 1;
                
                // Normal Processing
                val_d1 <= 1; 
                
                is_paper_d1 <= is_paper;
                col_cnt_d1 <= col_counter;
                width_d1 <= width;
                line_idx_d1 <= line_idx;
            end
        end else begin
             val_d1 <= 0;
        end
    end

    // Pipeline Stage 2: Window Update & Calculation
    always @(posedge clk) begin
        if (reset) begin
            // cleared above
        end else if (val_d1) begin
            // Shift Window Left
            w[0][0] <= w[0][1]; w[0][1] <= w[0][2];
            w[1][0] <= w[1][1]; w[1][1] <= w[1][2];
            w[2][0] <= w[2][1]; w[2][1] <= w[2][2];
            
            // Load New Column
            w[2][2] <= is_paper_d1;
            w[1][2] <= (line_idx_d1 >= 1) ? r_L1_val : 1'b0; 
            w[0][2] <= (line_idx_d1 >= 2) ? r_L2_val : 1'b0; 
            
            // Check logic
            // We check always. Padding logic ensures outside is 0.
            // w[1][1] center check logic handles empty spots.
            
            // Sum Neighbors
            // Note: sum logic moved to continuous assignment or outside block for V2005 compatibility
            if (val_d1 && (col_cnt_d1 >= 2 || col_cnt_d1 == 0)) begin // Guard against start trash
                if (w[1][1] && sum_wire < 4) begin
                    total_accessible <= total_accessible + 1;
                    // $display("V: Found at Row %d Col %d (Sum %d)", (col_cnt_d1 == 0 ? line_idx_d1 - 2 : line_idx_d1 - 1), (col_cnt_d1 == 0 ? width_d1 - 1 : col_cnt_d1 - 2), sum_wire);
                end
            end
        end
    end
    
    // Sum logic
    reg [3:0] sum_wire;
    reg mask_left, mask_right;
    
    always @* begin
        mask_left = (col_cnt_d1 == 13'd2);
        // col_cnt_d1 sequence: 0, 1, ... 136.
        // mask_left: when center is Col 0.
        // mask_right: when center is Col 136.
        
        mask_right = (col_cnt_d1 == 13'd0);
        
        sum_wire = (mask_left ? 1'b0 : (w[0][0] + w[1][0] + w[2][0])) + 
                   (                    w[0][1] +           w[2][1] ) + 
                   (mask_right ? 1'b0 : (w[0][2] + w[1][2] + w[2][2]));
    end
    
    // Note: This logic misses the edges (first/last col, first/last row).
    // The problem implies the grid is "on the floor". Edges have fewer neighbors (0 for outside).
    // Our 0-padding handles the "outside" value correctly.
    // But we need to process the edge pixels themselves.
    // Currently `col_cnt_d1 >= 2` starts processing at column index 2 (pixel 1).
    // We effectively skip col 0. We need to handle col 0.
    // To handle col 0, we can utilize the "0" values shifted in during reset/newline?
    // Reset clears `w`. Valid chars shift in.
    // Cycle 0: `.` `.` `p0`
    // Cycle 1: `.` `p0` `p1` -> Center is p0 (Col 0).
    // This looks correct.
    // The condition `col_cnt_d1 >= 2` might be delaying too much for the col 0 check.
    // Actually, `w[1][1]` is center.
    // Reset: 000
    // In 0: 00d0 -> Center 0.
    // In 1: 0d0d1 -> Center d0 (Col 0).
    // Correct.
    // So we should enable check when we have shifted enough.
    
endmodule
