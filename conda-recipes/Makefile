SHELL := /bin/bash

top_dir := $(shell git rev-parse --show-toplevel)
config_env := source $(top_dir)/config_env.sh

conda-build-%: %
	mkdir -p logs/ output/
	which conda-build
	$(config_env) && conda-build --channel conda-forge --output-folder output/ ./$< 2>&1 | tee logs/conda_build_$*.log
