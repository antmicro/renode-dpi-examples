cmake_minimum_required(VERSION 3.8)

# Name of the project
project(apb3_base_mem)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES apb3_completer_mem.sv)

set(APB3_DATA_WIDTH 32 CACHE STRING "Width of data channels in the APB3 bus")

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(VERILATOR_ARGS --timing --assert -GAPB3BusDataWidth=${APB3_DATA_WIDTH})

# Questa variables
set(QUESTA_OPTIMIZATION_ARGS -GAPB3BusDataWidth=${APB3_DATA_WIDTH})

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
