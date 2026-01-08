import sys
import os

def parse_and_write(input_path):
    with open(input_path, 'r') as f:
        lines = [line.rstrip('\n') for line in f]
    
    if not lines: return

    max_len = max(len(line) for line in lines)
    H = len(lines)
    W = max_len
    
    # Pad
    grid = [line.ljust(W) for line in lines]
    
    # Add dummy empty column at end to force flush
    W += 1
    # Grid logic below access grid[y][x]. 
    # Must ensure grid has W columns?
    # Actually just iter range(W-1) and then write 0.
    
    # Write Column-Major Input
    with open('../input/input_cols.hex', 'w') as f:
        for x in range(W):
            col_val = 0
            if x < W - 1:
                for y in range(H):
                    char = ord(grid[y][x])
                    col_val |= (char << (y * 8))
            else:
                col_val = 0 # Empty column
            
            # Hex chars = H * 2
            f.write(f"{col_val:0{H*2}X}\n")

    print(f"Stats: W={W}, H={H}")
    
    # Write params header
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam WIDTH = {W};\n")
        f.write(f"localparam HEIGHT = {H};\n")
        f.write(f"localparam COL_BITS = {H*8};\n")

if __name__ == '__main__':
    # Prefer input.txt, fallback to example.txt
    input_path = '../input/input.txt'
    if not os.path.exists(input_path) or os.path.getsize(input_path) == 0:
        input_path = '../input/example.txt'
        print("Using example.txt (input.txt missing or empty)")
    
    parse_and_write(input_path)
