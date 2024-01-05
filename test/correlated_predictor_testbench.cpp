#include "Vcorrelated_predictor.h"

#include <iostream>
#include <fstream>
#include <memory>
#include <verilated.h>

using namespace std;

void Tick(const unique_ptr<Vcorrelated_predictor> &top);

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {

    Verilated::mkdir("logs");
    Verilated::debug(0);
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    const unique_ptr<Vcorrelated_predictor> top{new Vcorrelated_predictor};

    top->reset = 1;
    Tick(top);
    Tick(top);
    top->reset = 0;
    Tick(top);

    for (int i = 0; i < 100; i++) {
        top->update = 1;
        top->taken = rand() % 2;
        Tick(top);
        top->update = 0;
        Tick(top);
        Tick(top);
    }

    top->final();

    return 0;
}

void Tick(const unique_ptr<Vcorrelated_predictor> &top) {
    top->clk = !top->clk;
    top->eval();
    main_time++;
    top->clk = !top->clk;
    top->eval();
    main_time++;
}
