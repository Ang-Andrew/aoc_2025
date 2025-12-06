module timing_fail (
    input wire clk,
    output wire led
);

    // ---------------------------------------------------------
    // TIMING FAILURE GENERATOR
    // ---------------------------------------------------------
    // Strategy:
    // 1. High Utilization: Fill the chip to create congestion.
    // 2. High Logic Depth: Create a long combinational path.
    // 3. High Fanout: Make signals drive many loads.
    // ---------------------------------------------------------

    parameter NUM_CHAINS = 200;      // Number of parallel chains
    parameter CHAIN_LENGTH = 100;    // Depth of each combinational chain
    
    // We will use a counter to drive the chains
    reg [31:0] counter;
    always @(posedge clk) begin
        counter <= counter + 1;
    end

    // Array to hold the results of our long chains
    wire [NUM_CHAINS-1:0] chain_results;

    genvar i, j;
    generate
        for (i = 0; i < NUM_CHAINS; i = i + 1) begin : gen_chains
            
            // Define the wires for this specific chain
            // (* keep *) prevents optimization
            (* keep *) wire [CHAIN_LENGTH-1:0] stage;

            // Start of the chain: Mix counter bits to ensure it changes
            assign stage[0] = counter[i % 32] ^ counter[(i+5) % 32];

            for (j = 1; j < CHAIN_LENGTH; j = j + 1) begin : gen_stages
                // Each stage depends on the previous one AND some other global state
                // This creates dependencies that are hard to optimize.
                // We use a mix of operations.
                assign stage[j] = (stage[j-1] & counter[(j % 32)]) ^ 
                                  (stage[j-1] | counter[((j+3) % 32)]);
            end

            // The result of this chain is the last stage
            assign chain_results[i] = stage[CHAIN_LENGTH-1];
        end
    endgenerate

    // ---------------------------------------------------------
    // Output Logic
    // ---------------------------------------------------------
    // Register the XOR sum of all chains.
    // The path from 'counter' -> 'chain logic' -> 'final_reg' is HUGE.
    // ---------------------------------------------------------
    
    reg final_reg;
    always @(posedge clk) begin
        final_reg <= ^chain_results;
    end

    assign led = final_reg;

endmodule
