#!/bin/bash
#PBS -A SCSG0001
#PBS -q main
#PBS -l select=1:ncpus=64:mpiprocs=64:ngpus=4
#PBS -l walltime=1:00:00

set -e

# This script will download, patch, build, and install NCCL and AWS-OFI-NCCL.
# NCCL tests can then be built in a container or baremetal for testing.
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
top_dir="${script_dir}/.." #$(git rev-parse --show-toplevel)

source ${top_dir}/profile.d/modules.sh || exit 1
module unload cray-mpich mkl

export INSTALL_DIR="${INSTALL_DIR:-${top_dir}/nccl-ofi/${NCAR_BUILD_ENV_COMPILER}}"
export NCCL_HOME=${INSTALL_DIR}
export LIBFABRIC_HOME=/opt/cray/libfabric/1.15.2.0
export MPI_HOME=${CRAY_MPICH_DIR}

export NVCC_GENCODE="-gencode=arch=compute_80,code=sm_80"

export N=10
export MPICC=/bin/false
export CC=$(which gcc)
export CXX=$(which g++)

build_dir=${top_dir}/build-${NCAR_BUILD_ENV_COMPILER}
rm -rf ${build_dir}
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
./configure --with-cuda=${CUDA_HOME} --with-libfabric=${LIBFABRIC_HOME} --prefix=${INSTALL_DIR} --disable-tests LDFLAGS="-Wl,-rpath,${LIBFABRIC_HOME}/lib64"
make -j ${N} install

cd ${script_dir}
rm -rf ${build_dir}

# symlink latest installed varsion path
cd ${INSTALL_DIR}/.. && rm -f ./install && ln -s ${NCAR_BUILD_ENV_COMPILER} ./install
