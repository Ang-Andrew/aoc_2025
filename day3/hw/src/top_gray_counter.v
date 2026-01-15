// Day 3: Gray Code Counter for Address Generation
// Gray code changes only 1 bit per increment = fewer carry chains
// Should significantly improve timing vs binary counter

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    // Gray code counter (fewer bit transitions = faster timing)
    reg [7:0] gray_addr;
    wire [7:0] binary_addr = gray_to_binary(gray_addr);

    function [7:0] gray_to_binary;
        input [7:0] gray;
        integer i;
        begin
            gray_to_binary[7] = gray[7];
            for (i = 6; i >= 0; i = i - 1)
                gray_to_binary[i] = gray_to_binary[i+1] ^ gray[i];
        end
    endfunction

    function [7:0] increment_gray;
        input [7:0] gray;
        reg [8:0] bin;
        begin
            // Convert to binary
            bin[8] = 1'b0;
            bin[7] = gray[7];
            bin[6:0] = gray[6:0] ^ {bin[7], bin[7:1]};
            // Increment
            bin = bin + 1;
            // Convert back to Gray
            increment_gray[7] = bin[7];
            increment_gray[6:0] = bin[7:1] ^ bin[6:0];
        end
    endfunction

    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(binary_addr),
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
    reg [16:0] acc_low;
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

    // Pipeline stage 3: High 16-bit accumulation
    reg [31:0] accumulator;

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 32'b0;
        end else if (valid_acc_low) begin
            accumulator[15:0] <= acc_low[15:0];
            accumulator[31:16] <= score[31:16] + rom_high_pipe + acc_low[16];
        end
    end

    always @(posedge clk) begin
        score <= accumulator;
    end

    // Gray code counter: only 1 bit changes per cycle
    always @(posedge clk) begin
        if (rst) begin
            gray_addr <= 8'b0;
            valid_rom_d <= 1'b0;
        end else if (binary_addr < 8'd199) begin
            gray_addr <= increment_gray(gray_addr);
            valid_rom_d <= 1'b1;
        end else begin
            valid_rom_d <= 1'b0;
        end
    end

endmodule
