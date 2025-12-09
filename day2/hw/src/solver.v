module solver #(
    parameter MEM_FILE = "mem.hex",
    parameter RANGE_COUNT = 38,
    parameter MAX_K = 12
)(
    input clk,
    input rst,
    output reg [63:0] total_sum,
    output reg done
);
    
    //-------------------------------------------------------------------------
    // 1. Generator Instantiation
    //-------------------------------------------------------------------------
    wire [63:0] gen_val;
    wire gen_valid;
    wire gen_done;
    reg stall_gen; 
    
    generator #(
        .MAX_K(MAX_K)
    ) gen_inst (
        .clk(clk),
        .rst(rst),
        .stall(stall_gen),
        .out_val(gen_val),
        .out_valid(gen_valid),
        .done(gen_done)
    );
    
    //-------------------------------------------------------------------------
    // 2. Memory (Ranges)
    //-------------------------------------------------------------------------
    // We use distributed RAM or regfile since RANGE_COUNT is small (~40).
    reg [127:0] ranges [0:RANGE_COUNT-1];
    initial $readmemh(MEM_FILE, ranges);
    
    //-------------------------------------------------------------------------
    // 3. Pipeline Stages
    //-------------------------------------------------------------------------
    
    // STAGE 0: Fetch Range ---------------------------------------------------
    reg [31:0] range_idx;
    reg [63:0] s0_r_start, s0_r_end;
    reg        s0_range_valid;
    
    always @(posedge clk) begin
        if (rst) begin
            range_idx <= 0;
            s0_range_valid <= 0;
        end else begin
            if (range_idx < RANGE_COUNT) begin
                s0_r_start <= ranges[range_idx][63:0];
                s0_r_end   <= ranges[range_idx][127:64];
                s0_range_valid <= 1;
            end else begin
                s0_range_valid <= 0;
            end
        end
    end

    // Handling Stalls/Updates
    // We need to stall Gen if stage 1 says "Advance Range".
    // "Advance Range" happens in Stage 2 logic? 
    // Actually, simple pipeline:
    // P0: Gen Output -> P1 Register
    // P1: Compare (Val vs Range). If Val > Range, signal Update Range. Stall P0.
    
    // Let's integrate Gen output deeply.
    // Gen output is valid at cycle T.
    // Range is valid at cycle T (fetched based on idx).
    
    wire [63:0] cur_r_start = ranges[range_idx][63:0];
    wire [63:0] cur_r_end   = ranges[range_idx][127:64];

    // Combinatorial Check
    wire is_past   = gen_valid && (range_idx < RANGE_COUNT) && (gen_val > cur_r_end);
    wire is_before = gen_valid && (range_idx < RANGE_COUNT) && (gen_val < cur_r_start);
    wire is_match  = gen_valid && (range_idx < RANGE_COUNT) && (!is_past && !is_before);
    
    // Stall Logic
    // If "is_past", we need to increment range_idx. 
    // The current gen_val MUST be preserved (stalled) so we can check it against NEW range.
    always @(*) begin
        stall_gen = is_past; 
    end
    
    // Accumulator Logic (Pipelined Adder?)
    // 250 MHz: 64-bit add might be slow.
    // Let's register the add. "if match, add".
    
    reg [63:0] add_val;
    reg        add_en;
    
    always @(posedge clk) begin
        if (rst) begin
            range_idx <= 0;
            add_val <= 0;
            add_en <= 0;
            done <= 0;
        end else begin
            add_en <= 0;
            
            if (!done) begin
                // Update Range Index
                if (is_past) begin
                    range_idx <= range_idx + 1;
                end
                
                // Processing
                if (is_match) begin
                    add_val <= gen_val;
                    add_en <= 1;
                end
                
                // Global Done Logic
                if ((gen_done || range_idx >= RANGE_COUNT) && !stall_gen) begin
                    // Wait for pipeline to drain? 1 cycle for adder.
                    done <= 1;
                end
            end
        end
    end
    
    // Final Adder Stage
    always @(posedge clk) begin
        if (rst) begin
            total_sum <= 0;
        end else if (add_en) begin
            total_sum <= total_sum + add_val;
        end
    end

endmodule
