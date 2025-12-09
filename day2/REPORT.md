# Engineering RFC: Day 2 Invalid ID Processor Architecture

## 1. Problem Definition & Constraints
**Goal**: Calculate the sum of "invalid IDs" (palindromic 2-part input patterns like `XYXY`) within arbitrary input ranges.
**Input**: ~40 ranges (e.g., `123-456`). Max ID value ~10^10 (Fit in 64-bit).
**Performance Target**: 250 MHz system clock on Lattice ECP5-25F.
**Portability Constraint**: Avoid hardware DSP (hard multipliers) to ensure portability to basic logic cells (LUT-only FPGAs).

## 2. Solution Space Exploration

### Option A: The "Software" Approach (Binary Search in Memory)
- **Concept**: Pre-generate all valid candidates (~20k integers) into a ROM/RAM. For each input range, perform a Binary Search to find start/end indices and sum the slice.
- **Micro-Architecture**:
    - Pointer logic traversing a 20k-entry BRAM.
    - Latency: $O(R \cdot \log N)$ where $R$ is ranges, $N$ is candidates. Very fast.
- **Trade-offs**:
    - **Space**: 20k * 64-bit = 1.28 Mbit. ECP5-25k has ~1 Mbit of sysMEM. **This might not fit** or would consume 100% of BRAM.
    - **Complexity**: Binary search state machine is complex (pointer arithmetic, memory latency handling).
- **Verdict**: Rejected due to high memory pressure on smaller FPGAs.

### Option B: The "Mathematician" Approach (Algebraic Calculation)
- **Concept**: A number `P` with repetition pattern `XYXY` is effectively `XY * (10^k + 1)`.
    - For a range `[A, B]`, strict bounds for base `XY` can be found: `ceil(A / (10^k+1)) <= XY <= floor(B / (10^k+1))`.
    - Sum is sum of arithmetic progression.
- **Micro-Architecture**:
    - Requires **Division** by arbitrary constants `1001`, `10001`, etc.
- **Trade-offs**:
    - **Latency**: $O(R \cdot K)$ where $K$ is number of digit-lengths (approx 10). Extremely low latency.
    - **Performance**: High-speed division (64-bit / 64-bit) is effectively impossible to close at 250 MHz without massive pipelining (30-60 cycles latency).
    - **Area**: Divisors consume huge area or DSPs.
- **Verdict**: Rejected due to timing closure risks with Division logic.

### Option C: Pipelined Streaming Generator (Selected Architecture)
- **Concept**: Generate the stream of invalid IDs monotonically using a lightweight 'next-state' logic. Stream these against sorted Input Ranges.
- **Micro-Architecture**:
    - **Generator**: Uses **Shift-Add** logic to generate `next_val`. $Val_{new} = Val_{old} + (10^k + 1)$.
    - **Solver**: Pipelined Comparator and Accumulator.
- **Trade-offs**:
    - **Latency**: $O(N)$. We must iterate ~20k-30k cycles. At 250 MHz, this is $120 \mu s$ total execution time. Negligible for the application constraints.
    - **Space**: Minimal (~500 LUTs). No BRAM for candidates needed.
    - **Portability**: Uses only Adds and Shifts. No DSPs required.
- **Verdict**: Selected for balance of low area, high clock speed, and simplicity.

## 3. Design Specification (v2.0)

### Clock Domain
- **Frequency**: 250 MHz.
- **Timing Budget**: 4 ns period.
- **Critical Path Mitigation**: 
    - 64-bit Accumulator split or heavily pipelined? Modern CLBs have fast carry chains; 64-bit add usually fits in < 3ns. We will attempt single-cycle accumulation but registers will be placed at module boundaries.

### Modules
1. **Generator (No-DSP)**
    - Replaces `x * 10` with `(x << 3) + (x << 1)`.
    - State machine setup for `10^k` calculations done via iterative adding to avoid initialization multipliers.
2. **Solver (Pipelined)**
    - **Stage 1 (Fetch)**: Get current Range from distributed RAM/Registers.
    - **Stage 2 (Compare)**: Compare Gen_ID vs Range. Generate control signals (Accumulate, Skip, Next_Range).
    - **Stage 3 (Update)**: Update Sum and Range Pointer.
