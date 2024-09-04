#!/usr/bin/env bash

set -e

saved_LD_LIBRARY_PATH="$(cat $PREFIX/lib/torch.deps/build_env_ld_library_path)"
patchelf="/glade/u/home/benkirk/bin/patchelf"

# cat $PREFIX/lib/torch.deps/pip_manifest_libs | while read libname; do
#     find $PREFIX/lib -name ${libname} -print0 \
#         | xargs -0 -n1 ${patchelf} --add-rpath ${saved_LD_LIBRARY_PATH}
# done
