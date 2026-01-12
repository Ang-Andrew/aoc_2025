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

    wire [63:0] r_next;
    wire [63:0] q_next;
    wire do_sub;

    assign r_next = {r_temp[62:0], q_temp[63]};
    assign do_sub = (r_next >= b_temp);
    assign q_next = {q_temp[62:0], (busy && count > 0 && do_sub) ? 1'b1 : 1'b0};

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
                // Update remainder and quotient
                if (do_sub) begin
                    r_temp <= r_next - b_temp;
                end else begin
                    r_temp <= r_next;
                end
                q_temp <= q_next;
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
