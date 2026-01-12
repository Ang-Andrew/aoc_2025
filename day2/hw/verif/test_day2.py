import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_day2_solution(dut):
    """
    Compare FPGA Solution against Python Reference for day2
    """
    
    # 1. Path Setup
    test_dir = os.path.dirname(os.path.abspath(__file__))
    hw_dir = os.path.dirname(test_dir)
    day_dir = os.path.dirname(hw_dir)
    sw_dir = os.path.join(day_dir, "py") # Most use 'py'
    if not os.path.exists(sw_dir): sw_dir = os.path.join(day_dir, "sw") # Fallback
    
    # Input Path (Standard location)
    # Most hardware reads ../input/input.hex or similar.
    # Python needs original text input usually.
    # We try typical locations.
    input_path = os.path.join(day_dir, "input", "input.txt")
    if not os.path.exists(input_path):
        input_path = os.path.join(day_dir, "input", "example.txt")

    dut._log.info(f"Adding {sw_dir} to PYTHONPATH")
    sys.path.append(sw_dir)

    # 2. Run Python Reference
    try:
        from solution import solve
    except ImportError:
        dut._log.error(f"Could not import solve from {sw_dir}")
        raise

    dut._log.info(f"Running Python Reference on {input_path}...")
    
    # Execute Python Solve
    val = solve(input_path)
    expected_val = val
    
    dut._log.info(f"Python Reference Expected Value: {expected_val}")

    # 3. Setup FPGA Simulation
    if hasattr(dut, 'clk'):
        clock = Clock(dut.clk, 10, unit="ns")
        cocotb.start_soon(clock.start())
    elif hasattr(dut, 'clk_250'): # Day 2/3 Top
        clock = Clock(dut.clk_250, 4, unit="ns")
        cocotb.start_soon(clock.start())
    else:
        dut._log.warning("No clock found!")

    # Reset
    if hasattr(dut, 'reset'):
        dut.reset.value = 1
        await Timer(100, units='ns')
        dut.reset.value = 0
    elif hasattr(dut, 'rst'):
        dut.rst.value = 1
        await Timer(100, units='ns')
        dut.rst.value = 0
    elif hasattr(dut, 'btn'): # Active high reset often mapped to btn
        dut.btn.value = 1
        await Timer(100, units='ns')
        dut.btn.value = 0
    
    dut._log.info("Reset complete, waiting for done...")

    # 4. Wait for Done
    if hasattr(dut, 'done'):
        await RisingEdge(dut.done)
        # Use the correct clock for stability wait
        if hasattr(dut, 'clk_250'):
             await RisingEdge(dut.clk_250)
        elif hasattr(dut, 'clk'):
             await RisingEdge(dut.clk)
    else:
        # Fallback or specific handling
        await Timer(100, units='us')

    
    # 5. Check Result
    # Access the internal wire 'total_sum' since we removed the port.
    actual_val = int(dut.total_sum.value)
    
    dut._log.info(f"FPGA Result: {actual_val}")
    
    assert actual_val == expected_val, f"Mismatch! FPGA={actual_val}, Exp={expected_val}"
    dut._log.info("Test Passed!")
