#!/usr/bin/env bash

for PYTORCH_VERSION in "2.4.0" "2.3.1" "2.2.2"; do

    source config_env.sh || exit 1

    make clean {install,build}-pbs
done
