
import sys

def solve(filename):
    with open(filename, 'r') as f:
        grid = [line.strip() for line in f if line.strip()]
        
    H = len(grid)
    if H == 0: return 0
    W = max(len(line) for line in grid)
    
    # Active set of x-coordinates
    active = set()
    
    # Find S
    for x in range(W):
        if 'S' in grid[0]: # Assumption: S is on first row? Text says "Marked S".
            # The example has S on first row. The input might have S elsewhere?
            # "A tachyon beam enters the manifold at the location marked S"
            # If S is at y=0, we start there.
            # If S is lower, we start simulation when we hit row y(S)?
             pass

    # Better logic:
    # Iterate rows.
    # Current active set.
    # If we find S in current row, add its x to active.
    
    active_now = set()
    splitters_hit = 0
    
    for y in range(H):
        row = grid[y]
        next_active = set()
        
        # Add new sources
        for x in range(W):
            if row[x] == 'S':
                 active_now.add(x)
                 
        # Process active beams
        # Use simple iteration over sorted list to be deterministic
        current_beams = sorted(list(active_now))
        
        for x in current_beams:
            # Beam is entering (x, y).
            cell = row[x]
            
            if cell == '^':
                splitters_hit += 1
                # Splits: spawns at (x-1, y+1) and (x+1, y+1)
                # But wait, does it spawn in CURRENT row or NEXT row logic?
                # "continuing from the immediate left... of the splitter"
                # If we are at row y, splitting happens. Result beams are at y+1?
                if x > 0: next_active.add(x - 1)
                if x < W - 1: next_active.add(x + 1)
            else:
                # '.' or 'S' (passes through S?)
                # "Tachyon beams pass freely through empty space (.)"
                # Assume S acts as empty after emission?
                # Beam continues down to (x, y+1)
                next_active.add(x)
                
        active_now = next_active
        print(f"Row {y}: Active {active_now}, Splitters {splitters_hit}")
        
        # Visualize
        # line = ""
        # for x in range(W):
        #     if x in active_now: line += "|"
        #     else: line += "."
        # print(line)
        
    return splitters_hit, len(active_now)

if __name__ == "__main__":
    splitters, beams = solve("../input/example.txt")
    print(f"Example: Splitters Hit: {splitters}, Final Beams: {beams}")
