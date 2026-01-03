# Advent of Code 2025 - FPGA Architectures

## Summary
This project implements hardware-accelerated solutions for AoC 2025.
Each day is analyzed for potential parallelism and data flow strategies, then implemented in synthesizable Verilog.

## Day 6: Trash Compactor
**Problem**: Column-oriented summation of numbers in a grid with variable horizontal spacing.
**Architecture**: BRAM Full-Grid Storage.
**Strategy**:
- **Phase 1**: Load grid and compute `ColumnMask` (detects value vs space columns).
- **Phase 2**: State machine uses mask to identify `Regions`.
- **Phase 3**: Within each region, parse rows into numbers/operators and accumulate.
**Status**: Implemented & Verified (Example).

## Day 7: Laboratories
**Problem**: Simulation of splitting beams moving downward on a grid.
**Architecture**: Row-Streaming Cellular Automaton.
**Strategy**:
- **Data Flow**: Process grid row-by-row.
- **State**: Line Buffer of `ActiveBeams`.
- **Logic**: For each row, compute `NextActive` based on `CurrentActive` and Splitter logic (`x-1`, `x+1`).
- **Performance**: O(N) single-pass streaming. O(W) memory.
**Status**: Implemented & Verified (Example).

## Future Work
- **Day 8**: Pending Description/Input.
