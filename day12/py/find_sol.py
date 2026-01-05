import sys
import os
import solution

def find_solvable():
    path = "../input/example.txt"
    if not os.path.exists(path):
        print(f"Error: {path} not found")
        return

    print(f"Reading {path}")
    shapes, regions = solution.parse_input(path)
    
    for i, reg in enumerate(regions):
        # Quick area check
        item_area = 0
        for idx_cnt, cnt in enumerate(reg['counts']):
            if cnt > 0:
                shape_grid = shapes[idx_cnt]
                area = sum(sum(r) for r in shape_grid)
                item_area += area * cnt
        
        if item_area > reg['w'] * reg['h']:
             continue
             
        # Try solving
        if solution.can_fit(reg['w'], reg['h'], reg['counts'], shapes):
            print(f"Found solvable problem at index {i}")
            print(f"Dims: {reg['w']}x{reg['h']}")
            print(f"Counts: {reg['counts']}")
            return

    print("No solvable problems found!?")

if __name__ == "__main__":
    find_solvable()
