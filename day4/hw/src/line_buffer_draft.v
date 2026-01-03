`default_nettype none

module line_buffer #(
    parameter DEPTH = 2048
)(
    input wire clk,
    input wire clken,
    input wire din,
    output wire dout
);
    // Inferred BRAM or DistRAM
    reg [0:0] memory [0:DEPTH-1];
    reg [10:0] ptr; // Assuming max 2048
    
    // Read-modify-write or just simple delay
    // We want a delay of exactly 'width'
    // But 'width' is variable per input file.
    // So we need a variable delay FIFO.
    // Actually, simplest is a fixed max size circular buffer with a read pointer = (write_pointer - width).
    // Or just a standard FIFO where we read and write at same rate once full?
    // The width is defined by the NEWLINES.
    
    // Alternative: We don't use fixed DEPTH. We use the 'valid' signal and dynamic addressing.
    // But for simplicity in this puzzle, let's assume a max width and use a pointer logic found by first Pass?
    // No, single pass.
    
    // We can use a standard FIFO.
    // Write at head, read at tail.
    // But we need to know WHEN to read. We read when we wrap a line.
    // Actually, simply:
    // We write every valid char.
    // We read every valid char.
    // BUT the data coming out must correspond to the pixel exactly one row above.
    // So if the row width is W, the FIFO depth is W.
    // We need to Detect W first? Or can we treat W as dynamic?
    
    // Dynamic W approach:
    // Store data. Don't read until we hit the first '\n'.
    // Then 'locked_width' = count.
    // Then we start reading.
    
    reg [11:0] wr_ptr;
    reg [11:0] rd_ptr;
    reg [11:0] recorded_width;
    reg width_locked;
    reg [11:0] current_count;

    always @(posedge clk) begin
        if (clken) begin
             memory[wr_ptr] <= din;
        end
    end
    
    assign dout = memory[rd_ptr];
    
    // Interface logic handled in parent
    
endmodule
