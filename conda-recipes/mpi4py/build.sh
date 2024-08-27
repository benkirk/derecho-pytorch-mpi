#!/usr/bin/env bash

# run via:
# conda-build ./conda-recipes/mpi4py

type module 2>/dev/null \
     || source /etc/profile.d/z00_modules.sh
env
echo && echo && echo

pwd

echo "Hello, World!!"
date | tee output.txt

echo "SRC_DIR=${SRC_DIR}"
echo "PYTHON=${PYTHON}"

conda list

activate_env=false
source config_env.sh
module unload cudnn >/dev/null 2>&1
module list

which python
which pip
which conda
which make
which mpicxx

# conda create \
#       --override-channels --channel conda-forge \
#       --prefix ./testenv python=3.11*

python -m pip install \
          --no-deps \
          https://github.com/mpi4py/mpi4py/releases/download/${PKG_VERSION}/mpi4py-${PKG_VERSION}.tar.gz

#conda activate ./testenv
#conda -y install conda-tree

exit 0
