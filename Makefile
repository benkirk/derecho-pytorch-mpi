SHELL           := /bin/bash
PBS_ACCOUNT     ?= SCSG0001
PYTORCH_VERSION ?= 2.3.1
TORCHVISION_VERSION ?= 0.18.1

.PHONY: clean clean-pytorch-v$(PYTORCH_VERSION) clean-vision-v$(TORCHVISION_VERSION) build-pytorch-v$(PYTORCH_VERSION)-pbs

# checkout / patch source code targets
pytorch-v$(PYTORCH_VERSION):
	rm -rf $@ $@.tmp
	git clone --depth 1 --branch v$(PYTORCH_VERSION) https://github.com/pytorch/pytorch $@.tmp
	if [ -d ./patches/v$(PYTORCH_VERSION) ]; then \
	  echo "Patching source..." ;\
	  cd $@.tmp ;\
	  for patchfile in ../patches/v$(PYTORCH_VERSION)/*; do \
	    patch -p1 < $$patchfile ;\
	  done ;\
	fi
	cd $@.tmp && git submodule update --init --recursive --depth 1
	mv $@.tmp $@

vision-v$(TORCHVISION_VERSION):
	rm -rf $@ $@.tmp
	git clone  --depth 1 --branch v$(TORCHVISION_VERSION) https://github.com/pytorch/vision.git $@.tmp
	mv $@.tmp $@

clean-pytorch-v$(PYTORCH_VERSION): pytorch-v$(PYTORCH_VERSION)
	cd $< && git clean -xdf .

clean-vision-v$(TORCHVISION_VERSION): vision-v$(TORCHVISION_VERSION)
	cd $< && git clean -xdf .

clean:
	$(MAKE) clean-vision-v$(TORCHVISION_VERSION)
	$(MAKE) clean-pytorch-v$(PYTORCH_VERSION)

# build targets
pytorch-v$(PYTORCH_VERSION)/.install.stamp: pytorch-v$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	rm -f $@ pytorch-v$(PYTORCH_VERSION)/build/install_manifest.txt
	source config_env.sh && cd pytorch-v$(PYTORCH_VERSION) && python setup.py install | tee install.log
	[ -f $</build/install_manifest.txt ] && date >> $@

pytorch-v$(PYTORCH_VERSION)/.wheel.stamp: pytorch-v$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	source config_env.sh && cd pytorch-v$(PYTORCH_VERSION) && python setup.py bdist_wheel | tee wheel.log
	[ -f $</build/install_manifest.txt ] && date >> $@

vision-v$(TORCHVISION_VERSION)/.install.stamp: vision-v$(TORCHVISION_VERSION) pytorch-v$(PYTORCH_VERSION)/.install.stamp
	source config_env.sh && cd vision-v$(TORCHVISION_VERSION) && python setup.py install | tee install.log
	[ -f $</build/install_manifest.txt ] && date >> $@

# build under PBS with qcmd. Intended to be run on a login node.
# first make clean; this will ensure we have the source tree.  This will run on a login node.
# then for good measure simply source the config_env.sh script; this will ensure we have
# the requisite conda env. Finally; use qcmd to launch the build rule on a dedicated GPU node.
# (use Brian's qcmd wrapper at the moment due to the qsub -V problem...)
build-pytorch-v$(PYTORCH_VERSION)-pbs: config_env.sh
	make clean-pytorch-v$(PYTORCH_VERSION)
	source $< && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=4:00:00 -l select=1:ncpus=64:ngpus=4 -- make pytorch-v$(PYTORCH_VERSION)/.install.stamp

build-pytorch-v$(PYTORCH_VERSION)-wheel-pbs: config_env.sh
	make clean-pytorch-v$(PYTORCH_VERSION)
	source $< && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=4:00:00 -l select=1:ncpus=64:ngpus=4 -- make pytorch-v$(PYTORCH_VERSION)/.wheel.stamp

nccl-ofi/install/lib/libnccl-net.so nccl-ofi/install/lib/libnccl.so nccl-ofi: \
	utils/build_nccl-ofi-plugin.sh
	./$<
