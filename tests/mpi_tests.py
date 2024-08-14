#!/usr/bin/env python

import torch
import torch.distributed as dist
from mpi4py import MPI

comm = MPI.COMM_WORLD
rank = comm.Get_rank()
size = comm.Get_size()

#import os

#os.environ['RANK'] = os.environ['PMI_RANK']
#os.environ['WORLD_SIZE'] = os.environ['PMI_SIZE']

dist.init_process_group(backend='mpi')

if 0 == rank:
    print(torch.cuda.device_count())
    print(torch.__config__.show())
    print(torch.__config__.parallel_info())


# first test come collective comm
if 0 == rank: print('Running all_reduce...')
tensor = torch.ones((1000, 1000)).cuda()
dist.all_reduce(tensor)

# now a pt2pt
del tensor
tensor = torch.zeros((1000, 1000)).cuda()
if 0 == rank:
    tensor += 1
    print('Running pt2pt test...')
    # Send the tensor to process 1
    req = dist.isend(tensor=tensor, dst=1)
    print('Rank 0 started sending')
    req.wait()
elif 1 == rank:
    # Receive tensor from process 0
    req = dist.irecv(tensor=tensor, src=0)
    print('Rank 1 started receiving')
    req.wait()


dist.barrier()

if 1 == rank:
    print('Rank ', rank, ' has data ', tensor[0])
