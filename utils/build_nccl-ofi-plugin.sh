#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -l select=1:ncpus=64:mpiprocs=64:ngpus=4
#PBS -l walltime=1:00:00

set -e

# This script will download, patch, build, and install NCCL and AWS-OFI-NCCL.
# NCCL tests can then be built in a container or baremetal for testing.
top_dir=$(git rev-parse --show-toplevel)
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

module reset >/dev/null 2>&1
module load gcc/12.2.0 cuda/12.2.1 >/dev/null 2>&1
module list

export INSTALL_DIR=${top_dir}/nccl-ofi/${NCAR_BUILD_ENV}
export NCCL_HOME=${INSTALL_DIR}
export LIBFABRIC_HOME=/opt/cray/libfabric/1.15.2.0
export MPI_HOME=${CRAY_MPICH_DIR}

export NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80"

export N=10
export MPICC=$(which mpicc)
export CC=$(which gcc)
export CXX=$(which g++)

build_dir=${top_dir}/build-${NCAR_BUILD_ENV}
rm -rf ${build_dir} ${INSTALL_DIR}
mkdir -p ${build_dir}

echo "========== BUILDING NCCL =========="
cd ${build_dir}
git clone --branch v2.21.5-1 https://github.com/NVIDIA/nccl.git
cd nccl
make -j ${N} PREFIX=${NCCL_HOME} src.build
make PREFIX=${NCCL_HOME} install

echo "========== BUILDING OFI PLUGIN =========="
cd ${build_dir}
git clone -b v1.6.0 https://github.com/aws/aws-ofi-nccl.git
cd aws-ofi-nccl
./autogen.sh
./configure --with-cuda=${CUDA_HOME} --with-libfabric=${LIBFABRIC_HOME} --prefix=${INSTALL_DIR} --disable-tests
make -j ${N} install

cd ${script_dir}
rm -rf ${build_dir}

# symlink latest installed varsion path
cd ${INSTALL_DIR}/.. && rm -f ./install && ln -s ${NCAR_BUILD_ENV} ./install
