# Day 7 Architecture: Tachyon Manifolds

## Problem Analysis
- Grid-based simulation.
- Start at 'S', beam moves Down.
- Empty space '.': Beam passes.
- Splitter '^': Beam stops. New beams spawn at `x-1` and `x+1` (immediate left/right).
- Logic implies `NewActive[x-1] |= 1`, `NewActive[x+1] |= 1`.

## Option A: Full Grid State (BRAM)
- Store 'Energized' bit for every cell.
- Iterate recursively or queue-based flood fill.
- *Pros*: Handles loops or complex paths easily.
- *Cons*: Needs full grid memory. Time non-deterministic (iterative flood fill).

## Option B: Row-Streaming Cellular Automaton (Selected)
- Since beams *always* move downward (or spawn side-then-down), there is no "upward" flow.
- This creates a **Topological Order**.
- We can solve the entire grid in **One Pass** row-by-row.
- **State**: `ActiveBeams` (Row Buffer, 1 bit per column).
- **Rule**:
    - For row `y` (current grid row):
    - `NextActive` initialized to 0.
    - `CurrentActive` is input.
    - For each `x`:
        - If `Active[x]`:
            - If `Grid[y][x] == '.'`: `NextActive[x] |= 1` (continue down).
            - If `Grid[y][x] == '^'`: `NextActive[x-1] |= 1`, `NextActive[x+1] |= 1` (split).
            - If `Grid[y][x] == 'S'`: (Treat as source) `NextActive[x] |= 1`.
        - Also if `Grid[y][x] == 'S'` (and it's start row), inject beam.
- *Pros*: O(1) memory (just one line buffer). O(N) time (streaming). Extremely fast and hardware efficient.
- *Cons*: Needs to handle boundary conditions (x-1, x+1).

## Implementation Details
- `LineBuffer` of size WIDTH.
- Pipeline scanning:
    - We scan row `y`.
    - We produce `NextActive` for row `y+1`.
    - We can just overwrite `Active` buffer in ping-pong or carefully ordered update?
    - Actually, since `x-1` and `x+1` interact, we need to generate the *next* row state completely before using it?
    - Yes, simple "Current Row" -> "Next Row" logic.
    - Since we process row `y` to produce `Active` for `y+1`.
    - We output the count or metric required (e.g. number of active splitters).

## Synthesizability
- Requires 2 line buffers (Current, Next) of size WIDTH bits.
- Logic is simple varying shifters.
- Very high frequency possible.
