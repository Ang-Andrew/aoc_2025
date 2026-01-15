// Day 4: Fixed Synthesis Version
// Rewritten to properly synthesize with ECP5
// - Flattened 2D window array into 1D
// - Proper BRAM inference for line buffer
// - Clean always blocks for state machine

`default_nettype none

module solver (
    input wire clk,
    input wire reset,
    input wire [7:0] char_in,
    input wire valid_in,
    output reg [31:0] total_accessible
);

    // Constants
    localparam MAX_WIDTH = 2048;
    localparam RAM_SIZE = 8192;
    localparam CHAR_AT = 8'h40;
    localparam CHAR_NL = 8'h0A;

    // State machine
    reg [12:0] width;
    reg [12:0] col_counter;
    reg is_first_line;

    // Window flattened from [0:2][0:2] to linear array [0:8]
    // Indices: 0=w[0][0], 1=w[0][1], 2=w[0][2],
    //          3=w[1][0], 4=w[1][1], 5=w[1][2],
    //          6=w[2][0], 7=w[2][1], 8=w[2][2]
    reg window [0:8];

    // BRAM for line buffer
    reg is_paper_mem [0:RAM_SIZE-1];
    reg [12:0] wr_ptr;

    // Derived signals
    wire is_newline = (char_in == CHAR_NL);
    wire is_paper = (char_in == CHAR_AT);
    wire [12:0] rd_ptr_L1 = wr_ptr - width;
    wire [12:0] rd_ptr_L2 = wr_ptr - (width << 1);

    // Registered BRAM reads
    reg r_L1_val, r_L2_val;
    reg val_d1;
    reg is_paper_d1;
    reg [12:0] col_cnt_d1;
    reg [12:0] width_d1;

    // Window accessing (helper for readability)
    wire w00 = window[0], w01 = window[1], w02 = window[2];
    wire w10 = window[3], w11 = window[4], w12 = window[5];
    wire w20 = window[6], w21 = window[7], w22 = window[8];

    // Sum computation
    wire [3:0] sum_neighbors;
    wire mask_left = (col_cnt_d1 == 13'd2);
    wire mask_right = (col_cnt_d1 == 13'd0);

    // Compute sum of neighbors (not including center)
    assign sum_neighbors = (mask_left ? 4'd0 : {w00 + w10 + w20}) +
                           {w01 + w21} +
                           (mask_right ? 4'd0 : {w02 + w12 + w22});

    // Initialize all window cells to 0
    integer i;
    initial begin
        for (i = 0; i < 9; i = i + 1) begin
            window[i] = 1'b0;
        end
        for (i = 0; i < RAM_SIZE; i = i + 1) begin
            is_paper_mem[i] = 1'b0;
        end
    end

    // ====================
    // Stage 1: Main FSM
    // ====================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            total_accessible <= 32'b0;
            width <= 13'b0;
            col_counter <= 13'b0;
            is_first_line <= 1'b1;
            wr_ptr <= 13'b0;
        end else if (valid_in) begin
            if (is_newline) begin
                // End of line
                if (is_first_line) begin
                    width <= col_counter;
                    is_first_line <= 1'b0;
                end
                col_counter <= 13'b0;
            end else begin
                // Regular character
                is_paper_mem[wr_ptr] <= is_paper;
                r_L1_val <= is_paper_mem[rd_ptr_L1];
                r_L2_val <= is_paper_mem[rd_ptr_L2];
                col_counter <= col_counter + 1'b1;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Pipeline delay
            val_d1 <= 1'b1;
            is_paper_d1 <= is_paper;
            col_cnt_d1 <= col_counter;
            width_d1 <= width;
        end else begin
            val_d1 <= 1'b0;
        end
    end

    // ====================
    // Stage 2: Window Update & Accumulation
    // ====================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset already handled in Stage 1
        end else if (val_d1) begin
            // Shift window left: [col-1 ... col+1]
            window[0] <= window[1];
            window[1] <= window[2];

            window[3] <= window[4];
            window[4] <= window[5];

            window[6] <= window[7];
            window[7] <= window[8];

            // Load new column data
            // Current row: is_paper_d1
            // Previous row: r_L1_val
            // Two rows back: r_L2_val
            window[2] <= is_paper_d1;
            window[5] <= (col_cnt_d1 >= 1) ? r_L1_val : 1'b0;
            window[8] <= (col_cnt_d1 >= 2) ? r_L2_val : 1'b0;

            // Check and accumulate
            if (col_cnt_d1 >= 2 || col_cnt_d1 == 13'd0) begin
                if (w11 && sum_neighbors < 4'd4) begin
                    total_accessible <= total_accessible + 1'b1;
                end
            end
        end
    end

endmodule
