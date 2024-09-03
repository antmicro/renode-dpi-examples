cmake_minimum_required(VERSION 3.8)

# Name of the project
project(apb3_base_mem)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES apb3_completer_mem.sv)

# TODO: Tests currently assume 32 bits, changing this will cause them to fail.
#    Modify the tests to work with all possible bus widths.
set(APB3_DATA_WIDTH 32 CACHE STRING "Width of data channels in the APB3 bus")

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(VERILATOR_ARGS --timing --assert -GAPB3BusDataWidth=${APB3_DATA_WIDTH})

# Questa variables
set(QUESTA_ARGS "")
set(QUESTA_OPTIMIZATION_ARGS -floatparameters+ReceiverPort+SenderPort+Address -GAPB3BusDataWidth=${APB3_DATA_WIDTH})

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
