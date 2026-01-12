module solver #(
    parameter MEM_FILE = "mem.hex",
    parameter RANGE_COUNT = 38,
    parameter MAX_K = 12
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);
    
    // 1. Memory
    reg [127:0] ranges [0:RANGE_COUNT-1];
    initial $readmemh(MEM_FILE, ranges);
    
    // 2. Single Core Instance
    reg core_start;
    reg [63:0] core_start_val;
    reg [63:0] core_end_val;
    wire [63:0] core_sum_out;
    wire core_done;
    
    range_calc #(
        .MAX_K(MAX_K)
    ) rc (
        .clk(clk),
        .rst(rst),
        .start(core_start),
        .range_start(core_start_val),
        .range_end(core_end_val),
        .sum_out(core_sum_out),
        .done(core_done)
    );

    // 3. Control & Accumulation
    reg [2:0] state;
    integer range_idx;
    reg [63:0] temp_sum;
    
    localparam S_IDLE = 0;
    localparam S_START_RANGE = 1;
    localparam S_WAIT_BUSY = 2;
    localparam S_WAIT_RANGE = 3;
    localparam S_ACCUM = 4;
    localparam S_NEXT = 5;
    localparam S_DONE = 6;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE;
            done <= 0;
            total_sum <= 0;
            range_idx <= 0;
            core_start <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    range_idx <= 0;
                    total_sum <= 0;
                    state <= S_START_RANGE;
                end
                
                S_START_RANGE: begin
                    if (range_idx < RANGE_COUNT) begin
                        core_start_val <= ranges[range_idx][63:0];
                        core_end_val <= ranges[range_idx][127:64];
                        core_start <= 1;
                        state <= S_WAIT_BUSY;
                    end else begin
                        state <= S_DONE;
                    end
                end
                
                S_WAIT_BUSY: begin
                    core_start <= 0;
                    state <= S_WAIT_RANGE;
                end
                
                S_WAIT_RANGE: begin
                    if (core_done) begin
                        state <= S_ACCUM;
                    end
                end
                
                S_ACCUM: begin
                    total_sum <= total_sum + core_sum_out;
                    state <= S_NEXT;
                end
                
                S_NEXT: begin
                    range_idx <= range_idx + 1;
                    state <= S_START_RANGE;
                end
                
                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
