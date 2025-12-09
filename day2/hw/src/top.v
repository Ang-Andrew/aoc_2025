module top(
    input clk_250,
    input btn,
    output led
);
    wire clk = clk_250;
    // Debounce reset? For this simple task, no.
    wire rst = btn; 
    
    wire [63:0] total_sum;
    wire done;
    
    // Hardcode parameters for the Example or Real Input?
    // Using default (Example) for now.
    solver #(
        .MEM_FILE("src/mem.hex"), 
        .RANGE_COUNT(11), 
        .MAX_K(7) 
    ) solver_inst (
        .clk(clk),
        .rst(rst),
        .total_sum(total_sum),
        .done(done)
    );
    
    // Visual feedback
    assign led = done ? total_sum[5] : 1'b0; 
    
endmodule
