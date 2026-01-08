import re

def parse_file(filename, pattern, shift_col=0):
    coords = set()
    with open(filename, 'r') as f:
        for line in f:
            m = re.search(pattern, line)
            if m:
                coords.add((int(m.group(1)), int(m.group(2)) + shift_col))
    return coords

# Hardware reports Col X when it finds solution at Col X-1.
# So if Hardware reports 1, it means Col 0.
# So we need to shift Hardware by -1 to match Python (which reports 0).
py_coords = parse_file('day4_py_out.txt', r'Py: Found at Row\s+(\d+)\s+Col\s+(\d+)', 0)
hw_coords = parse_file('day4_hw_out.txt', r'V: Found at Row\s+(\d+)\s+Col\s+(\d+)', -1)

print(f"Python found {len(py_coords)} items")
print(f"Hardware found {len(hw_coords)} items")

only_py = sorted(list(py_coords - hw_coords))
only_hw = sorted(list(hw_coords - py_coords))

print(f"In Python but not Hardware ({len(only_py)}):")
for r, c in only_py[:20]:
    print(f"  Row {r} Col {c}")

print(f"In Hardware but not Python ({len(only_hw)}):")
for r, c in only_hw[:20]:
    print(f"  Row {r} Col {c}")
