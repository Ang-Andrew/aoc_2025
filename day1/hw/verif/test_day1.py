import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_day1_solution(dut):
    """
    Compare FPGA Solver against Python Reference
    """
    
    # 1. Run Python Reference
    # Structure:
    # day1/hw/verif/test_day1.py (this file)
    # day1/sw/solve.py
    # day1/hw/data/input
    
    test_dir = os.path.dirname(os.path.abspath(__file__)) # hw/verif
    hw_dir = os.path.dirname(test_dir)                    # hw
    day1_dir = os.path.dirname(hw_dir)                    # day1
    sw_dir = os.path.join(day1_dir, "sw")
    input_path = os.path.join(hw_dir, "data", "input")
    
    dut._log.info(f"Adding {sw_dir} to PYTHONPATH to import solve.py")
    sys.path.append(sw_dir)

    try:
        from solve import solve as solve_ref
    except ImportError:
        dut._log.error(f"Could not import solve.py from {sw_dir}")
        raise
    
    dut._log.info(f"Running Python Reference on {input_path}...")
    
    # solve.py returns (part1, part2)
    exp_p1, exp_p2 = solve_ref(input_path)
    dut._log.info(f"Python Reference: Part1={exp_p1}, Part2={exp_p2}")

    # 2. Setup FPGA Simulation
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    dut.reset.value = 1
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)

    # 3. Drive Inputs
    with open(input_path, 'r') as f:
        lines = [l.strip() for l in f.readlines() if l.strip()]

    dut._log.info("Driving FPGA with inputs (Vectorized)...")
    
    VECTOR_WIDTH = 16
    ITEM_BITS = 17
    
    # Process in batches
    for i in range(0, len(lines), VECTOR_WIDTH):
        batch = lines[i:i+VECTOR_WIDTH]
        
        packed_val = 0
        count = 0
        
        for item in batch:
            direction_char = item[0]
            distance = int(item[1:])
            dir_bit = 1 if direction_char == 'R' else 0
            
            val = (dir_bit << 16) | distance
            packed_val |= (val << (count * ITEM_BITS))
            count += 1
            
        # Pad remaining if partial batch
        # Zero padding is already handled by packed_val initialization and not shifting further
        
        dut.flat_data.value = packed_val
        dut.valid_mask.value = 0xFFFF # Assume all valid or logic handles padding (Dist=0 is NoOp)
        dut.valid_in.value = 1
        
        await RisingEdge(dut.clk)
        
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    # 4. Check Results
    fpga_p1 = int(dut.part1_count.value)
    fpga_p2 = int(dut.part2_count.value)
    
    dut._log.info(f"FPGA Results: Part1={fpga_p1}, Part2={fpga_p2}")
    
    assert fpga_p1 == exp_p1, f"Part 1 Mismatch! FPGA={fpga_p1}, Exp={exp_p1}"
    assert fpga_p2 == exp_p2, f"Part 2 Mismatch! FPGA={fpga_p2}, Exp={exp_p2}"
    
    dut._log.info("SUCCESS: FPGA matches Python reference!")
