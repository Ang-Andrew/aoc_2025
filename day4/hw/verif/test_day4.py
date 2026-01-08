import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_day4_solution(dut):
    """
    Compare FPGA Solution against Python Reference for Day 4
    """
    
    # 1. Path Setup
    test_dir = os.path.dirname(os.path.abspath(__file__))
    hw_dir = os.path.dirname(test_dir)
    day_dir = os.path.dirname(hw_dir)
    sw_dir = os.path.join(day_dir, "py")
    
    input_path = os.path.join(day_dir, "input", "input.txt")
    if not os.path.exists(input_path):
        raise FileNotFoundError(f"Input file not found at {input_path}")

    dut._log.info(f"Adding {sw_dir} to PYTHONPATH")
    sys.path.append(sw_dir)

    # 2. Run Python Reference
    try:
        from solution import solve
    except ImportError:
        dut._log.error(f"Could not import solve from {sw_dir}")
        raise

    dut._log.info(f"Running Python Reference on {input_path}...")
    
    with open(input_path, 'r') as f:
        content = f.read()

    expected_val = solve(content)
    dut._log.info(f"Python Reference Expected Value: {expected_val}")

    # 3. Setup FPGA Simulation
    clock = Clock(dut.clk, 10, unit="ns")
    cocotb.start_soon(clock.start())

    # Reset
    dut.reset.value = 1
    dut.valid_in.value = 0
    dut.char_in.value = 0
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.reset.value = 0
    await RisingEdge(dut.clk)
    
    dut._log.info("Reset complete, sending data...")

    # 4. Drive Data
    # Convert content to bytes/char stream
    # Ensure newlines are sent as 0x0A
    
    for char in content:
        byte_val = ord(char)
        dut.char_in.value = byte_val
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)
        
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)

    # Ensure last line is terminated and processed (in case input lacks trailing newline)
    dut._log.info("Sending trailing newline...")
    dut.char_in.value = 0x0A
    dut.valid_in.value = 1
    await RisingEdge(dut.clk)
    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    
    # Flush the pipeline by sending a row's worth of "empty" pixels
    # This pushes the last actual row into the processing window (center)
    # Sending MAX_WIDTH (2048) to be safe.
    dut._log.info("Flushing pipeline with dummy data...")
    for _ in range(2048):
        dut.char_in.value = ord('.')
        dut.valid_in.value = 1
        await RisingEdge(dut.clk)

    dut.valid_in.value = 0
    await RisingEdge(dut.clk)
    
    # Wait a few cycles for pipeline to flush
    for _ in range(20):
        await RisingEdge(dut.clk)
    
    # 5. Check Result
    actual_val = int(dut.total_accessible.value)
    
    dut._log.info(f"FPGA Result: {actual_val}")
    
    assert actual_val == expected_val, f"Mismatch! FPGA={actual_val}, Exp={expected_val}"
    dut._log.info("Test Passed!")
