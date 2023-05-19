# Source this file

export CCACHE_DIR="$PWD/ccache"

if [ -z "$RUNNER_OS" -o -z "$MAKE_BIN" ]; then
    echo "Not all required environment variables set (RUNNER_OS, MAKE_BIN)!"
    exit -1
fi

git clone https://github.com/verilator/verilator
pushd verilator

git checkout 46f719ceaaa658a2c51cf974b548b635fc276593

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    pacman --noconfirm -S --needed autoconf bison flex mingw-w64-x86_64-python mingw-w64-x86_64-python-pip mingw-w64-x86_64-ccache mingw-w64-x86_64-autotools gperf
    cp /usr/include/FlexLexer.h include/
    cp ../patches/verilator/svdpi.h include/vltstd/svdpi.h
fi

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
