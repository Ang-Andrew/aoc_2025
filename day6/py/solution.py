
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
            
            # Improved parsing to handle cases like '123+' or '123*'
            # Scan the token for numbers and operators.
            # Simple regex-like logic or manual scan.
            idx = 0
            curr_num_str = ""
            while idx < len(token):
                char = token[idx]
                if char.isdigit():
                    curr_num_str += char
                elif char in ['+', '*']:
                    # If we had a number accumulating, push it
                    if curr_num_str:
                        numbers.append(int(curr_num_str))
                        curr_num_str = ""
                    op = char
                else:
                    # Ignore other chars? Or if space (should verify strip logic)
                    if curr_num_str:
                        numbers.append(int(curr_num_str))
                        curr_num_str = ""
                idx += 1
            
            # End of token
            if curr_num_str:
                numbers.append(int(curr_num_str))
        
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
    try:
        real_result = solve("../input/input.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input not found.")
