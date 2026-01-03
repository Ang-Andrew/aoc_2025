import sys
import os

def generate_hex(input_path):
    with open(input_path, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
        
    adj = {}
    nodes = set()
    
    for line in lines:
        parts = line.split(':')
        src = parts[0].strip()
        dests = parts[1].strip().split() if parts[1].strip() else []
        adj[src] = dests
        nodes.add(src)
        for d in dests: nodes.add(d)
        
    if 'you' not in nodes or 'out' not in nodes:
        print("Missing start/end nodes")
        return
        
    # Build Topological Sort
    # standard DFS post-order gives reverse topological?
    # Or just use Kahn's algorithm or recursive DFS.
    
    topo_order = []
    visited = set()
    temp_mark = set()
    
    def visit(u):
        if u in temp_mark:
            raise ValueError("Cycle detected")
        if u in visited:
            return
            
        temp_mark.add(u)
        if u in adj:
            for v in adj[u]:
                visit(v)
        temp_mark.remove(u)
        visited.add(u)
        topo_order.append(u)
        
    visit('you')
    
    # topo_order has children visited before parents (Post-Order).
    # e.g. [out, eee, bbb, you...]
    # Wait, Post-Order: visit children, then add self.
    # So `out` is added first (leaf). `you` added last.
    # Yes.
    # If we process in this order (0 to end), we see `out` first.
    # `Paths(out) = 1`.
    # Next node `eee`: Children `out`. `Paths(eee) = Paths(out)`.
    # This works. Memory dependency is satisfied.
    
    # Mapping
    node_to_id = {name: i for i, name in enumerate(topo_order)}
    N = len(topo_order)
    
    # Write inputs
    with open('../input/input.hex', 'w') as f:
        # We need to map 'out' index
        out_idx = node_to_id['out']
        # Write 'out' index first? Or hardcode logic.
        # Actually logic:
        # Initialize RAM[out_idx] = 1.
        # Iterate topo_order.
        # For each u, sum = 0.
        # For v in children: sum += RAM[v].
        # If u == out, sum = 1 (or init).
        # RAM[u] = sum.
        
        # We can implement initialization in HW.
        # Input stream: For each node in topo_order:
        # [NodeID] [NumChildren] [Child1_ID] [Child2_ID] ...
        
        for u in topo_order:
            u_id = node_to_id[u]
            children = adj.get(u, [])
            
            # Format:
            # Word 0: [NodeID: 16] [NumChildren: 16]
            children_ids = [node_to_id[c] for c in children if c in node_to_id]
            
            f.write(f"{u_id:04X}{len(children_ids):04X}\n")
            
            # Children words (packed 2 per word?)
            # Keep it simple: 1 per word (32-bit).
            for cid in children_ids:
                f.write(f"{cid:08X}\n")

    # Params
    with open('../hw/src/params.vh', 'w') as f:
        f.write(f"localparam NUM_NODES = {N};\n")
        f.write(f"localparam OUT_NODE = {node_to_id['out']};\n")
        f.write(f"localparam YOU_NODE = {node_to_id['you']};\n")

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if not os.path.exists(input_path):
        input_path = '../input/example.txt'
        print("Using example.txt")
        
    generate_hex(input_path)
