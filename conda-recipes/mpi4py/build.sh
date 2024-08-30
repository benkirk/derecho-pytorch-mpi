#!/usr/bin/env bash

# run via:
# conda-build --output-folder output/ ./mpi4py 2>&1 | tee conda_build_mpi4py.log

source modules.sh >/dev/null 2>&1
module unload ncarcompilers cudnn >/dev/null 2>&1
module list

export MPI4PY_BUILD_MPICC=$(which mpicc)
#export MPI4PY_BUILD_CONFIGURE=1 #

echo "SRC_DIR=${SRC_DIR}"
echo "PYTHON=${PYTHON}"
echo "MPI4PY_BUILD_MPICC=${MPI4PY_BUILD_MPICC}"
echo "BUILD_STRING=${BUILD_STRING}"

which python
which pip
which mpicc

python -m \
       pip install \
       --no-deps --verbose \
       https://github.com/mpi4py/mpi4py/releases/download/${PKG_VERSION}/mpi4py-${PKG_VERSION}.tar.gz
