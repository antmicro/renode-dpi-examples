cmake_minimum_required(VERSION 3.8)

# Name of the project
project(axi_ram)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES axi_ram.v)

# Verilator variables
set(VERILATOR_CSOURCES sim_main.cpp)
set(VERILATOR_ARGS -Wno-WIDTH -Wno-CASEINCOMPLETE --trace --timing)

# Questa variables
set(QUESTA_ARGS "")
set(QUESTA_OPTIMIZATION_ARGS -floatparameters+ReceiverPort+SenderPort+Address)

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
