SHELL           := /bin/bash
PBS_ACCOUNT     ?= SCSG0001
PYTORCH_VERSION ?= 2.3.1
TORCHVISION_VERSION ?= 0.18.1

.PHONY: clean \
        clean-pytorch-v$(PYTORCH_VERSION) \
	clean-vision-v$(TORCHVISION_VERSION) \
	build-pbs \
	build-vision-v$(TORCHVISION_VERSION)-pbs \
	build-pytorch-v$(PYTORCH_VERSION)-pbs

# checkout / patch source code targets
pytorch-v$(PYTORCH_VERSION):
	rm -rf $@ $@.tmp
	git clone --depth 1 --branch v$(PYTORCH_VERSION) https://github.com/pytorch/pytorch $@.tmp
	if [ -d ./patches/pytorch/v$(PYTORCH_VERSION) ]; then \
	  echo "Patching source..." ;\
	  cd $@.tmp ;\
	  for patchfile in ../patches/pytorch/v$(PYTORCH_VERSION)/*; do \
	    patch -p1 < $$patchfile ;\
	  done ;\
	fi
	cd $@.tmp && git submodule update --init --recursive --depth 1
	mv $@.tmp $@

vision-v$(TORCHVISION_VERSION):
	rm -rf $@ $@.tmp
	git clone  --depth 1 --branch v$(TORCHVISION_VERSION) https://github.com/pytorch/vision $@.tmp
	if [ -d ./patches/vision/v$(TORCHVISION_VERSION) ]; then \
	  echo "Patching source..." ;\
	  cd $@.tmp ;\
	  for patchfile in ../patches/vision/v$(TORCHVISION_VERSION)/*; do \
	    patch -p1 < $$patchfile ;\
	  done ;\
	fi
	mv $@.tmp $@

# clean targets
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
	source config_env.sh ;\
          cd pytorch-v$(PYTORCH_VERSION) ;\
	  echo "$${PYTORCH_BUILD_VERSION}" > version.txt ;\
          python setup.py install | tee install.log
	[ -f $</build/install_manifest.txt ] && date >> $@

pytorch-v$(PYTORCH_VERSION)/.wheel.stamp: pytorch-v$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	source config_env.sh && cd pytorch-v$(PYTORCH_VERSION) && python setup.py bdist_wheel | tee wheel.log
	[ -f $</build/install_manifest.txt ] && date >> $@

# specifically *unset* PYTORCH_VERSION during build, otherwise torchvision will attempt to
# require that, match closest, and download something.  Which we do not want.
vision-v$(TORCHVISION_VERSION)/.install.stamp: vision-v$(TORCHVISION_VERSION) pytorch-v$(PYTORCH_VERSION)/.install.stamp
	source config_env.sh ;\
          cd vision-v$(TORCHVISION_VERSION) ;\
	  echo "$(TORCHVISION_VERSION)+$${NCAR_BUILD_ENV}" > version.txt ;\
          PYTORCH_VERSION="$${PYTORCH_BUILD_VERSION}" ;\
          python setup.py install | tee install.log
	[ -d $</dist ] && date >> $@

# build under PBS with qcmd. Intended to be run on a login node.
# first make clean; this will ensure we have the source tree.  This will run on a login node.
# then for good measure simply source the config_env.sh script; this will ensure we have
# the requisite conda env. Finally; use qcmd to launch the build rule on a dedicated GPU node.
# (use Brian's qcmd wrapper at the moment due to the qsub -V problem...)
build-pytorch-v$(PYTORCH_VERSION)-pbs: config_env.sh
	$(MAKE) clean-pytorch-v$(PYTORCH_VERSION)
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.install.stamp

build-pytorch-v$(PYTORCH_VERSION)-wheel-pbs: config_env.sh
	$(MAKE) clean-pytorch-v$(PYTORCH_VERSION)
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.wheel.stamp

build-vision-v$(TORCHVISION_VERSION)-pbs: config_env.sh
	$(MAKE) clean-vision-v$(TORCHVISION_VERSION)
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) vision-v$(TORCHVISION_VERSION)/.install.stamp

# umbrella build-pbs rule
build-pbs: config_env.sh
	$(MAKE) clean
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
          qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 \
          -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.install.stamp vision-v$(TORCHVISION_VERSION)/.install.stamp
	source config_env.sh && python ./tests/credit_imports.py

nccl-ofi/install/lib/libnccl-net.so nccl-ofi/install/lib/libnccl.so nccl-ofi: \
	utils/build_nccl-ofi-plugin.sh
	./$<
