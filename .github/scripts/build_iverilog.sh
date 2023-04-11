# Source this file

if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

git clone https://github.com/steveicarus/iverilog.git
pushd iverilog
sh autoconf.sh
./configure
make -j `nproc` && sudo make install
popd
