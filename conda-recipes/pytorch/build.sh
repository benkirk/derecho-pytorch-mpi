#!/usr/bin/env bash

# run via:
# conda build -c conda-forge -c pytorch -c base ./conda-recipes/pytorch

# find $CONDA_PREFIX -name libtorch*.so | xargs ldd | grep " => " | sort | awk '{NF=NF-1; print $0}' | uniq

# find $CONDA_PREFIX -name libtorch*.so | xargs ldd | grep " => " | grep -v "_test_env_placehold_placehold" | sort | awk '{NF=NF-1; print $0}' | uniq | grep -v "$(pwd)"


python -m \
       pip install \
       --no-deps --verbose \
       /glade/derecho/scratch/benkirk/derecho-pytorch-mpi-devel/pytorch-v2.3.1/dist/torch-2.3.1+derecho.gcc.12.2.0.cray.mpich.8.1.27-cp311-cp311-linux_x86_64.whl

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
ls
find lib* -name *.so*


objdump -p $(find -name "libtorch*so") | grep NEEDED | sort | uniq
for lib in $(find -name "libtorch*so"); do
    echo && echo && echo ${lib}
    objdump -p ${lib} | grep NEEDED
done
exit 0
