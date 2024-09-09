#include <iostream>
#include <iomanip>
#include <cassert>
#include <cstdio>
#include <vector>
#include <unistd.h>
#include <omp.h>
#include "mpi.h"
#include "cuda.h"
#include "cuda_runtime.h"



enum MemType { CPU=0, GPU_Device, GPU_Managed };



int CUDA_CHECK(cudaError_t stmt)
{
  int err_n = static_cast<int>(stmt);
  if (0 != err_n) {
    fprintf(stderr, "[%s:%d] CUDA call '%s' failed with %d: %s \n",
            __FILE__, __LINE__, stmt, err_n, cudaGetErrorString(stmt));
    exit(EXIT_FAILURE);
  }
  assert(cudaSuccess == err_n);

  return 0;
}



__global__ void fillprintCUDAbuf(int* buf, std::size_t size)
{
  for (int i=0; i<size; ++i)
    {
      buf[i] = i;
      printf("%d ", buf[i]);
    }
  printf("\n");
}



int* allocate(const std::size_t size, const MemType mem_type)
{
  int* buffer = NULL;

  switch (mem_type)
    {
    case CPU:
      buffer = (int *) malloc(size*sizeof(int));
      assert (NULL != buffer);
      std::cout << "Successfully allocated " 
		<< size*sizeof(int)
		<< " bytes of CPU memory\n";
      break;

    case GPU_Device:
      CUDA_CHECK(cudaMalloc((void**) &buffer, size*sizeof(int)));
      CUDA_CHECK(cudaMemset(buffer, 0, size*sizeof(int)));
      std::cout << "Successfully allocated " 
		<< size*sizeof(int)
		<< " bytes of GPU memory\n";
      fillprintCUDAbuf<<<1, 1>>>(buffer, size);
      return buffer;

    case GPU_Managed:
      CUDA_CHECK(cudaMallocManaged((void**) &buffer, size*sizeof(int)));
      std::cout << "Successfully allocated " 
		<< size*sizeof(int)
		<< " bytes of managed GPU memory\n";
      break;

    default:
      assert (false);
      break;
    }

  for (int i=0; i<size; ++i)
    {
      buffer[i] = i;
      std::cout << buffer[i] << " ";
    }
  std::cout << std::endl;

  return buffer;
}



int deallocate (int *buffer, const MemType mem_type)
{
  if (NULL == buffer)
    return 0;

  switch (mem_type)
    {
    case CPU:
      free(buffer);
      buffer = NULL;
      break;

    case GPU_Device:
    case GPU_Managed:
      CUDA_CHECK(cudaFree(buffer));
      buffer = NULL;
      break;

    default:
      assert (false);
      break;
    }

  return 0;
}



int main (int argc, char **argv)
{
  int numprocs, rank, nthreads=1, opt;
  const std::size_t bufsize = 10;
  int *sbuf = NULL;
  int *rbuf = NULL;
  MemType mem_type = CPU;

  while((opt = getopt(argc, argv, ":dm")) != -1) 
    { 
      switch(opt) 
        { 
	case 'd':
	  mem_type = GPU_Device;
	  break; 

	case 'm':
	  mem_type = GPU_Managed;
	  break; 

	case '?': 
	  printf("unknown option: %c\n", opt);
	  break; 
        } 
    } 

#pragma omp parallel
  { if (0 == omp_get_thread_num()) nthreads = omp_get_num_threads(); }

  MPI_Init(&argc, &argv);
  MPI_Comm_size (MPI_COMM_WORLD, &numprocs);
  MPI_Comm_rank (MPI_COMM_WORLD, &rank);

  if (numprocs != 2)
    {
      std::cerr << "ERROR: this requires exactly 2 ranks!\n";
      assert(false);
    }

  std::cout << "Hello from " << std::setw(3) << rank
	    << ", running " << argv[0] << " on "
	    << std::setw(3) << numprocs << " rank(s)"
	    << " with " << nthreads << " threads"
	    << std::endl;


  //--------------------
  sbuf = allocate(bufsize, mem_type);
  rbuf = allocate(bufsize, mem_type);

  MPI_Barrier(MPI_COMM_WORLD);
  if (0 == rank)
      MPI_Send (&sbuf[0], 1, MPI_INT, /* dest = */ 1, /* tag = */ 100, MPI_COMM_WORLD); 

  else
    MPI_Recv (&rbuf[0], 1, MPI_INT, /* src = */ 0, /* tag = */ 100, MPI_COMM_WORLD, MPI_STATUS_IGNORE); 

  MPI_Barrier(MPI_COMM_WORLD);

  deallocate(sbuf, mem_type);
  deallocate(rbuf, mem_type);

  MPI_Finalize();

  return 0;
}
