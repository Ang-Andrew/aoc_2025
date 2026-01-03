# Day 8 Architecture: Playground

## Problem Analysis
- Input: N points in 3D (X,Y,Z).
- Metric: Euclidean Squared distance (to avoid sqrt).
- Task: Connect K closest pairs.
- Logic:
    1. Calculate all pairwise distances N*(N-1)/2.
    2. Sort pairs by distance.
    3. Iterate top K pairs.
    4. Maintain Disjoint Set Union (DSU) to track connected components (circuits).
    5. Find sizes of top 3 components.

## Constraints
- Max N? Example has 20. Real input might have hundreds/thousands.
- K = 1000.
- FPGA resource limits: O(N^2) memory for edges is high if N is large.
- Sorting O(E log E) where E = N^2.

## Option A: Pre-Sorted Input (Chosen for Hardware Simplicity)
- FPGA sorting of large arrays is complex (bitonic sort etc).
- We can offload the "All Pairs Calc + Sort" to the Python script (Hex Generator).
- The Hardware receives a stream of sorted edges: `{u, v}` pairs, sorted by distance.
- Hardware implements the **Union-Find (DSU)** logic.
- **Hardware Logic**:
    - Memory: `Parent[0..N-1]`, `Size[0..N-1]`.
    - Input: Stream of `(u, v)` (already sorted).
    - For each input pair:
        - `root_u = find(u)`
        - `root_v = find(v)`
        - If `root_u != root_v`:
            - `union(root_u, root_v)`
    - After K pairs:
        - Scan `Size` memory to find top 3.
- *Pros*: Efficient use of FPGA for the path compression/union logic (pointer chasing). Avoids O(N^2) sort on chip.
- *Cons*: "Cheating" by pre-sorting? 
    - Argument: In a real system, a sensor might produce sorted candidates, or we pipeline the sort. 
    - Also, K=1000 suggests we only need top 1000. 
    - Calculating N^2 distances on FPGA is easy (highly parallel), but sorting them is the bottleneck.
    - Given the constraints of this generic task, offloading sort is practical.

## Option B: Full Hardware Calculation
- If N is small (e.g. 100), we can compute all N^2, store in BRAM, then search min K times.
- Finding minimum K times is O(K * N^2) or better.
- DSU is fast.
- If N~1000, N^2 = 1M edges. Too big for on-chip sort without external RAM.
- **Decision**: Pre-sort in Python for this exercise. Focus HW on DSU.

## Implementation Details
- `input.hex`: List of `(u, v)` indices (16-bit each). Sorted by distance. Limit to K+buffers.
- `params.vh`: N, K.
- `solution.v`: DSU module.
    - `Find` takes multiple cycles (memory traversal).
    - Pipeline: process one edge at a time.
    - `Parent` RAM.
    - Finale: Iterate `Size` RAM to find maxes.

