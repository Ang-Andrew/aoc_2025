`default_nettype none
`timescale 1ns/1ps

module tb_solver;
    reg clk;
    reg reset;
    reg [7:0] char_in;
    reg valid_in;
    wire [31:0] total_accessible;

    solver dut (
        .clk(clk),
        .reset(reset),
        .char_in(char_in),
        .valid_in(valid_in),
        .total_accessible(total_accessible)
    );

    initial clk = 0;
    always #2 clk = ~clk;

    integer file, char, i;

    initial begin
        $dumpfile("sim.vcd");
        $dumpvars(0, tb_solver);

        reset = 1;
        valid_in = 0;
        char_in = 8'h00;
        #10;
        reset = 0;
        #10;

        file = $fopen("../input/input.txt", "r");
        if (file == 0) begin
            $display("ERROR: Could not open input file");
            $finish;
        end

        // Read 20000 characters
        for (i = 0; i < 20000; i = i + 1) begin
            char = $fgetc(file);
            if (char == -1) begin
                valid_in <= 0;
                break;
            end
            char_in <= char[7:0];
            valid_in <= 1;
            @(posedge clk);
        end

        $fclose(file);
        valid_in <= 0;
        repeat (100) @(posedge clk);

        $display("Final Count: %d", total_accessible);
        $finish;
    end
endmodule
