#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -l select=1:ncpus=64:mpiprocs=64:ngpus=4
#PBS -l walltime=1:00:00

# This script will download, patch, build, and install NCCL and AWS-OFI-NCCL.
# NCCL tests can then be built in a container or baremetal for testing.
top_dir=$(git rev-parse --show-toplevel)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

module reset >/dev/null 2>&1
module load gcc/12.2.0 cuda/12.2.1 >/dev/null 2>&1
module list

export INSTALL_DIR=${top_dir}/nccl-ofi/${NCAR_BUILD_ENV}
export PLUGIN_DIR=${INSTALL_DIR}/aws-ofi-nccl-plugin
export NCCL_HOME=${INSTALL_DIR}
export LIBFABRIC_HOME=/opt/cray/libfabric/1.15.2.0
export GDRCOPY_HOME=/usr
export MPI_HOME=${CRAY_MPICH_DIR}

export NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80"

export N=10
export MPICC=$(which mpicc)
export CC=$(which gcc)
export CXX=$(which g++)

build_dir=${top_dir}/build-${NCAR_BUILD_ENV}
rm -rf ${build_dir} ${INSTALL_DIR}
mkdir -p ${build_dir} || exit 1

echo "========== BUILDING NCCL =========="
cd ${build_dir} || exit 1
git clone --branch v2.21.5-1 https://github.com/NVIDIA/nccl.git || exit 1
cd nccl || exit 1
make -j ${N} PREFIX=${NCCL_HOME} src.build || exit 1
make PREFIX=${NCCL_HOME} install || exit 1

echo "========== BUILDING OFI PLUGIN =========="
cd ${build_dir} || exit 1
git clone -b v1.6.0 https://github.com/aws/aws-ofi-nccl.git || exit 1
cd aws-ofi-nccl || exit 1
./autogen.sh || exit 1
./configure --with-cuda=${CUDA_HOME} --with-libfabric=${LIBFABRIC_HOME} --prefix=${PLUGIN_DIR} --with-gdrcopy=${GDRCOPY_HOME} --disable-tests || exit 1
make -j ${N} install  || exit 1

cd ${script_dir} || exit 1
rm -rf ${build_dir} || exit 1

echo "========== PREPARING DEPENDENCIES =========="
set -x
mkdir -p ${PLUGIN_DIR}/deps/lib
cp -P $(cat ${script_dir}/nccl-ofi-dependencies.txt) ${PLUGIN_DIR}/deps/lib/

# symlink latest installed varsion path
cd ${INSTALL_DIR}/.. && rm -f ./install && ln -s ${NCAR_BUILD_ENV} ./install
