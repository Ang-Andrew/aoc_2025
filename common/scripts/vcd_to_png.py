import argparse
import matplotlib.pyplot as plt
from vcdvcd import VCDVCD
import sys

def main():
    parser = argparse.ArgumentParser(description='Convert VCD to PNG waveform')
    parser.add_argument('vcd_file', help='Input VCD file')
    parser.add_argument('output_png', help='Output PNG file')
    parser.add_argument('--signals', nargs='+', help='List of signals to plot (e.g. top.clk top.rst)', required=True)
    parser.add_argument('--start', type=int, default=0, help='Start time')
    parser.add_argument('--end', type=int, default=None, help='End time')
    
    args = parser.parse_args()
    
    try:
        vcd = VCDVCD(args.vcd_file)
    except Exception as e:
        print(f"Error loading VCD: {e}")
        sys.exit(1)

    # Setup plot
    num_signals = len(args.signals)
    fig, axes = plt.subplots(num_signals, 1, sharex=True, figsize=(10, 2 * num_signals))
    if num_signals == 1:
        axes = [axes]

    for i, signal_name in enumerate(args.signals):
        ax = axes[i]
        try:
            # vcdvcd returns (time, value) tuples or similar
            # vcd[signal] returns a Signal object which has .tv attribute (list of (time, value))
            sig = vcd[signal_name]
            t_v = sig.tv # List of (time, value)
            
            # Unzip
            times = [float(t) for t, v in t_v]
            values = []
            for t, v in t_v:
                try:
                    val = int(v, 2) # Binary string to int
                except:
                   # specific check for 'x', 'z'
                   if v == 'x': val = 0 # Handle x as 0 or undefined
                   elif v == 'z': val = 0
                   else: val = float(v)
                values.append(val)
                
            # Step plot
            ax.step(times, values, where='post')
            ax.set_ylabel(signal_name)
            ax.grid(True)
            
            # Limits
            if args.start is not None:
                ax.set_xlim(left=args.start)
            if args.end is not None:
                ax.set_xlim(right=args.end)
                
        except KeyError:
            print(f"Signal {signal_name} not found in VCD.")
            # Only print all signals once to avoid spam
            if 'printed_signals' not in locals():
               print("Available signals:")
               print(list(vcd.signals))
               locals()['printed_signals'] = True
            ax.text(0.5, 0.5, f"Signal {signal_name} not found", ha='center', va='center')
        except Exception as e:
            print(f"Error plotting {signal_name}: {e}")

    plt.xlabel('Time')
    plt.tight_layout()
    plt.savefig(args.output_png)
    print(f"Saved waveform to {args.output_png}")

if __name__ == '__main__':
    main()
