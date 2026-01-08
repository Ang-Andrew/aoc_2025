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
    
    // 2. Instantiate Cores
    wire [63:0] core_sums [0:RANGE_COUNT-1];
    wire [RANGE_COUNT-1:0] core_dones;
    
    // Start signal
    reg start_cores;
    
    genvar i;
    generate
        for (i=0; i<RANGE_COUNT; i=i+1) begin : cores
            range_calc #(
                .MAX_K(MAX_K)
            ) rc (
                .clk(clk),
                .rst(rst),
                .start(start_cores),
                .range_start(ranges[i][63:0]),
                .range_end(ranges[i][127:64]),
                .sum_out(core_sums[i]),
                .done(core_dones[i])
            );
        end
    endgenerate
    
    // 3. Control & Accumulation
    reg [2:0] state;
    integer j;
    
    localparam S_WAIT_START = 0;
    localparam S_RUN = 1;
    localparam S_SUM = 2;
    localparam S_DONE = 3;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= S_WAIT_START;
            total_sum <= 0;
            done <= 0;
            start_cores <= 0;
        end else begin
            case (state)
                S_WAIT_START: begin
                    // Wait 1 cycle for reset to settle?
                    start_cores <= 1;
                    state <= S_RUN;
                end
                
                S_RUN: begin
                    start_cores <= 0;
                    if (&core_dones) begin // All Done
                        state <= S_SUM;
                    end
                end
                
                S_SUM: begin
                    // Sum all outputs (Combinational loop ok since done)
                    // Or registered?
                    // Let's do a simple loop sum. 38 items. Ripple adder might be slow but it's 1 cycle.
                    // Synthesizer will tree it.
                    reg [63:0] temp_sum;
                    temp_sum = 0;
                    for (j=0; j<RANGE_COUNT; j=j+1) begin
                        temp_sum = temp_sum + core_sums[j];
                    end
                    total_sum <= temp_sum;
                    state <= S_DONE;
                end
                
                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

endmodule
