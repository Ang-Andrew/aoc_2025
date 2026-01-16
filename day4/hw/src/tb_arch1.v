`timescale 1ns/1ps

module tb_solver;
    reg clk;
    reg reset;
    reg [7:0] char_in;
    reg valid_in;
    wire [31:0] total_accessible;

    reg [7:0] memory [0:65535];
    integer i, cycles;

    solver dut (
        .clk(clk),
        .reset(reset),
        .char_in(char_in),
        .valid_in(valid_in),
        .total_accessible(total_accessible)
    );

    initial clk = 0;
    always #2 clk = ~clk;

    initial cycles = 0;
    always @(posedge clk) cycles = cycles + 1;

    initial begin
        $dumpfile("sim_arch1.vcd");
        $dumpvars(0, tb_solver);

        for (i = 0; i < 65536; i = i + 1) begin
            memory[i] = 8'h00;
        end
        $readmemh("../input/input.hex", memory);

        #10;
        reset = 1;
        valid_in = 0;
        char_in = 0;
        #10;
        reset = 0;
        #10;

        @(posedge clk);

        for (i = 0; i < 18905; i = i + 1) begin
            char_in <= memory[i];
            valid_in <= 1;
            @(posedge clk);
        end

        valid_in <= 0;
        char_in <= 0;
        @(posedge clk);

        char_in <= 8'h0A;
        valid_in <= 1;
        @(posedge clk);
        valid_in <= 0;
        @(posedge clk);

        repeat (2100) @(posedge clk);

        $display("Final Count: %d", total_accessible);
        $display("Simulation cycles: %d", cycles);

        if (total_accessible == 1424) begin
            $display("SUCCESS: Matches Ground Truth");
        end else begin
            $display("FAILURE: Expected 1424, got %d", total_accessible);
        end

        $finish;
    end
endmodule
