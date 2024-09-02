SHELL := /bin/bash

top_dir := $(shell git rev-parse --show-toplevel)
config_env := source $(top_dir)/config_env.sh

%-testenv: %.yaml
	rm -rf $@
	$(config_env) && conda env create --file $< --prefix $@

solve-%: %.yaml
	$(config_env) && conda env create --file $< --prefix $@ --dry-run
