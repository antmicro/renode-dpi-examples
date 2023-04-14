#!/bin/bash
set -eu

if [ "$RUNNER_OS" = "Linux" ]; then  # Ubuntu
    RENODE_ARCHIVE=renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz
    wget --progress=dot:giga "https://dl.antmicro.com/projects/renode/builds/custom/$RENODE_ARCHIVE"
    mkdir -p renode
    tar xf "$RENODE_ARCHIVE" --strip-components 1 -C renode
fi

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    RENODE_ARCHIVE=renode_1.13.2+20230412git4d56db3f.zip
    wget --progress=dot:giga "https://dl.antmicro.com/projects/renode/builds/custom/$RENODE_ARCHIVE"
    unzip "$RENODE_ARCHIVE"
    mv "$RENODE_ARCHIVE" renode
fi

rm $RENODE_ARCHIVE

pip install -r renode/tests/requirements.txt
