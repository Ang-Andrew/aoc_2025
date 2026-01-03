import sys
import os

def string_to_hex(input_str, out_path):
    with open(out_path, 'w') as f:
        for char in input_str:
            f.write(f"{ord(char):02X}\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
    
    with open(input_path, 'r') as f:
        content = f.read()
    
    # Verify content ends with newline, if not add one
    if not content.endswith('\n'):
        content += '\n'
        
    string_to_hex(content, '../input/input.hex')
    print(f"Generated hex from {input_path}")
