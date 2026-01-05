#include "Vsolution.h"
#include <cstdint>
#include <iostream>
#include <verilated.h>

// This is required for Verilator
double sc_time_stamp() { return 0; }

int main(int argc, char **argv) {
  Verilated::commandArgs(argc, argv);
  Vsolution *top = new Vsolution;

  // 1. Initialize
  top->clk = 0;
  top->rst = 1;

  // 2. Reset for a few cycles
  for (int i = 0; i < 20; i++) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
  }
  top->rst = 0;

  std::cout << "Simulation Started..." << std::endl;

  // 3. Run search (10 Billion cycles limit)
  uint64_t cycles = 0;
  while (!top->done && cycles < 10000000000ULL) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
    cycles++;
    if (cycles % 100000000 == 0) {
      std::cout << "Cycle Heartbeat: " << cycles / 1000000
                << "M. total_count so far: " << top->total_count << std::endl;
    }
  }

  // 4. Report
  if (top->done) {
    std::cout << "--------------------------------" << std::endl;
    std::cout << "Simulation Complete." << std::endl;
    std::cout << "Final Total Valid Regions: " << top->total_count << std::endl;
    std::cout << "Total Simulation Cycles: " << cycles << std::endl;
    std::cout << "--------------------------------" << std::endl;
  } else {
    std::cout << "TIMEOUT: Simulation exceeded 10 Billion cycles." << std::endl;
  }

  top->final();
  delete top;
  return 0;
}
