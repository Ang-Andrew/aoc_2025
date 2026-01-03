import sys
import os

def solve_line(line):
    # O(N^2) Reference Implementation
    digits = [int(c) for c in line.strip()]
    max_val = 0
    for i in range(len(digits)):
        for j in range(i + 1, len(digits)):
            val = digits[i] * 10 + digits[j]
            if val > max_val:
                max_val = val
    return max_val

def solve_line_streaming(line):
    # O(N) Streaming Implementation (Hardware Friendly)
    digits = [int(c) for c in line.strip()]
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

def solve(input_str):
    lines = input_str.strip().split('\n')
    total = 0
    for line in lines:
        if not line.strip(): continue
        val = solve_line_streaming(line)
        # Verify with reference
        ref = solve_line(line)
        assert val == ref, f"Mismatch for line {line}: Streaming {val}, Ref {ref}"
        total += val
    return total

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    
    if not os.path.exists(input_path):
        print(f"Error: Input file not found at {input_path}")
        # Try example
        input_path = '../input/example.txt'
        print(f"Trying example file at {input_path}")
    
    if os.path.exists(input_path):
        with open(input_path, 'r') as f:
            print(f"Solving {input_path}...")
            print(f"Total Output Joltage: {solve(f.read())}")
    else:
        print("No input file found.")
