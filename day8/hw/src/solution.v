`timescale 1ns/1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] product,
    output reg done
);
    `include "params.vh"
    
    // Memories
    // Parent: log2(N) bits -> 16 bits sufficient for N<=65536
    reg [15:0] parent [0:N-1];
    // Size: log2(N) bits (actually up to N). 16 bits.
    reg [15:0] sz [0:N-1];
    // Edge ROM
    // K lines.
    reg [31:0] edges [0:K-1];
    
    initial begin
        $readmemh("../input/edges.hex", edges);
    end
    
    // FSM States
    localparam S_INIT = 0;
    localparam S_READ = 1;
    localparam S_FIND_U = 2;
    localparam S_FIND_V = 3;
    localparam S_UNION = 4;
    localparam S_SCAN = 5;
    localparam S_DONE = 6;
    
    reg [3:0] state;
    reg [15:0] i; // Iterator for init/scan
    reg [15:0] edge_idx;
    
    // Edge Data
    reg [15:0] u, v;
    reg [15:0] root_u, root_v;
    reg [15:0] curr_node; // For find traversal
    
    // Top 3 Tracking
    reg [15:0] top1, top2, top3;
    reg [15:0] s; // Temp variable for scanning

    always @(posedge clk) begin
        if (rst) begin
            state <= S_INIT;
            i <= 0;
            edge_idx <= 0;
            product <= 0;
            done <= 0;
            top1 <= 0; top2 <= 0; top3 <= 0;
        end else begin
            case (state)
                S_INIT: begin
                    parent[i] <= i;
                    sz[i] <= 1;
                    if (i == N-1) begin
                         state <= S_READ;
                         edge_idx <= 0;
                    end else begin
                         i <= i + 1;
                    end
                end
                
                S_READ: begin
                    if (edge_idx >= K) begin
                        state <= S_SCAN;
                        i <= 0;
                    end else begin
                        u = edges[edge_idx][15:0];
                        v = edges[edge_idx][31:16];
                        
                        // Start Find U
                        curr_node <= u;
                        state <= S_FIND_U;
                    end
                end
                
                S_FIND_U: begin
                    if (parent[curr_node] == curr_node) begin
                        root_u <= curr_node;
                        // Start Find V
                        curr_node <= v; // v is from Read stage latch? Or need reg?
                        // edges is memory, u/v valid? "edges" is array reg.
                        // I used blocking/NBA mix carefully?
                        // 'v' variable above was blocking read. Need to persist.
                        // But 'v' is reg? Yes.
                        // Wait, 'u' and 'v' assigned in S_READ are regs. They hold value.
                        state <= S_FIND_V;
                    end else begin
                        curr_node <= parent[curr_node];
                        // Optional Path Compression: parent[curr_node] <= parent[parent[curr_node]];
                    end
                end
                
                S_FIND_V: begin
                    if (parent[curr_node] == curr_node) begin
                        root_v <= curr_node;
                        state <= S_UNION;
                    end else begin
                        curr_node <= parent[curr_node];
                    end
                end
                
                S_UNION: begin
                    if (root_u != root_v) begin
                        // Merge
                        // Simple: Attach root_v to root_u
                        // Weighted: Check sizes?
                        // Let's do simple for speed, check size if needed?
                        // Actually size update is needed for result.
                        // So we MUST read sizes.
                        // In Verilog, read sz[root_u] is available next cycle?
                        // "sz" is reg array. Read is immediate in same cycle if index stable at start?
                        // 'sz' is inferred block RAM or distributed?
                        // With N=1000, distributed. Read is async.
                        // Correct.
                        if (sz[root_u] < sz[root_v]) begin
                            // Attach u to v
                            parent[root_u] <= root_v;
                            sz[root_v] <= sz[root_v] + sz[root_u];
                        end else begin
                            // Attach v to u
                            parent[root_v] <= root_u;
                            sz[root_u] <= sz[root_u] + sz[root_v];
                        end
                    end
                    edge_idx <= edge_idx + 1;
                    state <= S_READ;
                end
                
                S_SCAN: begin
                    // Scan all nodes. If root, check size.
                    if (parent[i] == i) begin
                        // Is Root
                        s = sz[i];
                        
                        // Update Top 3
                        if (s > top1) begin
                            top3 <= top2;
                            top2 <= top1;
                            top1 <= s;
                        end else if (s > top2) begin
                            top3 <= top2;
                            top2 <= s;
                        end else if (s > top3) begin
                            top3 <= s;
                        end
                    end
                    
                    if (i == N-1) begin
                        state <= S_DONE;
                    end else begin
                        i <= i + 1;
                    end
                end
                
                S_DONE: begin
                    // Product
                    // Ensure 64-bit width multiply
                    product <= {48'b0, top1} * {48'b0, top2} * {48'b0, top3};
                    done <= 1;
                end
            endcase
        end
    end

endmodule
