#!/bin/bash


export PYTORCH_VERSION="${PYTORCH_VERSION:-v2.3.1}"

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

#-------------------------------------------------------------------------------
# setup host environment
module --force purge
module load ncarenv/23.09 gcc/12.2.0 ncarcompilers cray-mpich/8.1.27 conda/latest cuda/12.2.1
case "${PYTORCH_VERSION}" in
    *"v2.4"*)
        module load cudnn/9.2.0.82-12
        ;;
    *)
        #module load cudnn/8.7.0.84-11.8
        #LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:/glade/u/apps/common/23.08/spack/opt/spack/cuda/11.8.0/targets/x86_64-linux/lib  # <-- required when using cudnn/8.7.0.84-11.8 with cuda/12.2.1 so cuDNN can locate libcublas.so.11
        module load cudnn/8.8.1.3-12
        ;;
esac
module list

env_name="pytorch-${PYTORCH_VERSION}-${NCAR_BUILD_ENV}"
env_dir="${script_dir}/${env_name}"

echo "PYTORCH_VERSION=${PYTORCH_VERSION}"
echo "NCAR_BUILD_ENV=${NCAR_BUILD_ENV}"
echo "env_dir=${env_dir}"


#-------------------------------------------------------------------------------
# build nccl with AWS libfabric plugin if needed
make -s -C ${script_dir} nccl-ofi

#-------------------------------------------------------------------------------
# clone pytorch source if needed
make -s -C ${script_dir} pytorch-${PYTORCH_VERSION}



#-------------------------------------------------------------------------------
# function to activate conda env (create if needed)
init_conda_env()
{
    # quick init / return if exists
    if [ -d ${env_dir} ]; then
        conda activate ${env_dir}
        return
    fi

    # otherwise create a conda env, taking pytorch pip requirements.txt from the
    # pytorch source tree - if we can write to it!
    [ -w ${script_dir} ] || { echo "cannot write to ${script_dir} to create ${env_dir}!!"; exit 1; }

    env_file=${env_dir}.yaml

    cat <<EOF > ${env_file}
channels:
  - conda-forge
  - pytorch
  - base
dependencies:
  - ccache
  - cmake
  - cusparselt
  - magma-cuda121 # <-- https://github.com/pytorch/pytorch?tab=readme-ov-file#install-dependencies
  - ninja
  - python=3.12
  - pip
  - pip:
    - mkl-include
    - mkl-static
    - mpi4py
    - -r ${script_dir}/pytorch-${PYTORCH_VERSION}/requirements.txt
EOF

    cat ${env_file}
    echo "creating ${env_dir}..."
    conda env \
          create \
          -f ${env_file} \
          -p ${env_dir} \
        || exit 1

    conda activate ${env_dir}
    return
}

init_conda_env

#-------------------------------------------------------------------------------

unset CUDA_VISIBLE_DEVICES # <--let pytorch manage visible devices

export MPICC=$(which mpicc)
export MPICXX=$(which mpicxx)
export CC=${MPICC}
export CXX=${MPICXX}
export CMAKE_C_COMPILER=${CC}
export CMAKE_CXX_COMPILER=${CXX}
export CFLAGS='-Wno-maybe-uninitialized -Wno-uninitialized -Wno-nonnull'
export CXXFLAGS="${CFLAGS}"

export MAX_JOBS=64

export USE_MPI=1
export MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU

export USE_CUDA=1 # <-- https://github.com/pytorch/pytorch#from-source
export TORCH_CUDA_ARCH_LIST="8.0" # <-- A100s

export USE_CUDNN=1
export CUDNN_LIBRARY=${NCAR_ROOT_CUDNN}
export CUDNN_LIB_DIR=${NCAR_ROOT_CUDNN}/lib
export CUDNN_INCLUDE_DIR=${NCAR_ROOT_CUDNN}/include

export USE_CUSPARSELT=1

export USE_SYSTEM_NCCL=1
export NCCL_ROOT=${script_dir}/nccl-ofi/install
export LD_LIBRARY_PATH=${NCCL_ROOT}/lib:${NCCL_ROOT}/aws-ofi-nccl-plugin/lib:${LD_LIBRARY_PATH}

export FI_CXI_DISABLE_HOST_REGISTER=1
export NCCL_CROSS_NIC=1
export NCCL_SOCKET_IFNAME=hsn
export NCCL_NET_GDR_LEVEL=PHB
export NCCL_NET="AWS Libfabric"

export BLAS=MKL

export CMAKE_PREFIX_PATH=${CONDA_PREFIX}
