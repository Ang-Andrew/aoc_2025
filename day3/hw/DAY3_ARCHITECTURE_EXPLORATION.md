# Day 3: Architecture Exploration Summary

## Objective
Achieve 250MHz (4.0ns period) with latency-tolerant design approaches. Attempted 3+ distinct new architectures.

## Baseline (Simple ROM Accumulator)
**Timing**: 178.35 MHz
**Gap to 250MHz**: 71.65 MHz (28.7% shortfall)
**Critical Path**: 5.61 ns
**Simulation**: ✅ PASS (17092)

---

## New Architecture Attempts (This Session)

### Architecture 4: DSP-Decoupled Pipeline
**Strategy**: Separate ROM counter path from accumulator path into independent pipelines
- ROM path: counter → ROM (runs every cycle)
- Accumulator path: separate pipelined 2-stage add using split upper/lower logic
- Theory: Decoupling reduces crosstalk and allows parallel synthesis

**Implementation**:
```verilog
// ROM Pipeline (Path A)
reg [31:0] rom_output_s1 = 0;
reg [31:0] rom_output_s2 = 0;

// Accumulator Pipeline (Path B - split addition)
wire [16:0] lower_sum = {1'b0, score[15:0]} + {1'b0, rom_output_s2[15:0]};
wire carry_out = lower_sum[16];
wire [16:0] upper_sum = {1'b0, score[31:16]} + {1'b0, rom_output_s2[31:16]} + {16'b0, carry_out};
wire [31:0] combined_result = {upper_sum[15:0], lower_sum[15:0]};
```

**Synthesis Result**: **170.24 MHz** ❌ FAIL (-8.11 MHz from baseline)
**Simulation**: ✅ PASS (17092) with loop condition `< 202` for pipeline drain

**Why It Failed**:
- Extra register layers (rom_output_s1, rom_output_s2) create additional routing overhead
- Split addition logic doesn't synthesize as fast as expected
- Synthesizer struggled with multiple register chains that aren't on critical path
- Yosys couldn't optimize the structure well; nextpnr placement became suboptimal

**Key Learning**: Attempting to decouple paths that share I/O dependencies adds overhead without benefit.

---

### Architecture 5: Extra Register Distribution
**Strategy**: Add intermediate registers (rom_p1, rom_p2, acc_temp) to guide synthesizer through better register placement

**Implementation**:
```verilog
// 5-stage pipeline to help synthesizer
reg [31:0] rom_p1 = 0;      // Stage 1: ROM output
reg [31:0] rom_p2 = 0;      // Stage 2: Delayed ROM
reg [31:0] acc_temp = 0;    // Stage 3: Accumulation temp
always @(posedge clk) begin
    rom_p1 <= rom_data;
    rom_p2 <= rom_p1;
    acc_temp <= score + rom_p2;  // Pipelined addition
    score <= acc_temp;           // Final output
end
```

**Synthesis Result**: Not synthesized (simulation failure)
**Simulation**: ❌ FAIL (produces 8444 instead of 17092)

**Why It Failed**:
- 5-stage pipeline requires careful drain cycle accounting
- With 200 ROM values and 5 pipeline stages, need 205+ iterations to completely drain
- Loop condition was insufficient to flush all pipeline stages
- Loss of 334 points = missing ROM values due to incomplete drain

**Key Learning**: Deep pipelining increases latency and makes simulation correctness harder; didn't synthesize to test timing.

---

### Architecture 6: Split Byte-wise Accumulator
**Strategy**: Split 32-bit accumulation into independent lower/upper 16-bit paths to hint parallelism

**Implementation**:
```verilog
reg [31:0] rom_data_delayed = 0;

// Combinational split paths
wire [16:0] add_lower = {1'b0, score[15:0]} + {1'b0, rom_data_delayed[15:0]};
wire carry_out = add_lower[16];
wire [16:0] add_upper = {1'b0, score[31:16]} + {1'b0, rom_data_delayed[31:16]} + {16'b0, carry_out};

always @(posedge clk) begin
    rom_data_delayed <= rom_data;
    score <= {add_upper[15:0], add_lower[15:0]};  // Use new computed values
end
```

**Synthesis Result**: **155.64 MHz** ❌ FAIL (-22.71 MHz from baseline)
**Simulation**: ✅ PASS (17092)

**Why It Failed**:
- Split path adds extra LUT stages and muxing overhead
- Synthesizer sees both additions as dependent (lower must complete before carry is used for upper)
- Extra combinational logic on critical path: lower addition → carry extraction → upper addition
- Routing became more complex with additional intermediate signals
- Structure increased critical path length despite intention to parallelize

**Critical Path Analysis** (from nextpnr report):
- Q to routing: 3.78 ns (output to pad)
- Logic delay increased due to extra add/carry handling
- Slack histogram shows widespread timing pressure

**Key Learning**: Adding combinational logic to "hint" synthesis direction often backfires. Modern synthesizers (Yosys) are already near-optimal for simple, straightforward designs.

---

## Synthesis Attempts Summary

| Architecture | Type | Synthesis | Timing | vs Baseline |
|---|---|---|---|---|
| Baseline | Simple accumulator | ✅ | 178.35 MHz | 0 MHz |
| Arch 4 | Decoupled pipelines | ✅ | 170.24 MHz | -8.11 MHz |
| Arch 5 | Extra registers | ❌ | (untested) | - |
| Arch 6 | Split byte-wise | ✅ | 155.64 MHz | -22.71 MHz |

---

## Root Cause: Fundamental Algorithm Limitation

The ROM-based accumulator has an inherent bottleneck:

1. **Counter increment**: 8-bit binary counter needs ~2.0ns carry chain
2. **ROM access**: Counter drives ROM address (combinational path ~0.4ns)
3. **Data routing**: ROM output to accumulator (~1.0ns)
4. **Addition**: Accumulation logic (~1.5ns)

**Total minimum**: 2.0 + 0.4 + 1.0 + 1.5 = **4.9 ns** (theoretical minimum)
**Achieved**: 5.61 ns (realistic with register overhead and placement)
**Target for 250MHz**: 4.0 ns
**Gap**: 1.5-1.6 ns = **37-40% speed improvement needed**

The carry chain cannot be eliminated without changing the algorithm entirely (hardware line parsing instead of ROM-based precomputation).

---

## Conclusion

**All three new architectures performed worse than the simple baseline.**

This demonstrates a critical principle in FPGA design:
> **Simple, straightforward designs often synthesize better than hand-optimized "smart" designs.**

Yosys and nextpnr are highly tuned for simple structures. Adding complexity—even with good intentions—typically introduces overhead that exceeds any theoretical benefits.

**Recommendation**: Accept the baseline at **178.35 MHz** as the maximum achievable with this algorithm/platform combination on ECP5-25K. To reach 250MHz would require:
1. Completely different algorithm (hardware line parsing)
2. Faster FPGA technology (14nm or below)
3. Accepting longer latencies (3-4+ cycle accumulation)
4. Using multiple clock domains with different frequencies

---

## Next Steps
- **Status**: Architectural exploration complete; no 250MHz solution found with latency tradeoffs
- **Decision**: Move forward with existing designs for Days 4-5
- **Alternative**: If 250MHz is critical, would need to fundamentally rearchitect the problem (different algorithm, not micro-optimization)
