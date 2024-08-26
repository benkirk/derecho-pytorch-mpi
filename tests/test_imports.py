#!/usr/bin/env python

import os
import sys
import glob
import yaml

from pathlib import Path
from argparse import ArgumentParser

import torch
import torch.distributed as dist
from torch.cuda.amp import GradScaler
from torch.utils.data.distributed import DistributedSampler
from torch.distributed.fsdp.sharded_grad_scaler import ShardedGradScaler
import torchvision
import mpi4py


print('\n'*3)
print('-'*80)
print(__file__)
print('All modules imported.')
print('torch version = {}'.format(torch.__version__))
print('torchvision version = {}'.format(torchvision.__version__))
print('mpi4py version = {}'.format(mpi4py.__version__))
print('-'*80)
print('\n'*3)
