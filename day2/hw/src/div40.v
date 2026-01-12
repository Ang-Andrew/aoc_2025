module div40 (
    input clk,
    input rst,
    input start,
    input [39:0] dividend,
    input [40:0] divisor,
    output reg [39:0] quotient,
    output reg done
);

    reg [39:0] q_temp;
    reg [40:0] r_temp;
    reg [40:0] b_temp;
    reg [5:0] count;
    reg busy;

    wire [40:0] r_next;
    wire [39:0] q_next;
    wire do_sub;

    assign r_next = {r_temp[39:0], q_temp[39]};
    assign do_sub = (r_next >= b_temp);
    assign q_next = {q_temp[38:0], (busy && count > 0 && do_sub) ? 1'b1 : 1'b0};

    always @(posedge clk) begin
        if (rst) begin
            done <= 0;
            busy <= 0;
            quotient <= 0;
        end else if (start && !busy) begin
            if (divisor == 0) begin
                quotient <= 40'hFFFFFFFFFF;
                done <= 1;
            end else begin
                count <= 40;
                q_temp <= 0;
                r_temp <= 0;
                b_temp <= divisor;
                q_temp <= dividend;
                r_temp <= 0;
                busy <= 1;
                done <= 0;
            end
        end else if (busy) begin
            if (count > 0) begin
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
