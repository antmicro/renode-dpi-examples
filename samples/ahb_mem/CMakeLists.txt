cmake_minimum_required(VERSION 3.8)

# Name of the project
project(ahb_mem)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES mem_ahb.v)

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(VERILATOR_ARGS --timing)

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
