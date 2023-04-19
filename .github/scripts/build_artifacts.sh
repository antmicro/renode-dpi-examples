# Source this file

ARTIFACTS_DIR="$PWD/artifacts"
mkdir -p $ARTIFACTS_DIR


if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

pushd cosim_bfm_library
pushd lib_bfm
make -f Makefile.lib_bfm cleanup
make INCLUDES=../../verilator/include/vltstd -f Makefile.lib_bfm
make -f Makefile.lib_bfm install
popd
pushd verilator-build
verilator --timing --cc -Wno-WIDTH cosim_bfm_axi_dpi.sv top.v mem_axi_beh.v -exe Vcosim_bfm_axi_dpi__main.cpp cosim_bfm_api.c cosim_bfm_dpi.c cosim_ipc.c
make -C obj_dir/ -f Vcosim_bfm_axi_dpi.mk
popd
popd

cp `find . -name Vcosim_bfm_axi_dpi` $ARTIFACTS_DIR
cp `find . -name libcosim_bfm.so` $ARTIFACTS_DIR

ls -lh $ARTIFACTS_DIR
