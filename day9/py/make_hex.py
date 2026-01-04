import sys
import os

def generate_hex(input_path):
    with open(input_path, 'r') as f:
        points = []
        for line in f:
            if line.strip():
                x,y = map(int, line.strip().split(','))
                points.append((x,y))
                
    N = len(points)
    
    # Write input.hex: 32 bit per point
    with open('../input/input.hex', 'w') as f:
        for x, y in points:
            # 64-bit word: 32-bit x, 32-bit y
            f.write(f"{x:08X}{y:08X}\n")
            
    # Write params.vh
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam NUM_POINTS = {N};\n")

if __name__ == '__main__':
    input_path = '../input/example.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
        
    generate_hex(input_path)
