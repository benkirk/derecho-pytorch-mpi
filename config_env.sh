#!/bin/bash


export PYTORCH_VERSION="${PYTORCH_VERSION:-v2.3.1}"

top_dir=$(git rev-parse --show-toplevel)

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

envname="pytorch-${PYTORCH_VERSION}-${NCAR_BUILD_ENV}"
envdir="${top_dir}/${envname}"

echo "PYTORCH_VERSION=${PYTORCH_VERSION}"
echo "NCAR_BUILD_ENV=${NCAR_BUILD_ENV}"
echo "envdir=${envdir}"


#-------------------------------------------------------------------------------
# clone pytorch source if needed
make -s -C ${top_dir} pytorch-${PYTORCH_VERSION}



#-------------------------------------------------------------------------------
# function to activate conda env (create if needed)
init_conda_env()
{
    # quick init / return if exists
    if [ -d ${envdir} ]; then
        conda activate ${envdir}
        return
    fi

    # otherwise create a conda env, taking pytorch pip requirements.txt from the
    # pytorch source tree
    envfile=${envdir}.yaml

    cat <<EOF > ${envfile}
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
    - -r ${top_dir}/pytorch-${PYTORCH_VERSION}/requirements.txt
EOF

    cat ${envfile}
    echo "creating ${envdir}..."
    conda env \
          create \
          -f ${envfile} \
          -p ${envdir} \
        || exit 1

    conda activate ${envdir}
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
#export PKG_CONFIG_PATH=${CUDA_HOME}/pkgconfig:${PKG_CONFIG_PATH}

export USE_CUDNN=1
export CUDNN_LIBRARY=${NCAR_ROOT_CUDNN}
export CUDNN_LIB_DIR=${NCAR_ROOT_CUDNN}/lib
export CUDNN_INCLUDE_DIR=${NCAR_ROOT_CUDNN}/include

export USE_CUSPARSELT=1

export USE_SYSTEM_NCCL=0

export BLAS=MKL

export CMAKE_PREFIX_PATH=${CONDA_PREFIX}
