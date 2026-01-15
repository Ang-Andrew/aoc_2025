// Minimal test: Just accumulate ROM values without split pipeline
module top (
    input wire clk,
    input wire rst,
    output reg [31:0] score
);

    reg [7:0] rom_addr = 0;
    reg read_enable = 0;
    reg [8:0] read_count = 0;

    wire [31:0] rom_data;

    rom_feeder_generic #(
        .FILENAME("data/results.hex"),
        .WIDTH(32)
    ) rf (
        .clk(clk),
        .addr(rom_addr),
        .data(rom_data)
    );

    reg [31:0] rom_data_reg = 0;
    reg read_enable_reg = 0;

    always @(posedge clk) begin
        if (rst) begin
            rom_data_reg <= 32'b0;
            read_enable_reg <= 1'b0;
        end else begin
            rom_data_reg <= rom_data;
            read_enable_reg <= read_enable;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            score <= 32'b0;
        end else if (read_enable_reg) begin
            score <= score + rom_data_reg;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 0;
            read_enable <= 0;
            read_count <= 0;
        end else if (read_count < 200) begin
            rom_addr <= read_count[7:0];
            read_enable <= 1;
            read_count <= read_count + 1;
        end else begin
            read_enable <= 0;
        end
    end

endmodule
