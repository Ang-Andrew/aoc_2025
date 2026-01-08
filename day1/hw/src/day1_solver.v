module day1_solver (
    input wire clk,
    input wire reset,
    
    // Command Interface
    // Vectorized Interface (W=16)
    input wire valid_in,
    input wire [271:0] flat_data, // 16 x 17-bit items
    input wire [15:0] valid_mask, // Currently assume all valid or simple padding? Let's use valid_in as "all valid" for now or mask
                                  // For simplicity, we assume padding is NO-OP (Distance 0). 
                                  // gen_hex pads with 0, which is L0 = NoOp.
    
    // Result Interface
    output reg [31:0] part1_count,
    output reg [31:0] part2_count
);

    // Unpack Data
    wire [16:0] items [0:15];
    genvar i;
    generate
        for (i=0; i<16; i=i+1) begin : unpack
            assign items[i] = flat_data[i*17 +: 17];
        end
    endgenerate

    // State
    reg [6:0] current_pos; // 0-99
    
    // Constants
    localparam OFFSET = 200000;

    // --- Combinational Vector Logic ---
    
    // 1. Calculate Individual Displacements and Part 2 Wraps
    reg signed [31:0] displacements [0:15];
    
    integer j;
    always @(*) begin
        for (j=0; j<16; j=j+1) begin
            if (items[j][16]) begin // Right
                displacements[j] = {16'b0, items[j][15:0]};
            end else begin // Left
                displacements[j] = -{16'b0, items[j][15:0]};
            end
        end
    end

    // 2. Parallel Prefix Sum of Displacements (Scan)
    // To check intermediate positions for Part 1.
    // prefix_disp[k] = sum(disp[0]..disp[k])
    
    reg signed [31:0] prefix_disp [0:15];
    always @(*) begin
        prefix_disp[0] = displacements[0];
        for (j=1; j<16; j=j+1) begin
            prefix_disp[j] = prefix_disp[j-1] + displacements[j];
        end
        // Note: For true "Engineering Triumph" in hardware, this loop 
        // synthesizes to a ripple chain. A tree structure is better for timing,
        // but for W=16 and 250MHz, ripple *might* pass, but tree is safer.
        // Given Synthesis tools are smart, this + operator chain is often retimed.
        // We'll stick to behavioral for readability unless timing fails.
    end

    // 3. Calculate "Next Positions" and Check for Zero (Part 1)
    // 4. Calculate Part 2 Wraps
    
    reg [4:0] batch_zeros;
    reg signed [31:0] batch_wraps;
    
    reg signed [31:0] abs_pos;
    reg signed [31:0] start_pos_ext;
    
    reg signed [31:0] prev_offset_sum; // Sum of disp up to k-1
    reg signed [31:0] step_target;
    
    always @(*) begin
        batch_zeros = 0;
        batch_wraps = 0;
        start_pos_ext = current_pos; // Sign extend
        
        for (j=0; j<16; j=j+1) begin
            // Part 1: Position Check
            // pos_k = (start + prefix_disp[k]) % 100
            
            // Handle Modulo with negative numbers for Part 1 Check
            step_target = start_pos_ext + prefix_disp[j];
            
            // Logic for (A % 100) == 0 equivalent to (A % 100) == 0 in Python
            // Python: -5 % 100 = 95. 0 % 100 = 0. 100 % 100 = 0.
            // A number leads to 0 if it is a multiple of 100.
            if ((step_target % 100) == 0) begin
                batch_zeros = batch_zeros + 1;
            end
            
            // Part 2: Wraps
            // Wraps = floor(target/100) - floor(start/100)
            // Here, for step j, start is (start + prefix[j-1]), target is (start + prefix[j])
            // Effectively, Total Wraps = floor(End/100) - floor(Start/100) ?
            // NO. Part 2 says "part2_count += distance // 100" plus simulation of steps.
            // Wait, previous Python code:
            // part2_count += distance // 100
            // then simulate remainder steps, if temp_pos == 0 count++;
            // This is actually checking if we CROSS ZERO during the move?
            // "Count full rotations" usually implies how many times we wrap.
            // Let's re-read Day 1 Python logic carefully.
            
            // Python:
            // part2_count += distance // 100
            // remainder loop: step by 1. if pos == 0 count++.
            
            // This logic counts how many times we land on/pass through 0 in specific way?
            // "distance // 100" counts full wraps.
            // Then it simulates remainder.
            
            // Optimization for Vector Logic:
            // Total Part 2 contribution for a move (D) starting at S:
            // Default count = D / 100.
            // Remainder R = D % 100.
            // Simulate R steps from S.
            // Essentially, we are counting how many times '0' is hit *during* the movement units.
            
            // Math: Number of times (Start + k) % 100 == 0 for 1 <= k <= D.
            // Valid k are k s.t. Start+k is multiple of 100.
            // Start + k = M * 100
            // k = M*100 - Start.
            // We need 1 <= M*100 - Start <= D.
            // (Start + 1) <= M*100 <= (Start + D).
            // So we just count multiples of 100 in range [Start+1, Start+D].
            // Count = floor((Start+D)/100) - floor(Start/100).
            
            // So YES, my previous formula: floor(target/100) - floor(start/100) was correct for Positive moves.
            // For Negative: [Start-D, Start-1].
            // Count = floor((Start-1)/100) - floor((Start-D-1)/100).
            
            // Let's implement this calculation for each item.
            // We need "Start for step j" which is `current_pos + prefix_disp[j-1]` (or current_pos for j=0).
            
        end
    end
    
    // Separate loop for Part 2 to avoid scope confusion/complexity
    reg signed [31:0] p2_start;
    reg signed [31:0] p2_end;
    reg signed [31:0] dist_val;
    reg dir_right;
    
    always @(*) begin
        batch_wraps = 0;
        for (j=0; j<16; j=j+1) begin
             if (j == 0) p2_start = current_pos;
             else p2_start = current_pos + prefix_disp[j-1];
             
             p2_end = current_pos + prefix_disp[j];
             dist_val = displacements[j]; // Signed
             
             if (dist_val >= 0) begin // Right
                 // Range [Start+1, End]
                 // Count = floor((End + OFFSET)/100) - floor((Start + OFFSET)/100)
                 // Note: Start+1 issue? 
                 // If Start=99, D=2. End=101. Range [100, 101]. 100 is multiple.
                 // floor(101/100) - floor(99/100) = 1 - 0 = 1. Correct.
                 // If Start=0, D=1. End=1. Range [1]. No multiple.
                 // floor(1/100) - floor(0/100) = 0. Correct.
                 // Wait, OFFSET is used to handle negatives safely, but for Right moves everything is positive if Start >= 0. 
                 // But strictly, p2_start can be negative if previous moves were left!
                 // The "Position" is modulo 100, checking zero crossings.
                 // But here we are tracking "Global Position on integer line" then counting multiples of 100.
                 // Yes, valid.
                 batch_wraps = batch_wraps + ( (p2_end + OFFSET)/100 - (p2_start + OFFSET)/100 );
             end else begin // Left
                 // Range [End, Start-1] (Traversing backwards)
                 // Count = floor((Start-1)/100) - floor((End-1)/100)
                 // Start=0, D=1 (Left 1). End=-1. Range [-1].
                 // floor(-1/100) - floor(-2/100). -1 - (-1) = 0. Correct.
                 // Start=1, D=1. End=0. Range [0]. 0 is multiple.
                 // floor(0/100) - floor(-1/100). 0 - (-1) = 1. Correct.
                 batch_wraps = batch_wraps + ( (p2_start - 1 + OFFSET)/100 - (p2_end - 1 + OFFSET)/100 );
             end
        end
    end

    // Sequential Update
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            current_pos <= 50;
            part1_count <= 0;
            part2_count <= 0;
        end else if (valid_in) begin
            part1_count <= part1_count + batch_zeros;
            part2_count <= part2_count + batch_wraps;
            
            // Update position modulo 100
            // New pos = (current + total_disp) % 100
            step_target = current_pos + prefix_disp[15];
            
            // Proper Modulo
            if (step_target >= 0) begin
                current_pos <= step_target % 100;
            end else begin
                // e.g. -1 % 100 -> 99.
                // Verilog % can return negative.
                // -1 % 100 = -1.
                current_pos <= (100 - ((-step_target) % 100)) % 100;
            end
        end
    end
    
endmodule
