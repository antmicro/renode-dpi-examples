# Source this file

ARTIFACTS_DIR="$PWD/artifacts"
mkdir -p $ARTIFACTS_DIR


if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

pushd cosim_bfm_library

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    # Adds <sys/types.h> to Windows includes
    # cosim_bfm_library expects headers in /usr/local/include/iverilog and libs in /usr/local/lib.
    # MSYS2 installer places those files in the following locations:
    export CPATH="/mingw64/include/iverilog"
    export LIBRARY_PATH="/mingw64/lib"
fi

pushd lib_bfm
make -f Makefile.lib_bfm cleanup
make INCLUDES=../../verilator/include/vltstd -f Makefile.lib_bfm
make -f Makefile.lib_bfm install
popd
pushd verilator-build
verilator --timing --cc -Wno-WIDTH cosim_bfm_axi_dpi.sv top.v mem_axi_beh.v -exe Vcosim_bfm_axi_dpi__main.cpp cosim_bfm_api.c cosim_bfm_dpi.c cosim_ipc.c

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    make PYTHON3="$WINDOWS_PYTHON_PATH" -C obj_dir/ -f Vcosim_bfm_axi_dpi.mk
else
    make -C obj_dir/ -f Vcosim_bfm_axi_dpi.mk
fi

popd
popd

cp `find . -name Vcosim_bfm_axi_dpi -o -name Vcosim_bfm_axi_dpi.exe` $ARTIFACTS_DIR
cp `find . -name libcosim_bfm.so` $ARTIFACTS_DIR

ls -lh $ARTIFACTS_DIR
