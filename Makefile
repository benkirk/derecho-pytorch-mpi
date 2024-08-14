SHELL           := /bin/bash
PBS_ACCOUNT     ?= SCSG0001
PYTORCH_VERSION ?= v2.3.1

.PHONY: clean-pytorch-$(PYTORCH_VERSION) build-pbs

pytorch-$(PYTORCH_VERSION):
	rm -rf $@ $@.tmp
	git clone --depth 1 --branch $(PYTORCH_VERSION) https://github.com/pytorch/pytorch $@.tmp
	cd $@.tmp && for patchfile in ../patches/$(PYTORCH_VERSION)/*;\
	  do patch -p1 < $$patchfile ;\
	done
	cd $@.tmp && git submodule update --init --recursive --depth 1
	mv $@.tmp $@

pytorch-%/.build.stamp: pytorch-% Makefile config_env.sh
	rm -f $@
	source config_env.sh && cd pytorch-$* && python setup.py install | tee install.log
	date >> $@

clean-pytorch-$(PYTORCH_VERSION): pytorch-$(PYTORCH_VERSION)
	cd $< && git clean -xdf .

build-pbs:
	make clean-pytorch-$(PYTORCH_VERSION)
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	qcmd -q main -A $(PBS_ACCOUNT) -l walltime=4:00:00 -l select=1:ncpus=64:ngpus=4 -- make pytorch-$(PYTORCH_VERSION)/.build.stamp
