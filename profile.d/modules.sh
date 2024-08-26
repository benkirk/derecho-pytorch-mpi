export PYTORCH_VERSION="${PYTORCH_VERSION:-2.3.1}"

#-------------------------------------------------------------------------------
# setup host environment
module --force purge
module load ncarenv/23.09 gcc/12.2.0 ncarcompilers cray-mpich/8.1.27 conda/latest cuda/12.2.1
export CONDA_OVERRIDE_CUDA="12.2"

case "${PYTORCH_VERSION}" in
    # see https://github.com/pytorch/vision for torch & vision compatibility
    "2.4.0"*)
        module load cudnn/9.2.0.82-12
        export TORCHVISION_VERSION="0.19.0"
        ;;
    "2.3.1"*)
        module load cudnn/8.8.1.3-12
        export TORCHVISION_VERSION="0.18.1"
        ;;
    "2.2.2"*)
        module load cudnn/8.8.1.3-12
        export TORCHVISION_VERSION="0.17.2"
        ;;
    *)
        echo "ERROR: unknown / unsupported PYTORCH_VERSION: ${PYTORCH_VERSION}"
        exit 1
        ;;
esac
module list
