
import sys
import re

def solve(filename):
    with open(filename, 'r') as f:
        lines = [line.strip() for line in f if line.strip()]
        
    total_presses = 0
    
    for line in lines:
        # Parse Line
        # Format: [DIAGRAM] (BUTTON) (BUTTON) ... {JOLTAGES}
        # Ignore joltages.
        # 1. Extract diagram: between [ and ]
        m_diag = re.search(r'\[(.*?)\]', line)
        if not m_diag: continue
        diag_str = m_diag.group(1)
        
        # Target state vector
        target = []
        for c in diag_str:
            target.append(1 if c == '#' else 0)
        L = len(target)
        
        # 2. Extract buttons: between ( and )
        # Note: there are multiple groups in parens.
        # Use simple iterative find or regex.
        # Remove the diagram part to make search easier?
        rest = line[m_diag.end():]
        # Remove curly braces part if present?
        # Just find all ( ... )
        button_matches = re.findall(r'\((.*?)\)', rest)
        
        buttons = []
        for b_str in button_matches:
            # "1,3" -> [1, 3]
            indices = [int(x) for x in b_str.split(',') if x.strip()]
            
            # Create bit vector for button
            vec = [0] * L
            for idx in indices:
                if idx < L:
                    vec[idx] = 1
            buttons.append(vec)
            
        # Problem: Minimum button presses to reach target.
        # Since it's XOR logic (toggle), order doesn't matter.
        # Pressing a button twice is same as 0.
        # So each button is pressed either 0 or 1 time.
        # This is a system of linear equations over GF(2)!
        # A * x = target
        # A is matrix where columns are buttons.
        # x is vector of presses (0 or 1).
        # We need to find x with minimum weight (sum of 1s).
        
        # However, typically solving Ax=b gives a solution space (particular + null space).
        # If the null space is trivial, only 1 solution.
        # If not, we iterate solutions to find min weight.
        
        # How to solve Ax=b over GF(2)? Gaussian Elimination.
        
        num_vars = len(buttons)
        num_eqs = L
        
        # Construct augmented matrix: [Cols | Target]
        # Rows are indicator list positions. Cols are buttons.
        matrix = []
        for r in range(num_eqs):
            row = []
            for c in range(num_vars):
                row.append(buttons[c][r])
            row.append(target[r])
            matrix.append(row)
            
        # Gaussian Elimination
        pivot_row = 0
        pivot_cols = []
        free_vars = []
        
        for c in range(num_vars):
            if pivot_row >= num_eqs:
                free_vars.append(c)
                continue
                
            # Find pivot in col c from pivot_row down
            sel = -1
            for r in range(pivot_row, num_eqs):
                if matrix[r][c] == 1:
                    sel = r
                    break
            
            if sel == -1:
                free_vars.append(c)
                continue
                
            # Swap
            matrix[pivot_row], matrix[sel] = matrix[sel], matrix[pivot_row]
            
            pivot_cols.append(c)
            
            # Eliminate other rows
            for r in range(num_eqs):
                if r != pivot_row and matrix[r][c] == 1:
                    # Row Add (XOR)
                    for k in range(c, num_vars + 1):
                        matrix[r][k] ^= matrix[pivot_row][k]
                        
            pivot_row += 1
            
        # Check consistency
        # If any row is [0 0 ... 0 | 1], then impossible.
        possible = True
        for r in range(pivot_row, num_eqs):
            if matrix[r][num_vars] == 1:
                possible = False
                break
                
        if not possible:
            print("Impossible config found")
            continue
            
        # If possible, we have a particular solution for the pivot variables.
        # The free variables can be anything (0 or 1).
        # Total vars = pivots + free.
        # Equation for pivot p_i:
        # p_i + sum(free_j * coeff) = target_i
        # p_i = target_i - sum(...)  (since + is - in GF2)
        
        # We want to minimize HammingWeight(x).
        # Since num_vars is small (example has ~6 buttons), maybe we can iterate all free var assignments?
        # Example lines have ~5-10 buttons. 2^10 = 1024, easy.
        # If N is larger (e.g. 50), this is hard (Nearest Codeword is NP-hard).
        # But AoC usually has N < 20 or specific structure.
        # Let's count free vars.
        num_free = len(free_vars)
        if num_free > 20:
            print(f"Warning: {num_free} free variables. Exponential search.")
            
        min_presses = float('inf')
        
        for i in range(1 << num_free):
            # Assign free vars
            assignment = [0] * num_vars
            
            # Set free vars values
            for bit_idx, fv_idx in enumerate(free_vars):
                val = (i >> bit_idx) & 1
                assignment[fv_idx] = val
                
            # Solve for pivots (Back-substitution order not needed because matrix is reduced row echelon form)
            # Actually, standard RREF computes pivots such that pivot val depends only on free vars later in row?
            # Yes, each pivot row is: [0... 1 ... free_coeffs ... | val]
            # pivot_var + free_part = val => pivot_var = val ^ free_part
            
            # Since we diagonalized (eliminated ABOVE and BELOW pivots for the pivot columns),
            # Each pivot row `r` corresponds to `pivot_cols[r]`.
            for r in range(len(pivot_cols)):
                c = pivot_cols[r]
                # Calculate required val
                row_val = matrix[r][num_vars]
                # Add accumulation from free vars in this row
                for fv in free_vars:
                    if fv > c: # Should be all free vars essentially, but free vars to left were processed?
                        # RREF: free cols can be anywhere.
                        if matrix[r][fv] == 1:
                            row_val ^= assignment[fv]
                            
                assignment[c] = row_val
                
            # Calculate weight
            w = sum(assignment)
            if w < min_presses:
                min_presses = w
                
        total_presses += min_presses
        
    return total_presses

if __name__ == "__main__":
    ex_result = solve("../input/example.txt")
    print(f"Example Result: {ex_result}")
    
    try:
        real_result = solve("../input/input.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input missing.")
