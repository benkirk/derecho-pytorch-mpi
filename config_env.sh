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
        module load cudnn/8.8.1.3-12
        ;;
esac
module list

env_name="env-pytorch-${PYTORCH_VERSION}-${NCAR_BUILD_ENV}"
env_dir="${script_dir}/${env_name}"

echo "PYTORCH_VERSION=${PYTORCH_VERSION}"
echo "NCAR_BUILD_ENV=${NCAR_BUILD_ENV}"
echo "env_dir=${env_dir}"

#-------------------------------------------------------------------------------
# clone pytorch source if needed
make -s -C ${script_dir} pytorch-${PYTORCH_VERSION}

#-------------------------------------------------------------------------------
# function to activate conda env (or, create if needed)
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

    mkdir -p ${env_dir}/etc/conda/activate.d ${env_dir}/etc/conda/deactivate.d

    cat <<EOF > ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh
#-------------------------------------------------------------------------------
# defaults for runtime variables we want when operating inside the
# ${env_name} conda environment

# pytorch manage visible devices
unset CUDA_VISIBLE_DEVICES

# Cray-MPICH GPU-Centric bits
#export MPICH_GPU_MANAGED_MEMORY_SUPPORT_ENABLED=1
export MPICH_GPU_SUPPORT_ENABLED=1
export MPICH_OFI_NIC_POLICY=GPU

# NCCL with AWS-OFI-Plugin
export FI_CXI_DISABLE_HOST_REGISTER=1
export NCCL_CROSS_NIC=1
export NCCL_SOCKET_IFNAME=hsn
export NCCL_NET_GDR_LEVEL=PHB
export NCCL_NET="AWS Libfabric"
export NCCL_DEBUG=WARN
#-------------------------------------------------------------------------------
EOF
    cat ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh
    conda activate ${env_dir}
    return
}

init_conda_env


#-------------------------------------------------------------------------------
echo "#--> setting buildtime variables we want when compiling pytorch"
set -x
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

export USE_CUDA=1 # <-- https://github.com/pytorch/pytorch#from-source
export TORCH_CUDA_ARCH_LIST="8.0" # <-- A100s

export USE_CUDNN=1
export CUDNN_LIBRARY=${NCAR_ROOT_CUDNN}
export CUDNN_LIB_DIR=${NCAR_ROOT_CUDNN}/lib
export CUDNN_INCLUDE_DIR=${NCAR_ROOT_CUDNN}/include

export USE_CUSPARSELT=1

export USE_SYSTEM_NCCL=1
export NCCL_ROOT=${script_dir}/nccl-ofi/install
export NCCL_LIB_DIR=${NCCL_ROOT}/lib
export NCCL_INCLUDE_DIR=${NCCL_ROOT}/include

export BLAS=MKL

export CMAKE_PREFIX_PATH=${CONDA_PREFIX}
set +x
#-------------------------------------------------------------------------------
