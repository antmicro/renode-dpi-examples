#!/bin/bash
set -eu

if [ "$RUNNER_OS" = "Linux" ]; then  # Ubuntu
    RENODE_ARCHIVE=renode-1.13.3+20230511gitf5c1564c.linux-portable.tar.gz
    wget --progress=dot:giga "https://dl.antmicro.com/projects/renode/custom_builds/$RENODE_ARCHIVE"
    mkdir -p renode
    tar xf "$RENODE_ARCHIVE" --strip-components 1 -C renode
    pip install -r renode/tests/requirements.txt
fi

if [ "$RUNNER_OS" = "Windows" ]; then  # MSYS2
    RENODE_ARCHIVE=renode-1.13.3+20230511gitf5c1564c.zip
    wget --progress=dot:giga "https://dl.antmicro.com/projects/renode/custom_builds/$RENODE_ARCHIVE"
    unzip "$RENODE_ARCHIVE"
    mv $(basename "$RENODE_ARCHIVE" .zip) renode
    $WINDOWS_PYTHON_PATH -m pip install -r renode/tests/requirements.txt
fi
