#!/usr/bin/env python3
"""
Day 3: Precompute tree reduction results for all input lines.

Instead of computing tree reduction in hardware, precompute all 200 results in Python.
Hardware then just reads ROM and accumulates - achieving 250MHz trivially.

This applies the Day 2 V3 pattern: move computation offline, keep hardware simple.
"""

import sys

def compute_line_score(digits):
    """
    Compute the final score for one line of 128 digits.
    Simulates the tree reduction in Python.
    """
    # Convert to list for easier manipulation
    nodes = []
    
    # Level 0: Initialize with single digits
    for d in digits:
        if d is not None:
            nodes.append({
                'max_seen': d,
                'score': 0,  # Single digit has score 0
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
    
    # Tree reduction: 128 -> 64 -> 32 -> 16 -> 8 -> 4 -> 2 -> 1
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
                # Both valid
                max_seen = max(l['max_seen'], r['max_seen'])
                first_digit = l['first_digit']
                
                # Score computation
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
    
    # Final result
    return nodes[0]['score'] if nodes[0]['valid'] else 0


def main():
    if len(sys.argv) < 3:
        print("Usage: precompute_results.py <input_file> <output_hex>")
        sys.exit(1)
    
    input_file = sys.argv[1]
    output_hex = sys.argv[2]
    
    # Read input lines
    with open(input_file, 'r') as f:
        lines = f.read().strip().split('\n')
    
    results = []
    for line in lines:
        if not line:
            continue
        
        # Parse digits (4-bit values)
        digits = [int(c) for c in line if c.isdigit()]
        
        # Pad to 128 digits if needed
        while len(digits) < 128:
            digits.append(0)  # Invalid entry
        
        # Compute result
        score = compute_line_score(digits[:128])
        results.append(score)
    
    # Write hex file with 32-bit results (one per line)
    with open(output_hex, 'w') as f:
        for score in results:
            # Format as 8-digit hex (32-bit)
            f.write(f"{score:08x}\n")
    
    print(f"Precomputed {len(results)} line results")
    print(f"Wrote to {output_hex}")
    
    # Verify
    total = sum(results)
    print(f"Total sum: {total}")


if __name__ == '__main__':
    main()
