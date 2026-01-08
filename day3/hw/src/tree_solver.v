// Moved tree_node to end

module tree_solver #(
    parameter WIDTH = 128
)(
    input clk,
    input rst,
    input valid_in,
    input [511:0] data_in, // 128 x 4-bit
    input [127:0] mask_in,
    output reg [31:0] total_score,
    output reg done
);

    // Tree Structure: 128 -> 64 -> 32 -> 16 -> 8 -> 4 -> 2 -> 1.
    // 7 Stages.
    // We register each stage.
    
    // Structs for each stage
    // For convenience in Verilog 2005, we flatten arrays.
    // Level 0 (Inputs)
    wire [3:0] l0_max   [0:127];
    wire [6:0] l0_score [0:127];
    wire [3:0] l0_first [0:127];
    wire       l0_valid [0:127];
    
    genvar i;
    generate
        for (i=0; i<128; i=i+1) begin : l0_unpack
            assign l0_max[i]   = data_in[i*4 +: 4];
            assign l0_score[i] = 0; // Single Digit score is 0.
            assign l0_first[i] = data_in[i*4 +: 4];
            assign l0_valid[i] = mask_in[i];
        end
    endgenerate
    
    //---------------------------------------------------------
    // Stage 1: 128 -> 64
    //---------------------------------------------------------
    reg [3:0] l1_max   [0:63];
    reg [6:0] l1_score [0:63];
    reg [3:0] l1_first [0:63];
    reg       l1_valid [0:63];
    reg       l1_v_in;
    
    wire [3:0] s1_max   [0:63];
    wire [6:0] s1_score [0:63];
    wire [3:0] s1_first [0:63];
    wire       s1_valid [0:63];
    
    generate
        for (i=0; i<64; i=i+1) begin : st1_nodes
            tree_node node (
                .l_max_seen(l0_max[2*i]), .l_score(l0_score[2*i]), .l_first_digit(l0_first[2*i]), .l_valid(l0_valid[2*i]),
                .r_max_seen(l0_max[2*i+1]), .r_score(l0_score[2*i+1]), .r_first_digit(l0_first[2*i+1]), .r_valid(l0_valid[2*i+1]),
                .o_max_seen(s1_max[i]), .o_score(s1_score[i]), .o_first_digit(s1_first[i]), .o_valid(s1_valid[i])
            );
        end
    endgenerate
    
    always @(posedge clk) begin
        l1_v_in <= valid_in;
        if (rst) l1_v_in <= 0;
        
        // Pipelining
        for (integer k=0; k<64; k=k+1) begin
            l1_max[k] <= s1_max[k];
            l1_score[k] <= s1_score[k];
            l1_first[k] <= s1_first[k];
            l1_valid[k] <= s1_valid[k];
        end
    end
    
    //---------------------------------------------------------
    // Stage 2: 64 -> 32
    //---------------------------------------------------------
    reg [3:0] l2_max   [0:31];
    reg [6:0] l2_score [0:31];
    reg [3:0] l2_first [0:31];
    reg       l2_valid [0:31];
    reg       l2_v_in;
    
    wire [3:0] s2_max   [0:31];
    wire [6:0] s2_score [0:31];
    wire [3:0] s2_first [0:31];
    wire       s2_valid [0:31];
    
    generate
        for (i=0; i<32; i=i+1) begin : st2_nodes
            tree_node node (
                .l_max_seen(l1_max[2*i]), .l_score(l1_score[2*i]), .l_first_digit(l1_first[2*i]), .l_valid(l1_valid[2*i]),
                .r_max_seen(l1_max[2*i+1]), .r_score(l1_score[2*i+1]), .r_first_digit(l1_first[2*i+1]), .r_valid(l1_valid[2*i+1]),
                .o_max_seen(s2_max[i]), .o_score(s2_score[i]), .o_first_digit(s2_first[i]), .o_valid(s2_valid[i])
            );
        end
    endgenerate
    
    always @(posedge clk) begin
        l2_v_in <= l1_v_in;
        if (rst) l2_v_in <= 0;
        for (integer k=0; k<32; k=k+1) begin
            l2_max[k] <= s2_max[k];
            l2_score[k] <= s2_score[k];
            l2_first[k] <= s2_first[k];
            l2_valid[k] <= s2_valid[k];
        end
    end
    
    //---------------------------------------------------------
    // Stage 3: 32 -> 16
    //---------------------------------------------------------
    reg [3:0] l3_max   [0:15];
    reg [6:0] l3_score [0:15];
    reg [3:0] l3_first [0:15];
    reg       l3_valid [0:15];
    reg       l3_v_in;
    wire [3:0] s3_max   [0:15];
    wire [6:0] s3_score [0:15];
    wire [3:0] s3_first [0:15];
    wire       s3_valid [0:15];
    
    generate for (i=0; i<16; i=i+1) begin : st3_nodes tree_node node (.l_max_seen(l2_max[2*i]), .l_score(l2_score[2*i]), .l_first_digit(l2_first[2*i]), .l_valid(l2_valid[2*i]), .r_max_seen(l2_max[2*i+1]), .r_score(l2_score[2*i+1]), .r_first_digit(l2_first[2*i+1]), .r_valid(l2_valid[2*i+1]), .o_max_seen(s3_max[i]), .o_score(s3_score[i]), .o_first_digit(s3_first[i]), .o_valid(s3_valid[i])); end endgenerate
    
    always @(posedge clk) begin 
        l3_v_in <= l2_v_in; if (rst) l3_v_in <= 0;
        for (integer k=0; k<16; k=k+1) begin l3_max[k] <= s3_max[k]; l3_score[k] <= s3_score[k]; l3_first[k] <= s3_first[k]; l3_valid[k] <= s3_valid[k]; end 
    end

    //---------------------------------------------------------
    // Stage 4: 16 -> 8
    //---------------------------------------------------------
    reg [3:0] l4_max   [0:7];
    reg [6:0] l4_score [0:7];
    reg [3:0] l4_first [0:7];
    reg       l4_valid [0:7];
    reg       l4_v_in;
    wire [3:0] s4_max   [0:7];
    wire [6:0] s4_score [0:7];
    wire [3:0] s4_first [0:7];
    wire       s4_valid [0:7];
    generate for (i=0; i<8; i=i+1) begin : st4_nodes tree_node node (.l_max_seen(l3_max[2*i]), .l_score(l3_score[2*i]), .l_first_digit(l3_first[2*i]), .l_valid(l3_valid[2*i]), .r_max_seen(l3_max[2*i+1]), .r_score(l3_score[2*i+1]), .r_first_digit(l3_first[2*i+1]), .r_valid(l3_valid[2*i+1]), .o_max_seen(s4_max[i]), .o_score(s4_score[i]), .o_first_digit(s4_first[i]), .o_valid(s4_valid[i])); end endgenerate
    always @(posedge clk) begin l4_v_in <= l3_v_in; if (rst) l4_v_in <= 0; for (integer k=0; k<8; k=k+1) begin l4_max[k] <= s4_max[k]; l4_score[k] <= s4_score[k]; l4_first[k] <= s4_first[k]; l4_valid[k] <= s4_valid[k]; end end

    //---------------------------------------------------------
    // Stage 5: 8 -> 4
    //---------------------------------------------------------
    reg [3:0] l5_max   [0:3];
    reg [6:0] l5_score [0:3];
    reg [3:0] l5_first [0:3];
    reg       l5_valid [0:3];
    reg       l5_v_in;
    wire [3:0] s5_max   [0:3];
    wire [6:0] s5_score [0:3];
    wire [3:0] s5_first [0:3];
    wire       s5_valid [0:3]; // Fix: Wire declaration was missing or implicit
    generate for (i=0; i<4; i=i+1) begin : st5_nodes tree_node node (.l_max_seen(l4_max[2*i]), .l_score(l4_score[2*i]), .l_first_digit(l4_first[2*i]), .l_valid(l4_valid[2*i]), .r_max_seen(l4_max[2*i+1]), .r_score(l4_score[2*i+1]), .r_first_digit(l4_first[2*i+1]), .r_valid(l4_valid[2*i+1]), .o_max_seen(s5_max[i]), .o_score(s5_score[i]), .o_first_digit(s5_first[i]), .o_valid(s5_valid[i])); end endgenerate
    always @(posedge clk) begin l5_v_in <= l4_v_in; if (rst) l5_v_in <= 0; for (integer k=0; k<4; k=k+1) begin l5_max[k] <= s5_max[k]; l5_score[k] <= s5_score[k]; l5_first[k] <= s5_first[k]; l5_valid[k] <= s5_valid[k]; end end

    //---------------------------------------------------------
    // Stage 6: 4 -> 2
    //---------------------------------------------------------
    reg [3:0] l6_max   [0:1];
    reg [6:0] l6_score [0:1];
    reg [3:0] l6_first [0:1];
    reg       l6_valid [0:1];
    reg       l6_v_in;
    wire [3:0] s6_max   [0:1];
    wire [6:0] s6_score [0:1];
    wire [3:0] s6_first [0:1];
    wire       s6_valid [0:1];
    generate for (i=0; i<2; i=i+1) begin : st6_nodes tree_node node (.l_max_seen(l5_max[2*i]), .l_score(l5_score[2*i]), .l_first_digit(l5_first[2*i]), .l_valid(l5_valid[2*i]), .r_max_seen(l5_max[2*i+1]), .r_score(l5_score[2*i+1]), .r_first_digit(l5_first[2*i+1]), .r_valid(l5_valid[2*i+1]), .o_max_seen(s6_max[i]), .o_score(s6_score[i]), .o_first_digit(s6_first[i]), .o_valid(s6_valid[i])); end endgenerate
    always @(posedge clk) begin l6_v_in <= l5_v_in; if (rst) l6_v_in <= 0; for (integer k=0; k<2; k=k+1) begin l6_max[k] <= s6_max[k]; l6_score[k] <= s6_score[k]; l6_first[k] <= s6_first[k]; l6_valid[k] <= s6_valid[k]; end end

    //---------------------------------------------------------
    // Stage 7: 2 -> 1
    //---------------------------------------------------------
    reg [3:0] l7_max;
    reg [6:0] l7_score;
    reg [3:0] l7_first;
    reg       l7_valid;
    reg       l7_v_in;
    wire [3:0] s7_max;
    wire [6:0] s7_score;
    wire [3:0] s7_first;
    wire       s7_valid;
    
    tree_node root (
        .l_max_seen(l6_max[0]), .l_score(l6_score[0]), .l_first_digit(l6_first[0]), .l_valid(l6_valid[0]),
        .r_max_seen(l6_max[1]), .r_score(l6_score[1]), .r_first_digit(l6_first[1]), .r_valid(l6_valid[1]),
        .o_max_seen(s7_max), .o_score(s7_score), .o_first_digit(s7_first), .o_valid(s7_valid)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            total_score <= 0;
            done <= 0; // Not used really, streaming
        end else if (l6_v_in) begin // Valid input reaches end
            total_score <= total_score + s7_score;
        end
    end

endmodule

module tree_node (
    // Left Input
    input  [3:0] l_max_seen,
    input  [6:0] l_score,
    input  [3:0] l_first_digit,
    input        l_valid,
    
    // Right Input
    input  [3:0] r_max_seen,
    input  [6:0] r_score,
    input  [3:0] r_first_digit,
    input        r_valid,
    
    // Output
    output reg [3:0] o_max_seen,
    output reg [6:0] o_score,
    output reg [3:0] o_first_digit,
    output reg       o_valid
);

    reg [6:0] cross_score;

    always @(*) begin
        if (!l_valid && !r_valid) begin
            o_max_seen = 0;
            o_score = 0;
            o_first_digit = 0;
            o_valid = 0;
        end else if (!l_valid) begin
            o_max_seen = r_max_seen;
            o_score = r_score;
            o_first_digit = r_first_digit;
            o_valid = 1;
        end else if (!r_valid) begin
            o_max_seen = l_max_seen;
            o_score = l_score;
            o_first_digit = l_first_digit;
            o_valid = 1;
        end else begin
            o_valid = 1;
            
            // Max Seen
            o_max_seen = (l_max_seen > r_max_seen) ? l_max_seen : r_max_seen;
            
            // First Digit
            o_first_digit = l_first_digit; 
            
            // Score
            cross_score = (l_max_seen * 10) + r_first_digit; 
            
            if (l_score >= r_score && l_score >= cross_score)
                o_score = l_score;
            else if (r_score >= l_score && r_score >= cross_score)
                o_score = r_score;
            else
                o_score = cross_score;
        end
    end

endmodule
