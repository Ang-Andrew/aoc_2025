import sys
import os

WIDTH = 128 # Max line length supported

def convert(input_path, output_path):
    with open(input_path, 'r') as f:
        lines = [l.strip() for l in f.read().split('\n') if l.strip()]
        
    with open(output_path, 'w') as f:
        for line in lines:
            line = line.strip()
            # Truncate if too long (shouldn't be based on wc -L)
            if len(line) > WIDTH:
                print(f"Warning: Line truncated from {len(line)} to {WIDTH}")
                line = line[:WIDTH]
                
            # Pack Data: 4 bits per digit. LSB = First char? 
            # Usual convention: Char 0 is at bottom (LSB) or top (MSB)?
            # In simple streaming: Char 0 comes first.
            # In vector: Items[0] should be Char 0.
            # So LSB = Char 0.
            
            data_int = 0
            mask_int = 0
            
            for i, char in enumerate(line):
                digit = int(char)
                data_int |= (digit << (i * 4))
                mask_int |= (1 << i)
                
            # data is 128*4 = 512 bits.
            # mask is 128 bits.
            # Total 640 bits.
            # Write hex. 640/4 = 160 chars.
            
            val = (mask_int << 512) | data_int
            f.write(f"{val:0160X}\n")

if __name__ == "__main__":
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_dir = os.path.dirname(os.path.dirname(script_dir)) # day3/hw/
    input_path = os.path.join(base_dir, "input", "input.txt")
    output_path = os.path.join(base_dir, "hw", "data", "input.hex") # Assume hex goes to hw/data/
    
    # If args provided (e.g. from Makefile)
    if len(sys.argv) > 2:
        input_path = sys.argv[1]
        output_path = sys.argv[2]
        
    convert(input_path, output_path)
