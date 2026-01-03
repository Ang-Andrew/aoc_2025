import sys
import os
import re

def generate_hex(input_path):
    with open(input_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    with open('../input/input.hex', 'w') as f:
        for line in lines:
            # Parse diagram
            m_diag = re.search(r'\[(.*?)\]', line)
            if not m_diag: continue
            diag_str = m_diag.group(1)
            target = [(1 if c == '#' else 0) for c in diag_str]
            L = len(target)
            
            # Parse buttons
            rest = line[m_diag.end():]
            button_matches = re.findall(r'\((.*?)\)', rest)
            buttons = []
            for b_str in button_matches:
                indices = [int(x) for x in b_str.split(',') if x.strip()]
                vec = [0] * L
                for idx in indices:
                    if idx < L: vec[idx] = 1
                buttons.append(vec)
            
            # Write Header: [NumRows(L), NumCols(Buttons)]
            # 32-bit word: [Rows:16, Cols:16]
            f.write(f"{L:04X}{len(buttons):04X}\n")
            
            # Write Matrix Rows
            # Augmented Matrix: [Buttons... | Target]
            # Each ROW is written as a bit vector.
            # Width = NumCols + 1.
            # Pack into 32-bit (or 64-bit if needed).
            # Assume Width <= 32 for now.
            for r in range(L):
                row_val = 0
                # Bits 0..Cols-1 are buttons. Bit Cols is Target.
                for c in range(len(buttons)):
                    if buttons[c][r]:
                         row_val |= (1 << c)
                if target[r]:
                    row_val |= (1 << len(buttons))
                
                f.write(f"{row_val:08X}\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
        
    generate_hex(input_path)
