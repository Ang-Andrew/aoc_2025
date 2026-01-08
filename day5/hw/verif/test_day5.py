import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_day5_solution(dut):
    """
    Test Day 5 Parallel Solver
    """
    
    # 1. Path Setup
    test_dir = os.path.dirname(os.path.abspath(__file__))
    hw_dir = os.path.dirname(test_dir)
    day_dir = os.path.dirname(hw_dir) # day5
    sw_dir = os.path.join(day_dir, "py") 
    input_path = os.path.join(day_dir, "input", "input.txt")
    if not os.path.exists(input_path):
        input_path = os.path.join(day_dir, "input", "example.txt")

    # 2. Run Python Reference
    sys.path.append(sw_dir)
    try:
        from solution import solve
        exp_count = solve(input_path)
        dut._log.info(f"Python Reference Count: {exp_count}")
    except ImportError:
        dut._log.warning("Could not import python solution, skipping comparison.")
        exp_count = None

    # 3. Setup FPGA Simulation
    clock = Clock(dut.clk, 4, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # 4. Wait for Done
    await RisingEdge(dut.done)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    final_count = int(dut.count.value)
    dut._log.info(f"FPGA Count: {final_count}")
    
    if exp_count is not None:
        assert final_count == exp_count, f"Mismatch: FPGA={final_count}, Exp={exp_count}"
