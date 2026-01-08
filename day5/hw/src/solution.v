module solution (
    input clk,
    input rst,
    output reg [31:0] count,
    output reg done
);
    `include "params.vh"
    
    // Memory for Ranges (Loaded via hex, accessed in parallel)
    // Structure: 2 * NUM_RANGES. [Start0, End0, Start1, End1...]
    reg [63:0] ranges_mem [0:2*NUM_RANGES-1];
    
    // Memory for IDs (Streamed)
    reg [63:0] ids_mem [0:NUM_IDS-1];
    
    initial begin
        $readmemh("../input/ranges.hex", ranges_mem);
        $readmemh("../input/ids.hex", ids_mem);
    end

    // Internal Signals
    reg [31:0] id_ptr;
    wire [63:0] cur_id;
    
    // Pipeline Stages
    reg [63:0] p1_id;
    reg        p1_valid;
    reg        p1_done;
    
    wire [NUM_RANGES-1:0] p1_matches;
    reg        p2_match;
    reg        p2_valid;
    reg        p2_done;

    // Fetch Stage
    assign cur_id = ids_mem[id_ptr];
    
    always @(posedge clk) begin
        if (rst) begin
            id_ptr <= 0;
            p1_valid <= 0;
            p1_done <= 0;
        end else begin
            if (id_ptr < NUM_IDS) begin
                p1_id <= cur_id;
                p1_valid <= 1;
                id_ptr <= id_ptr + 1;
                p1_done <= 0;
            end else begin
                p1_valid <= 0;
                p1_done <= 1; // Pulse done or hold?
            end
        end
    end
    
    // Parallel Compare Stage (Spatial)
    genvar i;
    generate
        for (i=0; i<NUM_RANGES; i=i+1) begin : comparators
            // Range i corresponds to mem[2*i] and mem[2*i+1]
            assign p1_matches[i] = (p1_id >= ranges_mem[2*i]) && (p1_id <= ranges_mem[2*i+1]);
        end
    endgenerate
    
    // Reduction and Accumulate Stage
    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            done <= 0;
        end else begin
            // Pipeline P2
            if (p1_valid) begin
                if (|p1_matches) begin
                    count <= count + 1;
                end
            end
            
            // Done Logic (delayed by pipeline stages)
            // P1 Done -> P2 Done
            if (p1_done) begin
                done <= 1;
            end
        end
    end

endmodule
