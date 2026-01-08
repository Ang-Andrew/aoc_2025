
import sys

def solve(grid):
    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0
    count = 0
    matches = []
    
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
                count += 1
                matches.append((r, c))
    return count, matches

# Read input.txt
with open('../input/input.txt', 'r') as f:
    orig_content = f.read()
    orig_grid = [list(line.strip()) for line in orig_content.strip().split('\n')]

# Read input.hex
hex_grid_str = ""
with open('../input/input.hex', 'r') as f:
    for line in f:
        code = int(line.strip(), 16)
        hex_grid_str += chr(code)

# Parse hex grid
# Hex grid has newlines (0A).
lines = hex_grid_str.split('\n')
# Remove empty lines / padding

# Parse hex grid
# Hex grid has newlines (0A).
lines = hex_grid_str.split('\n')
grid_from_hex = []
for line in lines:
    if not line: continue 
    # Do not filter startswith('.') as real input can start with '.'
    grid_from_hex.append(list(line))

# Remove trailing padding lines if any (dummy lines)
# make_hex adds 3 lines.
if len(grid_from_hex) > len(orig_grid):
     grid_from_hex = grid_from_hex[:len(orig_grid)]


# Compare grids
print(f"Orig Grid: {len(orig_grid)} rows x {len(orig_grid[0])} cols")
# Hex grid might have extra rows.
print(f"Hex Grid: {len(grid_from_hex)} lines")

# Truncate hex grid to orig size for comparison
matched = True
for r in range(len(orig_grid)):
    if r >= len(grid_from_hex):
        print(f"Hex grid shorter! Row {r}")
        matched = False
        break
    # Hex line might include \r if not handled? No, make_hex stripped it.
    # Check content
    l_orig = "".join(orig_grid[r])
    l_hex = "".join(grid_from_hex[r])
    
    # Hex grid logic in make_hex: "dummy_line * 3" appended.
    # So hex grid should match exactly for N rows.
    
    if l_orig != l_hex:
        print(f"Mismatch at Row {r}")
        print(f"Orig: {l_orig[:20]}...")
        print(f"Hex : {l_hex[:20]}...")
        matched = False
        break

if matched:
    print("Grids match!")
else:
    print("Grids mismatch!")

# Solve using Hex Grid to be sure
# Remove the padding lines
clean_hex_grid = [grid_from_hex[r] for r in range(len(orig_grid))]
c, m = solve(clean_hex_grid)
print(f"Hex Grid Solution: {c}")

with open('py_out.txt', 'r') as f:
    content = f.read()
    if f"Total Accessible Paper Rolls: {c}" in content:
        print("Matches py_out.txt")
    else:
        print("Does not match py_out.txt")
