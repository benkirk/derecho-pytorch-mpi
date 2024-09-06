SHELL := /bin/bash

PBS_ACCOUNT ?= SCSG0001

top_dir := $(shell git rev-parse --show-toplevel)
config_env := source $(top_dir)/config_env.sh

#vision_extra_channels := -c file://$(shell pwd)/output

conda-build-%: %
	mkdir -p logs/ output/
	$(config_env) && conda-build $($*_extra_channels) --channel conda-forge --output-folder output/ ./$< 2>&1 | tee logs/$*.log

pbs-build-%: %
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
          qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 \
          -- $(MAKE) conda-build-$*
