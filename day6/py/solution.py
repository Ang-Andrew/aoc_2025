
import sys

def solve(filename):
    with open(filename, 'r') as f:
        lines = [line.rstrip('\n') for line in f]
    
    if not lines:
        return 0

    max_len = max(len(line) for line in lines)
    # Pad to rectangle
    grid = [line.ljust(max_len) for line in lines]
    H = len(grid)
    W = max_len
    
    # 1. Compute Column Mask (hardware pass 1)
    col_mask = [False] * W
    for x in range(W):
        for y in range(H):
            if grid[y][x] != ' ':
                col_mask[x] = True
                break
    
    # 2. Identify Regions based on mask
    regions = []
    start_x = -1
    for x in range(W):
        if col_mask[x]:
            if start_x == -1:
                start_x = x
        else:
            if start_x != -1:
                regions.append((start_x, x)) # [start, end)
                start_x = -1
    if start_x != -1:
        regions.append((start_x, W))
        
    total = 0
    
    for (r_start, r_end) in regions:
        # Extract numbers and operator for this region
        # In this region, we look for tokens.
        # A token is a contiguous string of non-space chars in a row logic?
        # Actually, simpler: join the rows into a string, split by whitespace?
        # BUT: "123" on row 1 and "45" on row 2 are separate numbers.
        # So for each row, extract number.
        numbers = []
        op = None
        
        for y in range(H):
            row_slice = grid[y][r_start:r_end]
            token = row_slice.strip()
            if not token:
                continue
            
            if token in ['+', '*']:
                op = token
            else:
                try:
                    numbers.append(int(token))
                except ValueError:
                    pass # Should not happen based on problem
        
        if op == '+':
            val = sum(numbers)
        elif op == '*':
            val = 1
            for n in numbers:
                val *= n
        else:
            val = 0 # No op found
            
        total += val
        
    return total

if __name__ == "__main__":
    ex_result = solve("../input/example.txt")
    print(f"Example Result: {ex_result}")
    
    try:
        real_result = solve("../input/input.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input not found.")
