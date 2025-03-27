# renode-dpi-examples

Copyright (c) 2023 [Antmicro](https://www.antmicro.com)

Example integration between [Renode](https://renode.io/) and a Verilog model using DPI (SystemVerilog Direct Programming Interface) calls.

All samples are intended to work in both [Verilator](https://www.veripool.org/verilator/) and [Questa](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/questa-edition.html) simulators. This repository contains a CI configured to build and run samples in Verilator. Looking at [the CI configuration](/.github/workflows/dpi-examples.yml) is a good way to reproduce an example, but you can follow the instructions below, especially if you use Questa.

## Architecture
Renode communicates with the simulator over TCP using a dedicated protocol. The library which implements this protocol can be found in [Renode sources](https://github.com/renode/renode/tree/master/src/Plugins/CoSimulationPlugin). It's mainly written in C++, but there is an additional wrapper written in SystemVerilog, which uses DPI calls to interact with the API written in C++.

The HDL top simulation file contains Renode related snippets:
* code initializing a connection (with ports and IP address passed from parameters of a module)
* code creating modules and interfaces of busses
* code resetting a bus
* code used to receive and handle messages 

> **Note**  
> The code intentionally blocks the elapse of the simulation time while waiting for a message.

## Usage of prebuilt example

### Preparing Renode
The rest of this instruction assumes you have Renode in the `renode` directory inside this repository. You just need to download and extract it, and install dependencies for the Robot test framework. Follow the steps below.

#### Linux
Run commands
```bash
wget --progress=dot:giga https://builds.renode.io/renode-latest.linux-portable.tar.gz
mkdir renode
tar -xf renode-latest.linux-portable.tar.gz --strip-components 1 -C renode
python3 -m pip install -r renode/tests/requirements.txt
```

#### Windows
* Download [the Renode nightly package](https://builds.renode.io/renode-latest.zip)
* Extract it to the `renode` directory
* Run `python -m pip install -r renode/tests/requirements.txt`

### Running Linux on Zynq-7000 with verilated FastVDMA 
Run one of the commands below. It will start Renode and show two windows:
* Monitor which can be used to manage a simulation
* UART analyzer with terminal for interaction with Linux on Zynq-7000

This sample uses a prebuilt executable of a verilated [FastVDMA controller](https://github.com/antmicro/fastvdma). You can build the executable by yourself from [the sample directory](samples/axi_fastvdma/).

#### Linux
```bash
renode/renode -e start samples/axi_fastvdma_prebuilt/platform.resc
```

#### Windows
```cmd
renode\bin\Renode.exe -e start samples\axi_fastvdma_prebuilt\platform.resc
```

## Manual compilation

### Building Verilator
For simplicity, build Verilator in the `verilator` directory inside this repository to use unmodified commands from this README.  
Instead of building Verilator from source you can download the artifacts with Verilator, which is built on the CI.
You can find it in a specific run listed on [the Actions page](https://github.com/antmicro/renode-dpi-examples/actions?query=branch%3Amain).

#### Linux (Ubuntu)
Use command below to build Verilator.
```bash
sudo apt-get update && sudo apt-get install git help2man perl python3 make autoconf g++ flex bison ccache libgoogle-perftools-dev numactl perl-doc libfl2 libfl-dev zlibc zlib1g zlib1g-dev
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.018
autoconf
./configure
make -j `nproc`
```

### Preparing Renode
You can find an instruction on preparing Renode in [the previous section](/#preparing-renode).

### Building a sample

#### Linux
Run in `samples/axi_ram`
```bash
mkdir build
cd build
cmake .. -DUSER_RENODE_DIR=../../../renode -DUSER_VERILATOR_DIR=../../../verilator
make
```

> **Note**  
> Instead of using `-D` arguments you can set `RENODE_ROOT` or `VERILATOR_ROOT` environmental variables.  
> You may use a path to installed packages in both approaches i.e. `export RENODE_ROOT=/opt/renode` or `-DUSER_RENODE_DIR=/opt/renode`

#### Windows
To build a sample on Windows you need the dependencies listed below:
* `mingw32-make.exe`
* [CMake](https://cmake.org/download/)

A lot of MinGW toolchains contain required tools. The one of approaches is to download [the WinLibs archive](https://www.mingw-w64.org/downloads/#winlibscom), extract it and add to the PATH enviromental variable.

Run in CMD in `samples/axi_ram`
```cmd
mkdir build
cd build
cmake.exe .. -G "MinGW Makefiles" -DUSER_RENODE_DIR="..\..\..\renode" -DUSER_VERILATOR_DIR="..\..\..\verilator"
mingw32-make.exe
```

## Testing
There are tests for Verilator, Questa and VCS. If the cosimulation block executable is not found for some of them, the corresponding tests will be skipped.

To run tests, do the following from the repository root:

#### Linux
```bash
renode/renode-test samples/axi_ram/tests.robot
```

#### Windows

```cmd
renode\bin\renode-test.bat samples\axi_ram\tests.robot --variable=VERILATED_BINARY:samples\axi_ram\build\verilated.exe
```

## Running a sample manually
Instead of run an automatic test using the Robot Framework, you can manually run Renode and an external simulator.  

### Starting Renode
To run Renode with the [RESC script](https://renode.readthedocs.io/en/latest/basic/monitor-syntax.html#renode-script-syntax), which creates a platform, just execute one of the following commands in the repository root:
* `renode/renode samples/axi_ram/platform.resc` on Linux 
* `renode\bin\Renode.exe samples\axi_ram\platform.resc` on Windows

Renode communicates with a simulator over sockets and you will need communication parameters.
Run the `mem ConnectionParameters` command in [the Monitor](https://renode.readthedocs.io/en/latest/basic/monitor-syntax.html).

The output of the command consists of:
* the receiver port (later referenced to as `<ReceiverPort>`),
* the sender port (later referenced to as `<SenderPort>`),
* the IP address (later referenced to as `<Address>`).  

You will need to substitute placeholders in the following commands which use these parameters.
  
### Connecting to a simulator
                                         
You can use one of the following command to start the simulator and pass connection parameters:
* `samples/axi_ram/build/verilated +RENODE_RECEIVER_PORT=<ReceiverPort> +RENODE_SENDER_PORT=<SenderPort> +RENODE_ADDRESS=<Address>` for Verilator on Linux
* `samples\axi_ram\build\verilated.exe +RENODE_RECEIVER_PORT=<ReceiverPort> +RENODE_SENDER_PORT=<SenderPort> +RENODE_ADDRESS=<Address>` for Verilator on Windows
* `vsim design_optimized -work samples/axi_ram/build/work_questa -do "run -all" +RENODE_RECEIVER_PORT=<ReceiverPort> +RENODE_SENDER_PORT=<SenderPort> +RENODE_ADDRESS=\"<Address>\"` for Questa on Linux
* ``vsim design_optimized -work samples\axi_ram\build\work_questa -do "run -all" +RENODE_RECEIVER_PORT=<ReceiverPort> +RENODE_SENDER_PORT=<SenderPort> +RENODE_ADDRESS=\`"<Address>\`" -ldflags -lws2_32`` in Powershell for Questa on Windows

After starting the simulator establish a connection by executing the `mem Connect` command in the Renode Monitor.
No output indicates that Renode and the simulator are successfully connected.

> **Note**  
> Questa may not be responsive during simulation.  
> Instead of passing the `-do "run -all"` argument to Questa you may execute the `run -all` command in the transcript window.

### Interacting with the design
You can simply try the prepared setup by running the following commands in the Renode.
```
mem WriteDoubleWord 0x10 0x12345678
mem ReadDoubleWord 0x10
```

You can close the simulation by calling the `quit` command in the Renode Monitor.
It will also finish the HDL simulation.

## Samples list

|                                                 Sample name                                                 |                Function Description                 |
| :---------------------------------------------------------------------------------------------------------: | :-------------------------------------------------: |
|                                    [AXI RAM](/samples/axi_ram/axi_ram.v)                                    |                 *AXI4 Subordinate*                  |
| [DMATop](/samples/axi_fastvdma/DMATop.v) ([the FastVDMA controller](https://github.com/antmicro/fastvdma))  |     *AXI4-Lite Subordinate, AXI4 Manager, GPIO*     |
|                                   [AHB Memory](/samples/ahb_mem/mem_ahb.v)                                  |                 *AHB Subordinate*                   |
|                                 [Simple AHB DMA](/samples/ahb_dma/dma_ahb_simple.v)                         |       *AHB Subordinate, AHB Manager, GPIO*          |
|                                 [Simple AHB Manager](/samples/ahb_simple_manager/ahb_manager_synth.sv)      |                   *AHB Manager*                     |
|                 [APB3 Completer Memory](/samples/apb3_completer_mem/apb3_completer_mem.sv)                  |                  *APB3 Completer*                   |
|            [APB3 Requester Synthesizable](/samples/apb3_requester_synth/apb3_requester_synth.sv)            |                  *APB3 Requester*                   |
|                        [APB3 Standalone Simulation](/samples/apb3_standalone/sim.sv)                        | *APB3 Requester, APB3 Completer, without DPI usage* |
|                        [AXI interconnect](/samples/axi_interconnect/sim.sv)                                  | *Two AXI memories connected to Renode through an AXI interconnect* |
|                        [No interconnect](/samples/no_interconnect/sim.sv)                                   | *Two AXI managers and two AHB subordinates connected directly to Renode* |
