module top (
    input wire clk,
    input wire rst,
    output wire [31:0] score
);

    reg [7:0] rom_addr;
    wire [639:0] rom_data; // 128 Mask + 512 Data
    
    // Valid Logic
    reg valid_pulse;
    reg [2:0] state;
    
    localparam S_START = 0;
    localparam S_RUN   = 1;
    localparam S_DONE  = 2;
    
    rom_feeder rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );
    
    // Register ROM output to break critical path at 250MHz
    // ROM clock-to-Q (5.83ns) exceeds 4ns budget
    reg [639:0] rom_data_reg;
    reg valid_rom;

    always @(posedge clk) begin
        rom_data_reg <= rom_data;
        valid_rom <= valid_pulse;
    end

    // We assume 200 lines max (addr 8 bit is enough)

    tree_solver ts (
        .clk(clk),
        .rst(rst),
        .valid_in(valid_rom),
        .data_in(rom_data_reg[511:0]),
        .mask_in(rom_data_reg[639:512]),
        .total_score(score),
        .done()
    );
    
    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 0;
            valid_pulse <= 0;
            state <= S_START;
        end else begin
            case (state) 
                S_START: state <= S_RUN;
                
                S_RUN: begin
                    // Pipeline: Addr -> Data -> Valid Pulse
                    valid_pulse <= 1; 
                    if (rom_addr == 199) begin // 200 lines
                        state <= S_DONE;
                        valid_pulse <= 1; // Last one
                    end else begin
                        rom_addr <= rom_addr + 1;
                    end
                end
                
                S_DONE: begin
                    valid_pulse <= 0;
                end
            endcase
        end
    end

endmodule
