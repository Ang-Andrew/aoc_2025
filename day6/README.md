# Day 6 Architecture: Trash Compactor

## Problem Analysis
The input consists of multiple "problems" arranged horizontally, separated by empty vertical columns.
Numbers are vertical lists. Operators are at the bottom.
Key Constraint: "Problems are separated by a full column of only spaces".

## Option A: Full Grid BRAM Storage (Selected)
We store the entire ASCII grid in on-chip BRAM.
Max Dimensions check:
- standard AoC lines ~ 100-200 chars.
- standard AoC height ~ 100-200 lines.
- 200*200 = 40,000 bytes.
- ECP5-85F has 3.7Mb blocks ~ 400KB.
- This fits easily.

### Workflow
1.  **Ingest & Mask**:
    - As we initialize the ROM/RAM from `readmemh`, we logically equivalent to a load.
    - However, since we use `readmemh`, the data is pre-loaded.
    - We need a hardware pass to compute the `ColumnMask`.
    - **Compute Mask State**: Iterate `x=0..W`. For each `x`, iterate `y=0..H`. Check if any char is not space. Set `Mask[x] = 1`.
    - Optimization: We can do this on the fly or just process Regions.
2.  **Region Processing (State Machine)**:
    - Iterate `x` from 0 to `W`.
    - maintain `in_region` flag.
    - If `Mask[x]` and !`in_region`: Start of Region (`r_start = x`).
    - If !`Mask[x]` and `in_region`: End of Region (`r_end = x`). Trigger `COMPUTE`.
3.  **Compute Phase**:
    - Given `r_start`, `r_end`.
    - Iterate `y` from 0 to `H`.
    - For each row, read chars `[r_start : r_end]`.
    - Parse token:
        - Skip spaces.
        - If digits: build number. add to list.
        - If `+` or `*`: set op.
    - Perform calc: `sum` or `prod` of list.
    - Add to `GrandTotal`.

### Trade-offs
- **Pros**: 
    - No need for complex streaming buffered logic.
    - "Full column" check is trivial if we can access all pixels (or scan column-wise).
    - Fits in parsing FPGAs.
- **Cons**:
    - Latency: Needs roughly 2 passes (one for mask, one for solve).
    - BRAM usage.

## Implementation Details
- `input.hex`: raw ASCII bytes.
- `params.vh`: Width, Height.
- `solution.v`:
    - `reg [7:0] mem [0:Size-1]`
    - FSM.

## Synthesizability
- The design uses standard Block RAM inference.
- FSM is standard.
- Math is 64-bit addition/multiplication (DSP blocks).

