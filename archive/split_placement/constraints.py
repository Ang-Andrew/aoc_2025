# Create regions
ctx.createRectangularRegion("left_region", 2, 2, 20, 70)
ctx.createRectangularRegion("right_region", 75, 2, 93, 70)

# Debug: Print first 5 cell names
count = 0
for name, _ in ctx.cells:
    if count < 5:
        print("DEBUG CELL NAME:", name)
        count += 1

# Assign cells
constrained_count = 0
for name, cell in ctx.cells:
    if "left" in name and "chain" in name:
        ctx.constrainCellToRegion(name, "left_region")
        constrained_count += 1
    elif "right" in name and "chain" in name:
        ctx.constrainCellToRegion(name, "right_region")
        constrained_count += 1

print(f"DEBUG: Constrained {constrained_count} cells.")
