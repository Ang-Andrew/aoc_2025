module top(
    input clk_250,
    input btn,
    output led,
    output [63:0] total_sum_out
);
    wire clk = clk_250;
    // Debounce reset? For this simple task, no.
    wire rst = btn; 
    
    wire [63:0] total_sum;
    assign total_sum_out = total_sum;
    wire done;
    
    // Hardcode parameters for the Example or Real Input?
    // Using default (Example) for now.
    solver #(
        .MEM_FILE("src/input.hex"), 
        .RANGE_COUNT(38), 
        .MAX_K(6) 
    ) solver_inst (
        .clk(clk),
        .rst(rst),
        .total_sum(total_sum),
        .done(done)
    );
    
    // Visual feedback
    assign led = done ? total_sum[5] : 1'b0; 
    
endmodule
