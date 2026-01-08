import re
import os
import sys

VECTOR_WIDTH = 16
ITEM_BITS = 17

def parse_input(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = [l.strip() for l in f.readlines() if l.strip()]

    packed_data = []
    current_pack = 0
    count = 0
    
    for line in lines:
        direction = line[0]
        distance = int(line[1:])
        
        dir_bit = 1 if direction == 'R' else 0
        val = (dir_bit << 16) | distance
        
        # Pack into current_pack (Little Endian: Item 0 at LSB)
        current_pack |= (val << (count * ITEM_BITS))
        count += 1
        
        if count == VECTOR_WIDTH:
            packed_data.append(current_pack)
            current_pack = 0
            count = 0
            
    # Handle remaining
    if count > 0:
        packed_data.append(current_pack)

    with open(output_path, 'w') as f:
        for val in packed_data:
            # 272 bits = 68 hex chars
            f.write(f"{val:068X}\n")

if __name__ == "__main__":
    # Determine base directory (../ relative to script)
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(script_dir)
    
    input_path = os.path.join(base_dir, "data", "input")
    output_path = os.path.join(base_dir, "data", "input.hex")
    
    print(f"Generating Vectorized ROM hex (W={VECTOR_WIDTH}) from {input_path} to {output_path}")
    parse_input(input_path, output_path)
