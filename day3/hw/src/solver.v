`default_nettype none

module solver (
    input wire clk,
    input wire reset,
    input wire [7:0] char_in,
    input wire valid_in,
    output reg [31:0] total_joltage
);

    // ASCII constants
    localparam [7:0] CHAR_0 = 8'h30;
    localparam [7:0] CHAR_9 = 8'h39;
    localparam [7:0] CHAR_NL = 8'h0A;

    reg [3:0] digit_max;
    reg [6:0] line_max;
    
    wire [3:0] current_digit = char_in[3:0];
    wire is_digit = (char_in >= CHAR_0) && (char_in <= CHAR_9);
    wire is_newline = (char_in == CHAR_NL);

    // Calculation: Previous Max * 10 + Current
    // x * 10 = (x * 8) + (x * 2) = (x << 3) + (x << 1)
    wire [6:0] candidate_score = ({3'b0, digit_max} << 3) + ({3'b0, digit_max} << 1) + {3'b0, current_digit};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            total_joltage <= 32'd0;
            digit_max <= 4'd0;
            line_max <= 7'd0;
        end else if (valid_in) begin
            if (is_newline) begin
                // End of line: Accumulate and Reset line logic
                total_joltage <= total_joltage + {25'd0, line_max};
                digit_max <= 4'd0;
                line_max <= 7'd0;
            end else if (is_digit) begin
                // Streaming update
                if (candidate_score > line_max) begin
                    line_max <= candidate_score;
                end
                
                if (current_digit > digit_max) begin
                    digit_max <= current_digit;
                end
            end
        end
    end

endmodule
