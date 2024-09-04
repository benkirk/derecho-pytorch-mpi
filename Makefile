PBS_ACCOUNT     ?= SCSG0001
PYTORCH_VERSION ?= 2.3.1
TORCHVISION_VERSION ?= 0.18.1

# require make to use a more capable shell
SHELL := /bin/bash

# setup some make variables for controlling installation, packaging rules
pip_install_flags := --no-build-isolation --no-clean #--no-deps -v # --no-clean keeps build directories, and wheels
pkg_install_cmd := python -m pip install $(pip_install_flags) .
#pkg_install_cmd := python setup.py install

python_build_flags := --no-isolation --skip-dependency-check --wheel # --verbose
pkg_build_cmd := python -m build $(python_build_flags) .
#pkg_build_cmd := python -m pip wheel $(pip_install_flags) .

.PHONY: clean \
        clean-pytorch-v$(PYTORCH_VERSION) \
	clean-vision-v$(TORCHVISION_VERSION) \
	install-pbs \
	install-vision-v$(TORCHVISION_VERSION)-pbs \
	install-pytorch-v$(PYTORCH_VERSION)-pbs \
	build-pbs \
	build-vision-v$(TORCHVISION_VERSION)-pbs \
	build-pytorch-v$(PYTORCH_VERSION)-pbs

# source checkout / patch source code targets
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
	rm -f $@
	source config_env.sh ;\
	  pip uninstall --yes torchvision torch ;\
          cd pytorch-v$(PYTORCH_VERSION) ;\
	  echo "$${PYTORCH_BUILD_VERSION}" > version.txt ;\
          $(pkg_install_cmd) | tee install.log \
            && cp install.log install.stamp && date >> install.stamp \
	    && mv install.stamp .install.stamp

pytorch-v$(PYTORCH_VERSION)/.build.stamp: pytorch-v$(PYTORCH_VERSION) Makefile config_env.sh nccl-ofi
	rm -f $@
	source config_env.sh ;\
          cd pytorch-v$(PYTORCH_VERSION) ;\
	  echo "$${PYTORCH_BUILD_VERSION}" > version.txt ;\
          $(pkg_build_cmd) | tee build.log \
            && cp build.log build.stamp && date >> build.stamp \
	    && mkdir -p ../wheels && cp -f ./dist/*.whl ../wheels \
	    && mv build.stamp .build.stamp

# specifically *unset* PYTORCH_VERSION during build, otherwise torchvision will attempt to
# require that, match closest, and download something.  Which we do not want.
vision-v$(TORCHVISION_VERSION)/.install.stamp: vision-v$(TORCHVISION_VERSION)
	rm -f $@
	source config_env.sh ;\
	  pip uninstall --yes torchvision ;\
          cd vision-v$(TORCHVISION_VERSION) ;\
	  echo "$${TORCHVISION_BUILD_VERSION}" > version.txt ;\
          PYTORCH_VERSION="$${PYTORCH_BUILD_VERSION}" ;\
          $(pkg_install_cmd) | tee install.log \
            && cp install.log install.stamp && date >> install.stamp \
	    && mv install.stamp .install.stamp

vision-v$(TORCHVISION_VERSION)/.build.stamp: vision-v$(TORCHVISION_VERSION)
	rm -f $@
	source config_env.sh ;\
          cd vision-v$(TORCHVISION_VERSION) ;\
	  echo "$${TORCHVISION_BUILD_VERSION}" > version.txt ;\
          PYTORCH_VERSION="$${PYTORCH_BUILD_VERSION}" ;\
          $(pkg_build_cmd) | tee build.log \
            && cp build.log build.stamp && date >> build.stamp \
	    && mkdir -p ../wheels && cp -f ./dist/*.whl ../wheels \
	    && mv build.stamp .build.stamp

# build under PBS with qcmd. Intended to be run on a login node.
# first make clean; this will ensure we have the source tree.  This will run on a login node.
# then for good measure simply source the config_env.sh script; this will ensure we have
# the requisite conda env. Finally; use qcmd to launch the build rule on a dedicated GPU node.
# (use Brian's qcmd wrapper at the moment due to the qsub -V problem...)
install-pytorch-v$(PYTORCH_VERSION)-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.install.stamp

build-pytorch-v$(PYTORCH_VERSION)-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.build.stamp

install-vision-v$(TORCHVISION_VERSION)-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) vision-v$(TORCHVISION_VERSION)/.install.stamp

build-vision-v$(TORCHVISION_VERSION)-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
	  qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 -- $(MAKE) vision-v$(TORCHVISION_VERSION)/.build.stamp

# umbrella install-pbs rule
install-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
          qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 \
          -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.install.stamp vision-v$(TORCHVISION_VERSION)/.install.stamp
	source config_env.sh && python ./tests/test_imports.py

# umbrella build-pbs rule
build-pbs: config_env.sh
	source config_env.sh && conda list
	PATH=/glade/derecho/scratch/vanderwb/experiment/pbs-bashfuncs/bin:$$PATH ;\
          qcmd -q main -A $(PBS_ACCOUNT) -l walltime=1:00:00 -l select=1:ncpus=128 \
          -- $(MAKE) pytorch-v$(PYTORCH_VERSION)/.build.stamp vision-v$(TORCHVISION_VERSION)/.build.stamp

nccl-ofi/install/lib/libnccl-net.so nccl-ofi/install/lib/libnccl.so nccl-ofi: \
	utils/build_nccl-ofi-plugin.sh
	./$<

# QoL rule to run etags on all git-managed source files (optionally, containing STR).
tags TAGS etags:
	if [ "x$(STR)" != "x" ]; then \
	  echo "Tagging files containing $(STR)" ; \
	  git grep -l $(STR) ; \
	  etags $$(git grep -l $(STR)) ; \
	else \
	  echo "Tagging all git managed files:" ; \
	  git ls-tree -r HEAD --name-only ; \
	  etags $$(git ls-tree -r HEAD --name-only) ; \
	fi
