import sys
import os

def eudist_sq(p1, p2):
    return (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2 + (p1[2]-p2[2])**2

def make_hex(input_path, k_shortest, output_path):
    with open(input_path, 'r') as f:
        points = []
        for line in f:
            if line.strip():
                x,y,z = map(int, line.strip().split(','))
                points.append((x,y,z))
                
    N = len(points)
    
    # Calculate all pair distances
    edges = []
    for i in range(N):
        for j in range(i+1, N):
            d = eudist_sq(points[i], points[j])
            edges.append((d, i, j))
            
    edges.sort(key=lambda x: x[0])
    
    # Write top K edges (u, v)
    # Each u, v is log2(N) bits. Pack into 32 bits?
    # Max N < 65536. 16 bits each.
    
    with open(output_path, 'w') as f:
        for i in range(min(len(edges), k_shortest)):
             d, u, v = edges[i]
             val = (u & 0xFFFF) | ((v & 0xFFFF) << 16)
             f.write(f"{val:08X}\n")
             
    # Write params
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam N = {N};\n")
        f.write(f"localparam K = {k_shortest};\n")
        
    print(f"Stats: N={N}, K={k_shortest}")

if __name__ == "__main__":
    input_path = '../input/input.txt'
    k = 1000
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        k = 10
        print("Using example.txt with K=10")
        
    make_hex(input_path, k, '../input/edges.hex')
