import sys
import os

def eudist_sq(p1, p2):
    return (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2 + (p1[2]-p2[2])**2

def generate_hex(input_path, k_limit):
    with open(input_path, 'r') as f:
        points = []
        for line in f:
            if line.strip():
                x,y,z = map(int, line.strip().split(','))
                points.append((x,y,z))
                
    N = len(points)
    
    edges = []
    for i in range(N):
        for j in range(i+1, N):
            d = eudist_sq(points[i], points[j])
            edges.append((d, i, j)) # d, u, v
            
    # Sort
    edges.sort(key=lambda x: x[0])
    
    # We only need top K edges for the hardware to process?
    # Actually, "connect together the 1000 pairs... which are closest".
    # So we feed EXACTLY K pairs to the hardware.
    # The HW will just UNION them all.
    # Logic check: "Because these two... were already in the same circuit, nothing happens!"
    # This implies the HW just runs Union(u,v) K times.
    
    edges_to_write = edges[:k_limit]
    
    # Write input.hex
    # Each line: u (16 bit) v (16 bit) -> 32 bit hex
    with open('../input/input.hex', 'w') as f:
        for d, u, v in edges_to_write:
            # 32-bit word: [u:16, v:16]
            f.write(f"{u:04X}{v:04X}\n")
            
    # Write params.vh
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam NUM_NODES = {N};\n")
        f.write(f"localparam NUM_EDGES = {len(edges_to_write)};\n")
        f.write(f"localparam K_LIMIT = {k_limit};\n")

if __name__ == '__main__':
    input_path = '../input/example.txt'
    k = 1000
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        k = 10
        print("Using example.txt")
        
    generate_hex(input_path, k)
