cmake_minimum_required(VERSION 3.8)

# Name of the project
project(apb3_base_mem)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES apb3_completer_mem.sv)

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(VERILATOR_ARGS --timing --assert)

# Questa variables
set(QUESTA_ARGS "")
set(QUESTA_OPTIMIZATION_ARGS -floatparameters+ReceiverPort+SenderPort+Address)

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
