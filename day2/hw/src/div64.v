module div64 (
    input clk,
    input rst,
    input start,
    input [63:0] dividend,
    input [63:0] divisor,
    output reg [63:0] quotient,
    output reg done
);

    reg [63:0] q_temp;
    reg [63:0] r_temp;
    reg [63:0] b_temp;
    reg [6:0] count;
    reg busy;

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            busy <= 0;
            quotient <= 0;
        end else if (start && !busy) begin
            if (divisor == 0) begin
                // Div by zero handling (return max or 0?)
                quotient <= 64'hFFFFFFFFFFFFFFFF;
                done <= 1;
            end else begin
                // Initialize
                count <= 64;
                q_temp <= 0;
                r_temp <= 0;
                b_temp <= divisor;
                // Pre-shift dividend into a shift register? 
                // Standard non-restoring: shift R, shift in bit of D, subtract.
                // Or simplified: R = (R << 1) | D_msb.
                // Let's use a 128-bit register {r, d}.
                // {r_next, d_next} = {r, d} << 1.
                // if r_next >= b, r_next -= b, q_bit=1.
                
                // Working registers:
                // We use 'quotient' to store the shifting dividend? No, separate.
                q_temp <= dividend; // reuse q_temp as dividend/quotient shift reg
                r_temp <= 0;
                
                busy <= 1;
                done <= 0;
            end
        end else if (busy) begin
            if (count > 0) begin
                // Shift Left {r, q}
                r_temp = {r_temp[62:0], q_temp[63]};
                q_temp = {q_temp[62:0], 1'b0};
                
                // Subtract?
                if (r_temp >= b_temp) begin
                    r_temp = r_temp - b_temp;
                    q_temp[0] = 1'b1;
                end
                
                count <= count - 1;
            end else begin
                quotient <= q_temp;
                done <= 1;
                busy <= 0;
            end
        end else begin
            done <= 0;
        end
    end

endmodule
