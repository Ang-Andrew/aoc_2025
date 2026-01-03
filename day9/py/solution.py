
import sys

def solve(filename):
    with open(filename, 'r') as f:
        points = []
        for line in f:
            if line.strip():
                x,y = map(int, line.strip().split(','))
                points.append((x,y))
                
    N = len(points)
    max_area = 0
    
    # Iterate all pairs
    for i in range(N):
        for j in range(i+1, N):
            x1, y1 = points[i]
            x2, y2 = points[j]
            
            # Area = |dx| + 1 * |dy| + 1 ?
            # Example: 2,5 and 9,7.
            # Grid coords?
            # 2,5 (#) to 9,7 (#).
            # dx = 9-2 = 7. dy = 7-5 = 2.
            # Area = (9-2+1) * (7-5+1)?
            # Let's check example.
            # OOO...
            # 2,5 to 9,7.
            # Width is |9-2| + 1 = 8.
            # Height is |7-5| + 1 = 3.
            # Area = 8 * 3 = 24. Matches example.
            
            # 2,5 and 11,1.
            # w = |11-2|+1 = 10.
            # h = |1-5|+1 = 5.
            # Area = 50. Matches example.
            
            w = abs(x2-x1) + 1
            h = abs(y2-y1) + 1
            area = w * h
            if area > max_area:
                max_area = area
                
    return max_area

if __name__ == "__main__":
    ex_result = solve("../input/example.txt")
    print(f"Example Result: {ex_result}")
    
    try:
        real_result = solve("../input/input.txt")
        print(f"Real Result: {real_result}")
    except FileNotFoundError:
        print("Real input missing.")
