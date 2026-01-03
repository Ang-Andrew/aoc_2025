# Day 11 Architecture: Reactor

## Problem Analysis
- Input: Directed Graph (likely DAG).
- Task: Count all distinct paths from `you` to `out`.
- Algorithm: Depth First Search (DFS) with Memoization (Dynamic Programming).
- `Paths(u) = Sum(Paths(v)) for v in children(u)`.

## Architecture: Topological Sort + Sweep (or Pipeline)
- Hardware DFS/Recursion is hard without a stack.
- DP approach is better if we visit nodes in reverse topological order.
- **Topological Sort**:
    - Pre-processing step (can be done in Python hex gen).
    - Sort nodes such that if `u -> v`, `u` appears before `v` (or after, depending on processing direction).
    - If we stream nodes in Reverse Topological Order (Out -> In), we can calculate `Paths(u)` immediately as `Sum(Paths(v))`.
    - This requires logic O(N).
- Hardware Strategy A: Reverse Topo Stream
    1. Python pre-sorts nodes: `out` first, then headers... up to `you`.
    2. Input line format: `[NodeID] [Count_Outputs] [Out1_ID] [Out2_ID] ...`
    3. Hardware stores `Counts[NodeID]` in RAM.
    4. Initialize `Counts['out'] = 1`. Other Counts = 0.
    5. Stream nodes (Reverse Topo):
        - For node `u`, read `Counts[v]` for all its children.
        - `Counts[u] = Sum(Counts[v])`.
        - Store `Counts[u]`.
    6. Finally, read `Counts['you']`.

## Implementation Details
- `input.hex`:
    - List of nodes.
    - Node IDs mapped to 0..N-1.
    - 'out' is mapped to 0? 'you' to 1?
    - List MUST be in Reverse Topological Order.
    - Line format: `[NumChildren] [Child1_Addr] [Child2_Addr] ...`
    - Stored in memory.
- `solution.v`:
    - RAM `Counts`.
    - FSM iterates through input stream.
    - Accumulates sum.
    - Writes to `Counts`.
- Synthesizability:
    - Standard RAM and Adder.
    - Pre-computed schedule (Topo Sort) simplifies HW controls significantly.

## Handling String IDs
- Python script will map strings to integers `0..N-1`.
- `out` = 0.
- `you` = N-1 (or distinct).
