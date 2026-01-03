module top(
    input clk_250,
    input btn,
    output led
);
    wire clk = clk_250;
    wire reset = !btn; // Active low button implies reset? Or active high? Assuming btn is reset.
    // Day 2 LPF says "btn" on P4. Usually buttons are active low or high depending on board.
    // Let's assume active high reset for simplicity of logic, or invert if needed.

    wire [7:0] char_stream;
    wire valid_stream;
    wire feeder_done;
    wire [31:0] total_joltage;

    rom_feeder #(
        .MEM_FILE("../input/input.hex"),
        .MEM_SIZE(20200) // Approx size from wc -l
    ) feeder (
        .clk(clk),
        .reset(reset),
        .char_out(char_stream),
        .valid_out(valid_stream),
        .done(feeder_done)
    );

    solver solver_inst (
        .clk(clk),
        .reset(reset),
        .char_in(char_stream),
        .valid_in(valid_stream),
        .total_joltage(total_joltage)
    );

    // Prevent optimization
    assign led = |total_joltage[31:24]; 

endmodule
