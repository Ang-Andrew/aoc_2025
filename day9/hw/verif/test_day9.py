import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os
import sys

@cocotb.test()
async def test_day9_solution(dut):
    test_dir = os.path.dirname(os.path.abspath(__file__))
    hw_dir = os.path.dirname(test_dir)
    day_dir = os.path.dirname(hw_dir)
    sw_dir = os.path.join(day_dir, "py") 
    input_path = os.path.join(day_dir, "input", "input.txt")
    if not os.path.exists(input_path):
        input_path = os.path.join(day_dir, "input", "example.txt")

    sys.path.append(sw_dir)
    try:
        from solution import solve
        exp_area = solve(input_path)
        dut._log.info(f"Python Reference Area: {exp_area}")
    except ImportError:
        dut._log.warning("Could not import python solution.")
        exp_area = None

    clock = Clock(dut.clk, 4, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # Wait loop
    # N=1000 -> N^2/4 = 250k. 
    # Timeout needs to be generous.
    for i in range(500000):
        await RisingEdge(dut.clk)
        if dut.done.value == 1:
            break
            
    final_area = int(dut.max_area.value)
    dut._log.info(f"FPGA Area: {final_area}")
    
    if exp_area is not None:
        assert final_area == exp_area
