import sys
import os
import time

# Ensure we can import solution from current directory
sys.path.append(os.getcwd())
import solution

def check():
    path = "../input/example.txt"
    if not os.path.exists(path):
        print(f"Error: {path} not found")
        return

    print(f"Reading {path}")
    shapes, regions = solution.parse_input(path)
    
    # Check Prob 0
    reg = regions[0]
    items_count = sum(reg['counts'])
    print(f"Prob 0: {reg['w']}x{reg['h']}, {items_count} items.")
    
    start = time.time()
    # solution.can_fit returns True/False
    res = solution.can_fit(reg['w'], reg['h'], reg['counts'], shapes)
    end = time.time()
    
    print(f"Prob 0 Solvable: {res}")
    print(f"Time: {end-start:.4f}s")

if __name__ == "__main__":
    check()
