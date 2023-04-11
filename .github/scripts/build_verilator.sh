# Source this file

export CCACHE_DIR="$PWD/ccache"

if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

git clone https://github.com/verilator/verilator
pushd verilator

if [ "$RUNNER_OS" = "Linux" ]; then  # Ubuntu
    sudo apt update
    sudo apt install -y git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 autoconf flex bison perl perl-doc numactl libfl2 libfl-dev verilator help2man
fi

autoconf
./configure CC='ccache g++'
make -j `nproc` && sudo make install

export PATH=`pwd`/bin:$PATH
export VERILATOR_ROOT="$PWD"
popd

ccache -s
