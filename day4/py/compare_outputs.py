
import re

def parse_py(filename):
    matches = set()
    with open(filename, 'r') as f:
        for line in f:
            m = re.search(r'Py: Found at Row (\d+) Col (\d+)', line)
            if m:
                matches.add((int(m.group(1)), int(m.group(2))))
    return matches

def parse_v(filename):
    matches = set()
    with open(filename, 'r') as f:
        for line in f:
            m = re.search(r'V: Match at Row\s+(\d+)\s+Col\s+(\d+)', line)
            if m:
                matches.add((int(m.group(1)), int(m.group(2))))
    return matches

py_matches = parse_py('py_out.txt')
v_matches = parse_v('v_out.txt')


with open('diff.txt', 'w') as f:
    f.write(f"Python matches: {len(py_matches)}\n")
    f.write(f"Verilog matches: {len(v_matches)}\n")

    missing_in_v = sorted(list(py_matches - v_matches))
    extra_in_v = sorted(list(v_matches - py_matches))

    f.write("\nMissing in Verilog:\n")
    for r, c in missing_in_v:
        f.write(f"Row {r} Col {c}\n")

    f.write("\nExtra in Verilog:\n")
    for r, c in extra_in_v:
        f.write(f"Row {r} Col {c}\n")
