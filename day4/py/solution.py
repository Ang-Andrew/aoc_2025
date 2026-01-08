import sys
import os

def solve(input_str):
    grid = [list(line.strip()) for line in input_str.strip().split('\n')]
    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0
    
    count = 0
    
    for r in range(rows):
        for c in range(cols):
            if grid[r][c] != '@':
                continue
                
            neighbor_count = 0
            # Check 8 neighbors
            for dr in [-1, 0, 1]:
                for dc in [-1, 0, 1]:
                    if dr == 0 and dc == 0:
                        continue
                    
                    nr, nc = r + dr, c + dc
                    
                    if 0 <= nr < rows and 0 <= nc < cols:
                        if grid[nr][nc] == '@':
                            neighbor_count += 1
            
            if neighbor_count < 4:
                count += 1
                print(f"Py: Found at Row {r} Col {c} (Neighbors {neighbor_count})")
                
    return count

def solve_part2(input_str):
    grid = [list(line.strip()) for line in input_str.strip().split('\n')]
    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0
    
    total_removed = 0
    
    while True:
        to_remove = []
        for r in range(rows):
            for c in range(cols):
                if grid[r][c] != '@':
                    continue
                
                neighbor_count = 0
                for dr in [-1, 0, 1]:
                    for dc in [-1, 0, 1]:
                        if dr == 0 and dc == 0:
                            continue
                        
                        nr, nc = r + dr, c + dc
                        
                        if 0 <= nr < rows and 0 <= nc < cols:
                            if grid[nr][nc] == '@':
                                neighbor_count += 1
                
                if neighbor_count < 4:
                    to_remove.append((r, c))
        
        if not to_remove:
            break
            
        total_removed += len(to_remove)
        for r, c in to_remove:
            grid[r][c] = '.'
            
    return total_removed

if __name__ == '__main__':
    input_path = '../input/input.txt'
    if len(sys.argv) > 1:
        input_path = sys.argv[1]
    
    if not os.path.exists(input_path):
        print(f"Error: Input file not found at {input_path}")
        # Try example
        input_path = '../input/example.txt'
        print(f"Trying example file at {input_path}")
    
    if os.path.exists(input_path):
        with open(input_path, 'r') as f:
            content = f.read()
            print(f"Solving {input_path}...")
            print(f"Part 1 - Total Accessible Paper Rolls: {solve(content)}")
            print(f"Part 2 - Total Removed Paper Rolls: {solve_part2(content)}")
    else:
        print("No input file found.")
