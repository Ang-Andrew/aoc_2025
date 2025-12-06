import re
import os
import sys

def parse_input(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = f.readlines()

    with open(output_path, 'w') as f:
        for line in lines:
            line = line.strip()
            if not line:
                continue
            
            direction = line[0]
            distance = int(line[1:])
            
            dir_bit = 1 if direction == 'R' else 0
            val = (dir_bit << 16) | distance
            
            f.write(f"{val:05X}\n")
            
if __name__ == "__main__":
    # Determine base directory (../ relative to script)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    
    input_path = os.path.join(base_dir, "data", "input")
    output_path = os.path.join(base_dir, "data", "input.hex")
    
    print(f"Generating ROM hex from {input_path} to {output_path}")
    parse_input(input_path, output_path)
