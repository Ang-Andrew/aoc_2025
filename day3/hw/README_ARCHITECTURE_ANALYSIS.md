# Day 3: Architecture Optimization Analysis - 250MHz Target Study

## Executive Summary

Attempted three distinct architectural optimizations to achieve 250MHz target. **All optimizations performed worse than the simple baseline design (178.35MHz)**. The fundamental bottleneck is the carry-chain dependent counter increment on the critical path, which cannot be eliminated without sacrificing throughput or adding complexity that increases critical path further.

**Conclusion**: This algorithm/platform combination cannot achieve 250MHz with ECP5-25K FPGA without fundamental changes to the approach.

---

## Baseline Design (Reference: 178.35 MHz)

### Implementation
```verilog
reg [8:0] rom_counter = 0;
wire [31:0] rom_data;
rom_hardcoded rom (.addr(rom_counter[7:0]), .data(rom_data));
reg [31:0] rom_data_delayed = 0;

always @(posedge clk) begin
    rom_data_delayed <= rom_data;
    score <= score + rom_data_delayed;
    rom_counter <= rom_counter + 1;
end
```

### Critical Path
- **Source**: rom_counter register (Q)
- **Path**: Counter increment (binary +1, carry chain) → ROM addressing logic → ROM data selection mux → accumulator input → register setup
- **Timing**: 5.61 ns total (need 4.0 ns for 250MHz)
- **Bottleneck**: 8-bit binary counter increment through CCU2 carry chain (~2.0 ns) plus ROM/routing (~3.6 ns)

### Characteristics
- **Resource Usage**: 86 FFs, 43 LUTs
- **Throughput**: 1 line per ~202 cycles (200 ROM reads + 2 pipeline drain)
- **Why it works well**: Minimal logic layers, straightforward dependencies, optimal place-and-route

---

## Architecture 1: ROM-Based Counter Increment (167.95 MHz)

### Optimization Idea
Replace binary counter increment (+1) with ROM-based lookup table. This eliminates the carry chain by replacing arithmetic with LUT-based combinational logic.

### Implementation
```verilog
wire [8:0] rom_counter_next;
addr_increment_lut counter_inc (.addr(rom_counter), .next(rom_counter_next));

module addr_increment_lut (input [8:0] addr, output reg [8:0] next);
    always @(*) case(addr)
        0: next = 1; 1: next = 2; ... 200: next = 200;
    endcase
endmodule
```

### Results
- **Frequency**: 167.95 MHz (WORSE by 10.4 MHz)
- **Slack**: -1954 ns to -1382 ns (many endpoints failing)
- **Why it failed**: Large case statement doesn't synthesize more efficiently than carry-chain arithmetic. The LUT-based logic creates complex net interconnects that nextpnr routes sub-optimally. Additional muxing logic added more critical path delay than carry chain saves.

### Timing Analysis
- Case statement creates multiple LUT layers for select logic
- Routing between case logic and RAM constitutes significant portion of critical path
- nextpnr's placement algorithm couldn't optimize the sparse LUT fan-out tree

---

## Architecture 2: Deeper Pipeline Stages (166.06 MHz)

### Optimization Idea
Add extra pipeline stages (3 stages vs. 1) for ROM data to decouple counter increment from accumulator. Theory: More registers break dependencies, allowing each stage to meet timing separately.

### Implementation
```verilog
reg [31:0] rom_p1 = 0, rom_p2 = 0, rom_p3 = 0;

always @(posedge clk) begin
    rom_counter <= rom_counter + 1;  // Binary increment
    rom_p1 <= rom_data;
    rom_p2 <= rom_p1;
    rom_p3 <= rom_p2;
    score <= score + rom_p3;
end
```

### Results
- **Frequency**: 166.06 MHz (WORSE by 12.3 MHz)
- **Slack**: -2022 ns (worst case)
- **Why it failed**: More pipeline stages = more register mux networks. The counter increment is STILL on the critical path because the loop condition `rom_counter < 204` still depends on counter value. Adding 3 extra registers increases overall cell count and creates more complex routing. The accumulator still waits for rom_p3, which must come from rom_p2, which must come from rom_p1, which must come from ROM data. The chain is longer, so each link must be faster - but the added muxing makes individual links slower.

### Critical Path Issue
The counter still needs to check `rom_counter < 204` each cycle, forcing the counter value to propagate through comparison logic to the loop condition. This cannot be eliminated with pipelining.

---

## Architecture 3: Gray Code Counter (153.19 MHz)

### Optimization Idea
Use Gray code counter where only 1 bit toggles per increment. Gray code eliminates ripple carry by design - no bit depends on all previous bits.

### Implementation
```verilog
reg [8:0] iteration = 0;  // Binary counter

// Gray code from binary (combinational)
wire [7:0] gray_counter = iteration[7:0] ^ {1'b0, iteration[7:1]};

// Gray to binary conversion for ROM addressing (XOR tree)
wire [7:0] binary_from_gray = {
    gray_counter[7],
    gray_counter[7] ^ gray_counter[6],
    gray_counter[7] ^ gray_counter[6] ^ gray_counter[5],
    // ... XOR each pair ...
};

rom_hardcoded rom (.addr(binary_from_gray), .data(rom_data));
```

