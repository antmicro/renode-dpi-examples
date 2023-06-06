#! /usr/bin/env bash

set -eux

export CCACHE_DIR="$PWD/ccache"

if [ -z "$RUNNER_OS" ]; then
    echo "Not all required environment variables set (RUNNER_OS)!"
    exit -1
fi

git clone --depth 1 --branch $VERILATOR_GIT_REF https://github.com/verilator/verilator
cd verilator

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    pacman --noconfirm -S --needed autoconf bison flex help2man mingw-w64-x86_64-python mingw-w64-x86_64-python-pip mingw-w64-x86_64-ccache mingw-w64-x86_64-autotools gperf
    cp /usr/include/FlexLexer.h include/
fi

if [ "$RUNNER_OS" = "Linux" ]; then  # Ubuntu
    sudo apt update
    sudo apt install -y git cmake ninja-build gperf ccache dfu-util device-tree-compiler wget python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file make gcc gcc-multilib g++-multilib libsdl2-dev libmagic1 autoconf flex bison perl perl-doc numactl libfl2 libfl-dev verilator help2man
fi

autoconf
./configure CC="ccache $CXX"
make -j `nproc`

ccache -s
