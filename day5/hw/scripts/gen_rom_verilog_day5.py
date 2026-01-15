#!/usr/bin/env python3
"""
Generate Verilog ROM for Day 5
Each ROM entry contains 1 if ID matches a range, 0 otherwise
"""

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

def generate_rom_verilog_day5(input_file, output_file):
    """Generate Verilog ROM for Day 5"""
    ranges, ids = parse_input(input_file)

    rom_data = []
    count = 0

    print(f"Processing {len(ids)} IDs against {len(ranges)} ranges...")

    for id_val in ids:
        is_fresh = False
        for start, end in ranges:
            if start <= id_val <= end:
                is_fresh = True
                break

        if is_fresh:
            rom_data.append(1)
            count += 1
        else:
            rom_data.append(0)

    depth = len(rom_data)

    verilog = f"""// Day 5 ROM with match data
// Depth: {depth} entries (1000 IDs)
// Sum: {count}

module rom_day5_data #(
    parameter WIDTH = 32,
    parameter DEPTH = {depth}
) (
    input wire clk,
    input wire [{len(bin(depth-1))-3}:0] addr,
    output reg [WIDTH-1:0] data
);

    reg [WIDTH-1:0] memory [0:DEPTH-1];

    initial begin
        // Initialize ROM with precomputed match data
"""

    # Generate ROM initialization with individual assignments
    for i in range(0, depth, 20):
        lines = []
        for j in range(i, min(i+20, depth)):
            lines.append(f"        memory[{j:4d}] = {rom_data[j]};")
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
    print(f"  Count: {count}")
    return rom_data, count

if __name__ == '__main__':
    rom_data, count = generate_rom_verilog_day5('input/input.txt', 'hw/src/rom_day5_auto.v')
