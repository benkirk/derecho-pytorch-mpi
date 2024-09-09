#include <iostream>
#include <iomanip>
#include <omp.h>
#include <unistd.h>
#include "mpi.h"



int main (int argc, char **argv)
{
  int numprocs, rank, nthreads=1;
  char hn[256];

  gethostname(hn, sizeof(hn) / sizeof(char));

#pragma omp parallel
  { if (0 == omp_get_thread_num()) nthreads = omp_get_num_threads(); }

  MPI_Init(&argc, &argv);

  MPI_Comm_size (MPI_COMM_WORLD, &numprocs);
  MPI_Comm_rank (MPI_COMM_WORLD, &rank);

  std::cout << "Hello from " << std::setw(3) << rank
            << " / " << std::string (hn)
            << ", running " << argv[0] << " on "
            << std::setw(3) << numprocs << " rank(s)"
            << " with " << nthreads << " threads"
            << std::endl;

  MPI_Finalize();

  return 0;
}
