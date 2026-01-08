
import sys
import os

def string_to_hex(input_str, out_path):
    with open(out_path, 'w') as f:
        for char in input_str:
            f.write(f"{ord(char):02X}\n")

if __name__ == '__main__':
    input_path = '../input/example.txt'
    
    print(f"Reading from {input_path}")
    with open(input_path, 'r') as f:
        lines = f.readlines()
        
    if not lines:
        print("Empty file")
        sys.exit(1)
        
    width = len(lines[0].strip())
    print(f"Detected width: {width}")
    
    content = ""
    for line in lines:
        content += line.strip() + '\n'
        
    # Append 3 dummy lines of '.'
    dummy_line = '.' * width + '\n'
    content += dummy_line * 3
    
    # Write to input.hex (which TB reads)
    string_to_hex(content, '../input/input.hex')
    print(f"Generated hex to ../input/input.hex from example")
