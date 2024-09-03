SHELL := /bin/bash

top_dir := $(shell git rev-parse --show-toplevel)
config_env := source $(top_dir)/config_env.sh

vision_extra_channels := -c file://$(shell pwd)/output

conda-build-%: %
	mkdir -p logs/ output/
	which conda-build
	$(config_env) && conda-build $($*_extra_channels) --channel conda-forge --output-folder output/ ./$< 2>&1 | tee logs/conda_build_$*.log
