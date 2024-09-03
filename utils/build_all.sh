#!/usr/bin/env bash

top_dir=$(git rev-parse --show-toplevel)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for ENV_PYTHON_VERSION in "3.12" "3.11" "3.10"; do
    for PYTORCH_VERSION in "2.4.0" "2.3.1" "2.2.2"; do
        source ${top_dir}/config_env.sh || exit 1

        #make clean {install,build}-pbs
        make -C conda-recipes conda-build-torch
        make -C conda-recipes conda-build-vision
    done
done
#exit 0

for MPI4PY_VERSION in "4.0.0" "3.1.6"; do

    source ${top_dir}/config_env.sh || exit 1

    make -C conda-recipes conda-build-mpi4py
done
