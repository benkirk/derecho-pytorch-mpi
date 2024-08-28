#!/usr/bin/env bash

# run via:
# conda-build ./conda-recipes/mpi4py

source profile.d/modules.sh >/dev/null 2>&1
module unload ncarcompilers cudnn  >/dev/null 2>&1
module list

pwd

export MPI4PY_BUILD_MPICC=$(which mpicc)
#export MPI4PY_BUILD_CONFIGURE=1

echo "SRC_DIR=${SRC_DIR}"
echo "PYTHON=${PYTHON}"
echo "MPI4PY_BUILD_MPICC=${MPI4PY_BUILD_MPICC}"

conda list

#activate_env=false
#source config_env.sh
#module list

which python
which pip
which conda
which mpicc

python -m \
       pip install \
       --no-deps --verbose \
       https://github.com/mpi4py/mpi4py/releases/download/${PKG_VERSION}/mpi4py-${PKG_VERSION}.tar.gz
