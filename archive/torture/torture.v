module torture (
    input wire clk,
    output wire led
);

    // ---------------------------------------------------------
    // FPGA TORTURE TEST (Ported from stnolting/fpga_torture)
    // ---------------------------------------------------------
    // This design implements a modified Galois LFSR to consume
    // all available logic resources and generate chaotic switching.
    // ---------------------------------------------------------

    // Number of cells in the chain. 
    // Adjust this to fill your specific FPGA.
    // ECP5-45F has ~44k LUTs/FFs.
    parameter NUM_CELLS = 40000; 

    reg [NUM_CELLS:0] chain;
    reg toggle_ff;

    // Toggle FF to start/seed the chain
    always @(posedge clk) begin
        toggle_ff <= ~toggle_ff;
    end

    // The Chain
    // chain(i) <= chain(i-3) ^ chain(i-2) ^ chain(i-1)
    integer i;
    always @(posedge clk) begin
        // First 3 elements need special handling or initialization
        // The original VHDL uses a toggle FF to feed the start.
        // Let's feed the toggle_ff into the first few cells to get it going.
        
        chain[0] <= toggle_ff;
        chain[1] <= chain[0] ^ toggle_ff;
        chain[2] <= chain[1] ^ chain[0] ^ toggle_ff;

        for (i = 3; i <= NUM_CELLS; i = i + 1) begin
            chain[i] <= chain[i-3] ^ chain[i-2] ^ chain[i-1];
        end
    end

    // Output to prevent optimization
    // We just take the last element of the chain
    assign led = chain[NUM_CELLS];

endmodule
