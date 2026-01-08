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
    reg [8:0] rom_addr = 0; // 4096 / 16 = 256 entries. 9 bits covers it.
    (* keep="true" *) wire [271:0] rom_data;
    
    reg valid_in = 0;
    wire [31:0] part1_count;
    (* keep="true" *) wire [31:0] part2_count;
    
    // ROM Instantiation
    input_rom #(
        .FILENAME("data/input.hex") 
    ) rom_inst (
        .clk(clk),
        .addr({4'b0, rom_addr}), // Pad address if ROM expects wider, or match types
        .data(rom_data)
    );
    
    // Solver Instantiation
    day1_solver solver_inst (
        .clk(clk),
        .reset(reset),
        .valid_in(valid_in),
        .valid_mask(16'hFFFF), // assume full vectors for simplicity
        .flat_data(rom_data),
        .part1_count(part1_count),
        .part2_count(part2_count)
    );
    
    // State Machine
    // 4098 items / 16 = 256.125 -> 257 lines.
    localparam MAX_ADDR = 256; 
    
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
                    state <= EXEC;
                end
                
                EXEC: begin
                    valid_in <= 1;
                    if (rom_addr == MAX_ADDR) begin
                        state <= DONE;
                        valid_in <= 1; 
                    end else begin
                        state <= FETCH; 
                        rom_addr <= rom_addr + 1;
                    end
                end
                
                DONE: begin
                    valid_in <= 0;
                end
            endcase
            
            if (state == EXEC) valid_in <= 0; 
        end
    end

    assign led = ~part2_count[0]; 

endmodule
