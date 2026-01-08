import os
import re

def update_makefile(day, is_day12=False):
    path = f"day{day}/hw/Makefile"
    if not os.path.exists(path):
        print(f"Skipping {path} (not found)")
        return

    with open(path, 'r') as f:
        content = f.read()

    if is_day12:
        # Day 12: Ensure sim runs verilator, test runs sim
        # Current Day 12 Makefile has:
        # verilator: ...
        # test: verilator
        
        # We want:
        # sim: verilator
        # test: sim
        
        # Replace 'verilator:' with 'sim:' ? Or keep verilator and add sim alias?
        # Let's keep verilator target as the implementation, make sim depend on it.
        
        if "sim:" not in content:
            content += "\n# Alias sim to verilator\nsim: verilator\n"
        
        # Ensure test depends on sim (or verilator)
        # Check current test target
        if re.search(r'^test:\s*verilator', content, re.MULTILINE):
            content = re.sub(r'^test:\s*verilator', 'test: sim', content, flags=re.MULTILINE)
        elif re.search(r'^test:\s*run', content, re.MULTILINE):
             content = re.sub(r'^test:\s*run', 'test: sim', content, flags=re.MULTILINE)

    else:
        # Days 1-11
        # 1. Remove dependency of 'test' on 'run' or 'sim'
        # Pattern: test: run -> test:
        # Pattern: test: sim -> test:
        
        content = re.sub(r'^test:\s*run\s*$', 'test:', content, flags=re.MULTILINE)
        content = re.sub(r'^test:\s*sim\s*$', 'test:', content, flags=re.MULTILINE)
        
        # 2. Ensure 'sim' target exists
        # If 'sim:' not in content
        if not re.search(r'^sim:', content, re.MULTILINE):
            # If 'run:' exists, alias sim: run
            if re.search(r'^run:', content, re.MULTILINE):
                 content += "\n# Runs Icarus Verilog Simulation\nsim: run\n"
            else:
                 # Should not match Day 1 which already has sim
                 pass

    with open(path, 'w') as f:
        f.write(content)
    print(f"Updated {path}")

def main():
    for i in range(1, 13):
        update_makefile(i, is_day12=(i==12))

if __name__ == "__main__":
    main()
