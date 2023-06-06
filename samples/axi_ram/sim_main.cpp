//
// Copyright (c) 2010-2021 Antmicro
//
//  This file is licensed under the MIT License.
//  Full license text is available in 'LICENSE' file.
//
#include <verilated.h>
#include "Vsim.h"
#include <verilated_vcd_c.h>
#include "src/renode_dpi.h"

int main(int argc, char **argv, char **env)
{
    if (argc < 3)
    {
        printf("Usage: %s {receiverPort} {senderPort} {address}\n", argv[0]);
        exit(-1);
    }
    const char *address = argc < 3 ? "127.0.0.1" : argv[3];
    renodeDPIConnect(atoi(argv[1]), atoi(argv[2]), address);

    VerilatedContext *contextp = new VerilatedContext;
    contextp->commandArgs(argc, argv);
    Vsim *top = new Vsim{contextp};

    Verilated::traceEverOn(true);
    VerilatedVcdC *tfp = new VerilatedVcdC;
    top->trace(tfp, 99);
    tfp->open("sim.vcd");

    while (!contextp->gotFinish())
    {
        top->eval();
        tfp->dump(contextp->time());
        if (!top->eventsPending()) break;
        contextp->time(top->nextTimeSlot());
    }

    tfp->close();
    delete top;
    delete contextp;
    return 0;
}
