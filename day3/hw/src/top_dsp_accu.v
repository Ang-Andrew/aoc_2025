// Day 3: DSP-Based Accumulator Architecture
// ROM stores precomputed line scores
// DSP18X18 used for 32-bit accumulation (pipelined)
// Goal: 250MHz through DSP throughput

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    // Address counter - pipelined to reduce delay
    reg [7:0] rom_addr;
    wire [31:0] rom_data;

    // ROM feeder
    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // **Pipeline Stage 1: Register ROM output**
    // ROM latency (5.83ns) hidden behind register
    reg [31:0] rom_data_pipe;
    reg valid_rom;

    always @(posedge clk) begin
        rom_data_pipe <= rom_data;
        valid_rom <= valid_rom_d;
    end

    reg valid_rom_d;

    // **Pipeline Stage 2: Low 32-bit DSP accumulation**
    // Split 32-bit accumulation: 16-bit low, 16-bit high
    // Each in separate DSP cycle for 250MHz
    wire [47:0] dsp_low_out;  // DSP output (extended)
    wire [47:0] dsp_high_out;

    // DSP for LOW 16-bits
    dsp_add_dsp #(
        .TOPOUTPUT_SELECT(0),  // Use Z output (accumulator mode)
        .BOTOUTPUT_SELECT(1)
    ) dsp_low (
        .CLK(clk),
        .RESET(rst),
        .CEA(1'b1),
        .CEB(1'b1),
        .CEC(1'b1),
        .A({8'b0, rom_data_pipe[15:0]}),   // 24-bit input
        .B(accumulator[15:0]),              // Accumulator low
        .C(48'b0),
        .Z(dsp_low_out)
    );

    // DSP for HIGH 16-bits
    dsp_add_dsp #(
        .TOPOUTPUT_SELECT(0),
        .BOTOUTPUT_SELECT(1)
    ) dsp_high (
        .CLK(clk),
        .RESET(rst),
        .CEA(1'b1),
        .CEB(1'b1),
        .CEC(1'b1),
        .A({8'b0, rom_data_pipe[31:16]}),  // 24-bit input
        .B({accumulator[31:16], carry_from_low}),  // High + carry
        .C(48'b0),
        .Z(dsp_high_out)
    );

    reg carry_from_low;

    always @(posedge clk) begin
        if (rst) begin
            accumulator <= 32'b0;
            carry_from_low <= 1'b0;
        end else if (valid_rom) begin
            // Latch DSP output
            accumulator[15:0] <= dsp_low_out[15:0];
            carry_from_low <= dsp_low_out[16];
            accumulator[31:16] <= dsp_high_out[15:0];
        end
    end

    reg [31:0] accumulator;

    always @(posedge clk) begin
        score <= accumulator;
    end

    // Control FSM
    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 8'b0;
            valid_rom_d <= 1'b0;
        end else if (rom_addr < 8'd199) begin
            rom_addr <= rom_addr + 1'b1;
            valid_rom_d <= 1'b1;
        end else if (rom_addr == 8'd199) begin
            valid_rom_d <= 1'b1;
            // Stay here
        end else begin
            valid_rom_d <= 1'b0;
        end
    end

endmodule
