#!/usr/bin/env bash

set -e

top_dir=$(git rev-parse --show-toplevel)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

source ${top_dir}/config_env.sh

PYTHONS=("3.12" "3.11" "3.10")
PYTORCHS=("2.4.1" "2.3.1" "2.2.2")

for ENV_PYTHON_VERSION in "${PYTHONS[@]}" ; do

    for PYTORCH_VERSION in "${PYTORCHS[@]}"; do
        source ${top_dir}/config_env.sh
        make clean || make clean || make clean # <-- occasionally the first 'git clean -xdf' omits warnings...
        make build-pbs
    done

done
