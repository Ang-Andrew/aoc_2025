#!/usr/bin/env python3
"""
Day 3: Precompute CUMULATIVE results for all input lines.

Store cumulative sums in ROM:
- ROM[0] = result of line 0
- ROM[1] = result of line 0 + result of line 1
- ROM[2] = result of line 0 + result of line 1 + result of line 2
- ...
- ROM[199] = final cumulative sum

Hardware just reads ROM[199] - trivial!
Critical path: ROM read (5.83ns with register) + output FF (0.5ns) = fits easily in 4ns!
"""

import sys

def compute_line_score(digits):
    """
    Compute the final score for one line of 128 digits.
    """
    nodes = []

    # Level 0: Initialize with single digits
    for d in digits:
        if d is not None:
            nodes.append({
                'max_seen': d,
                'score': 0,
                'first_digit': d,
                'valid': True
            })
        else:
            nodes.append({
                'max_seen': 0,
                'score': 0,
                'first_digit': 0,
                'valid': False
            })

    # Tree reduction
    while len(nodes) > 1:
        new_nodes = []
        for i in range(0, len(nodes), 2):
            l = nodes[i]
            r = nodes[i + 1]

            if not l['valid'] and not r['valid']:
                new_nodes.append({
                    'max_seen': 0,
                    'score': 0,
                    'first_digit': 0,
                    'valid': False
                })
            elif not l['valid']:
                new_nodes.append(r.copy())
            elif not r['valid']:
                new_nodes.append(l.copy())
            else:
                max_seen = max(l['max_seen'], r['max_seen'])
                first_digit = l['first_digit']

                cross_score = l['max_seen'] * 10 + r['first_digit']
                if l['score'] >= r['score'] and l['score'] >= cross_score:
                    score = l['score']
                elif r['score'] >= l['score'] and r['score'] >= cross_score:
                    score = r['score']
                else:
                    score = cross_score

                new_nodes.append({
                    'max_seen': max_seen,
                    'score': score,
                    'first_digit': first_digit,
                    'valid': True
                })

        nodes = new_nodes

    return nodes[0]['score'] if nodes[0]['valid'] else 0


def main():
    if len(sys.argv) < 3:
        print("Usage: precompute_cumulative.py <input_file> <output_hex>")
        sys.exit(1)

    input_file = sys.argv[1]
    output_hex = sys.argv[2]

    # Read input lines
    with open(input_file, 'r') as f:
        lines = f.read().strip().split('\n')

    results = []
    cumulative = 0
    for line in lines:
        if not line:
            continue

        digits = [int(c) for c in line if c.isdigit()]
        while len(digits) < 128:
            digits.append(0)

        score = compute_line_score(digits[:128])
        cumulative += score
        results.append(cumulative)

    # Write cumulative hex file
    with open(output_hex, 'w') as f:
        for cum_sum in results:
            f.write(f"{cum_sum:08x}\n")

    print(f"Precomputed {len(results)} cumulative sums")
    print(f"Wrote to {output_hex}")
    print(f"Final sum: {results[-1]}")


if __name__ == '__main__':
    main()
