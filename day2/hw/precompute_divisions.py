#!/usr/bin/env python3
"""
Pre-compute division results for Day 2 FPGA implementation
Generates ROM contents with x_start and x_end for each (range, K) combination
This eliminates the need for division on the FPGA, enabling 250MHz timing
"""

import sys

def read_ranges(input_file):
    """Read ranges from input file (comma-separated ranges in format start1-end1,start2-end2,...)"""
    ranges = []
    with open(input_file, 'r') as f:
        content = f.read().strip()
        # Split by comma to get individual ranges
        range_strs = content.split(',')
        # Each range is "start-end"
        for range_str in range_strs:
            parts = range_str.split('-')
            start = int(parts[0])
            end = int(parts[1])
            ranges.append((start, end))
    return ranges

def get_x_bounds(k):
    """Get valid x bounds for a given K value"""
    x_min = 10 ** (k - 1)
    x_max = 10 ** k - 1
    return x_min, x_max

def get_const_k(k):
    """Get the constant multiplier for a given K"""
    return 10 ** k + 1

def compute_x_range(range_start, range_end, k):
    """
    Compute x_start and x_end for a given range and K value
    Returns (x_start, x_end, valid) where valid indicates if there are any x values
    """
    const_k = get_const_k(k)
    x_min, x_max = get_x_bounds(k)

    # Compute x_start = ceil(range_start / const_k)
    x_start = (range_start + const_k - 1) // const_k

    # Compute x_end = floor(range_end / const_k)
    x_end = range_end // const_k

    # Clip to valid bounds
    x_start = max(x_start, x_min)
    x_end = min(x_end, x_max)

    # Check if valid range
    valid = x_start <= x_end

    if not valid:
        x_start = 0
        x_end = 0

    return x_start, x_end, valid

def generate_rom_hex(ranges, output_file):
    """
    Generate ROM hex file with pre-computed division results
    Format: Each entry is 96 bits = x_start (40) + x_end (40) + valid (1) + padding (15)
    Stored as: x_start in [39:0], x_end in [79:40], valid in bit 80
    """
    with open(output_file, 'w') as f:
        for range_start, range_end in ranges:
            for k in range(1, 13):  # K = 1 to 12
                x_start, x_end, valid = compute_x_range(range_start, range_end, k)

                # Pack into 96-bit value (use 96 bits = 24 hex digits for alignment)
                # Bits [39:0] = x_start
                # Bits [79:40] = x_end
                # Bit 80 = valid
                # Bits [95:81] = padding

                packed = x_start | (x_end << 40) | (int(valid) << 80)

                # Write as 24 hex digits (96 bits)
                hex_str = f"{packed:024x}"
                f.write(hex_str + "\n")

    print(f"Generated ROM with {len(ranges) * 12} entries")
    print(f"ROM size: {len(ranges) * 12 * 96} bits = {len(ranges) * 12 * 96 // 8} bytes")

if __name__ == "__main__":
    input_file = "../input/input.txt"
    output_file = "src/divisions.hex"

    if len(sys.argv) > 1:
        input_file = sys.argv[1]
    if len(sys.argv) > 2:
        output_file = sys.argv[2]

    print(f"Reading ranges from: {input_file}")
    ranges = read_ranges(input_file)
    print(f"Found {len(ranges)} ranges")

    print(f"Writing ROM to: {output_file}")
    generate_rom_hex(ranges, output_file)
    print("Done!")
