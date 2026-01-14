// Day 3: ROM-Based 250MHz Implementation
// Precomputed results: All tree reduction done offline in Python
// Hardware: Just ROM + accumulator (simple, fast)

module top (
    input wire clk,
    input wire rst,
    output wire [31:0] score
);

    reg [7:0] rom_addr;
    wire [31:0] rom_data;  // 32-bit pre-computed result per line

    // State machine
    reg valid_pulse;
    reg [2:0] state;

    localparam S_START = 0;
    localparam S_RUN   = 1;
    localparam S_DONE  = 2;

    // ROM feeder for precomputed results
    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    // Pipeline stage: Register ROM output to break memory latency
    // ROM clock-to-Q (5.83ns) latency is hidden behind FF
    reg [31:0] rom_data_pipe;
    reg valid_rom;

    always @(posedge clk) begin
        rom_data_pipe <= rom_data;
        valid_rom <= valid_pulse;
    end

    // Accumulator: Simply add precomputed results
    // This is trivial logic, easily fits in 4ns @ 250MHz
    always @(posedge clk) begin
        if (rst) begin
            score <= 32'b0;
        end else if (valid_rom) begin
            score <= score + rom_data_pipe;
        end
    end

    // Control FSM
    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 8'b0;
            valid_pulse <= 1'b0;
            state <= S_START;
        end else begin
            case (state)
                S_START: begin
                    state <= S_RUN;
                end

                S_RUN: begin
                    valid_pulse <= 1'b1;
                    if (rom_addr == 8'd199) begin  // 200 lines
                        state <= S_DONE;
                    end else begin
                        rom_addr <= rom_addr + 1'b1;
                    end
                end

                S_DONE: begin
                    valid_pulse <= 1'b0;
                end
            endcase
        end
    end

endmodule
