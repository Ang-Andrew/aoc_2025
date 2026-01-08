import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_day3_solution(dut):
    """
    Test Day 3 Parallel Tree Solver
    """
    
    # 1. Path Setup
    test_dir = os.path.dirname(os.path.abspath(__file__))
    hw_dir = os.path.dirname(test_dir)
    day3_dir = os.path.dirname(hw_dir)
    sw_dir = os.path.join(day3_dir, "sw")
    input_path = os.path.join(hw_dir, "data", "input") # Use copied input or original?
    # Original input
    input_orig = os.path.join(day3_dir, "input", "input.txt")
    
    # Run Python Reference
    sys.path.append(sw_dir)
    try:
        from solve import solve
        exp_score = solve(input_orig)
        dut._log.info(f"Python Reference Score: {exp_score}")
    except ImportError:
         dut._log.warning("Could not import python solution, skipping comparison.")
         exp_score = None

    # Setup Clock
    clock = Clock(dut.clk, 4, unit="ns") # 250 MHz
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    dut.valid_in.value = 0
    dut.data_in.value = 0
    dut.mask_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    await RisingEdge(dut.clk)
     
    # Drive Inputs (Vectorized)
    with open(input_orig, 'r') as f:
        lines = [l.strip() for l in f.read().split('\n') if l.strip()]
        
    WIDTH = 128
    
    for line in lines:
        if len(line) > WIDTH: line = line[:WIDTH]
        
        data_int = 0
        mask_int = 0
        for i, char in enumerate(line):
            digit = int(char)
            data_int |= (digit << (i * 4))
            mask_int |= (1 << i)
            
        dut.data_in.value = data_int
        dut.mask_in.value = mask_int
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    
    # Wait for pipeline (7 stages + margin)
    for _ in range(20):
        await RisingEdge(dut.clk)
        
    final_score = int(dut.total_score.value)
    dut._log.info(f"FPGA Score: {final_score}")
    
    if exp_score is not None:
        assert final_score == exp_score, f"Mismatch: FPGA={final_score}, Exp={exp_score}"
    
    # 4. Wait for Done
    if hasattr(dut, 'done'):
        await RisingEdge(dut.done)
    elif hasattr(dut, 'feeder'):
        # Access internal signal if possible, or just wait long enough
        await RisingEdge(dut.feeder.done)
    else:
        # Fallback or specific handling
        await Timer(500, units='us')

    
    # 5. Check Result
    actual_val = int(dut.total_joltage.value)
    
    dut._log.info(f"FPGA Result: {actual_val}")
    
    assert actual_val == expected_val, f"Mismatch! FPGA={actual_val}, Exp={expected_val}"
    dut._log.info("Test Passed!")
