
import sys
import math

def eudist_sq(p1, p2):
    return (p1[0]-p2[0])**2 + (p1[1]-p2[1])**2 + (p1[2]-p2[2])**2

def solve(filename, k_shortest):
    with open(filename, 'r') as f:
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
            
    # Sort edges by distance
    edges.sort(key=lambda x: x[0])
    
    # Union-Find
    parent = list(range(N))
    size = [1] * N
    
    def find(i):
        if parent[i] == i:
            return i
        parent[i] = find(parent[i])
        return parent[i]
        
    def union(i, j):
        root_i = find(i)
        root_j = find(j)
        if root_i != root_j:
            # Merge
            if size[root_i] < size[root_j]:
                root_i, root_j = root_j, root_i
            parent[root_j] = root_i
            size[root_i] += size[root_j]
            return True
        return False
        
    # Process k shortest edges (that connect distinct components?)
    # Problem: "After making the ten shortest connections"
    # "Because these two junction boxes were already in the same circuit, nothing happens!"
    # So we process the K shortest PAIRS. If they are already connected, nothing happens (union returns false).
    # But does "making the connection" count towards K?
    # "connect together the 1000 pairs of junction boxes which are closest together"
    # This implies we iterate through the sorted list of ALL pairs, and Attempt the first 1000.
    # OR does it mean "keep connecting until we have made 1000 SUCCESSFUL connections"?
    # Reread carefully: "The next two... were already in the same circuit, nothing happens!"
    # "After making the ten shortest connections" in the example (which led to 11 circuits).
    # The example text says:
    # 1. 1st pair: 162-425. Connected.
    # 2. 2nd pair: 162-431. Connected.
    # 3. 3rd pair: 906-805. Connected.
    # 4. 4th pair: 431-425. Already connected. "nothing happens!"
    # "This process continues for a while... After making the ten shortest connections"
    # It seems "ten shortest connections" refers to the top 10 pairs in the list, regardless of whether they merged or not?
    # NO. "Connection" usually implies an edge added.
    # Let's count how many pairs we check.
    # "connect together the 1000 pairs of junction boxes which are closest together"
    # This wording is ambiguous.
    # "connect together" is the action.
    # "pairs... which are closest".
    # This likely means: Take the top 1000 pairs from the sorted list of all N*(N-1)/2 pairs.
    # For each, Apply Union.
    # The example says "After making the ten shortest connections".
    # Wait, in the example, the 4th pair did nothing.
    # If we stop after 10 *attempts*, we might have fewer effective merges.
    # Let's assume K attempts from the sorted list.
    
    count_processed = 0
    for d, u, v in edges:
        # Check if we processed K
        if count_processed >= k_shortest:
            break
            
        union(u, v)
        count_processed += 1
        
    # Find sizes of components
    # We need representative sizes
    root_sizes = []
    visited_roots = set()
    for i in range(N):
        r = find(i)
        if r not in visited_roots:
            root_sizes.append(size[r])
            visited_roots.add(r)
            
    root_sizes.sort(reverse=True)
    
    # Multiply top 3
    if len(root_sizes) < 3:
        result = 0 # Not enough components?
        # Or just multiply what we have?
        result = 1
        for s in root_sizes: result *= s
    else:
        result = root_sizes[0] * root_sizes[1] * root_sizes[2]
        
    return result

if __name__ == "__main__":
    # Example K=10
    ex_result = solve("../input/example.txt", 10)
    print(f"Example Result (K=10): {ex_result}")
    
    # Real input K=1000
    try:
        real_result = solve("../input/example.txt", 1000)
        print(f"Real Result (K=1000): {real_result}")
    except FileNotFoundError:
        print("Real input not found.")
