SHELL := /bin/bash

top_dir := $(shell git rev-parse --show-toplevel)
config_env := source $(top_dir)/config_env.sh

%-testenv: %.yaml
	mv $@ $@.old && rm -rf $@.old &
	$(config_env) && conda env create --file $< --prefix $@
	$(config_env) && conda activate ./$@ && conda list

solve-%: %.yaml
	$(config_env) && conda env create --file $< --prefix $@ --dry-run
