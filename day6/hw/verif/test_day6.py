import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os
import sys

@cocotb.test()
async def test_day6_solution(dut):
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
        exp_count = solve(input_path)
        dut._log.info(f"Python Reference Count: {exp_count}")
    except ImportError:
        dut._log.warning("Could not import python solution.")
        exp_count = None

    clock = Clock(dut.clk, 4, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # 4. Wait for Done with Timeout
    for i in range(10000):
        await RisingEdge(dut.clk)
        if dut.done.value == 1:
            break
        if i % 1000 == 0:
            dut._log.info(f"Cycle {i}, x={dut.x.value}, state={dut.state.value}")
    else:
        dut._log.error("Timeout waiting for done!")
        assert False, "Timeout"
    
    try:
        final_count = int(dut.count.value)
        dut._log.info(f"FPGA Count: {final_count}")
        if exp_count is not None:
            assert final_count == exp_count
    except ValueError as e:
        dut._log.error(f"FPGA Count is invalid (X/Z): {dut.count.value}")
        dut._log.error(f"Collected Count: {dut.collected_count.value}")
        dut._log.error(f"Current Op: {dut.current_op.value}")
        raise e
