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
    top->clk = !top->clk;
    top->eval();
  }
  top->rst = 0;

  std::cout << "Simulation Started..." << std::endl;

  // 3. Run search (Timeout at 10 million cycles for the tiny test)
  uint64_t cycles = 0;
  while (!top->done && cycles < 10000000) {
    top->clk = 1;
    top->eval();
    top->clk = 0;
    top->eval();
    cycles++;
  }

  // 4. Report
  if (top->done) {
    std::cout << "--------------------------------" << std::endl;
    std::cout << "Simulation Done." << std::endl;
    std::cout << "Valid Regions (Solutions found): " << top->total_count
              << std::endl;
    std::cout << "Total Cycles: " << cycles << std::endl;
    std::cout << "--------------------------------" << std::endl;
  } else {
    std::cout << "TIMEOUT: Simulation exceeded cycle limit." << std::endl;
  }

  top->final();
  delete top;
  return 0;
}
