#!/usr/bin/env bash

top_dir=$(git rev-parse --show-toplevel)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

for PYTORCH_VERSION in "2.4.0" "2.3.1" "2.2.2"; do

    source ${top_dir}/config_env.sh || exit 1

    make clean {install,build}-pbs
done
