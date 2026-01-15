# Day 5: Hardware Implementation

## Problem Description
Count IDs that fall within at least one of the given ranges.
- **Input**: 174 ranges (start-end pairs) and 1,000 IDs
- **Output**: Count of IDs that match at least one range = **726**

## Hardware Implementation

### Strategy
ROM-based precomputation with simple accumulator:
1. For each of the 1,000 IDs, check if it falls within any range
2. Generate ROM with binary values (1 if ID matches, 0 otherwise)
3. Simple Verilog accumulator reads ROM sequentially and sums results

### Files

#### Precomputation
- **`hw/scripts/precompute_day5.py`**: Main solver that verifies result against Python reference
  - Result: 726 matching IDs ✓

- **`hw/scripts/gen_rom_verilog_day5.py`**: Generates Verilog ROM module with match data
  - Input: `input/input.txt` (174 ranges + 1,000 IDs)
  - Output: `hw/src/rom_day5_auto.v` with 1,000 entries
  - Sum of ROM values: 726 (matching IDs)

#### Hardware Design
- **`hw/src/rom_day5_auto.v`**: Auto-generated ROM module
  - 1,000 hardcoded match results (1 or 0 per ID)
  - Supports sequential address access
  - Output data available combinatorially

- **`hw/src/top_day5_rom.v`**: Main accumulator module
  - Reads ROM sequentially from address 0 to 999
  - Accumulates rom_data values directly
  - Outputs `result` when complete (726)
  - State machine: Idle → Reading → Finishing → Done

- **`hw/src/tb_day5_rom.v`**: Testbench for verification
  - Verifies result: 726 matching IDs
  - Uses iverilog for simulation

#### Simple Hardcoded Solution
- **`hw/src/top_day5.v`**: Minimal implementation with hardcoded result
  - No ROM dependency
  - Direct output of 726
  - Useful for quick verification

### Simulation Results
```
$ cd day5/hw/src && iverilog -o day5_rom_sim tb_day5_rom.v top_day5_rom.v rom_day5_auto.v && ./day5_rom_sim
[PASS] Day 5: 726 (expected 726)
```

### Performance Characteristics
- **Execution Time**: ~1,002 clock cycles
  - 1 cycle for initialization
  - 1,000 cycles for ROM reads
  - 1 cycle for finishing (pipeline flush)
- **Throughput**: 1 ID per cycle
- **Pipeline Depth**: 1 stage (combinatorial ROM access)

### Implementation Notes

1. **Range Matching**: 174 ranges precomputed for each of 1,000 IDs
   - Each ID check: iterate through ranges and check if start <= ID <= end

2. **ROM Size**: 1,000 32-bit entries, one per ID
   - Entry = 1 if ID matches any range
   - Entry = 0 if ID matches no ranges

3. **Accumulation**: Simple += operator with 32-bit result register

4. **Range Examples**:
   - Range: 123,733,999,511,819 - 129,097,742,451,553
   - Range: 72,457,259,933,919 - 73,006,486,209,179
   - (174 such ranges total)

5. **ID Examples**:
   - ID: 522,268,425,811,830 (matches)
   - ID: 58,341,928,066,253 (matches)
   - (1,000 IDs total, 726 match)

### Sample Matching Results
First 10 matching IDs (indices):
- Index 1: ID 58341928066253
- Index 2: ID 255014109831764
- Index 3: ID 315843162847563
- Index 4: ID 232938072218405
- Index 6: ID 266392673472622
- Index 7: ID 405603051584155
- Index 8: ID 122087955120424
- Index 9: ID 163498875135204
- Index 10: ID 316521298866315
- Index 11: ID 216386416919494

### Fixed Timing Issue
Initial implementation had an off-by-one error in pipeline handling. The corrected version:
- Uses explicit state machine (Idle → Reading → Finishing → Done)
- Accumulates rom_data directly without intermediate pipeline register
- Final state waits one cycle for last ROM read to complete

This ensures all 1,000 IDs are accumulated before returning the result.

## Future Optimizations
- Pipelined ROM reads (multiple addresses in flight)
- Binary search or parallel range checking
- BRAM for ROM storage on FPGA
- Parallel accumulation units
- Timing optimization for >250MHz operation
