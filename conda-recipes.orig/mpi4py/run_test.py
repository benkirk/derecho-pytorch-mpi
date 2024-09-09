#!/usr/bin/env python

import mpi4py
import mpi4py.MPI
import mpi4py.futures

if mpi4py.MPI.Get_version()[0] > 3:
    import mpi4py.util.dtlib
    import mpi4py.util.pkl5
    import mpi4py.util.pool
    import mpi4py.util.sync

print(mpi4py.get_config())
