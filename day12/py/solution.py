
import sys

def parse_input(filename):
    with open(filename, 'r') as f:
        content = f.read() # Read entire file content
        
    # Split by empty lines
    blocks = content.split('\n\n')
    shapes = {} # Keep as dict for easy lookup by index
    regions = []
    
    for block in blocks:
        block = block.strip()
        if not block: continue
        
        lines = block.split('\n')
        first_line = lines[0].strip()
        
        if 'x' in first_line and ':' in first_line:
            # This block contains one or more Regions
            for line in lines:
                line = line.strip()
                if not line: continue
                parts = line.split(':', 1)
                if len(parts) < 2: continue
                header = parts[0].strip()
                body = parts[1].strip()
                
                if 'x' in header:
                    w, h = map(int, header.split('x'))
                    counts = list(map(int, body.split()))
                    regions.append({'w': w, 'h': h, 'counts': counts})
        else:
            # This block is a Shape
            # Header is first line "0:"
            parts = first_line.split(':', 1)
            if len(parts) < 2: continue
            header = parts[0].strip()
            idx = int(header)
            
            grid = []
            for b_line in lines[1:]:
                b_line = b_line.strip()
                if not b_line: continue
                row = []
                for c in b_line:
                    row.append(1 if c == '#' else 0)
                if row:
                    grid.append(tuple(row))
            shapes[idx] = tuple(grid)
            
    return shapes, regions

def get_variations(shape_grid):
    # Rotate 0, 90, 180, 270. Flip.
    # Total 8 variations.
    vars = set()
    
    curr = shape_grid
    for _ in range(2): # Flip
        for _ in range(4): # Rotate
            # Add curr
            # Normalize? (Top-left aligned? Yes, but structure is tuple of tuples)
            vars.add(curr)
            
            # Rotate 90
            # (r, c) -> (c, H-1-r)
            H = len(curr)
            W = len(curr[0])
            new_grid = []
            for c in range(W):
                new_row = []
                for r in range(H-1, -1, -1):
                    new_row.append(curr[r][c])
                new_grid.append(tuple(new_row))
            curr = tuple(new_grid)
            
        # Flip (Reverse rows)
        curr = tuple(curr[::-1])
    
    return list(vars)

def can_fit(w, h, items, shapes):
    # Backtracking
    # items: list of shape_indices to place
    # Sort items by size (largest first)?
    
    # Grid: 0 empty, 1 filled
    grid = [[0]*w for _ in range(h)]
    
    # Flatten items list and Sort by area (descending)
    to_place = [] # list of (idx, variations)
    total_area = 0
    for idx_cnt, cnt in enumerate(items):
        if cnt > 0:
            shape_grid = shapes[idx_cnt]
            # Calc area
            area = sum(sum(r) for r in shape_grid)
            total_area += area * cnt
            vars = get_variations(shape_grid)
            for _ in range(cnt):
                to_place.append((area, vars))
    
    # Check if total area > w*h
    if total_area > w * h:
        return False
        
    # Sort largest first
    to_place.sort(key=lambda x: x[0], reverse=True)
    to_place_items = [x[1] for x in to_place] # remove area
    
    # Pre-compute bitmasks for variations
    # Grid is w x h. Flatten to w*h.
    # item_masks[i] = list of (mask, height, width)
    item_masks = []
    for var_list in to_place_items:
        masks = []
        for v_grid in var_list:
            vh = len(v_grid)
            vw = len(v_grid[0])
            base_mask = 0
            for r in range(vh):
                for c in range(vw):
                    if v_grid[r][c]:
                        base_mask |= (1 << (r * w + c))
            masks.append((base_mask, vh, vw))
        item_masks.append(masks)
        
    def place(item_idx, current_grid_mask):
        if item_idx >= len(item_masks):
            return True
            
        # Try all variations and positions
        # Optimization: Identify some cell that MUST be filled? 
        # Only if TotalArea == RemainingArea. Not guaranteed.
        
        # Optimization: symmetry breaking?
        # If multiple identical items, force order?
        # to_place was flattened. If we have 2 copies of Shape 4, they are distinct items now.
        # We can enforce that Item K+1's position > Item K's position if they are same shape.
        # But `to_place` list doesn't track shape ID easily (it's flattened).
        # We can rely on basic speed.
        
        possible_masks = item_masks[item_idx]
        
        for (base_mask, vh, vw) in possible_masks:
            # Try all positions (r, c)
            for r in range(h - vh + 1):
                for c in range(w - vw + 1):
                    # Create shifted mask
                    # Shift: r * w + c
                    shift = r * w + c
                    
                    # Check efficient shift:
                    # In python ints are infinite.
                    m = base_mask << shift
                    
                    if not (current_grid_mask & m):
                        # No collision
                        if place(item_idx + 1, current_grid_mask | m):
                            return True
                            
        return False

    return place(0, 0)

def solve(filename):
    shapes, regions = parse_input(filename)
    
    count = 0
    for reg in regions:
        if can_fit(reg['w'], reg['h'], reg['counts'], shapes):
            count += 1
            
    return count

if __name__ == "__main__":
    ex_result = solve("../input/example.txt")
    print(f"Example Result: {ex_result}")
    
    try:
        real_result = solve("../input/example.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input missing.")
