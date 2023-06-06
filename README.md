# renode-dpi-examples

Copyright (c) 2023 [Antmicro](https://www.antmicro.com)

Example integration between [Renode](https://renode.io/) and a Verilog model using DPI (SystemVerilog Direct Programming Interface) calls.

All samples are intended to work in both [Verilator](https://www.veripool.org/verilator/) and [Questa](https://www.intel.com/content/www/us/en/software/programmable/quartus-prime/questa-edition.html) simulators. This repository contains a CI configured to build and run samples in Verilator. Looking at [the CI configuration](/.github/workflows/dpi-examples.yml) is a good way to reproduce an example, but you can follow the instructions below, especially if you use Questa.

## Architecture
Renode communicates with the simulator over TCP using a dedicated protocol. The library which implements this protocol can be found in Renode sources. It's mainly written in C++, but there is an additional wrapper written in SystemVerilog, which uses DPI calls to interact with the API written in C++.

The HDL top simulation file contains Renode related snippets:
* an include compiler directive with the required SystemVerilog files
* code initializing a connection (with ports and IP address passed from parameters of a module)
* code resetting a bus
* code used to receive and handle messages 

> **Note**  
> The code intentionally blocks the elapse of the simulation time while waiting for a message.

## Usage

### Building Verilator
For simplicity, build Verilator in the `verilator` directory inside this repository to use unmodified commands from this README.

#### Linux
Use command below to build Verilator.
```bash
sudo apt update
sudo apt install -y git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 autoconf flex bison perl perl-doc numactl libfl2 libfl-dev verilator help2man
git clone https://github.com/verilator/verilator.git
cd verilator
git checkout v5.010
autoconf
./configure CC='ccache g++'
make -j `nproc`
```

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

### Bulding a sample

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

### Testing
Run in the repository root

#### Linux
```bash
renode/renode-test samples/axi_ram/tests.robot
```
> **Note**  
> You can add `--include verilator` or `--include questa` arguments to run tests for only one simulator.

#### Windows

```cmd
renode\bin\renode-test.bat samples\axi_ram\tests.robot --variable=VERILATED_BINARY:samples\axi_ram\build\verilated.exe
```

## Samples list
* [RAM as an AXI4 subordinate](/samples/axi_ram/axi_ram.v)
