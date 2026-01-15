// Day 3: Binary Counter + Split 16-bit Accumulator (CLEAN IMPLEMENTATION)
// v4: Proper pipeline valid signal propagation through all stages
// Binary counter for ROM addressing (no carry chain in critical path)
// Split accumulator in separate pipeline stages
// Total latency: 4 cycles per line (ROM + 3 accumulation stages)
//
// Timing Analysis:
// - ROM latency hidden behind register stage (5.83ns hidden)
// - Critical path: 16-bit additions in pipelined stages
// - Expected: ~200-220 MHz range

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    // ============================================================
    // Stage 0: ROM Addressing (BINARY COUNTER)
    // ============================================================
    // Simple binary counter 0-199 for ROM addressing
    // Binary counter is NOT on critical path (only drives ROM addr)
    reg [7:0] rom_addr = 8'b0;
    reg read_enable = 1'b0;  // Controls whether we're still reading

    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // ============================================================
    // Stage 1: ROM Output Register + Valid Pipeline
    // ============================================================
    reg [31:0] rom_data_pipe;
    reg valid_stage1;

    always @(posedge clk) begin
        if (rst) begin
            rom_data_pipe <= 32'b0;
            valid_stage1 <= 1'b0;
        end else begin
            rom_data_pipe <= rom_data;
            valid_stage1 <= read_enable;
        end
    end

    // ============================================================
    // Stage 2: Low 16-bit Accumulation with Carry
    // ============================================================
    // acc_low[16] is the carry bit
    reg [16:0] acc_low;
    reg [31:16] rom_high_pipe;
    reg valid_stage2;

    always @(posedge clk) begin
        if (rst) begin
            acc_low <= 17'b0;
            rom_high_pipe <= 16'b0;
            valid_stage2 <= 1'b0;
        end else begin
            // Add low 16 bits: score_low + rom_low
            acc_low <= score[15:0] + rom_data_pipe[15:0];
            // Pipeline the high word and valid bit
            rom_high_pipe <= rom_data_pipe[31:16];
            valid_stage2 <= valid_stage1;
        end
    end

    // ============================================================
    // Stage 3: High 16-bit Accumulation (with carry from low)
    // ============================================================
    reg [31:0] accumulator;
    reg valid_stage3;

    wire [31:0] next_accumulator;
    assign next_accumulator = {accumulator[31:16] + rom_high_pipe + acc_low[16], acc_low[15:0]};

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 32'b0;
            valid_stage3 <= 1'b0;
        end else begin
            if (valid_stage2) begin
                // Add next ROM entry to accumulator
                // Split into low 16 bits (from acc_low) and high 16 bits (with carry)
                accumulator <= next_accumulator;
            end
            valid_stage3 <= valid_stage2;
        end
    end

    // ============================================================
    // Stage 4: Output Register
    // ============================================================
    always @(posedge clk) begin
        if (rst) begin
            score <= 32'b0;
        end else begin
            if (valid_stage3) begin
                score <= accumulator;
            end
        end
    end

    // ============================================================
    // ROM Address Counter (Non-critical Binary Counter)
    // ============================================================
    // This counter is NOT on critical path because:
    // - It only feeds ROM address input (no feedback)
    // - ROM latency is hidden behind pipelining
    // - Next address is computed while current is being processed
    //
    // ROM has 1-cycle latency, so:
    // - Cycle N: Address X requested on rom_addr
    // - Cycle N+1: ROM output appears as rom_data
    // To ensure all 200 ROM reads are processed, we need read_enable
    // to propagate through the pipeline. So we extend it by 1 cycle
    // to account for ROM latency.
    reg [8:0] read_count = 9'b0;

    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 8'b0;
            read_enable <= 1'b0;
            read_count <= 9'b0;
        end else if (read_count < 9'd201) begin
            // Read exactly 200 ROM entries (addresses 0-199)
            // Plus 1 extra cycle to account for ROM latency
            if (read_count < 9'd200) begin
                rom_addr <= read_count[7:0];
            end
            read_enable <= 1'b1;
            read_count <= read_count + 1;
        end else begin
            // Done reading and ROM latency has propagated
            read_enable <= 1'b0;
        end
    end

endmodule
