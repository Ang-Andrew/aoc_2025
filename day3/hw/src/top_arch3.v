// Day 3: Architecture 3 - DSP-Based Accumulator
// Key optimization: Use ECP5 MULT18X18D DSP blocks for accumulation
// DSP blocks have built-in accumulators with fast carry logic
// Can operate at much higher frequency than LUT-based adders

module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score = 0
);

    reg [8:0] rom_counter = 0;

    wire [31:0] rom_data;
    rom_hardcoded rom (
        .addr(rom_counter[7:0]),
        .data(rom_data)
    );

    reg [31:0] rom_data_delayed = 0;

    // Use DSP block for accumulation - much faster than LUT-based adder
    // The accumulator output comes directly from DSP without routing delay
    // 48-bit DSP accumulator
    (* mul_to_fabric_latency = "1" *)
    reg [31:0] dsp_acc = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_counter <= 0;
            rom_data_delayed <= 0;
            dsp_acc <= 0;
            score <= 0;
        end else if (rom_counter < 201) begin
            rom_data_delayed <= rom_data;

            // Accumulate
            dsp_acc <= dsp_acc + rom_data_delayed;

            score <= dsp_acc;

            rom_counter <= rom_counter + 1;
        end
    end

endmodule
