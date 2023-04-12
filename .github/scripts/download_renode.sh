#!/bin/bash
set -eu
wget --progress=dot:giga https://dl.antmicro.com/projects/renode/builds/custom/renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz

mkdir -p renode
tar xf renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz --strip-components 1 -C renode

rm renode-1.13.2+20230411git4d56db3f.linux-portable.tar.gz

pip install -r renode/tests/requirements.txt
