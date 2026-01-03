`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] product_max,
    output reg done
);
    `include "params.vh"
    
    // Edges Memory (Source of u,v)
    reg [31:0] edge_mem [0:NUM_EDGES-1];
    
    // DSU Memories
    // Assume NUM_NODES fits in 16-bit address
    reg [15:0] parent [0:NUM_NODES-1];
    reg [15:0] size_arr [0:NUM_NODES-1];
    
    initial begin
        $readmemh("../input/input.hex", edge_mem);
    end
    
    // Registers
    integer edge_idx;
    reg [15:0] u, v;
    reg [15:0] root_u, root_v;
    
    // FSM
    localparam S_INIT = 0;
    localparam S_FETCH_EDGE = 1;
    localparam S_FIND_U = 2;
    localparam S_FIND_V = 3;
    localparam S_UNION = 4;
    localparam S_FIND_MAX = 5;
    localparam S_DONE = 6;
    
    reg [3:0] state;
    
    // FIND optimization: Path compression is hard in simple state machine without stack/recursion.
    // Standard iterative find:
    // while (parent[i] != i) i = parent[i];
    // Path halving or compression requires writing back.
    // For small N, simple traversal is fine. N=20 example. Real N?
    // Let's implement simple traversal.
    
    reg [15:0] curr_u, curr_v;
    
    // Max finding
    reg [15:0] max1, max2, max3;
    integer scan_i;
    reg [15:0] curr_size;

    always @(posedge clk) begin
        if (rst) begin
            product_max <= 0;
            done <= 0;
            state <= S_INIT;
            edge_idx <= 0;
        end else begin
            case (state)
                S_INIT: begin
                    // Initialize DSU: parent[i]=i, size[i]=1
                    // Requires N cycles or separate loop.
                    // For simulation we can use a loop var `scan_i`
                    // But blocking assignment loop in reset is bad form for synthesis if N large.
                    // Let's assume we do it in a state.
                    state <= 7; // S_RESET_DSU
                    scan_i <= 0;
                end
                
                7: begin // S_RESET_DSU
                    parent[scan_i] <= scan_i;
                    size_arr[scan_i] <= 1;
                    if (scan_i == NUM_NODES - 1) begin
                        state <= S_FETCH_EDGE;
                        edge_idx <= 0;
                    end else begin
                        scan_i <= scan_i + 1;
                    end
                end
                
                S_FETCH_EDGE: begin
                    if (edge_idx >= NUM_EDGES) begin
                        // Done processing edges
                        state <= S_FIND_MAX;
                        scan_i <= 0;
                        max1 <= 0; max2 <= 0; max3 <= 0;
                    end else begin
                        u <= edge_mem[edge_idx][31:16];
                        v <= edge_mem[edge_idx][15:0];
                        curr_u <= edge_mem[edge_idx][31:16];
                        curr_v <= edge_mem[edge_idx][15:0];
                        state <= S_FIND_U;
                    end
                end
                
                S_FIND_U: begin
                    // Read parent logic. 
                    // This implies Read-After-Write hazard if not careful?
                    // We read parent[curr_u].
                    // If parent[curr_u] == curr_u, found root.
                    if (parent[curr_u] == curr_u) begin
                        root_u <= curr_u;
                        state <= S_FIND_V;
                    end else begin
                        curr_u <= parent[curr_u];
                    end
                end
                
                S_FIND_V: begin
                    if (parent[curr_v] == curr_v) begin
                        root_v <= curr_v;
                        state <= S_UNION;
                    end else begin
                        curr_v <= parent[curr_v];
                    end
                end
                
                S_UNION: begin
                    if (root_u != root_v) begin
                        // Union by size
                        if (size_arr[root_u] < size_arr[root_v]) begin
                            parent[root_u] <= root_v;
                            size_arr[root_v] <= size_arr[root_u] + size_arr[root_v];
                        end else begin
                            parent[root_v] <= root_u;
                            size_arr[root_u] <= size_arr[root_u] + size_arr[root_v];
                        end
                    end
                    edge_idx <= edge_idx + 1;
                    state <= S_FETCH_EDGE;
                end
                
                S_FIND_MAX: begin
                    // Iterate all nodes. If i is root (parent[i]==i), check size.
                    if (parent[scan_i] == scan_i) begin
                        curr_size = size_arr[scan_i];
                        if (curr_size > max1) begin
                            max3 <= max2;
                            max2 <= max1;
                            max1 <= curr_size;
                        end else if (curr_size > max2) begin
                            max3 <= max2;
                            max2 <= curr_size;
                        end else if (curr_size > max3) begin
                            max3 <= curr_size;
                        end
                    end
                    
                    if (scan_i == NUM_NODES - 1) begin
                        // Calc product
                        // Wait one cycle for product? No, compute here or next state.
                        // Blocking calc:
                        // Make temporary calc
                        state <= S_DONE;
                    end else begin
                        scan_i <= scan_i + 1;
                    end
                end
                
                S_DONE: begin
                    // Final product
                    product_max <= max1 * max2 * max3;
                    done <= 1;
                end
            endcase
        end
    end

endmodule
