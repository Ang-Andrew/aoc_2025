`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] max_area,
    output reg done
);
    `include "params.vh"
    
    // RAM
    // 64-bit words: [X:32, Y:32]
    reg [63:0] points [0:NUM_POINTS-1];
    
    initial begin
        $readmemh("../input/input.hex", points);
    end
    
    integer i, j;
    reg [31:0] xi, yi, xj, yj; // Expanded to 32-bit
    reg [31:0] dx, dy; 
    
    // Architecture Note:
    // Expanding 'area' to 64-bit prevents overflow for results > 2^32.
    // Trade-off: On FPGAs with 18x18 or 25x18 DSP slices, a 32x32 multiply
    // requires cascaded DSPs.
    reg [63:0] area;
    
    localparam S_INIT = 0;
    localparam S_FETCH_I = 1;
    localparam S_FETCH_J = 2;
    localparam S_CALC = 3;
    localparam S_DONE = 4;
    
    reg [3:0] state;

    // Abs helpers
    function [31:0] abs_diff;
        input [31:0] a, b;
        begin
            if (a > b) abs_diff = a - b;
            else abs_diff = b - a;
        end
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            max_area <= 0;
            done <= 0;
            state <= S_INIT;
        end else begin
            case (state)
                S_INIT: begin
                    i <= 0;
                    state <= S_FETCH_I;
                end
                
                S_FETCH_I: begin
                    if (i >= NUM_POINTS) begin
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        xi <= points[i][63:32];
                        yi <= points[i][31:0];
                        j <= i + 1; // Start inner loop
                        state <= S_FETCH_J;
                    end
                end
                
                S_FETCH_J: begin
                    if (j >= NUM_POINTS) begin
                        // Next I
                        i <= i + 1;
                        state <= S_FETCH_I;
                    end else begin
                        xj <= points[j][63:32];
                        yj <= points[j][31:0];
                        state <= S_CALC;
                    end
                end
                
                S_CALC: begin
                    // Compute Area
                    dx = abs_diff(xi, xj) + 1;
                    dy = abs_diff(yi, yj) + 1;
                    // Force 64-bit arthimetic context
                    area = {32'b0, dx} * {32'b0, dy};
                    
                    if (area > max_area) begin
                        max_area <= area;
                    end
                    
                    j <= j + 1;
                    state <= S_FETCH_J;
                end
                
                S_DONE: begin
                    // done <= 1
                end
            endcase
        end
    end

endmodule
