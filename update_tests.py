import os

# Configuration for each day
# Day: (HW_Output_Signal, Python_Function_Call_Format, Python_Return_Tuple_Index (None if scalar))
DAYS_CONFIG = {
    2: ("total_sum", "solve(input_path)", None),
    3: ("total_joltage", "solve(open(input_path).read())", None),
    # Day 4 is special (needs driver), handled separately or with special template
    5: ("count", "solve(input_path)", None),
    6: ("count", "solve(input_path)", None),
    7: ("active_count", "solve(input_path)", 1), # returns (splitters, beams)
    8: ("product_max", "solve(input_path, 1000)", None),
    9: ("max_area", "solve(input_path)", None),
    10: ("total_presses", "solve(input_path)", None),
    11: ("total_paths", "solve(input_path)", None),
}

TEMPLATE = """import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer
import os
import sys

@cocotb.test()
async def test_{day}_solution(dut):
    \"\"\"
    Compare FPGA Solution against Python Reference for {day}
    \"\"\"
    
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

    dut._log.info(f"Adding {{sw_dir}} to PYTHONPATH")
    sys.path.append(sw_dir)

    # 2. Run Python Reference
    try:
        from solution import solve
    except ImportError:
        dut._log.error(f"Could not import solve from {{sw_dir}}")
        raise

    dut._log.info(f"Running Python Reference on {{input_path}}...")
    
    # Execute Python Solve
    val = {solve_call}
    expected_val = {process_result}
    
    dut._log.info(f"Python Reference Expected Value: {{expected_val}}")

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
        await RisingEdge(dut.clk) # One more for stability
    else:
        # Fallback or specific handling
        await Timer(100, units='us')

    
    # 5. Check Result
    actual_val = int(dut.{hw_signal}.value)
    
    dut._log.info(f"FPGA Result: {{actual_val}}")
    
    assert actual_val == expected_val, f"Mismatch! FPGA={{actual_val}}, Exp={{expected_val}}"
    dut._log.info("Test Passed!")
"""

def generate_tests():
    for day, (signal, call, tuple_idx) in DAYS_CONFIG.items():
        process_res = "val"
        if tuple_idx is not None:
            process_res = f"val[{tuple_idx}]"
            
        content = TEMPLATE.format(
            day=f"day{day}",
            solve_call=call,
            process_result=process_res,
            hw_signal=signal
        )
        
        path = f"day{day}/hw/verif/test_day{day}.py"
        print(f"Writing {path}...")
        with open(path, 'w') as f:
            f.write(content)

if __name__ == "__main__":
    generate_tests()
