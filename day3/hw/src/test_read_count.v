`timescale 1ns/1ps

module test_read_count;

    reg clk, rst;
    reg [8:0] read_count = 0;
    reg [7:0] rom_addr = 0;
    reg read_enable = 0;

    initial clk = 0;
    always #2 clk = ~clk;

    always @(posedge clk) begin
        if (rst) begin
            rom_addr <= 8'b0;
            read_enable <= 1'b0;
            read_count <= 9'b0;
        end else if (read_count < 9'd201) begin
            if (read_count < 9'd200) begin
                rom_addr <= read_count[7:0];
            end
            read_enable <= 1'b1;
            read_count <= read_count + 1;
        end else begin
            read_enable <= 1'b0;
        end
    end

    initial begin
        rst = 1;
        @(posedge clk);
        rst = 0;
        @(posedge clk);

        $display("Count | Addr | En");
        repeat(210) begin
            @(posedge clk);
            if (read_count <= 5 || read_count >= 195) begin
                $display("%5d | %3d  | %d", read_count, rom_addr, read_enable);
            end
        end

        $finish;
    end

endmodule
