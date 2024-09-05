#!/usr/bin/env bash

echo && echo && echo "------------------------------------------------------------------------------------------"
env
echo "------------------------------------------------------------------------------------------" && echo && echo

ncar_build_env_label="${NCAR_BUILD_ENV_COMPILER//-/.}"
echo "NCAR_BUILD_ENV_COMPILER=${NCAR_BUILD_ENV_COMPILER}"
echo ncar_build_env_label="${ncar_build_env_label}"
echo "SRC_DIR=${SRC_DIR}"
echo "RECIPE_DIR=${RECIPE_DIR}"
echo "PREFIX=${PREFIX}"
echo "PYTHON=${PYTHON}"

# first install our pytorch wheel
python -m \
       pip install \
       --no-deps --verbose \
       ${RECIPE_DIR}/../../wheels/torchvision-${PKG_VERSION//_derecho/}+${ncar_build_env_label}-*${PY_VER//./}*-linux_x86_64.whl
