#include "Vcore.h"

#include <iostream>
#include <fstream>
#include <memory>
#include <verilated.h>

using namespace std;

void LoadProgramAndData(char* prog_file, char* data_file, const unique_ptr<Vcore> &top);
void Tick(const unique_ptr<Vcore> &top);

vluint64_t main_time = 0;

double sc_time_stamp() {
    return main_time;
}

int main(int argc, char** argv) {

    if (argc != 4) {
        cout << "Invalid arguments. Expected: ./core_testbench [program file name] [data file name]" << endl;
        return 1;
    }

    Verilated::mkdir("logs");
    Verilated::debug(0);
    Verilated::commandArgs(argc, argv);
    Verilated::traceEverOn(true);

    const unique_ptr<Vcore> top{new Vcore};

    LoadProgramAndData(argv[1], argv[2], top);

    long num_branch_ops_handled = 0;
    long num_branch_preds_correct = 0;
    for (int i = 0; !top->halted; i++) {
        if (top->handling_branch_op_out) {
            num_branch_ops_handled++;
            if (!top->is_branching) {
                num_branch_preds_correct++;
            }
        }
        
        Tick(top);
    }

    top->final();

    cout << "Total branch ops handled: " << num_branch_ops_handled << endl;
    cout << "Total branch preds correct: " << num_branch_preds_correct << endl;

    return 0;
}

void Tick(const unique_ptr<Vcore> &top) {
    top->clk = !top->clk;
    top->eval();
    main_time++;
    top->clk = !top->clk;
    top->eval();
    main_time++;
}

// Resets the core and loads the program into the instruction memory
// Returns with clk at 0 and core at the start of the first "do" stage
void LoadProgramAndData(char* prog_file, char* data_file, const unique_ptr<Vcore> &top) {
    ifstream pf, df;

    pf.open(prog_file, ifstream::in);
    df.open(data_file, ifstream::in);
    
    top->reset = 1;
    Tick(top);
    Tick(top);
    top->reset = 0;
    Tick(top);

    uint32_t data = 0;
    uint32_t address = 0;
    string s;
    top->im_lden = 1;
    while (pf.good()) {
        getline(pf, s);
        if (s.length() <= 0) {
            break;
        }
        data = stol(s, nullptr, 16);
        top->inst_ld_data = data;
        top->inst_ld_addr = address;
        address += 4;
        Tick(top);
    }

    top->im_lden = 0;
    top->dm_lden = 1;
    address = 0;
    while (df.good()) {
        getline(df, s);
        if (s.length() <= 0) {
            break;
        }
        data = stol(s, nullptr, 16);
        top->word_ld_data = data;
        top->word_ld_addr = address;
        address += 4;
        Tick(top);
    }
    top->dm_lden = 0;

    top->start = 1;
    Tick(top);
    top->start = 0;

}
