import sys
import os

def parse_and_write(input_path):
    with open(input_path, 'r') as f:
        points = []
        for line in f:
            if line.strip():
                parts = line.strip().split(',')
                if len(parts) >= 2:
                    x,y = map(int, parts[:2])
                    points.append((x,y))

    N = len(points)
    
    # Pad to multiple of 4
    remainder = N % 4
    if remainder != 0:
        pad = 4 - remainder
        # Pad with (0,0) - Area calc will result in small values, won't affect Max
        for _ in range(pad):
            points.append((0,0))
    
    N_PADDED = len(points)
    DEPTH = N_PADDED // 4
    
    with open('../input/points.hex', 'w') as f:
        for i in range(DEPTH):
            # Pack 4 points
            # Each point: Y (32) | X (32) -> 64 bits
            # 4 points -> 256 bits
            
            line_val = 0
            for k in range(4):
                idx = i * 4 + k
                x, y = points[idx]
                p_val = (x & 0xFFFFFFFF) | ((y & 0xFFFFFFFF) << 32)
                line_val |= (p_val << (64 * k))
                
            f.write(f"{line_val:064X}\n")

    print(f"Stats: N={N}, N_PADDED={N_PADDED}, DEPTH={DEPTH}")
    
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam N = {N};\n")
        f.write(f"localparam N_PADDED = {N_PADDED};\n")
        f.write(f"localparam DEPTH = {DEPTH};\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
    
    parse_and_write(input_path)
