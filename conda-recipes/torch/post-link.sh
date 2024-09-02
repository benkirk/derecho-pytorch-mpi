#!/usr/bin/env bash

set -e

cd $PREFIX/lib/torch.deps

cat host_libs.dep | while read line; do
    linkname=$(echo ${line} | awk '{print $1}')
    target=$(echo ${line} | awk '{print $3}')
    ln -s ${target} ${linkname}
done

cat <<EOF >> $PREFIX/.messages.txt
------------------------------------------------------------------------------
re-linked host dependencies into lib/torch.deps:
$(cat host_libs.dep)
------------------------------------------------------------------------------

EOF
