import sys
import os

def parse_and_write(input_path):
    with open(input_path, 'r') as f:
        content = f.read().strip()
    
    parts = content.split('\n\n')
    range_lines = parts[0].split('\n')
    id_lines = parts[1].split('\n')
    
    # Write ranges
    with open('../input/ranges.hex', 'w') as f:
        for line in range_lines:
            start, end = map(int, line.split('-'))
            # Use 64-bit (16 hex chars)
            f.write(f"{start:016X} {end:016X}\n")
    
    # Write ids
    with open('../input/ids.hex', 'w') as f:
        for line in id_lines:
            val = int(line)
            f.write(f"{val:016X}\n")

    print(f"Stats: {len(range_lines)} ranges, {len(id_lines)} ids")
    
    # Write params header
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam NUM_RANGES = {len(range_lines)};\n")
        f.write(f"localparam NUM_IDS = {len(id_lines)};\n")

if __name__ == '__main__':
    # Prefer input.txt, fallback to example.txt
    input_path = '../input/input.txt'
    if not os.path.exists(input_path) or os.path.getsize(input_path) == 0:
        input_path = '../input/example.txt'
        print("Using example.txt (input.txt missing or empty)")
    
    parse_and_write(input_path)
