import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os
import sys

@cocotb.test()
async def test_day7_solution(dut):
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
        exp_splitters, exp_beams = solve(input_path)
        dut._log.info(f"Python Reference Splitters: {exp_splitters}")
    except ImportError:
        dut._log.warning("Could not import python solution.")
        exp_splitters = None

    clock = Clock(dut.clk, 4, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    await RisingEdge(dut.done)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    
    final_splitters = int(dut.splitters_hit.value)
    dut._log.info(f"FPGA Splitters: {final_splitters}")
    
    if exp_splitters is not None:
        assert final_splitters == exp_splitters
