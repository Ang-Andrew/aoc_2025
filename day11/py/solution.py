
import sys

def solve(filename):
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]

    # Parse Graph
    adj = {}
    
    for line in lines:
        # format: "node: dest1 dest2 ..."
        parts = line.split(':')
        src = parts[0].strip()
        dests_str = parts[1].strip()
        if dests_str:
            dests = dests_str.split()
        else:
            dests = []
        
        adj[src] = dests

    # Count paths from 'you' to 'out'
    # Start: 'you'
    # End: 'out'
    # Graph is likely DAG?
    # "Data only ever flows from a device through its outputs; it can't flow backwards."
    # Does this guarantee no cycles?
    # "Find every path".
    # If dynamic cycles, infinite paths. So likely DAG.
    # DFS with memoization (DP).
    
    memo = {}
    
    def count_paths(u):
        if u == 'out':
            return 1
        if u in memo:
            return memo[u]
        
        total = 0
        if u in adj:
            for v in adj[u]:
                total += count_paths(v)
                
        memo[u] = total
        return total
        
    result = count_paths('you')
    return result

if __name__ == "__main__":
    ex_result = solve("../input/example.txt")
    print(f"Example Result: {ex_result}")
    
    try:
        real_result = solve("../input/input.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input missing.")
