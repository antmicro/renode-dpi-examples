cmake_minimum_required(VERSION 3.8)

# Name of the project
project(axi_ram)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES axi_ram.v)

# Verilator variables
set(VERILATOR_CSOURCES ../../cpp/sim_main_dpi.cpp)
set(AXI_DATA_WIDTH 64 CACHE STRING "Width of data channels in the AXI data bus")
set(VERILATOR_ARGS -Wno-WIDTH -Wno-CASEINCOMPLETE -Wno-UNSIGNED --timing -GAXIDataWidth=${AXI_DATA_WIDTH})

# Questa variables
set(QUESTA_ARGS "")
set(QUESTA_OPTIMIZATION_ARGS -floatparameters+ReceiverPort+SenderPort+Address -GAXIDataWidth=${AXI_DATA_WIDTH})

# Xcelium variables
set(XCELIUM_ARGS -sv -elaborate -defparam sim.AXIDataWidth=${AXI_DATA_WIDTH} -top ${SIM_TOP})

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
