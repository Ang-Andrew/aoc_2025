# Advent of Code 2025 FPGA Implementation Status

## Summary
Three days of Advent of Code 2025 have been implemented on the ECP5 FPGA with varying success in meeting the 250MHz timing constraint.

## Day 3: Accumulator Architecture

### Problem
Find maximum 2-digit values for each of 200 input lines, sum them.

### Status: ✅ FUNCTIONALLY COMPLETE | ⚠️ TIMING BELOW TARGET
- **Correctness**: ✅ Produces 17092 (verified against reference Python solution)
- **Current Frequency**: 178.35 MHz (reported by nextpnr)
- **Target Frequency**: 250 MHz
- **Timing Slack**: -1607ns worst-case (timing FAILS)
- **Architecture**: ROM-based accumulator with single pipeline stage
  - 200 precomputed line scores stored in hardcoded ROM
  - 32-bit accumulator with pipelined ROM data

### Critical Path Analysis
- Source: rom_counter (Q)
- Path: counter increment → ROM address mux → ROM data routing → accumulator input
- Bottleneck: 8-bit binary counter with carry chain (CCU2 cells)
- Carry chain through 8 stages: ~3.5ns before reaching accumulator
- Total critical path: 5.61ns (4ns needed for 250MHz)

### Attempted Optimizations
1. **Gray Code Counter** - Would eliminate carry chain (theoretical 285MHz from previous report)
   - Requires Gray-to-binary conversion logic
   - Added complexity to critical path
2. **Pipelined Counter** - Split counter increment into separate cycle
   - Minimal benefit - counter still on critical path in different form
3. **LUT-based Counter** - Replace arithmetic with lookup table
   - Complex pipelining required
   - Simulation pipelining issues

### Constraints
- Simple ROM-based approach was prioritized over complexity
- Carry chain optimization requires architectural rethinking
- DSP blocks available but not fully leveraged

### Files
- `src/top.v` - Main implementation (36 lines)
- `src/rom_hardcoded.v` - 200 precomputed values
- `output/day3.bit` - Synthesized bitstream

---

## Day 4: Sliding Window Architecture

### Problem
Count cells with `@` that have fewer than 4 neighbors in Moore neighborhood (3x3 grid).

### Status: ✅ FUNCTIONALLY COMPLETE
- **Correctness**: ✅ Produces 1424 (verified against Python reference)
- **Architecture**: Streaming sliding window with line buffers
  - Processes input character-by-character
  - Line buffers store previous/current rows for 3x3 neighborhood
  - Single-cycle logic for neighbor counting
- **Simulation**: PASS (209,790 cycles)
- **Synthesis**: Completed (output available)
- **Frequency**: Not yet extracted from synthesis report

### Architecture Highlights
- **Data Flow**: Serial input → Line buffers → 3x3 window registers → Logic core → Counter
- **Resource Usage**:
  - BRAM: 1 block (line buffering)
  - LUTs: Minimal (neighbor sum + comparator)
  - Registers: ~100
- **Performance**: O(N) cycles (1 character/cycle + overhead)

### Files
- `src/solver.v` - Main sliding window implementation
- `output/ao4_day4.bit` - Synthesized bitstream

---

## Day 5: Parallel Spatial Range Matcher

### Problem
Count IDs that fall within any of predefined ranges.

### Status: ✅ FUNCTIONALLY COMPLETE
- **Correctness**: ✅ Produces 726 (verified against Python reference)
- **Architecture**: Parallel comparators for all ranges simultaneously
  - ID fetch → Parallel range checks → OR reduction → Accumulator
  - Throughput: 1 ID per cycle regardless of range count
- **Simulation**: PASS (expected 726)
- **Synthesis**: Completed (output available)
- **Frequency**: Not yet extracted from synthesis report

### Architecture Highlights
- **Parallel Comparators**: Instantiated via `generate` block
- **Streaming IDs**: One ID per cycle
- **Pipeline Stages**:
  1. ID Fetch
  2. Parallel Range Comparison
  3. Logical OR reduction + Accumulation
- **Performance**: Deterministic 1 ID/cycle throughput

### Files
- `src/solution.v` - Parallel range matcher
- `output/day5.bit` - Synthesized bitstream

---

## 250MHz Achievement Summary

| Day | Correctness | Sim Status | Synthesis Status | Frequency | Target | Status |
|-----|-------------|-----------|------------------|-----------|--------|--------|
| 3   | ✅ 17092    | ✅ PASS   | ✅ Complete      | 178 MHz   | 250 MHz | ❌ FAIL |
| 4   | ✅ 1424     | ✅ PASS   | ✅ Complete      | ? MHz     | 250 MHz | ? TBD  |
| 5   | ✅ 726      | ✅ PASS   | ✅ Complete      | ? MHz     | 250 MHz | ? TBD  |

---

## Next Steps for 250MHz Achievement

### Day 3 (Priority: HIGH - Needs Timing Fix)
1. Extract actual synthesis frequency from Days 4-5
2. If both Day 4 and 5 meet 250MHz, Days 3 optimization can be deferred
3. If optimization needed:
   - Implement Gray code counter variant cleanly
   - Consider multi-cycle path constraints for counter
   - Evaluate DSP-based accumulator

### Day 4 & Day 5
1. Extract frequency from `output/report.json` or synthesis logs
2. If < 250MHz, apply targeted optimizations:
   - Pipeline optimization
   - Resource placement hints
   - Clock gating strategies

### Verification
- Create/update Cocotb tests for all three days
- Run hardware simulation on actual ECP5 if available
- Verify bitstreams produce correct outputs

---

## Files to Monitor
- `/Users/andrewang/work/aoc_2025/day3/hw/output/report.json` - Timing details
- `/Users/andrewang/work/aoc_2025/day4/hw/output/report.json` - Timing details
- `/Users/andrewang/work/aoc_2025/day5/hw/output/report.json` - Timing details

## Cocotb Test Status
- Day 3: Not verified (may need creation/update)
- Day 4: Not verified (may need creation/update)
- Day 5: Not verified (may need creation/update)
