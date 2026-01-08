import sys
import re
import os

def parse_and_write(input_path):
    with open(input_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
        
    packet_stream = []
    
    max_r = 0
    max_c = 0
    
    for line in lines:
        m_diag = re.search(r'\[(.*?)\]', line)
        if not m_diag: continue
        diag_str = m_diag.group(1)
        
        target = []
        for c in diag_str:
            target.append(1 if c == '#' else 0)
        L = len(target) # ROWS
        
        rest = line[m_diag.end():]
        button_matches = re.findall(r'\((.*?)\)', rest)
        
        buttons = []
        for b_str in button_matches:
            indices = [int(x) for x in b_str.split(',') if x.strip()]
            vec = [0] * L
            for idx in indices:
                if idx < L: vec[idx] = 1
            buttons.append(vec)
            
        num_vars = len(buttons) # COLS
        num_eqs = L
        
        if num_eqs > 32 or num_vars > 31:
            print(f"Skipping large problem: {num_eqs}x{num_vars}")
            continue
            
        if num_eqs > max_r: max_r = num_eqs
        if num_vars > max_c: max_c = num_vars
        
        # Header: [31:16] COLS, [15:0] ROWS
        header = (num_vars << 16) | num_eqs
        packet_stream.append(header)
        
        # Matrix Rows: [Cols | Target]
        # Target in MSB? or LSB? 
        # Rows: bit 0 = Col 0. bit N-1 = Col N-1. bit N = Target.
        # Let's put target at bit 'num_vars'.
        
        for r in range(num_eqs):
            row_val = 0
            for c in range(num_vars):
                if buttons[c][r]:
                    row_val |= (1 << c)
            if target[r]:
                row_val |= (1 << num_vars)
            
            packet_stream.append(row_val)
            
    # Write terminator?
    packet_stream.append(0xFFFFFFFF)
            
    with open('../input/input_stream.hex', 'w') as f:
        for val in packet_stream:
            f.write(f"{val:08X}\n")
            
    print(f"Stats: MaxR={max_r}, MaxC={max_c}, Packets={len(packet_stream)}")
    
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam MAX_ROWS = 32;\n")
        f.write(f"localparam STREAM_DEPTH = {len(packet_stream)};\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
    
    parse_and_write(input_path)
