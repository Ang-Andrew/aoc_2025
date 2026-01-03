import sys
import os

def generate_hex(input_path):
    with open(input_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    if not lines:
        print("Empty input")
        return
        
    max_len = max(len(line) for line in lines)
    grid = [line.ljust(max_len, '.') for line in lines]
    H = len(grid)
    W = max_len
    
    # Write input.hex: 1 byte per char
    with open('../input/input.hex', 'w') as f:
        for line in grid:
            for char in line:
                f.write(f"{ord(char):02X}\n")
                
    # Write params.vh
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam WIDTH = {W};\n")
        f.write(f"localparam HEIGHT = {H};\n")
        f.write(f"localparam MEM_SIZE = {W * H};\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
        
    generate_hex(input_path)
