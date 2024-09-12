import os

import jax
import jax.numpy as jnp
import numpy as np
from jax.experimental import multihost_utils
from jax.experimental.pjit import pjit


try:
    from mpi4py import MPI
    comm = MPI.COMM_WORLD
    shmem_comm = comm.Split_type(MPI.COMM_TYPE_SHARED)
    LOCAL_RANK = shmem_comm.Get_rank()
    WORLD_SIZE = comm.Get_size()
    WORLD_RANK = comm.Get_rank()
    jax.distributed.initialize(cluster_detection_method="mpi4py",
                               local_device_ids=LOCAL_RANK)

except:
    try:
        jax.distributed.initialize(cluster_detection_method="mpi4py",
                                   local_device_ids=[int(x)
                                                     for x in os.environ.get('CUDA_VISIBLE_DEVICES').split(',')])
    except:
        jax.distributed.initialize(cluster_detection_method="mpi4py")


jax.print_environment_info()

print('jax.devices()={}'.format(jax.devices()))
print('jax.process_count()={}'.format(jax.process_count()))
print('jax.device_count()={}'.format(jax.device_count())) # total number of accelerator devices in the cluster
print('jax.local_device_count()={}'.format(jax.local_device_count()))  # number of accelerator devices attached to this host

xs = jax.numpy.ones(jax.local_device_count())
r = jax.pmap(lambda x: jax.lax.psum(x, 'i'), axis_name='i')(xs)
print(r)

# import itertools

# import jax.numpy as np
# import numpy.random as npr
# from jax import pmap, lax
# from tqdm import tqdm


# def do_allreduce(x):
#     x_full = lax.psum(x,axis_name='i')
#     return np.mean(x_full)


# if __name__ == '__main__':

#     for i in tqdm(itertools.count()):
#         x = npr.randn(8, 1, 1024, 1024)  # 4 MB object
#         val = do_allreduce(x)
