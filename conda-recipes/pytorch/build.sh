#!/usr/bin/env bash

# run via:
# conda-build --output-folder output/ --channel conda-forge --channel pytorch ./pytorch 2>&1 | tee conda_build_pytorch.log

# find $CONDA_PREFIX -name libtorch*.so | xargs ldd | grep " => " | sort | awk '{NF=NF-1; print $0}' | uniq

# find $CONDA_PREFIX -name libtorch*.so | xargs ldd | grep " => " | grep -v "_test_env_placehold_placehold" | sort | awk '{NF=NF-1; print $0}' | uniq | grep -v "$(pwd)"

echo && echo && echo "------------------------------------------------------------------------------------------"
env
echo "------------------------------------------------------------------------------------------" && echo && echo

python -m \
       pip install \
       --no-deps --verbose \
       /glade/derecho/scratch/benkirk/derecho-pytorch-mpi-devel/pytorch-v${PKG_VERSION}/dist/torch-${PKG_VERSION}+derecho.*-linux_x86_64.whl

source profile.d/modules.sh
module unload cudnn ncarcompilers
module list

pwd

echo "SRC_DIR=${SRC_DIR}"
echo "PYTHON=${PYTHON}"

conda list

which python
which pip
which make


export INSTALL_DIR="${PREFIX}"
make nccl-ofi
rm -vf ${INSTALL_DIR}/lib/libnccl_static.a
unset INSTALL_DIR

export MAX_JOBS=6

#activate_env=false
#source config_env.sh


echo "SRC_DIR=${SRC_DIR}"
echo "PYTHON=${PYTHON}"


cd ${PREFIX}
pwd
# ls
# find lib* -name *.so*


echo "dependencies of libtorch*.so:"
objdump -p $(find -name "libtorch*.so") | grep NEEDED | sort | uniq

for libname in $(find -name "libtorch*.so"); do
    echo && echo && echo ${libname}
    objdump -p ${libname} | grep NEEDED | sort | uniq
    ldd ${libname}
done
exit 0
