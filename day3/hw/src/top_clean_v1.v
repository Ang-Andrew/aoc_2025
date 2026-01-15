// Day 3: Clean ROM-based Accumulator at 250MHz+
// Architecture: Binary counter + ROM + pipelined accumulation
//
// Strategy:
// - Read 200 precomputed line scores from ROM sequentially
// - Accumulate them using a pipelined adder to meet timing
// - Split 32-bit addition into two 16-bit stages to keep critical path short
// - Use binary counter (simplest, most reliable) for ROM addressing
//   (Counter is NOT on critical path - it only feeds ROM address)

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    initial begin
        score = 32'b0;
    end

    // ============================================================
    // Control: Binary Counter for ROM Addressing (0-199)
    // ============================================================
    reg [8:0] rom_addr_counter;  // Counts 0-199 then stops
    wire rom_read_active = (rom_addr_counter < 9'd200);
    wire [7:0] rom_addr = rom_addr_counter[7:0];

    initial rom_addr_counter = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_addr_counter <= 0;
        end else if (rom_read_active) begin
            rom_addr_counter <= rom_addr_counter + 1;
        end
    end

    // ============================================================
    // ROM: Precomputed line scores
    // ============================================================
    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // ============================================================
    // PIPELINE STAGE 1: ROM Output Register
    // ============================================================
    // Hide ROM latency (1 cycle)
    // Store the ROM data and whether it's valid
    reg [31:0] rom_data_r1;
    reg rom_valid_r1;

    initial begin
        rom_data_r1 = 0;
        rom_valid_r1 = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            rom_data_r1 <= 0;
            rom_valid_r1 <= 0;
        end else begin
            rom_data_r1 <= rom_data;
            rom_valid_r1 <= rom_read_active;  // Valid if ROM is being read
        end
    end

    // ============================================================
    // PIPELINE STAGE 2: Low 16-bit Accumulation
    // ============================================================
    // Add low 16 bits of accumulator + low 16 bits of ROM
    // Result is 17 bits (16 bits + carry)
    // This keeps the critical path to only one 16-bit add operation
    reg [16:0] sum_low_r2;
    reg [31:16] rom_high_r2;
    reg rom_valid_r2;

    initial begin
        sum_low_r2 = 0;
        rom_high_r2 = 0;
        rom_valid_r2 = 0;
    end

    always @(posedge clk) begin
        if (rst) begin
            sum_low_r2 <= 0;
            rom_high_r2 <= 0;
            rom_valid_r2 <= 0;
        end else begin
            sum_low_r2 <= score[15:0] + rom_data_r1[15:0];
            rom_high_r2 <= rom_data_r1[31:16];
            rom_valid_r2 <= rom_valid_r1;
        end
    end

    // ============================================================
    // PIPELINE STAGE 3: High 16-bit Accumulation
    // ============================================================
    // Add high 16 bits of accumulator + high 16 bits of ROM + carry
    // This completes the 32-bit accumulation
    reg [31:0] accum_r3;
    reg rom_valid_r3;

    initial begin
        accum_r3 = 0;
        rom_valid_r3 = 0;
    end

    wire [17:0] sum_high_temp = {1'b0, score[31:16]} + {1'b0, rom_high_r2} + {17'd0, sum_low_r2[16]};

    always @(posedge clk) begin
        if (rst) begin
            accum_r3 <= 0;
            rom_valid_r3 <= 0;
        end else begin
            // Combine the two halves of the addition
            // sum_low_r2[15:0] = low 16 bits of result
            // sum_low_r2[16]   = carry bit to high addition
            // score[31:16]     = current high accumulator value
            // rom_high_r2      = high 16 bits of ROM entry being added
            accum_r3[15:0] <= sum_low_r2[15:0];
            accum_r3[31:16] <= sum_high_temp[15:0];  // Only lower 16 bits of high sum
            rom_valid_r3 <= rom_valid_r2;
        end
    end

    // ============================================================
    // PIPELINE STAGE 4: Output Register
    // ============================================================
    // Final accumulation output
    always @(posedge clk) begin
        if (rst) begin
            score <= 0;
        end else if (rom_valid_r3) begin
            score <= accum_r3;
        end
    end

endmodule
