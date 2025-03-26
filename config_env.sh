#!/bin/bash

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
activate_env=${activate_env:-true}

# package version defaults (set-if-unset)
export PYTORCH_VERSION="${PYTORCH_VERSION:-2.3.1}"
export ENV_PYTHON_VERSION="${ENV_PYTHON_VERSION:-3.11}"
export MPI4PY_VERSION="${MPI4PY_VERSION:-4.0.1}"

#-------------------------------------------------------------------------------
# setup host environment
source ${script_dir}/profile.d/modules.sh >/dev/null 2>&1 \
    || { echo "ERROR sourcing profile.d/modules.sh!!"; exit 1; }

case "${PYTORCH_VERSION}" in
    # see https://github.com/pytorch/vision for torch & vision compatibility
    "2.5.1")
        export TORCHVISION_VERSION="0.20.1"
        ;;
    "2.4.1")
        export TORCHVISION_VERSION="0.19.1"
        ;;
    "2.4.0")
        export TORCHVISION_VERSION="0.19.0"
        ;;
    "2.3.1")
        export TORCHVISION_VERSION="0.18.1"
        ;;
    "2.2.2")
        export TORCHVISION_VERSION="0.17.2"
        ;;
    *)
        echo "ERROR: unknown / unsupported PYTORCH_VERSION: ${PYTORCH_VERSION}"
        exit 1
        ;;
esac
module list

env_name="envs/pytorch-buildenv-py${ENV_PYTHON_VERSION}-${NCAR_BUILD_ENV}"
env_dir="${script_dir}/${env_name}"

echo "PYTORCH_VERSION=${PYTORCH_VERSION}"
echo "TORCHVISION_VERSION=${TORCHVISION_VERSION}"
echo "ENV_PYTHON_VERSION=${ENV_PYTHON_VERSION}"
echo "NCAR_BUILD_ENV=${NCAR_BUILD_ENV}"
echo "env_dir=${env_dir}"

##-------------------------------------------------------------------------------
## clone pytorch source if needed
#make -s -C ${script_dir} pytorch-v${PYTORCH_VERSION}
#make -s -C ${script_dir} vision-v${TORCHVISION_VERSION}

#-------------------------------------------------------------------------------
# function to activate conda env (or, create if needed)
activate_conda_env()
{
    # onnly load conda module if needed to activate env
    module load conda/latest

    # quick init / return if exists
    if [ -d ${env_dir} ]; then
        conda activate ${env_dir}
        return
    fi

    mkdir -p envs

    # otherwise create a conda env, taking pytorch pip requirements.txt from the
    # pytorch source tree - if we can write to it!
    [ -w ${script_dir} ] || { echo "cannot write to ${script_dir} to create ${env_dir}!!"; exit 1; }

    env_file=${env_dir}.yaml

    cat <<EOF > ${env_file}
channels:
  - conda-forge
  - base
dependencies:
  - python=${ENV_PYTHON_VERSION}
  - ccache
  - cmake
  - conda-tree
  - cusparselt
  - expecttest !=0.2.0 
  - pip
  - pip:
    - build
    - pipdeptree
    - mpi4py
    - astunparse
    - expecttest>=0.2.1
    - hypothesis
    - numpy
    - psutil
    - pyyaml
    - requests
    - setuptools<=72.1.0
    - types-dataclasses
    - typing-extensions>=4.8.0
    - sympy==1.13.1 
    - filelock
    - networkx
    - jinja2
    - fsspec
    - lintrunner
    - ninja
    - packaging
    - optree>=0.12.0 
    - flake8
    - wheel
    - packaging
    - pyyaml
EOF

    cat ${env_file}
    echo "creating ${env_dir}..."
    conda env \
          create \
          -f ${env_file} \
          -p ${env_dir} \
        || exit 1

    # set optimal NCCL env vars when activating environment
    mkdir -p ${env_dir}/etc/conda/activate.d ${env_dir}/etc/conda/deactivate.d
    cp ${script_dir}/profile.d/derecho-nccl-aws-ofi.cfg ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh
    cat ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh

    conda activate ${env_dir}
    conda-tree deptree

    # fix the conda shebang so conda build works!!
    # https://conda.discourse.group/t/conda-build-modulenotfounderror-no-module-named-conda/538/2
    sed -i "s,\#\!/usr/bin/env python,#\!${CONDA_PREFIX}/bin/python," ${CONDA_PREFIX}/*bin/conda

    # # total hack: conda-build likes to strip all rpaths that point to host directories. Which
    # # makes perfect sense for the typical use case.  However, here we want to keep those, as
    # # we are building packages designed only to run on this host, intentionally.
    # # (patch created by: diff -Naur conda_build/post.py{.old,} > <patchfile>)
    # pushd ${CONDA_PREFIX}/lib/python${ENV_PYTHON_VERSION}/site-packages
    # mv conda_build/post.py{,.orig}
    # cp conda_build/post.py{.orig,}
    # patch -p0 < ${script_dir}/patches/conda-build/patch-post.py
    # popd

    return
}

# save these **before** intializaing the monster conda environment
# defined above, in case that brings in its own MPI we want no part of...
save_MPICC=$(which mpicc)
save_MPICXX=$(which mpicxx)

[[ true == ${activate_env} ]] && activate_conda_env

#-------------------------------------------------------------------------------
echo "#--> setting buildtime variables we want when compiling pytorch / torchvision"
#set -x
export MPICC=${save_MPICC}
export MPICXX=${save_MPICXX}
export CC=${MPICC}
export CXX=${MPICXX}
export CMAKE_C_COMPILER=${CC}
export CMAKE_CXX_COMPILER=${CXX}
export CFLAGS='-Wno-maybe-uninitialized -Wno-uninitialized -Wno-nonnull'
export CXXFLAGS="${CFLAGS}"

export CMAKE_PREFIX_PATH=${CONDA_PREFIX}

export MAX_JOBS="${MAX_JOBS:-96}"

# pytorch:
export BUILD_TEST=0
export USE_FFMPEG=0 # <-- dropped in pytorch-v2.4, so lets keep out of earlier versions too.
export USE_BLAS=MKL
export BLAS=MKL # <-- this nugget will cause CMake to abort if it can't find MKL, instead of try others
# mkl from host environment - alternatively, omit these three and instead add to the conda env
export MKL_ROOT="${MKLROOT}"
export MKL_INCLUDE_DIR=${MKL_ROOT}/include
export MKL_LIB_DIR=${MKL_ROOT}/lib
export USE_STATIC_MKL=1
export USE_MKLDNN=1
export USE_DISTRIBUTED=1
export USE_MPI=1
export USE_CUDA=1
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
export PYTORCH_BUILD_VERSION="${PYTORCH_VERSION}+${NCAR_BUILD_ENV}"
export PYTORCH_BUILD_NUMBER=1

# torchvision:
export FORCE_CUDA=1 # <-- https://github.com/pytorch/vision/blob/main/CONTRIBUTING.md#clone-and-install-torchvision
#export TORCHVISION_USE_FFMPEG=1 # <-- works, just need ffmpeg >=4.2.2,<5 installed in the build and run environments
export TORCHVISION_USE_FFMPEG=0
export TORCHVISION_BUILD_VERSION="${TORCHVISION_VERSION}+${NCAR_BUILD_ENV_COMPILER}"
set +x
#-------------------------------------------------------------------------------
