import sys
import os

def parse_and_write(input_path):
    with open(input_path, 'r') as f:
        lines = [line.rstrip('\n') for line in f if line.strip()]
    
    if not lines: return

    H = len(lines)
    W = max(len(line) for line in lines)
    
    # Pad
    grid = [line.ljust(W, '.') for line in lines]
    
    # Pack Row-Major
    # 2 bits per cell.
    # 00: .
    # 01: ^
    # 10: S
    
    with open('../input/input.hex', 'w') as f:
        for line in grid:
            val = 0
            # Pack from Left=MSB or LSB? 
            # Verilog [WIDTH-1:0]. Usually index 0 is LSB.
            # Let's map x=0 to LSB.
            for x in range(W):
                char = line[x]
                code = 0
                if char == '^': code = 1
                elif char == 'S': code = 2
                
                # Shift into position x * 2
                val |= (code << (x * 2))
            
            # Width in hex chars. W * 2 bits. / 4 bits per hex.
            # (W*2 + 3) // 4
            hex_chars = (W * 2 + 3) // 4
            f.write(f"{val:0{hex_chars}X}\n")

    print(f"Stats: W={W}, H={H}")
    
    # Write params header
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam WIDTH = {W};\n")
        f.write(f"localparam HEIGHT = {H};\n")
        f.write(f"localparam ROW_BITS = {W*2};\n")

if __name__ == '__main__':
    # Prefer input.txt, fallback to example.txt
    input_path = '../input/input.txt'
    if not os.path.exists(input_path) or os.path.getsize(input_path) == 0:
        input_path = '../input/example.txt'
        print("Using example.txt")
    
    parse_and_write(input_path)
