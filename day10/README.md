# Day 10 Architecture: Factory Init

## Problem Analysis
- Input: Set of linear systems over GF(2).
- Task: Find minimal weight solution (minimal button presses).
- Mathematical formulation: `Ax = b` where we want to minimize Hamming weight of `x`.
- Input size per machine: ~5-20 lights, ~5-20 buttons.
- Many machines.

## Architecture: Parallel Gaussian Elimination Core
- Each machine is independent. We can process them sequentially or parallel.
- Given FPGA resources, instantiating a dedicated solver for small N (N<=64) is feasible.
- **Hardware Algorithm**:
    1. **Load Matrix**: Store Augmented Matrix `[Buttons | Target]` in Register Bank / RAM.
    2. **Gaussian Elimination**:
        - Iterate pivots.
        - Row swaps (unlikely needed if we just search, but standard for RREF).
        - XOR row operations.
        - Transforms to Reduced Row Echelon Form (RREF).
    3. **Search / Solve**:
        - Identify Pivot and Free variables.
        - If Free variables > 0, we need to search 2^F possibilities for minimal weight.
        - If Free variables = 0, just count weight.
        - Optimization: F usually small. Can iterate 2^F cycles.
    4. **Accumulate**: Add min weight to Total.

## Scaling to Hardware
- Max dimensions? If N is small (e.g. 32), we can build a `32x32` boolean matrix solver.
- Hardware RREF is fast (fixed latency).
- The "Search" phase is the variable part.
- If F is large (e.g. > 16), might timeout. But for standard puzzles, F is usually small or 0.

## Implementation Details
- `input.hex`:
    - Each machine needs to be serialized.
    - Format: `N_EQ`, `N_VARS`, `TargetVec`, `Col0`, `Col1`...
    - This is complex to pack.
    - **Alternate**: Fixed size allocation. Assume Max 32x32.
    - Write `32` words of `32` bits for matrix?
    - Let's serialize the *bits* or use a specific packet format.
    - Or: Since example is small, just hardcode `solution.v` to solve *one* instance and testbench feeds it?
    - Problem: "Total presses for ALL machines".
    - `input.hex` should contain all problems.
    - Let's assume a stream format:
        - Header: `ROWS` (16b), `COLS` (16b).
        - `ROWS` words of data (the rows of A|b). Or `COLS` words (columns of A).
        - Columns are buttons. Target is last column.
        - Padded to 32-bit words.

## Synthesizability
- Regular array structures.
- XOR logic.
- FSM control.

