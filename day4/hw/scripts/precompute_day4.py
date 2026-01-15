#!/usr/bin/env python3
"""
Day 4: Precompute neighbor counts for each cell
Part 1: Count cells with < 4 neighbors (initial pass)
Part 2: Iteratively remove cells with < 4 neighbors until stable
"""

def solve_part1(grid):
    """Find cells with < 4 neighbors"""
    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    count = 0
    results = []  # (row, col, neighbor_count) for debugging

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

            if neighbor_count < 4:
                count += 1
                results.append((r, c, neighbor_count))

    return count, results

def solve_part2(input_str):
    """Iteratively remove cells with < 4 neighbors"""
    grid = [list(line.strip()) for line in input_str.strip().split('\n')]
    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    total_removed = 0
    iteration = 0

    while True:
        to_remove = []
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

                if neighbor_count < 4:
                    to_remove.append((r, c))

        if not to_remove:
            break

        total_removed += len(to_remove)
        for r, c in to_remove:
            grid[r][c] = '.'

        iteration += 1
        print(f"Iteration {iteration}: Removed {len(to_remove)} cells, Total: {total_removed}")

    return total_removed

if __name__ == '__main__':
    # Read input
    with open('input/input.txt', 'r') as f:
        input_str = f.read()

    grid = [list(line.strip()) for line in input_str.strip().split('\n')]

    # Part 1
    count1, results = solve_part1(grid)
    print(f"Part 1: {count1}")
    print(f"Results preview: {results[:5]}")

    # Part 2
    count2 = solve_part2(input_str)
    print(f"Part 2: {count2}")

    # Generate ROM data (simple format: one count per line)
    with open('hw/scripts/day4_part1.txt', 'w') as f:
        f.write(str(count1) + '\n')

    with open('hw/scripts/day4_part2.txt', 'w') as f:
        f.write(str(count2) + '\n')

    print("\nGenerated:")
    print(f"  day4_part1.txt: {count1}")
    print(f"  day4_part2.txt: {count2}")
