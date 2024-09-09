#!/bin/bash

env

set -ex

pwd
ls


link_host_libs() {
    oldwd="$(pwd)"

    cd $PREFIX/lib

    while read library; do

        echo "linking ${library}"

        [[ -f "$(basename $library)" ]] && continue
        ln -s ${library} .

    done < <(find \
                 /opt/cray/pe/pals/1.2.12 \
                 /opt/cray/pe/cti/2.18.1/lib \
                 /opt/cray/pe/pmi/6.1.12/lib \
                 /opt/cray/libfabric/1.15.2.0/lib64 \
                 /opt/cray/pe/mpich/8.1.27/ofi/gnu/9.1/lib \
                 /usr/lib/ \
                 /usr/lib64/ \
                 -name "lib*.so*" | sort | uniq)

    cd ${oldwd}
}

echo "CXX=$CXX"
echo "gcc=$(which gcc)"
echo "PREFIX=$(cd $PREFIX && pwd)"
echo "BUILD_PREFIX=$(cd $BUILD_PREFIX && pwd)"
echo "SRC_DIR=$(cd $SRC_DIR && pwd)"

#--------------------------------------------------------------------------------
# BEGIN NCAR-Derecho Customization

which mpicxx
which gcc

mpicxx -show -o $PREFIX/bin/hello_world_mpi $SRC_DIR/hello_world_mpi.C -fopenmp
mpicxx -o $PREFIX/bin/hello_world_mpi $SRC_DIR/hello_world_mpi.C -fopenmp
ldd $PREFIX/bin/hello_world_mpi
$PREFIX/bin/hello_world_mpi

# mkdir -p $PREFIX/opt/cray
# cd $PREFIX/opt/cray
# ln -s /opt/cray/* .
# ls
# cd $SRC_DIR
# ls
# mkdir -p wrapper_bin
# cd wrapper_bin
# ln -s $(which $CXX) g++
# ln -s $(which $CC) gcc
#
# link_host_libs
# PATH=$PREFIX/opt/cray/pe/mpich/8.1.27/ofi/gnu/9.1/bin:$SRC_DIR/wrapper_bin:$PATH
# mpicxx -o $PREFIX/bin/hello_world_mpi.cray $SRC_DIR/hello_world_mpi.C -fopenmp


# END NCAR-Derecho Customization
#--------------------------------------------------------------------------------
