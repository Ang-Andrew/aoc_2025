import sys
import bisect

def generate_invalid_ids(max_val):
    invalid_ids = []
    # k is half length.
    # If input is huge, we rely on the fact that we stop when we exceed max_val.
    
    for k in range(1, 20): 
        start = 10**(k-1)
        end = 10**k
        multiplier = 10**k + 1
        
        # Smallest number for this k is start * multiplier.
        if start * multiplier > max_val:
            break
            
        for x in range(start, end):
            val = x * multiplier
            if val > max_val:
                break
            invalid_ids.append(val)
            
    invalid_ids.sort()
    return invalid_ids

def solve(input_file):
    with open(input_file, 'r') as f:
        data = f.read().strip()
    
    ranges_str = data.split(',')
    ranges = []
    max_limit = 0
    for r in ranges_str:
        if not r.strip(): continue
        parts = r.strip().split('-')
        if len(parts) != 2:
             continue
        start, end = int(parts[0]), int(parts[1])
        ranges.append((start, end))
        if end > max_limit:
            max_limit = end
            
    
    # Merge ranges to handle overlaps and sorting
    ranges.sort()
    merged_ranges = []
    if ranges:
        curr_start, curr_end = ranges[0]
        for next_start, next_end in ranges[1:]:
            if next_start <= curr_end + 1: # Overlap or adjacent
                 curr_end = max(curr_end, next_end)
            else:
                 merged_ranges.append((curr_start, curr_end))
                 curr_start, curr_end = next_start, next_end
        merged_ranges.append((curr_start, curr_end))
    
    ranges = merged_ranges
    
    # Check if HEX generation is requested
    if '--generate-hex' in sys.argv:
        try:
            hex_idx = sys.argv.index('--generate-hex')
            hex_file = sys.argv[hex_idx + 1]
            with open(hex_file, 'w') as f:
                for start, end in ranges:
                    # Format: 128 bit hex. Upper 64: End, Lower 64: Start
                    # Verilog $readmemh
                    line = f"{end:016x}{start:016x}\n"
                    f.write(line)
            print(f"Generated HEX file: {hex_file}")
        except:
            print("Error generating HEX file. Usage: ... --generate-hex <filename>")

    # Generate candidates
    print(f"Max limit in input: {max_limit}")
    candidates = generate_invalid_ids(max_limit * 10) # *10 buffer since max_limit is rough
    print(f"Generated {len(candidates)} candidate invalid IDs.")
    
    total_sum = 0
    
    for start, end in ranges:
        # Find first valid >= start
        idx_start = bisect.bisect_left(candidates, start)
        # Find first valid > end
        idx_end = bisect.bisect_right(candidates, end)
        
        subset = candidates[idx_start:idx_end]
        for val in subset:
            print(f"PY_ADDED: {val}")
        s = sum(subset)
        total_sum += s
        
    print(f"Total Sum: {total_sum}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python solution.py <input_file> [--generate-hex <hex_file>]")
        sys.exit(1)
    solve(sys.argv[1])
