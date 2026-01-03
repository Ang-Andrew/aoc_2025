# Day 9 Architecture: Movie Theater

## Problem Analysis
- Input: List of `(x, y)` coords of red tiles.
- Task: Find max Area of rectangle formed by any pair of coords.
- Area Formula: `(|x1 - x2| + 1) * (|y1 - y2| + 1)`.
- Complexity: O(N^2) for N points.

## Architecture: Parallel Systolic Array / Pipeline
- Given the O(N^2) nature, we can parallelize.
- Store points in memory: `RAM[0..N-1]`.
- **Strategy A: Nested Loop Controller**
    - One processing element (PE).
    - Loop `i` from 0 to N-1.
    - Loop `j` from `i+1` to N-1.
    - Fetch P[i], P[j].
    - Compute Area.
    - Update `MaxArea` register.
    - *Pros*: Simple FSM. Space efficient.
    - *Cons*: O(N^2) time. If N is large, slower. But N usually < 1000 for these inputs. 10^6 cycles at 100MHz = 10ms. Taggled.

- **Strategy B: Broadcast System (Selected if high perf needed)**
    - If N is small enough to fit on chip logic (e.g. N=50), we can have N comparators? No, N^2.
    - Let's stick to **Strategy A** (Sequential) for generic N scalability.
    - We can pipeline the calc: 
        1. Fetch I/J.
        2. Calc dx, dy.
        3. Calc Area.
        4. Compare Max.
        - Throughput: 1 pair per cycle.
    - Inner loop runs N times. Outer loop N times. Total N^2/2 cycles.

## Implementation Details
- `input.hex`: Packed coordinates. Assume X, Y fit in 16-bit?
    - AoC grids usually < 1000. 16-bit is safe (65535).
    - Format: `[31:16] X`, `[15:0] Y`.
- `solution.v`:
    - `reg [31:0] points [0:NUM_POINTS-1]`
    - FSM processing.

## Synthesizability
- Multiplexer for RAM read.
- 1 Multiplier (DSP).
- 1 Comparator.
- Very standard.
