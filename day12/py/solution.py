
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
        
    # Track if item is same as previous for symmetry breaking
    is_same_as_prev = [False] * len(to_place)
    for i in range(1, len(to_place)):
        # to_place is (area, vars). If vars are same, it's same shape.
        if to_place[i][1] == to_place[i-1][1]:
            is_same_as_prev[i] = True

    def place(item_idx, current_grid_mask, last_pos):
        if item_idx >= len(item_masks):
            return True
        
        start_pos = 0
        if is_same_as_prev[item_idx]:
            start_pos = last_pos + 1
            
        possible_masks = item_masks[item_idx]
        
        for (base_mask, vh, vw) in possible_masks:
            for shift in range(start_pos, w * h):
                r = shift // w
                c = shift % w
                
                if r + vh > h or c + vw > w:
                    continue
                
                m = base_mask << shift
                if not (current_grid_mask & m):
                    if place(item_idx + 1, current_grid_mask | m, shift):
                        return True
        return False

    return place(0, 0, -1)

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
