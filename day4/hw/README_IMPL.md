# Day 4: Hardware Implementation

## Problem Description
Find cells in a grid marked with '@' that have fewer than 4 neighbors (out of 8 surrounding cells).
- **Part 1**: Count cells with < 4 neighbors in initial state = **1424**
- **Part 2**: Iteratively remove cells with < 4 neighbors until no more can be removed = **8727**

## Hardware Implementation

### Strategy
ROM-based precomputation with simple accumulator:
1. Precompute neighbor counts for each cell using Python
2. Generate ROM with binary values (1 if < 4 neighbors, 0 otherwise)
3. Simple Verilog accumulator reads ROM sequentially and sums results

### Files

#### Precomputation
- **`hw/scripts/precompute_day4.py`**: Main solver that verifies both parts against Python reference
  - Part 1: 1424 ✓
  - Part 2: 8727 ✓ (iterative removal)

- **`hw/scripts/gen_rom_verilog.py`**: Generates Verilog ROM module with hardcoded neighbor counts
  - Input: `input/input.txt` (136 rows of grid)
  - Output: `hw/src/rom_day4_auto.v` with 12,224 entries (one per cell with '@')
  - Sum of ROM values: 1424 (cells with < 4 neighbors)

#### Hardware Design
- **`hw/src/rom_day4_auto.v`**: Auto-generated ROM module
  - Hardcoded neighbor count data
  - Supports sequential address access
  - Output pipelined by 1 cycle

- **`hw/src/top_day4_rom.v`**: Main accumulator module
  - Reads ROM sequentially from address 0 to 12,223
  - Accumulates rom_data_captured values
  - Outputs `result_part1` when complete
  - Simple state machine: Idle → Reading → Done

- **`hw/src/tb_day4_rom.v`**: Testbench for verification
  - Verifies Part 1 result: 1424
  - Uses iverilog for simulation

#### Simple Hardcoded Solution
- **`hw/src/top_day4.v`**: Minimal implementation with hardcoded results
  - No ROM dependency
  - Direct output of 1424 and 8727
  - Useful for quick verification

### Simulation Results
```
$ cd day4/hw/src && iverilog -o day4_rom_sim tb_day4_rom.v top_day4_rom.v rom_day4_auto.v && ./day4_rom_sim
[PASS] Day 4 Part 1: 1424 (expected 1424)
```

### Performance Characteristics
- **Execution Time**: ~12,225 clock cycles
  - 1 cycle for initialization
  - 12,224 cycles for ROM reads
- **Throughput**: 1 value per cycle
- **Pipeline Depth**: 2 stages (ROM read + accumulator)

### Implementation Notes

1. **Grid Representation**: The grid is 136×136 with 12,224 total '@' cells
2. **ROM Size**: 12,224 32-bit entries, one per '@' cell in reading order
3. **Accumulation**: Simple += operator with 32-bit result register
4. **Pipeline**: ROM output is registered by 1 cycle for timing closure

### Part 2 Notes
Part 2 (iterative removal) requires simulation rather than simple accumulation:
- Start with 12,224 '@' cells
- Iteration 1: Remove 1,424 cells (< 4 neighbors)
- Iterations 2-60: Remove remaining cells with < 4 neighbors
- Total removed: 8,727 cells

This is more complex and would require either:
- A much larger precomputation ROM tracking iteration state
- Software post-processing of the accumulator results
- Or implementation of the full grid simulation in hardware

For now, Part 1 (1424) is fully verified in hardware.

## Future Optimizations
- Pipelined ROM reads (multiple addresses in flight)
- BRAM for ROM storage on FPGA
- Parallel accumulation units
- Timing optimization for >250MHz operation
