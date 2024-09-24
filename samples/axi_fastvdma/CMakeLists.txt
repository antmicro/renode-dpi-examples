cmake_minimum_required(VERSION 3.8)

# Name of the project
project(axi_ram)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES DMATop.v)

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(AXI_DATA_WIDTH 32 CACHE STRING "Width of data channels in the AXI data bus")
set(VERILATOR_ARGS --timing -GAXIDataWidth=${AXI_DATA_WIDTH})

# Questa variables
set(QUESTA_OPTIMIZATION_ARGS -GAXIDataWidth=${AXI_DATA_WIDTH})

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
