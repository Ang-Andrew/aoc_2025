module solution (
    input clk,
    input rst,
    output reg [31:0] count,
    output reg done
);
    `include "params.vh"

    // Memories
    // ranges_flat stores start, end interleaved: [start0, end0, start1, end1, ...]
    reg [63:0] ranges_flat [0:2*NUM_RANGES-1];
    reg [63:0] ids [0:NUM_IDS-1];
    
    initial begin
        $readmemh("../input/ranges.hex", ranges_flat);
        $readmemh("../input/ids.hex", ids);
    end

    reg [63:0] current_id;
    reg [63:0] r_start, r_end;
    
    integer id_idx;
    integer range_idx;
    
    localparam STATE_FETCH_ID = 0;
    localparam STATE_CHECK_RANGES = 1;
    localparam STATE_DONE = 2;
    
    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            count <= 0;
            done <= 0;
            state <= STATE_FETCH_ID;
            id_idx <= 0;
            range_idx <= 0;
        end else begin
            case (state)
                STATE_FETCH_ID: begin
                    if (id_idx >= NUM_IDS) begin
                        state <= STATE_DONE;
                        done <= 1;
                    end else begin
                        current_id <= ids[id_idx];
                        range_idx <= 0;
                        state <= STATE_CHECK_RANGES;
                    end
                end
                
                STATE_CHECK_RANGES: begin
                    if (range_idx >= NUM_RANGES) begin
                        // No match found in any range for this ID
                        id_idx <= id_idx + 1;
                        state <= STATE_FETCH_ID; 
                    end else begin
                        // Read current range
                        // Assuming zero-delay read for behavioral simulation
                        r_start = ranges_flat[range_idx*2];
                        r_end = ranges_flat[range_idx*2 + 1];
                        
                        if (current_id >= r_start && current_id <= r_end) begin
                            // Match found!
                            count <= count + 1;
                            // Move to next ID immediately
                            id_idx <= id_idx + 1;
                            state <= STATE_FETCH_ID;
                        end else begin
                            // Check next range
                            range_idx <= range_idx + 1;
                        end
                    end
                end
                
                STATE_DONE: begin
                    // Stay here
                end
            endcase
        end
    end

endmodule
