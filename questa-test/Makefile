worklib:
	vlib work

compile:  ../cosim_bfm_library/verilator-build/cosim_bfm_axi_dpi.sv ../cosim_bfm_library/verilator-build/top.v ../cosim_bfm_library/verilator-build/mem_axi_beh.v ../cosim_bfm_library/verilator-build/cosim_bfm_api.c ../cosim_bfm_library/verilator-build/cosim_bfm_dpi.c ../cosim_bfm_library/verilator-build/cosim_ipc.c
	vlog ../cosim_bfm_library/verilator-build/cosim_bfm_axi_dpi.sv ../cosim_bfm_library/verilator-build/top.v ../cosim_bfm_library/verilator-build/mem_axi_beh.v -dpiheader ../cosim_bfm_library/verilator-build/dpi_types.h ../cosim_bfm_library/verilator-build/cosim_bfm_api.c ../cosim_bfm_library/verilator-build/cosim_bfm_dpi.c ../cosim_bfm_library/verilator-build/cosim_ipc.c

optimize:
	vopt top -o top_opt

sim:
	vsim top_opt

all: worklib compile optimize sim

clean:
	rm -rf work transcript vsim.wlf dpi_types.h
