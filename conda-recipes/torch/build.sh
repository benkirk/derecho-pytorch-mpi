#!/usr/bin/env bash

# run via:
# conda-build --output-folder output/ --channel conda-forge --channel pytorch ./pytorch 2>&1 | tee conda_build_pytorch.log


echo && echo && echo "------------------------------------------------------------------------------------------"
env
echo "------------------------------------------------------------------------------------------" && echo && echo

ncar_build_env_label="${NCAR_BUILD_ENV//-/.}"
echo "NCAR_BUILD_ENV=${NCAR_BUILD_ENV}"
echo ncar_build_env_label="${ncar_build_env_label}"
echo "SRC_DIR=${SRC_DIR}"
echo "RECIPE_DIR=${RECIPE_DIR}"
echo "PREFIX=${PREFIX}"
echo "PYTHON=${PYTHON}"

# install our pytorch wheel
python -m \
       pip install \
       --no-deps --verbose \
       ${RECIPE_DIR}/../../wheels/torch-${PKG_VERSION//_derecho/}+${ncar_build_env_label}-*${PY_VER//./}*-linux_x86_64.whl

# source profile.d/modules.sh
# saved_LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
# module unload cudnn ncarcompilers
# module list
# conda list
# which python
# which pip
# which make

# # then add the NCCL plugin dependency so it makes it into the final package
# export INSTALL_DIR="${PREFIX}"
# make nccl-ofi
# rm -vf ${INSTALL_DIR}/lib/libnccl_static.a
# unset INSTALL_DIR

# # create an activate script with NCCL settings
# mkdir -p "${PREFIX}/etc/conda/activate.d"
# cp profile.d/derecho-nccl-aws-ofi.cfg "${PREFIX}/etc/conda/activate.d/${PKG_NAME}_activate.sh"

#------------------------------------------------------------------------------------------
# host shared library hackery follows:
# OBE now if we don't strip existing rpahs
#------------------------------------------------------------------------------------------
# cd ${PREFIX}
# pwd

# echo "dependencies of libtorch*.so:"
# objdump -p $(find -name "libtorch*.so") | grep NEEDED | sort | uniq

# for libname in $(find -name "libtorch*.so"); do
#     echo && echo && echo ${libname}
#     objdump -p ${libname} | grep NEEDED | sort | uniq
# done

# echo "all shared lib deps:"
# cd ${PREFIX}
# mkdir -p lib/torch.deps
# find lib -name "libtorch*.so" -o -name "libnccl*.so" | \
#     2>/dev/null xargs ldd | \
#     grep " => "| grep -v '$PREFIX' | grep -v "${SYS_PREFIX}" | \
#     awk '{NF=NF-1; print $0}' | \
#     sort | uniq | \
#     tee lib/torch.deps/host_libs.dep

# echo "${saved_LD_LIBRARY_PATH}" > lib/torch.deps/build_env_ld_library_path

# pip show -f torch | grep "torch/lib/" | xargs -n 1 basename > lib/torch.deps/pip_manifest_libs
