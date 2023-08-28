cmake_minimum_required(VERSION 3.8)

# Name of the project
project(apb3_synth)

# Verilog file containing the simulation top module
set(SIM_TOP sim)
set(SIM_TOP_FILE sim.sv)
set(SIM_FILES
            ../../samples/apb3_requester_synth/apb3_mux.sv
            ../../samples/apb3_requester_synth/apb3_transfer_counter.sv
            ../../samples/apb3_requester_synth/apb3_transfer.sv
            ../../samples/apb3_requester_synth/apb3_requester_synth.sv
            ../../samples/apb3_completer_mem/apb3_completer_mem.sv
)

# Verilator variables
set(VERILATOR_CSOURCES sim_main.cpp)
set(VERILATOR_ARGS --timing --assert)

# Questa variables
set(QUESTA_ARGS "")
set(QUESTA_OPTIMIZATION_ARGS "")

# CMake file doing the hard job
include(../../cmake/build-cosimulation.cmake)
