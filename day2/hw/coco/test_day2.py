import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

@cocotb.test()
async def test_solution(dut):
    clock = Clock(dut.clk, 40, units="ns") # 25MHz
    cocotb.start_soon(clock.start())
    
    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0
    
    # Wait for done
    # 20k items * cycles. 50k cycles should be enough.
    for i in range(100000):
        if dut.done.value == 1:
            break
        await RisingEdge(dut.clk)
        
    assert dut.done.value == 1, "Simulation did not finish!"
    
    val = int(dut.total_sum.value)
    expected = 1227775554
    dut._log.info(f"Got Sum: {val}, Expected: {expected}")
    assert val == expected