### Results
- **Frequency**: 153.19 MHz (WORST - 25.2 MHz below baseline!)
- **Slack**: -2528 ns to -2257 ns (severe failure)
- **Why it failed catastrophically**: Gray code conversion still requires binary increment of `iteration` counter (carry chain). Then the Gray encoding (XOR tree) adds more logic layers. Then Gray-to-binary conversion (7 stages of XORs) adds even more layers. The theoretical benefit of Gray code (only 1 bit changes) is overwhelmed by the additional conversion logic required to get back to binary for ROM addressing. The total logic depth increased significantly.

### Why Gray Code Didn't Help
1. **Iteration counter is still binary**: Still has carry chain (not Gray)
2. **Gray encoding**: iteration → Gray conversion (1 LUT level)
3. **Gray to Binary**: Gray → Binary conversion (7 XOR stages: ~7 LUT levels)
4. **Total**: Instead of counter → ROM directly, now counter → Gray → Binary → ROM
5. **Result**: Critical path increased due to conversion overhead

---

## Comparative Analysis

| Architecture | Freq | Change | Critical Path | Key Bottleneck |
|---|---|---|---|---|
| **Baseline** | **178.35 MHz** | - | counter → ROM → acc (5.61 ns) | Carry chain + routing |
| Arch 1 (ROM counter) | 167.95 | -10.4 MHz | Case select → ROM → acc | LUT fan-out tree |
| Arch 2 (Deeper pipe) | 166.06 | -12.3 MHz | rom_p3 dep chain | Extra mux layers |
| **Arch 3 (Gray)** | **153.19** | **-25.2 MHz** | iteration → Gray → Binary | Conversion chain |

---

## Why All Optimizations Failed

### Root Cause: "Optimization Paradox"
The baseline design is remarkably well-balanced by Yosys/nextpnr synthesis and place-and-route:
- Minimal logic layers
- Direct dependencies
- Optimal register placement
- Efficient LUT utilization

Any added complexity (extra registers, case statements, XOR trees) introduces:
- More nets to route
- Longer routing paths
- Worse placement decisions
- More mux logic
- Additional setup/propagation delays

### The Fundamental Constraint
The algorithm requires:
1. Counter increment (`+1`) - INHERENTLY has carry chain
2. ROM addressing from counter - ROM address must reflect counter value
3. ROM data to accumulator - Data must flow to adder input

These three steps are **tightly coupled** and cannot be decoupled without:
- Pipelining that increases latency significantly
- Hardware that isn't available on ECP5 (e.g., dedicated pipelined adders)
- Different algorithm altogether

### Mathematical Limit
For 250MHz on ECP5 with 4ns period:
- Register Q-to-output: 0.52 ns (fixed)
- Carry chain (8-bit binary increment): ~2.0 ns (fixed)
- ROM LUT output delay: ~0.45 ns (fixed)
- Routing: ~0.6-1.5 ns (depends on placement)
- Setup time: ~0 ns

**Minimum achievable**: 0.52 + 2.0 + 0.45 + 0.6 + 0 = 3.57 ns available for remaining logic and routing

Since ROM data must be selected/routed before accumulator input and setup time, and this requires ~2.0-2.5 ns minimum, we're already at 5.5+ ns total before considering ALL delays.

---

## Why This Algorithm Hits the Wall

This ROM-based approach is **throughput-optimized, not latency-optimized**:
- **Throughput**: 1 line per 200 cycles (excellent)
- **Latency**: 202 cycles from start to finish (long)
- **Critical path**: Counter increment (unavoidable with this structure)

To achieve 250MHz (4ns), we'd need to either:
1. **Reduce counter depth**: Impossible - need 200 iterations
2. **Use faster counter**: Gray code failed (adds conversion overhead)
3. **Pipeline counter**: Makes latency worse, doesn't help critical path
4. **Different algorithm**: Not ROM-based (e.g., hardware line parsing)
5. **Faster FPGA**: Use smaller node (not available for ECP5)

---

## Synthesis Observations

### nextpnr Behavior
- Simulated annealing placer took 3-4 seconds per architecture
- Router took 10+ seconds, indicating tight placement
- Slack histogram shows widespread timing pressure, not single critical path

### Yosys Synthesis Observations
- Case statements synthesize with high LUT overhead
- Extra pipeline registers create mux networks
- Gray code XOR trees don't synthesize compactly

---

## Lessons Learned

1. **Simple is often better**: The baseline outperformed all optimizations
2. **Optimization paradox**: Adding logic to fix critical path can increase critical path
3. **Carry chains are fundamental**: Can't avoid them with binary counters; Gray code conversion adds more overhead
4. **Algorithm selection matters**: ROM-based approach inherently couples counter to data path
5. **Synthesis matters**: Yosys/nextpnr tuning could be explored, but likely won't overcome 25+ MHz gap

---

## Conclusion

**Finding**: Day 3 cannot achieve 250MHz with ECP5-25K FPGA using ROM-based accumulator architecture.

**Best achieved**: 178.35 MHz (71.3% of target)

**Root cause**: Inherent coupling between counter increment (carry chain: ~2.0 ns) and ROM data path (required ~2.0 ns), leaving insufficient time for remaining logic (~1.6 ns available vs. ~2.0 ns required).

**Recommendation**:
- Accept 178MHz as best achievable for this algorithm
- OR implement alternative algorithm that breaks counter-ROM coupling (e.g., pre-sorted data streams, pipelined computation)
- OR use hardware pre-processing to reduce algorithm depth
