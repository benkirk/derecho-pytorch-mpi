#!/usr/bin/env python

import torch
import torch.distributed as dist
#import os

#os.environ['RANK'] = os.environ['PMI_RANK']
#os.environ['WORLD_SIZE'] = os.environ['PMI_SIZE']


print(torch.__config__.show())
print(torch.__config__.parallel_info())


dist.init_process_group(backend='mpi')

t = torch.zeros(5,5).fill_(dist.get_rank()).cuda()

dist.all_reduce(t)
