`timescale 1ns/1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] max_area,
    output reg done
);
    `include "params.vh"
    
    // Memory: 256-bit wide, holds 4 points per line (64 bits each)
    reg [255:0] mem [0:DEPTH-1];
    
    initial begin
        $readmemh("../input/points.hex", mem);
    end
    
    // Registers
    reg [15:0] i; // coordinate index
    reg [15:0] j_block; // block index
    
    reg [63:0] p_i;    // Current point i (64-bit {Y, X})
    reg [255:0] row_j; // Fetched row of 4 points
    
    // State Machine
    localparam S_FETCH_I = 0;
    localparam S_RUN_J = 1;
    localparam S_DONE = 2;
    reg [1:0] state;
    
    // Helper function for absolute difference (32-bit)
    function [31:0] abs_diff;
        input [31:0] a, b;
        begin
            if (a > b) abs_diff = a - b;
            else abs_diff = b - a;
        end
    endfunction
    
    // Combinational Area Logic
    reg [63:0] area0, area1, area2, area3;
    reg [63:0] p0, p1, p2, p3;
    
    always @(*) begin
        p0 = row_j[63:0];
        p1 = row_j[127:64];
        p2 = row_j[191:128];
        p3 = row_j[255:192];
        
        // p_i is {Y, X} (32-bit each)
        // Area = (abs(x1-x2)+1) * (abs(y1-y2)+1)
        // Coords are [31:0] and [63:32]
        
        area0 = ({48'd0, abs_diff(p_i[31:0], p0[31:0])} + 64'd1) * ({48'd0, abs_diff(p_i[63:32], p0[63:32])} + 64'd1);
        area1 = ({48'd0, abs_diff(p_i[31:0], p1[31:0])} + 64'd1) * ({48'd0, abs_diff(p_i[63:32], p1[63:32])} + 64'd1);
        area2 = ({48'd0, abs_diff(p_i[31:0], p2[31:0])} + 64'd1) * ({48'd0, abs_diff(p_i[63:32], p2[63:32])} + 64'd1);
        area3 = ({48'd0, abs_diff(p_i[31:0], p3[31:0])} + 64'd1) * ({48'd0, abs_diff(p_i[63:32], p3[63:32])} + 64'd1);
    end
    
    wire [15:0] i_blk_idx = i[15:2]; 
    wire [1:0]  i_sub_idx = i[1:0];
    
    reg [255:0] fetch_i_block_data;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_FETCH_I;
            i <= 0;
            j_block <= 0;
            max_area <= 0;
            done <= 0;
            p_i <= 0;
        end else begin
            case (state)
                S_FETCH_I: begin
                    if (i >= N) begin
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        fetch_i_block_data = mem[i_blk_idx]; 
                        
                        case (i_sub_idx)
                            2'd0: p_i <= fetch_i_block_data[63:0];
                            2'd1: p_i <= fetch_i_block_data[127:64];
                            2'd2: p_i <= fetch_i_block_data[191:128];
                            2'd3: p_i <= fetch_i_block_data[255:192];
                        endcase
                        
                        j_block <= i_blk_idx; 
                        state <= S_RUN_J;
                    end
                end
                
                S_RUN_J: begin
                    // 1. Fetch Row J
                    row_j = mem[j_block];
                    
                    // 2. Calc happens in comb logic (area0..3)
                    
                    // 3. Update Max
                    if (area0 > max_area) max_area <= area0;
                    if (area1 > max_area) max_area <= area1;
                    if (area2 > max_area) max_area <= area2;
                    if (area3 > max_area) max_area <= area3;
                    
                    // Loop
                    if (j_block == DEPTH - 1) begin
                        // Done with this I
                        i <= i + 1;
                        state <= S_FETCH_I;
                    end else begin
                        j_block <= j_block + 1;
                    end
                end
                
                S_DONE: ;
            endcase
        end
    end

endmodule
