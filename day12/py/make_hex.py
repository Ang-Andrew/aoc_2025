import sys
import os

def parse_input(filename):
    with open(filename, 'r') as f:
        content = f.read() 
        
    blocks = content.split('\n\n')
    shapes = {} 
    regions = []
    
    for block in blocks:
        block = block.strip()
        if not block: continue
        
        lines = block.split('\n')
        first_line = lines[0].strip()
        
        if 'x' in first_line and ':' in first_line:
            # Regions
            for line in lines:
                line = line.strip()
                if not line: continue
                parts = line.split(':', 1)
                if len(parts) < 2: continue
                header = parts[0].strip()
                body = parts[1].strip()
                w, h = map(int, header.split('x'))
                counts = list(map(int, body.split()))
                regions.append({'w': w, 'h': h, 'counts': counts})
        else:
            # Shape
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
    vars_set = set()
    curr = shape_grid
    for _ in range(2): # Flip
        for _ in range(4): # Rotate
            vars_set.add(curr)
            # Rot 90
            H = len(curr)
            W = len(curr[0])
            new_grid = []
            for c in range(W):
                new_row = []
                for r in range(H-1, -1, -1):
                    new_row.append(curr[r][c])
                new_grid.append(tuple(new_row))
            curr = tuple(new_grid)
        curr = tuple(curr[::-1])
    return list(vars_set)

def generate_hex(input_path):
    shapes, regions = parse_input(input_path)
    
    # 1. Process Shapes
    # Shape Table: map ShapeID -> List of Element Entries
    # Element Entry: W, H, Mask (64 bit?)
    # We need to flatten this for HW.
    # shape_mem format: 
    # [Variation Data ...]
    # shape_idx_mem format:
    # [StartPtr, Count]
    
    # Analyze max shape size to determine mask width
    max_s_w = 0
    max_s_h = 0
    
    variation_data = [] # List of (w, h, mask, fr, fc)
    shape_map = {} # ID -> (start, count)
    
    sorted_shape_ids = sorted(shapes.keys())
    # Ensure dense ID space or handle gaps? 
    # Example IDs are 0..5.
    
    for sid in sorted_shape_ids:
        vars_list = get_variations(shapes[sid])
        start_idx = len(variation_data)
        count = len(vars_list)
        
        for v in vars_list:
            h = len(v)
            w = len(v[0])
            mask = 0
            # Flatten to bits. Row major?
            # HW Grid is flat. r*GW + c.
            # Mask needs to be shiftable.
            # Let's store mask as a small 8x8 bitmap (64 bits)
            # where bit (r,c) is set.
            # HW will expand this to full grid width.
            for r in range(h):
                row_mask = 0
                for c in range(w):
                    if v[r][c]:
                        # Piece Column 0 (Leftmost) -> Bit 0 (LSB)
                        # Hardware will reverse this to MSB
                        row_mask |= (1 << c)
                mask |= (row_mask << (r * 8))
            
            # Calculate fr, fc here while we have v
            fr, fc = 0, 0
            found = False
            for r in range(h):
                for c in range(w):
                    if v[r][c]:
                        fr, fc = r, c
                        found = True
                        break
                if found: break

            variation_data.append((w, h, mask, fr, fc))
            
        shape_map[sid] = (start_idx, count)
        
    # Write shapes.hex
    # For simplicity, let's write `shape_params.hex` (Variation Data)
    # and `shape_index.hex` (Index Table).
    # HW: shape_rom[idx]
    
    with open('../input/shapes.hex', 'w') as f:
        # First word: Count
        f.write(f"{len(variation_data):08X}\n")
        for (w, h, m, fr, fc) in variation_data:
            
            # Write Packed Word 0: first_c(8) | first_r(8) | H(8) | W(8)
            # Actually, let's just use existing slots.
            # slot 0: W. lets make it packed.
            packed_info = (fc << 24) | (fr << 16) | w
            f.write(f"{packed_info:08X}\n")
            f.write(f"{h:08X}\n")
            f.write(f"{m & 0xFFFFFFFF :08X}\n")
            f.write(f"{(m >> 32) & 0xFFFFFFFF :08X}\n")

    # Write Index Map (for S_INIT_PROB to lookup ranges)
    # Since ShapeIDs are small 0..N, we can index directly.
    # Write to params or a header in shapes.hex?
    # Let's write `shape_idx.hex`
    with open('../input/shape_idx.hex', 'w') as f:
        max_id = max(sorted_shape_ids) if sorted_shape_ids else 0
        for i in range(max_id + 1):
            if i in shape_map:
                s, c = shape_map[i]
                f.write(f"{s:04X}{c:04X}\n") # Start, Count
            else:
                f.write("00000000\n")

    # 2. Process Problems (input.hex)
    # Format:
    # NumProblems
    # For each:
    # W, H
    # NumItems
    # Item0_ShapeID
    # Item1_ShapeID ...
    
    with open('../input/input.hex', 'w') as f:
        f.write(f"{len(regions):08X}\n")
        for reg in regions:
            W = reg['w']
            H = reg['h']
            counts = reg['counts']
            # Expand items
            items = []
            for idx, cnt in enumerate(counts):
                for _ in range(cnt):
                    items.append(idx)
                    
            # Sort items by size (Area) descending? Optimizing search.
            # Calculate area for each shape
            items_with_area = []
            for sid in items:
                gf = shapes[sid]
                area = sum(sum(row) for row in gf)
                items_with_area.append((area, sid))
            
            # Sort by Area (descending) and ShapeID (ascending) for symmetry breaking
            items_with_area.sort(key=lambda x: (-x[0], x[1]))
            
            # Check for Area Constraint
            total_item_area = sum(x[0] for x in items_with_area)
            if total_item_area > W * H:
                # Impossible. Replace with trivial failure case.
                # Grid 1x1. Item: Size > 1.
                # Use the first item from sorted (largest).
                W = 1
                H = 1
                sorted_items = [items_with_area[0][1]]
            else:
                sorted_items = [x[1] for x in items_with_area]
            
            f.write(f"{W:04X}{H:04X}\n") # W, H
            f.write(f"{len(sorted_items):08X}\n") # NumItems
            
            # Write items
            for sid in sorted_items:
                f.write(f"{sid:08X}\n")

if __name__ == '__main__':
    input_path = '../input/example.txt'
    if len(sys.argv) > 1: input_path = sys.argv[1]
    
    generate_hex(input_path)
