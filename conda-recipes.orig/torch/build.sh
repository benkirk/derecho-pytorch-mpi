#!/usr/bin/env bash

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
