module split_placement (
    input wire clk,
    output wire led
);

    wire mid_signal;
    wire final_signal;

    // ---------------------------------------------------------
    // LEFT BLOCK
    // ---------------------------------------------------------
    // We use the UGROUP attribute to group these cells together.
    // The LPF file will constrain this group to the left side of the chip.
    (* UGROUP="left_group" *)
    logic_cloud #(.WIDTH(2000)) left (
        .clk(clk),
        .in_signal(1'b0),
        .out_signal(mid_signal)
    );

    // ---------------------------------------------------------
    // RIGHT BLOCK
    // ---------------------------------------------------------
    // Constrained to the right side of the chip.
    // The signal 'mid_signal' must cross the entire chip to get here.
    (* UGROUP="right_group" *)
    logic_cloud #(.WIDTH(2000)) right (
        .clk(clk),
        .in_signal(mid_signal),
        .out_signal(final_signal)
    );

    assign led = final_signal;

endmodule

// A dense block of logic to fill up the region
module logic_cloud #(parameter WIDTH = 1000) (
    input wire clk,
    input wire in_signal,
    output wire out_signal
);
    reg [WIDTH-1:0] chain;
    
    integer i;
    always @(posedge clk) begin
        // Seed the first bit with the input
        chain[0] <= in_signal ^ chain[WIDTH-1];
        
        // Create a dense XOR chain
        for (i = 1; i < WIDTH; i = i + 1) begin
            chain[i] <= chain[i-1] ^ chain[i];
        end
    end

    assign out_signal = chain[WIDTH-1];
endmodule
