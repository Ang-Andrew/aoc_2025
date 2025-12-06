module top (
    input wire clk_250,
    input wire btn, // btn used for reset
    output wire led
);
    
    wire clk = clk_250;
    wire reset = btn; // Active high push button? Usually active low on EVN but lets assume active high for now or check schematic.
                         // ECP5-EVN buttons are usually Active Low? 
                         // Let's assume Active High for simplicity in code, we can invert in LPF or here if needed.
                         // Actually, I'll instantiate a counter to run the ROM.

    // Signals
    reg [12:0] rom_addr = 0;
    (* keep="true" *) wire [16:0] rom_data;
    
    reg valid_in = 0;
    wire [31:0] part1_count;
    (* keep="true" *) wire [31:0] part2_count;
    
    // ROM Instantiation
    input_rom #(
        .FILENAME("data/input.hex") // Path relative to synthesis execution
    ) rom_inst (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );
    
    // Solver Instantiation
    day1_solver solver_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .direction(rom_data[16]),
        .distance(rom_data[15:0]),
        .part1_count(part1_count),
        .part2_count(part2_count)
    );
    
    // State Machine to feed data
    // Very simple: just increment address every other cycle (because ROM has 1 cycle latency)
    // 4098 instructions.
    
    reg [2:0] state = 0;
    localparam IDLE = 0;
    localparam FETCH = 1;
    localparam EXEC = 2;
    localparam DONE = 3;
    
    always @(posedge clk) begin
        if (reset) begin
            rom_addr <= 0;
            valid_in <= 0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    rom_addr <= 0;
                    valid_in <= 0;
                    state <= FETCH;
                end
                
                FETCH: begin
                    // rom_addr is valid.
                    // Next cycle, rom_data will be valid.
                    state <= EXEC;
                end
                
                EXEC: begin
                    // rom_data is valid now.
                    valid_in <= 1;
                    
                    if (rom_addr == 4097) begin
                        state <= DONE; // We just processed the last one
                        valid_in <= 1; // Pulse valid for last instruction
                    end else begin
                        state <= FETCH; // Go back to fetch/wait for next address
                        rom_addr <= rom_addr + 1; // Increment for next fetch
                    end
                end
                
                DONE: begin
                    valid_in <= 0;
                    // Stay here
                end
            endcase
            
            // Note: valid_in needs to be PULSED.
            // In EXEC, we set valid_in <= 1.
            // In FETCH/DONE, valid_in <= 0.
            // This creates a pulse every 2 cycles, matching the rom latency pipeline roughly.
            if (state == EXEC) valid_in <= 0; // Turn off immediately in next cycle?
            // Actually:
            // T0: State=FETCH, Address=A.
            // T1: State=EXEC, Data=D(A). valid_in <= 1. Next State=FETCH/DONE. Address=(A+1).
            // T2: State=FETCH. valid_in <= 0.
            // Yes, this works. valid_in is high for 1 cycle.
        end
    end

    assign led = ~part2_count[0]; 

endmodule
