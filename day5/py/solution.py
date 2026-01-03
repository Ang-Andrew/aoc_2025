def parse_input(filename):
    with open(filename, 'r') as f:
        content = f.read().strip()
    
    parts = content.split('\n\n')
    range_lines = parts[0].split('\n')
    id_lines = parts[1].split('\n')
    
    ranges = []
    for line in range_lines:
        start, end = map(int, line.split('-'))
        ranges.append((start, end))
        
    ids = []
    for line in id_lines:
        ids.append(int(line))
        
    return ranges, ids

def solve(filename):
    ranges, ids = parse_input(filename)
    
    count = 0
    for id_val in ids:
        is_fresh = False
        for start, end in ranges:
            if start <= id_val <= end:
                is_fresh = True
                break
        if is_fresh:
            count += 1
            
    return count

if __name__ == "__main__":
    example_result = solve("../input/example.txt")
    print(f"Example result: {example_result}")
    
    real_result = solve("../input/input.txt")
    print(f"Real result: {real_result}")
