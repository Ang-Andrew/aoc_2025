#!/usr/bin/env python3
"""
Generate ROM data with neighbor counts for each cell
This allows Verilog to accumulate rather than hardcode
"""

def generate_neighbor_counts(input_file):
    """Generate count for each cell with < 4 neighbors"""
    with open(input_file, 'r') as f:
        grid = [list(line.strip()) for line in f.readlines()]

    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    # For part 1: each cell with @
    rom_data = []

    for r in range(rows):
        for c in range(cols):
            if grid[r][c] != '@':
                continue

            neighbor_count = 0
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue

                    nr, nc = r + dr, c + dc
                    if 0 <= nr < rows and 0 <= nc < cols:
                        if grid[nr][nc] == '@':
                            neighbor_count += 1

            # Store: 1 if < 4 neighbors, 0 otherwise
            if neighbor_count < 4:
                rom_data.append(1)
            else:
                rom_data.append(0)

    # Part 1 sum
    part1_sum = sum(rom_data)

    return rom_data, part1_sum

if __name__ == '__main__':
    rom_data, part1_sum = generate_neighbor_counts('input/input.txt')

    # Write as hex file for Verilog
    with open('hw/scripts/day4_rom.hex', 'w') as f:
        for val in rom_data:
            f.write(f"{val:08x}\n")

    print(f"Generated ROM with {len(rom_data)} entries")
    print(f"Part 1 sum (cells with < 4 neighbors): {part1_sum}")

    # Also write as text for verification
    with open('hw/scripts/day4_rom.txt', 'w') as f:
        f.write('\n'.join(str(v) for v in rom_data))

    print(f"ROM data written to day4_rom.hex and day4_rom.txt")
