def solve(filename):
    try:
        with open(filename, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        print("Error: 'input' file not found.")
        return

    current_pos = 50
    part1_count = 0
    part2_count = 0

    for line in lines:
        line = line.strip()
        if not line:
            continue
        
        direction = line[0]
        distance = int(line[1:])

        # Part 2: Count full rotations
        part2_count += distance // 100
        
        # Simulate remaining steps for Part 2
        remainder = distance % 100
        temp_pos = current_pos
        for _ in range(remainder):
            if direction == 'L':
                temp_pos = (temp_pos - 1) % 100
            elif direction == 'R':
                temp_pos = (temp_pos + 1) % 100
            
            if temp_pos == 0:
                part2_count += 1

        # Part 1: Update final position for this command
        if direction == 'L':
            current_pos = (current_pos - distance) % 100
        else:
            current_pos = (current_pos + distance) % 100
            
        if current_pos == 0:
             part1_count += 1

    return part1_count, part2_count
    # print(f"Password: {zero_count}")

if __name__ == "__main__":
    p1, p2 = solve("input")
    print(f"Part 1: {p1}")
    print(f"Part 2: {p2}")
