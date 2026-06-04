#-------------------------------------------------------------------------------
# setup host environment
type module >/dev/null 2>&1 \
    || source /etc/profile.d/z00_modules.sh
module --force purge
#module load ncarenv/23.09 gcc/12.2.0 ncarcompilers cray-mpich/8.1.27 cuda/12.2.1 mkl/2024.0.0 conda/latest cudnn/8.8.1.3-12
module load ncarenv/24.12 gcc/12.4.0 ncarcompilers cray-mpich/8.1.29 cuda/12.3.2 conda/latest mkl/2025.0.1 cudnn/9.2.0.82-12

HWLOC_HOME="/glade/u/apps/derecho/24.12/spack/opt/spack/hwloc/2.11.1/gcc/12.4.0/khq6"
