import os
import json

def get_report(day_path):
    report_path = os.path.join(day_path, "output", "report.json")
    if not os.path.exists(report_path):
        # Check Day 4 custom path
        if "day4" in day_path:
            report_path = os.path.join(day_path, "report.json")
            if not os.path.exists(report_path):
                return None
        else:
            return None
    
    try:
        with open(report_path, "r") as f:
            return json.load(f)
    except:
        return None

def main():
    days = [f"day{i}" for i in range(1, 13)]
    print(f"{'Day':<8} | {'Status':<10} | {'LUTs':<8} | {'FFs':<8} | {'BRAMs':<8} | {'Fmax (MHz)':<10}")
    print("-" * 70)
    
    for day in days:
        day_hw = os.path.join(day, "hw")
        report = get_report(day_hw)
        
        if report:
            util = report.get("utilization", {})
            luts = util.get("TRELLIS_COMB", {}).get("used", "N/A")
            ffs = util.get("TRELLIS_FF", {}).get("used", "N/A")
            brams = util.get("DP16KD", {}).get("used", "0")
            
            # Find fmax
            fmax = "N/A"
            fmax_data = report.get("fmax", {})
            for clk, data in fmax_data.items():
                if isinstance(data, dict):
                     fmax = f"{data.get('achieved', 0):.2f}"
                else:
                     fmax = f"{data:.2f}"
                break
            
            print(f"{day:<8} | {'SUCCESS':<10} | {luts:<8} | {ffs:<8} | {brams:<8} | {fmax:<10}")
        else:
            # Check if logs exist to see if it failed
            impl_log = os.path.join(day_hw, "output", "impl.log")
            if os.path.exists(impl_log):
                print(f"{day:<8} | {'FAILED':<10} | {'-':<8} | {'-':<8} | {'-':<8} | {'-':<10}")
            else:
                print(f"{day:<8} | {'NOT RUN':<10} | {'-':<8} | {'-':<8} | {'-':<8} | {'-':<10}")

if __name__ == "__main__":
    main()
