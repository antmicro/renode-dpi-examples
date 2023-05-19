# Source this file

ARTIFACTS_DIR="$PWD/artifacts"
mkdir -p $ARTIFACTS_DIR


if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

pushd cosim_bfm_library

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    export CPATH="/mingw64/include/iverilog"
    export LIBRARY_PATH="/mingw64/lib"
fi

pushd lib_bfm
make -f Makefile.lib_bfm cleanup
make INCLUDES=../../verilator/include/vltstd -f Makefile.lib_bfm
make -f Makefile.lib_bfm install
popd
pushd verilator-build
verilator \
  -I../include/verilog --timing --cc \
  -Wno-WIDTH -Wno-CASEINCOMPLETE \
  ../lib_bfm/verilog/cosim_bfm_axi_dpi.sv \
  ../verification/test_axi_dpi_vpi/hw/design/verilog/top.v \
  ../verification/test_axi_dpi_vpi/hw/design/verilog/mem_axi_beh.v \
  -exe \
  Vcosim_bfm_axi_dpi__main.cpp \
  ../lib_bfm/c/cosim_bfm_api.c \
  ../lib_bfm/c/cosim_bfm_dpi.c \
  ../lib_ipc/src/cosim_ipc.c

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
