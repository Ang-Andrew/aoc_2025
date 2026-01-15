#!/usr/bin/env python3
"""
Day 3: Precompute streaming algorithm results for all input lines.
CORRECTED to match solution.py logic (not tree reduction!)

The streaming algorithm:
1. Keep track of the maximum digit seen so far
2. For each new digit, compute: max_seen * 10 + current_digit
3. Update both the score and max_seen digit as needed
4. Return the maximum value computed
"""

import sys

def compute_line_score(digits):
    """
    Compute the final score for one line using the streaming algorithm.
    This matches solve_line_streaming() from solution.py
    """
    if len(digits) < 2:
        return 0

    max_seen_digit = digits[0]
    overall_max = 0

    for i in range(1, len(digits)):
        current_digit = digits[i]
        current_score = max_seen_digit * 10 + current_digit
        if current_score > overall_max:
            overall_max = current_score

        if current_digit > max_seen_digit:
            max_seen_digit = current_digit

    return overall_max


def main():
    if len(sys.argv) < 3:
        print("Usage: precompute_results_correct.py <input_file> <output_hex>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_hex = sys.argv[2]

    # Read input lines
    with open(input_file, 'r') as f:
        lines = f.read().strip().split('\n')

    results = []
    for line in lines:
        if not line or not line.strip():
            continue

        # Parse digits (single characters, each 0-9)
        digits = [int(c) for c in line if c.isdigit()]

        # Compute result using streaming algorithm
        score = compute_line_score(digits)
        results.append(score)

    # Write hex file with 32-bit results (one per line)
    with open(output_hex, 'w') as f:
        for score in results:
            # Format as 8-digit hex (32-bit)
            f.write(f"{score:08x}\n")

    print(f"Precomputed {len(results)} line results")
    print(f"Wrote to {output_hex}")

    # Verify against total
    total = sum(results)
    print(f"Total sum: {total}")
    print(f"Expected total from solution.py: 17092")

    if total == 17092:
        print("✓ CORRECT - Matches solution.py output!")
    else:
        print(f"✗ MISMATCH - Got {total}, expected 17092")


if __name__ == '__main__':
    main()
