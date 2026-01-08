import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
import os
import sys

@cocotb.test()
async def test_day8_solution(dut):
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
        # We need to pass the same K as used in make_hex
        # make_hex reads params.vh? No.
        # But simulation has params.vh compiled in.
        # We can try to read K from params?
        # Or just use 10 for example (as per make_hex log)
        # But if we use input.txt, K was 1000.
        # Check filename
        if "example.txt" in input_path:
            k = 10
        else:
            k = 1000
            
        exp_product = solve(input_path, k)
        dut._log.info(f"Python Reference Product: {exp_product} (K={k})")
    except ImportError:
        dut._log.warning("Could not import python solution.")
        exp_product = None

    clock = Clock(dut.clk, 4, unit="ns")
    cocotb.start_soon(clock.start())

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # Wait loop
    for i in range(100000):
        await RisingEdge(dut.clk)
        if dut.done.value == 1:
            break
            
    final_product = int(dut.product.value)
    dut._log.info(f"FPGA Product: {final_product}")
    
    if exp_product is not None:
        assert final_product == exp_product
