SHELL           := /bin/bash
PBS_ACCOUNT     ?= SCSG0001
PYTORCH_VERSION ?= v2.3.1
TORCHVISION_VERSION ?= 0.18

.PHONY: clean-pytorch-$(PYTORCH_VERSION) build-pytorch-$(PYTORCH_VERSION)-pbs

# checkout / patch source code targets
pytorch-$(PYTORCH_VERSION):
	rm -rf $@ $@.tmp
	git clone --depth 1 --branch $(PYTORCH_VERSION) https://github.com/pytorch/pytorch $@.tmp
	if [ -d ./patches/$(PYTORCH_VERSION) ]; then \
	  echo "Patching source..." ;\
	  cd $@.tmp ;\
	  for patchfile in ../patches/$(PYTORCH_VERSION)/*; do \
	    patch -p1 < $$patchfile ;\
	  done ;\
	fi
	cd $@.tmp && git submodule update --init --recursive --depth 1
	mv $@.tmp $@

vision-v$(TORCHVISION_VERSION):
	rm -rf $@ $@.tmp
	git clone  --depth 1 --branch release/$(TORCHVISION_VERSION) https://github.com/pytorch/vision.git $@.tmp
	mv $@.tmp $@

clean-pytorch-$(PYTORCH_VERSION): pytorch-$(PYTORCH_VERSION)
	cd $< && git clean -xdf .

clean-vision-v$(TORCHVISION_VERSION): vision-v$(TORCHVISION_VERSION)
	cd $< && git clean -xdf .

# build targets
pytorch-$(PYTORCH_VERSION)/.install.stamp: pytorch-$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	rm -f $@ pytorch-$(PYTORCH_VERSION)/build/install_manifest.txt
	source config_env.sh && cd pytorch-$(PYTORCH_VERSION) && python setup.py install | tee install.log
	[ -f $</build/install_manifest.txt ] && date >> $@

pytorch-$(PYTORCH_VERSION)/.wheel.stamp: pytorch-$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	source config_env.sh && cd pytorch-$(PYTORCH_VERSION) && python setup.py bdist_wheel | tee wheel.log
	[ -f $</build/install_manifest.txt ] && date >> $@

vision-v$(TORCHVISION_VERSION)/.install.stamp: vision-v$(TORCHVISION_VERSION) pytorch-$(PYTORCH_VERSION)/.install.stamp
	source config_env.sh && cd vision-v$(TORCHVISION_VERSION) && MAX_JOBS=6 python setup.py install | tee install.log
	[ -f $</build/install_manifest.txt ] && date >> $@

# build under PBS with qcmd. Intended to be run on a login node.
# first make clean; this will ensure we have the source tree.  This will run on a login node.
# then for good measure simply source the config_env.sh script; this will ensure we have
# the requisite conda env. Finally; use qcmd to launch the build rule on a dedicated GPU node.
# (use Brian's qcmd wrapper at the moment due to the qsub -V problem...)
build-pytorch-$(PYTORCH_VERSION)-pbs: config_env.sh
	make clean-pytorch-$(PYTORCH_VERSION)
	source $< && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=4:00:00 -l select=1:ncpus=64:ngpus=4 -- make pytorch-$(PYTORCH_VERSION)/.install.stamp

build-pytorch-$(PYTORCH_VERSION)-wheel-pbs: config_env.sh
	make clean-pytorch-$(PYTORCH_VERSION)
	source $< && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=4:00:00 -l select=1:ncpus=64:ngpus=4 -- make pytorch-$(PYTORCH_VERSION)/.wheel.stamp

nccl-ofi/install/lib/libnccl-net.so nccl-ofi/install/lib/libnccl.so nccl-ofi: \
	utils/build_nccl-ofi-plugin.sh
	./$<
