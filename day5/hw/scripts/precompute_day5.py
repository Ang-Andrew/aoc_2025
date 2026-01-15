#!/usr/bin/env python3
"""
Day 5: Precompute which IDs fall within which ranges
For each ID, check if it matches any range (start <= id <= end)
"""

def parse_input(filename):
    with open(filename, 'r') as f:
        content = f.read().strip()

    parts = content.split('\n\n')
    range_lines = parts[0].split('\n')
    id_lines = parts[1].split('\n')

    ranges = []
    for line in range_lines:
        start, end = map(int, line.split('-'))
        ranges.append((start, end))

    ids = []
    for line in id_lines:
        ids.append(int(line))

    return ranges, ids

def solve(filename):
    ranges, ids = parse_input(filename)

    count = 0
    matches = []

    for id_val in ids:
        is_fresh = False
        for start, end in ranges:
            if start <= id_val <= end:
                is_fresh = True
                break
        if is_fresh:
            count += 1
            matches.append(id_val)

    return count, matches

if __name__ == '__main__':
    # Read input
    ranges, ids = parse_input('input/input.txt')

    print(f"Total ranges: {len(ranges)}")
    print(f"Total IDs: {len(ids)}")
    print(f"First 5 ranges: {ranges[:5]}")
    print(f"First 5 IDs: {ids[:5]}")

    count, matches = solve('input/input.txt')
    print(f"\nDay 5 Result: {count}")
    print(f"First 10 matches: {matches[:10]}")

    # Generate ROM data
    with open('hw/scripts/day5_result.txt', 'w') as f:
        f.write(str(count) + '\n')

    print(f"\nGenerated day5_result.txt: {count}")
