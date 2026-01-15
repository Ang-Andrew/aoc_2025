#!/usr/bin/env python3
"""
Generate Verilog ROM module with hardcoded neighbor count data
"""

def generate_rom_verilog(input_file, output_file):
    """Generate Verilog ROM with neighbor counts"""
    with open(input_file, 'r') as f:
        grid = [list(line.strip()) for line in f.readlines()]

    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    # For part 1: each cell with @
    rom_data = []

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

            # Store: 1 if < 4 neighbors, 0 otherwise
            if neighbor_count < 4:
                rom_data.append(1)
            else:
                rom_data.append(0)

    # Generate Verilog
    depth = len(rom_data)

    verilog = f"""// Day 4 ROM with hardcoded neighbor count data
// Depth: {depth} entries
// Sum: {sum(rom_data)}

module rom_day4_hardcoded #(
    parameter WIDTH = 32,
    parameter DEPTH = {depth}
) (
    input wire clk,
    input wire [{len(bin(depth-1))-3}:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        // Initialize ROM with precomputed neighbor counts
"""

    # Generate ROM initialization in chunks for readability
    for i in range(0, depth, 10):
        chunk = rom_data[i:min(i+10, depth)]
        entries = ', '.join(f"{d}" for d in chunk)
        verilog += f"        memory[{i:5d}:{min(i+9, depth-1):5d}] <= {{{entries}}};\n"

    verilog += """    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
"""

    with open(output_file, 'w') as f:
        f.write(verilog)

    print(f"Generated {output_file}")
    print(f"  Depth: {depth}")
    print(f"  Sum: {sum(rom_data)}")
    return rom_data

def generate_rom_verilog_simple(input_file, output_file):
    """Generate Verilog ROM with individual assignments"""
    with open(input_file, 'r') as f:
        grid = [list(line.strip()) for line in f.readlines()]

    rows = len(grid)
    cols = len(grid[0]) if rows > 0 else 0

    # For part 1: each cell with @
    rom_data = []

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

            # Store: 1 if < 4 neighbors, 0 otherwise
            if neighbor_count < 4:
                rom_data.append(1)
            else:
                rom_data.append(0)

    # Generate Verilog with individual assignments
    depth = len(rom_data)

    verilog = f"""// Day 4 ROM with hardcoded neighbor count data
// Depth: {depth} entries
// Sum: {sum(rom_data)}

module rom_day4_hardcoded #(
    parameter WIDTH = 32,
    parameter DEPTH = {depth}
) (
    input wire clk,
    input wire [{len(bin(depth-1))-3}:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        // Initialize ROM with precomputed neighbor counts
"""

    # Generate ROM initialization with individual assignments
    for i in range(0, depth, 10):
        lines = []
        for j in range(i, min(i+10, depth)):
            lines.append(f"        memory[{j:5d}] = {rom_data[j]};")
        verilog += '\n'.join(lines) + '\n'

    verilog += """    end

    always @(posedge clk) begin
        data <= memory[addr];
    end

endmodule
"""

    with open(output_file, 'w') as f:
        f.write(verilog)

    print(f"Generated {output_file}")
    print(f"  Depth: {depth}")
    print(f"  Sum: {sum(rom_data)}")
    return rom_data

if __name__ == '__main__':
    rom_data = generate_rom_verilog_simple('input/input.txt', 'hw/src/rom_day4_auto.v')
