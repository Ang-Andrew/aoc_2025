`timescale 1ns / 1ps

module solution (
    input clk,
    input rst,
    output reg [63:0] total_paths,
    output reg done
);
    // `include "params.vh"
    localparam NUM_NODES = 111;
    localparam OUT_NODE = 0;
    localparam YOU_NODE = 110;
    
    // Input Stream RAM
    // Size unknown...
    reg [31:0] input_mem [0:4095];
    
    // Path Count RAM
    reg [63:0] paths [0:NUM_NODES-1];
    
    initial begin
        $readmemh("../input/input.hex", input_mem);
    end
    
    integer mem_idx;
    integer i;
    
    // Processing Vars
    reg [15:0] curr_node;
    reg [15:0] num_children;
    reg [15:0] child_idx;
    reg [63:0] acc;
    
    reg [3:0] state;
    localparam S_INIT = 0;
    localparam S_READ_HEADER = 1;
    localparam S_READ_CHILD = 2;
    localparam S_WRITE = 3;
    localparam S_DONE = 4;
    
    always @(posedge clk) begin
        if (rst) begin
            total_paths <= 0;
            done <= 0;
            state <= S_INIT;
            mem_idx <= 0;
        end else begin
            case (state)
                S_INIT: begin
                    // Init paths array?
                    // Verilog doesn't allow easy array block clear.
                    // Assume simulation init.
                    // Synthesis requires loop state.
                    // Rely on 'paths' being written before read (Topo Order).
                    // EXCEPT 'out' node which relies on logic.
                    // Topo Order ensures we hit 'out' first (post-order) or last?
                    // Python does Post-Order traversal visit.
                    // `out` is usually a leaf (or close to).
                    // `visit(out)` adds `out` to list.
                    // So `out` appears early.
                    mem_idx <= 0;
                    state <= S_READ_HEADER;
                end
                
                S_READ_HEADER: begin
                    // inputs end? check sentinel or num_nodes count?
                    // Checking bounds.
                    if (input_mem[mem_idx] === 32'bx) begin // Sentinel
                         state <= S_DONE;
                         done <= 1;
                    end else begin
                        curr_node = input_mem[mem_idx][31:16];
                        num_children = input_mem[mem_idx][15:0];
                        mem_idx <= mem_idx + 1;
                        
                        // If num_children == 0?
                        // If it's 'out' node, it might have children according to graph?
                        // Or 'out' is a sink.
                        // Logic: If curr_node == OUT_NODE, paths=1.
                        // Else paths = sum(children).
                        // Note: If sink but NOT out, paths=0.
                        
                        if (curr_node == OUT_NODE) begin
                            acc <= 1;
                        end else begin
                            acc <= 0;
                        end
                        
                        if (num_children == 0) begin
                            state <= S_WRITE;
                        end else begin
                            i <= 0;
                            state <= S_READ_CHILD;
                        end
                    end
                end
                
                S_READ_CHILD: begin
                    child_idx = input_mem[mem_idx]; // Full word? py wrote 32-bit
                    mem_idx <= mem_idx + 1;
                    
                    // Accumulate paths from child
                    // Since Topo order, child processed already.
                    acc <= acc + paths[child_idx];
                    
                    if (i == num_children - 1) begin
                        state <= S_WRITE;
                    end else begin
                        i <= i + 1;
                    end
                end
                
                S_WRITE: begin
                    paths[curr_node] <= acc;
                    
                    // Check if we are done with all? Or just loop until break.
                    if (curr_node == YOU_NODE) begin
                        // Found result
                        total_paths <= acc;
                        // Don't stop, process rest? Or stop?
                        // `you` is the start node. In post-order, it is last.
                        // So we are done.
                        state <= S_DONE;
                        done <= 1;
                    end else begin
                        state <= S_READ_HEADER;
                    end
                end
                
                S_DONE: begin
                    // Hold
                end
            endcase
        end
    end

endmodule
