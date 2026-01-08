# Day 5: Range Validator

## Problem Analysis
- **Goal**: Count the number of Input IDs that fall within any of the defined Valid Ranges.
- **Input**:
    - `ids.hex`: ~1000 IDs (64-bit integers).
    - `ranges.hex`: 174 Ranges (Start, End pairs).
- **Complexity**: O(N * M) where N is IDs and M is Ranges.

## Architecture: Sequential Range Scanner
Given the constraints and input size, a straightforward sequential scanner was selected.
- **Concept**: For each ID, iterate through the list of Ranges until a match is found or all ranges are checked.
- **State Machine**:
    1.  **FETCH_ID**: Load the next ID from memory.
    2.  **CHECK_RANGES**: Iterate through the Range Memory.
        - If `Range.Start <= ID <= Range.End`: Increment Count, Break (Next ID).
        - If End of Ranges reached: Break (Next ID).
    3.  **DONE**: Signal completion.

## Implementation Details
- **Memories**:
    - `ids`: ROM initialized from `ids.hex`.
    - `ranges_flat`: ROM initialized from `ranges.hex` (Interleaved Start/End).
- **Logic**: 64-bit Comparators.
- **Synthesizability**: Pure logic and Block RAM. No complex arithmetic or DSP required.

## Hardware Simulation Results
Simulation using Icarus Verilog Testbench (`sim/tb.v`).

- **Cycle Count**: Approx 110,102 cycles.
- **Result**: 726 (Matches Python Ground Truth).
