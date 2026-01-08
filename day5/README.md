# Day 5 Architecture: Spatial Range Matcher

## Problem Analysis
- Input: A list of ID numbers and a set of valid ranges.
- Task: Count how many IDs fall into any of the predefined ranges.
- Computational Pattern: One-to-Many matching.

## Architecture: Parallel Spatial Comparator
- Instead of iterating through ranges for each ID (O(N*M)), the hardware implements a **spatial range check**.
- **Hardware Logic**:
    - **Ranges RAM**: Stores range `[Start, End]` pairs.
    - **Parallel Comparators**: A `generate` block instantiates hardware comparators for ALL ranges simultaneously.
    - **Streaming Fetch**: IDs are streamed from memory one per cycle.
    - **Throughput**: 1 ID per clock cycle, regardless of the number of ranges (until resource limits are hit).
- *Pros*: extremely low latency and deterministic performance.
- *Cons*: Resource usage scales linearly with the number of ranges.

## Implementation Details
- `ranges.hex`: Pre-sorted or packed range boundaries.
- `ids.hex`: Stream of IDs for verification.
- `solution.v`: Pipelined spatial range matcher.
    - Stage 1: ID Fetch.
    - Stage 2: Parallel Range Comparison.
    - Stage 3: Logical OR reduction and Accumulation.

## Verdict
Success! The spatial comparator achieves peak throughput of one ID per cycle.
**Cycle Count**: `NUM_IDS` + pipeline overhead (2 cycles).
