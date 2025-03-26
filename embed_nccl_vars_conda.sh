#!/bin/bash -l 
echo "Conda env: $CONDA_PREFIX"
env_dir=$CONDA_PREFIX
script_dir="./"
mkdir -p ${env_dir}/etc/conda/activate.d ${env_dir}/etc/conda/deactivate.d
cp ${script_dir}/profile.d/derecho-nccl-aws-ofi.cfg ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh
cat ${env_dir}/etc/conda/activate.d/derecho-env_vars.sh
