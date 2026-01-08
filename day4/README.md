# Day 4: Printing Department - FPGA Architecture Report

## 1. Problem Analysis
The goal is to count cells containing `@` that have strictly fewer than 4 neighbors (also `@`) in a 3x3 grid neighborhood (Moore neighborhood).
Input is a 2D grid.

### Key Characteristics
*   **Local Operation**: The decision for cell `(r,c)` depends only on the 3x3 window centered at `(r,c)`.
*   **Streaming Input**: Characters arrive serially.
*   **Buffer Requirement**: To compute for row `r`, we need data from rows `r-1`, `r`, `r+1`. This requires buffering 2 full lines.

## 2. Architecture: Sliding Window Pipeline

### Data Flow
1.  **Input Stream**: Characters come in 1 per clock.
2.  **Line Buffers**: Implemented as a BRAM/RAM circular buffer logic.
    *   Writes current char.
    *   Reads `r-1` (Addr - Width).
    *   Reads `r-2` (Addr - 2*Width).
3.  **Window Registers**: `win[3][3]` array acting as a 3x3 shift register.
    *   Shifts left every valid cycle.
    *   Loads new column from Input, L1 Read, L2 Read.
4.  **Logic Core**:
    *   Center Check: `win[1][1] == '@'`.
    *   Neighbor Sum: Sum of 8 surrounding bits, with Edge Masking.
    *   Threshold: If Sum < 4, increment `accessible_count`.

## 3. Implementation Details
*   **Dynamic Width**: The design detects line width from the first newline character.
*   **Edge Handling**: 
    *   **Padding**: Input rows are padded with `.` in the hex file to allow full flushing.
    *   **Masking**: Left and Right edge columns are masked to prevent wrapping artifacts from the circular line buffer.
*   **Resource Utilization**:
    *   **Registers**: ~100 (Window + Counters).
    *   **BRAM**: 1 block (4096 depth) for Line Buffering.
    *   **Logic**: Minimal LUTs for adders and comparators.

## 4. Results
- **Python Ground Truth**: 1424
- **FPGA Simulation**: 1424
- **Match**: 100%

The sliding window architecture effectively solves the 2D cellular automata problem in a single pass with O(1) memory relative to total grid size (O(W) relative to width).

## 5. Verdict
Success! The sliding window pipeline processes the entire grid in O(N) cycles (1 char per cycle).
**Cycle Count**: 209,790 Cycles (approx 1 char/cycle + flush overhead).

## 5. Visualization
To inspect the physical resource allocation on the ECP5 optimization, the build flow now generates visual maps of the utilization:
*   `ao4_day4_placed.svg`: Shows the physical placement of Look-Up Tables (LUTs) and Flip-Flops (FFs) on the die.
*   `ao4_day4_routed.svg`: Shows the detailed routing interconnects.

These images are generated automatically during the bitstream creation via the `make` command.
