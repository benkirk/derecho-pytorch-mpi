#-------------------------------------------------------------------------------
# setup host environment
type module >/dev/null 2>&1 \
    || source /etc/profile.d/z00_modules.sh
module --force purge
module load ncarenv/23.09 gcc/12.2.0 ncarcompilers cray-mpich/8.1.27 cuda/12.2.1 mkl/2024.0.0 conda/latest
