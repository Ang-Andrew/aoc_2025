# Day 3: Lobby - FPGA Architecture Report

## 1. Problem Analysis
The goal is to find the maximum possible 2-digit number formed by any two digits in a sequence, respecting their original order ($d_i, d_j$ where $i < j$).
The total answer is the sum of these maximums across all banks (lines).

### Mathematical Simplification
For a sequence $S$, we want to maximize $S[i] \times 10 + S[j]$ subject to $i < j$.
Since digits are $0-9$, the value is determined heavily by the first digit $S[i]$.
If we iterate through the sequence, maintaining the **maximum digit seen so far** ($M_i = \max(S[0]...S[i-1])$), then for any current digit $S[k]$, the best pair ending at $k$ is formed with $M_k$.
The value is $V_k = M_k \times 10 + S[k]$.
We simply track the global maximum of $V_k$ for the entire sequence.

This allows for an **O(N) single-pass streaming** algorithm.

## 2. Architecture Exploration

### Option A: Buffered Search
*   Store the entire line in a register array.
*   Double loop search (i, j).
*   **Pros**: Easy to debug.
*   **Cons**: Requires knowing max line length. High resource usage (regs). Slow (O(N^2) cycles).

### Option B: Reverse Search
*   Store line. Scan backwards finding max digit, then etc.
*   **Cons**: Still requires buffering.

### Option C: Streaming Solver (Selected)
*   Process one character per clock cycle.
*   State Registers:
    *   `max_seen` (4 bits): Maximum digit encountered in current line.
    *   `current_max` (7 bits): Maximum score calculated for current line.
*   Datapath:
    *   `candidate_score = (max_seen * 10) + current_digit`
    *   `current_max <= max(current_max, candidate_score)`
    *   `max_seen <= max(max_seen, current_digit)`
*   Update Accumulator at End of Line.

## 3. Implementation Details (Lattice ECP5)
*   **Frequency Target**: 250 MHz.
*   **Logic**:
    *   Comparison is simple LUT logic.
    *   x10 multiplication: `(x << 3) + (x << 1)`. No DSP needed.
    *   Accumulator: 32-bit adder for total score.

## 4. Results
*   **Python Ground Truth**: 17092
*   **FPGA Simulation**: 17092
*   **Status**: SUCCESS

The Streaming Solver architecture successfully processes the input at 1 character per clock cycle with minimal resource usage and no line buffering required.

## 5. Resource Utilization (Actual from Implementation)
The design was synthesized and implemented for Lattice ECP5 (LFE5U-25F).

| Resource Type | Count | Description |
| :--- | :--- | :--- |
| **Registers (TRELLIS_FF)** | **65** | Logic states + Accumulators |
| **LUTs (TRELLIS_COMB)** | **227** | Logic + Arith + Route-thru |
| **Block RAM (DP16KD)** | **7** | Used for Input ROM (20kB input file) |
| **DSP Slices (MULT18X18D)** | **0** | No DSPs used |
| **Fmax** | **64.5 MHz** | Timing constraint (250 MHz) not met due to single-cycle accumulator path |

*Note: The BRAM usage is due to embedding the Puzzle Input as a ROM for standalone operation. The core logic itself uses 0 BRAM.*
