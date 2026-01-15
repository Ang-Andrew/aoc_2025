// Day 3: Split 16-bit Pipelined Accumulator
// Process accumulation in two independent 16-bit stages per cycle
// Reduces critical path by splitting 32-bit add into 16-bit stages

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    reg [7:0] rom_addr;
    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // Pipeline stage 1: Register ROM output
    reg [31:0] rom_data_pipe;
    reg valid_rom;

    always @(posedge clk) begin
        rom_data_pipe <= rom_data;
        valid_rom <= valid_rom_d;
    end

    reg valid_rom_d;

    // Pipeline stage 2: Low 16-bit accumulation with carry
    reg [16:0] acc_low;    // 16-bit value + carry
    reg [31:16] rom_high_pipe;
    reg valid_acc_low;

    always @(posedge clk) begin
        if (rst) begin
            acc_low <= 17'b0;
        end else if (valid_rom) begin
            acc_low <= score[15:0] + rom_data_pipe[15:0];
        end

        rom_high_pipe <= rom_data_pipe[31:16];
        valid_acc_low <= valid_rom;
    end

    // Pipeline stage 3: High 16-bit accumulation (with carry from low)
    reg [31:0] accumulator;

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 32'b0;
        end else if (valid_acc_low) begin
            // Combine: high 16 bits + carry
            accumulator[15:0] <= acc_low[15:0];
            accumulator[31:16] <= score[31:16] + rom_high_pipe + acc_low[16];
        end
    end

    always @(posedge clk) begin
        score <= accumulator;
    end

    // Control FSM: Simple counter that's pipelined
    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 8'b0;
            valid_rom_d <= 1'b0;
        end else if (rom_addr < 8'd199) begin
            rom_addr <= rom_addr + 1'b1;
            valid_rom_d <= 1'b1;
        end else begin
            valid_rom_d <= 1'b0;
        end
    end

endmodule
