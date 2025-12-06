module day1_solver (
    input wire clk,
    input wire reset,
    
    // Command Interface
    input wire valid_in,
    input wire direction, // 0 = Left, 1 = Right
    input wire [15:0] distance,
    
    // Result Interface
    output reg [31:0] part1_count,
    output reg [31:0] part2_count
);

    reg [6:0] position; // 0-99 needs 7 bits

    // Temporary variables for calculation
    reg signed [31:0] current_pos_extended;
    reg signed [31:0] target_pos_extended;
    reg [6:0] next_pos_norm;
    reg [6:0] mod_val;
    
    // Offset for calculating "floor" division using positive numbers
    // 200000 is safely larger than max negative value (~-65536)
    localparam OFFSET = 200000;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            position <= 50; // Starts at 50
            part1_count <= 0;
            part2_count <= 0;
        end else if (valid_in) begin
            
            current_pos_extended = position;
            
            if (direction) begin // RIGHT
                target_pos_extended = current_pos_extended + distance;
                
                // Formula: floor(target/100) - floor(current/100)
                // Excludes start, includes end.
                part2_count <= part2_count + 
                               ((target_pos_extended + OFFSET) / 100) - 
                               ((current_pos_extended + OFFSET) / 100);
                
                // Update position
                position <= target_pos_extended % 100;
                
                // Prepare check for Part 1
                next_pos_norm = target_pos_extended % 100;

            end else begin // LEFT
                target_pos_extended = current_pos_extended - distance;
                
                // Formula: floor((current-1)/100) - floor((target-1)/100)
                // Excludes start, includes end (mathematically checking intervals crossing k*100)
                part2_count <= part2_count + 
                               ((current_pos_extended - 1 + OFFSET) / 100) - 
                               ((target_pos_extended - 1 + OFFSET) / 100);
                               
                // Update position (Handle negative modulo correctly)
                if (target_pos_extended < 0) begin
                    mod_val = (0 - target_pos_extended) % 100;
                    if (mod_val == 0) begin
                        position <= 0;
                        next_pos_norm = 0;
                    end else begin
                        position <= 100 - mod_val;
                        next_pos_norm = 100 - mod_val;
                    end
                end else begin
                    position <= target_pos_extended % 100;
                    next_pos_norm = target_pos_extended % 100;
                end
            end
            
            // Part 1 Check
            if (next_pos_norm == 0) begin
                part1_count <= part1_count + 1;
            end
            
        end
    end

endmodule
