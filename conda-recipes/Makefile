SHELL := /bin/bash

conda-build-%: %
	mkdir -p logs/ output/
	which conda-build
	source ../config_env.sh && conda-build --channel conda-forge --channel pytorch --output-folder output/ ./$< 2>&1 | tee logs/conda_build_$*.log
