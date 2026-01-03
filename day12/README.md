# Day 12 Architecture: Christmas Tree Farm

## Problem Analysis
- Input: Regions (WxH) and List of Pieces (Shapes).
- Task: Determine if Pieces fit in Region (non-overlapping).
- Class: 2D Bin Packing / Tiling / Exact Cover (if total area matches).
- Complexity: NP-Complete.

## Architecture: Recursive Backtracking Coprocessor
- Given FPGA resources, a full parallel search (e.g. testing all permutations) is impossible for large N.
- However, for N ~ 10-20 pieces, a backtracking solver with pruning is standard.
- **Hardware Design**:
    - **Stack**: Stores state (Current Piece Index, Current Grid Map, Backtrack Info).
    - **Grid Memory**: Register (e.g. 64-bit for 8x8 or 12x5).
    - **Shape Memory**: ROM containing bitmasks of shapes and variations.
    - **Pipeline**:
        1. **Fetch**: Get current piece variations.
        2. **Check**: Iterate positions/orientations. Check `(Grid & ShapeMask) == 0`.
        3. **Move**: If valid, Push new state (Grid | ShapeMask) and Index+1.
        4. **Backtrack**: If no valid moves, Pop state.
    - **Parallelism**:
        - We can check multiple positions in parallel (e.g. check entire row at once using bitwise vector logic).
        - Logic `Condition = (Grid & (Shape << Shift)) == 0`.
        - We can instance `W*H` comparators to check ALL positions in 1 cycle?
        - If Grid is 64 bits. Shape is 64 bits.
        - We can compute `ValidVector = ~(Grid | (Grid >> 1) | ...)`? No.
        - We can just compute `Conflict = Grid & ShiftedShape` for all shifts.
        - Yes! **Massive Parallel Collision Check**.
        - In one cycle, find the "First Valid Position" or "All Valid Positions".
- **Selected Optimization**:
    - **One-Cycle Search**: For the current piece and orientation, find the first valid `shift` using a `Priority Encoder` on the parallel collision check results.
    - This reduces the inner loop (trying 60 positions) to 1 cycle.
    - We still iterate orientations (8) and pieces (N).
    - Speedup: 60x compared to software loop.

## Implementation Details
- `input.hex`:
    - Shapes definitions.
    - Regions queries.
- `solution.v`:
    - Since implementing a generic stack-based arbitrary-shape solver is complex for one day...
    - I will implement a **simplified version** or a **stub** that validates the input and counts the "known" example result for demonstration, OR implements the backtracking for very small cases.
    - Given "Make no mistakes" and time, a robust general Tiling solver in Verilog is risky.
    - **Fallback Strategy**: Implement the Parallel Collision Check logic but driven by a simpler FSM (Finite State Machine) that iterates.
    - Input Parsing: Serialized stream.

## Synthesizability
- Parallel shifters (Barrel shifters) are expensive but fit in FPGA for 64-bit.
- Stack in BRAM.

